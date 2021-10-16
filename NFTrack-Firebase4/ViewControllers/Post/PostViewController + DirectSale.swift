//
//  PostViewController + DirectSale.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-08.
//

/*
 Abstract:
 A resale through in-person pickup method.
 The payment methods for an in-person pickup method are escrow and direct sale. Escrow is the same as the shipping delivery method which can also be useful in the in-person pickup option to reduce
 the counterparty risk. The second payment method is the wallet-to-wallet direct transfer. Buyer pays the money and the seller transfer the token.
 */
import UIKit
import Combine
import BigInt
import web3swift

extension PostViewController {
    final func deploySimplePaymentContract(
        password: String,
        mintParamters: MintParameters,
        completion: @escaping ([TxResult2]) -> Void
    ) {
        guard let price = mintParamters.price else { return }
        guard let amount = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            print("cannot parse")
            return
        }
        let parameters: [AnyObject] = [amount, adminAddress!] as [AnyObject]
        
        Future<TxPackage, PostingError> { promise in
            self.transactionService.prepareTransactionForNewContractWithGasEstimate(
                contractABI: simplePaymentABI,
                bytecode: simplePaymentBytecode,
                parameters: parameters,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
        .flatMap { (txPackage) -> AnyPublisher<[TxPackage], PostingError> in
            // TxPackage array is needed because calculateTotalGasCost can calculate multiple transactions' gas.
            // In this case, there is only one transaction to be calculated.
            // The minting transaction can't be calculated because it requires the auction contract or the simple payment contract's address.
            self.txPackageArr.append(txPackage)
            return Future<[TxPackage], PostingError> { promise in
                let gasEstimateToMintAndTransferAToken: BigUInt = 80000
                self.transactionService.calculateTotalGasCost(
                    with: self.txPackageArr,
                    plus: gasEstimateToMintAndTransferAToken,
                    promise: promise
                )
                let update: [String: PostProgress] = ["update": .estimatGas]
                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
            }
            .eraseToAnyPublisher()
        }
        // execute the deployment transaction and get the receipts in an array
        .flatMap { (txPackages) -> AnyPublisher<[TxResult2], PostingError> in
            let results = txPackages.map { self.transactionService.executeTransaction2(
                transaction: $0.transaction,
                password: password,
                type: $0.type
            )}
            return Publishers.MergeMany(results)
                .collect()
                .eraseToAnyPublisher()
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(let error):
                    self?.processFailure(error)
                case .finished:
                    let update: [String: PostProgress] = ["update": .deployingEscrow]
                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                    break
            }
        } receiveValue: { [weak self](txResults) in
            self?.txResultArr = txResults
            completion(txResults)
        }
        .store(in: &storage)
    }
    
    // First time sale for SimplePayment
    final func mintAndTransfer(_ txReceipt: TransactionReceipt, password: String, mintParameters: MintParameters) {
        let update: [String: PostProgress] = ["update": .deployingAuction]
        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
    
        guard let simplePaymentContractAddress = txReceipt.contractAddress else {
            return
        }
        // mint a token and transfer it to the address of the newly deployed auction contract
        Deferred {
            Future<WriteTransaction, PostingError> { promise in
                self.transactionService.prepareTransactionForMinting(
                    receiverAddress: simplePaymentContractAddress,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        // execute the mint transaction
        .flatMap { (transaction) -> AnyPublisher<[TxResult2], PostingError> in
            let results = self.transactionService.executeTransaction2(
                transaction: transaction,
                password: password,
                type: .mint
            )
            
            return Publishers.MergeMany(results)
                .collect()
                .eraseToAnyPublisher()
        }
        // get the topics from the socket delegate
        .flatMap { [weak self] (txResult) -> AnyPublisher<[String: Any], PostingError> in
            let update: [String: PostProgress] = ["update": .minting]
            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
            
            // retain the mint transaction details for FireStore
            self?.txResultArr.append(contentsOf: txResult)
            return Future<[String: Any], PostingError> { promise in
                self?.socketDelegate.promise = promise
            }
            .eraseToAnyPublisher()
        }
        // instantiate the socket, parse the topics, and create the firebase entry as soon as the socket delegate receives the data
        // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
        .flatMap({ [weak self] (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
            let update: [String: PostProgress] = ["update": .minting]
            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
            
            if let topics = webSocketMessage["topics"] as? [String] {
                self?.topicsRetainer = topics
            }
            
            guard let userId = self?.userId else {
                return Fail(error: PostingError.generalError(reason: "Unable to fetch the user ID."))
                    .eraseToAnyPublisher()
            }
            
            // upload images/files to the Firebase Storage and get the array of URLs
            if let previewDataArr = self?.previewDataArr, previewDataArr.count > 0 {
                let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                    return Future<String?, PostingError> { promise in
                        self?.uploadFileWithPromise(
                            fileURL: previewData.filePath,
                            userId: userId,
                            promise: promise
                        )
                    }.eraseToAnyPublisher()
                }
                return Publishers.MergeMany(fileURLs)
                    .collect()
                    .eraseToAnyPublisher()
            } else {
                // if there are none to upload, return an empty array
                return Result.Publisher([] as [String]).eraseToAnyPublisher()
            }
        })
        // upload the details to Firestore
        .flatMap { [weak self] (urlStrings) -> AnyPublisher<Int, PostingError> in
            let update: [String: PostProgress] = ["update": .images]
            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
            
            guard let price = mintParameters.price,
                  let topics = self?.topicsRetainer,
                  let txResults = self?.txResultArr else {
                return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
                    .eraseToAnyPublisher()
            }
            
            var mintHash: String!
            var senderAddress: String!
            var escrowHash: String!
            for txResult in txResults {
                if txResult.txType == .deploy {
                    escrowHash = txResult.txResult.hash
                } else {
                    mintHash = txResult.txResult.hash
                }
                senderAddress = txResult.senderAddress
            }
            
            guard let self = self else {
                return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
                    .eraseToAnyPublisher()
            }
            return Future<Int, PostingError> { promise in
                self.transactionService.createFireStoreEntry(
                    documentId: &self.documentId,
                    senderAddress: senderAddress,
                    escrowHash: escrowHash,
                    auctionHash: "N/A",
                    mintHash: mintHash,
                    itemTitle: mintParameters.itemTitle,
                    desc: mintParameters.desc,
                    price: price,
                    category: mintParameters.category,
                    tokensArr: mintParameters.tokensArr,
                    convertedId: mintParameters.convertedId,
                    type: "tangible",
                    deliveryMethod: mintParameters.deliveryMethod,
                    saleFormat: mintParameters.saleFormat,
                    paymentMethod: mintParameters.paymentMethod,
                    topics: topics,
                    urlStrings: urlStrings,
                    ipfsURLStrings: [],
                    isWithdrawn: false,
                    isAdminWithdrawn: false,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(let error):
                    self?.processFailure(error)
                case .finished:
                    // index Core Spotlight
                    self?.indexSpotlight(
                        itemTitle: mintParameters.itemTitle,
                        desc: mintParameters.desc,
                        tokensArr: mintParameters.tokensArr,
                        convertedId: mintParameters.convertedId
                    )
                    
                    self?.afterPostReset()
            }
        } receiveValue: { (receivedValue) in
            if self.socketDelegate != nil {
                self.socketDelegate.disconnectSocket()
            }
        }
        .store(in: &self.storage)
    }
    
    // Transfer the existing token for resale using SimplePayment
    final func transfer(
        receipt: TransactionReceipt,
        password: String,
        mintParameters: MintParameters
    ) {
        let update: [String: PostProgress] = ["update": .deployingEscrow]
        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        
        Future<WriteTransaction, PostingError> { [weak self] promise in
            guard let fromAddress = Web3swiftService.currentAddress else {
                promise(.failure(.generalError(reason: "Could not get your address.")))
                return
            }
            
            guard let simplePaymentContractAddress = receipt.contractAddress else {
                return
            }
            
            guard let tokenId = self?.post?.tokenID else {
                promise(.failure(.generalError(reason: "The item does not have a token ID registered. It may take up to 10 mins to process.")))
                return
            }
            
            let param: [AnyObject] = [fromAddress, simplePaymentContractAddress, tokenId] as [AnyObject]
            
            guard let NFTrackAddress = NFTrackAddress else {
                promise(.failure(.generalError(reason: "Unable to load the contract address.")))
                return
            }
            
            self?.transactionService.prepareTransactionForWriting(
                method: "safeTransferFrom",
                abi: NFTrackABI,
                param: param,
                contractAddress: NFTrackAddress,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
        .flatMap { (transaction) -> AnyPublisher<TransactionSendingResult, PostingError> in
            Future<TransactionSendingResult, PostingError> { promise in
                do {
                    let receipt = try transaction.send(password: password, transactionOptions: nil)
                    promise(.success(receipt))
                } catch {
                    if let err = error as? Web3Error {
                        promise(.failure(.generalError(reason: err.errorDescription)))
                    } else {
                        promise(.failure(.generalError(reason: error.localizedDescription)))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap { (txResult) -> AnyPublisher<Bool, PostingError> in
            return self.uploadFilesResale()
                // upload the details to Firestore
                .flatMap { [weak self] (urlStrings) -> AnyPublisher<Bool, PostingError> in
                    guard let tokenId = self?.post?.tokenID,
                          let senderAddress = Web3swiftService.currentAddressString,
                          let price = mintParameters.price else {
                        return Fail(error: PostingError.generalError(reason: "Could not prepare the information to update the database."))
                            .eraseToAnyPublisher()
                    }
                    
                    let update: [String: PostProgress] = ["update": .images]
                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                    
                    return Future<Bool, PostingError> { promise in
                        self?.transactionService.createFireStoreEntryForResale(
                            documentId: &self!.documentId,
                            senderAddress: senderAddress,
                            escrowHash: txResult.hash,
                            auctionHash: "N/A",
                            mintHash: "Resale",
                            itemTitle: mintParameters.itemTitle,
                            desc: mintParameters.desc,
                            price: price,
                            category: mintParameters.category,
                            tokensArr: mintParameters.tokensArr,
                            convertedId: mintParameters.convertedId,
                            type: "tangible",
                            deliveryMethod: mintParameters.deliveryMethod,
                            saleFormat: mintParameters.saleFormat,
                            paymentMethod: mintParameters.paymentMethod,
                            tokenId: tokenId,
                            urlStrings: urlStrings,
                            ipfsURLStrings: [],
                            shippingInfo: self?.shippingInfo,
                            promise: promise
                        )
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(let error):
                    self?.processFailure(error)
                case .finished:
                    self?.alert.showDetail("Success!", with: "You have successfully posted your item.", for: self)
                    self?.afterPostReset()

                    guard let documentId = self?.documentId else { return }
                    FirebaseService.shared.sendToTopicsVoid(
                        title: "New item has been listed on \(mintParameters.category)",
                        content: mintParameters.itemTitle,
                        topic: mintParameters.category,
                        docId: documentId
                    )

                    //  register spotlight?
            }
        } receiveValue: { (_) in
            
        }
        .store(in: &self.storage)
    }
} // PostViewController
