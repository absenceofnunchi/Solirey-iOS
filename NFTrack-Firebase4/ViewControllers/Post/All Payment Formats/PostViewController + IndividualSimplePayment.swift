//
//  PostViewController + IndividualSimplePayment.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-08.
//

/*
 Abstract:
 Direct sale uses the deployment of SimplePayment contract by the seller.
 Currently not in use since the deployment of the contract for each item is costly.
 
 */
import UIKit
import Combine
import BigInt
import web3swift

extension PostViewController {
    // MARK: - processDirectSale
    final override func processDirectSale(_ mintParameters: MintParameters) {
        guard let price = mintParameters.price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        // change back to this after testing
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
            return
        }
        
        guard let NFTrackAddress = NFTrackAddress else {
            self.alert.showDetail("Sorry", with: "There was an error loading the minting contract address.", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                titleString: "",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                titleString: "Transaction Options",
                body: [AlertModalDictionary.gasLimit: "", AlertModalDictionary.gasPrice: "", AlertModalDictionary.nonce: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner {
            DispatchQueue.main.async {
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let self = self else { return }
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                            return
                        }
                        
                        self.dismiss(animated: true, completion: {
                            self.progressModal = ProgressModalViewController(paymentMethod: .directTransfer)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress)
                                // Deploy a simple payment contract, mint a token, and transfer it into the contract.
                                self.deploySimplePaymentContract(password: password, mintParamters: mintParameters) { (txResults) in
                                    guard let txResult = txResults.first else { return }
                                    // confirm that the receipt of the deployment transaction is obtained
                                    self.transactionService.confirmReceipt(txHash: txResult.txResult.hash)
                                        .sink { (completion) in
                                            switch completion {
                                                case .failure(let error):
                                                    self.processFailure(error)
                                                default:
                                                    break
                                            }
                                        } receiveValue: { (receipt) in
                                            print(receipt)
                                            // confirm that the block is added to the chain
                                            self.transactionService.confirmTransactions(receipt)
                                                .sink(receiveCompletion: { (completion) in
                                                    switch completion {
                                                        case .failure(let error):
                                                            self.processFailure(error)
                                                        default:
                                                            break
                                                    }
                                                }, receiveValue: { (receipt) in
                                                    // mint a new token and transfer it to the payment contract
                                                    self.mintAndTransfer(receipt, password: password, mintParameters: mintParameters)
                                                })
                                                .store(in: &self.storage)
                                        }
                                        .store(in: &self.storage)
                                } // deploySimplePaymentcontract
                            }) // self.present for ProgressModalVC
                        }) // self.dismiss
                    } //buttonAction
                } // alertVC.Action
                self.present(alertVC, animated: true, completion: nil)
            } // DispatchQueue
        } // hideSpinner
    } // processDirectSale
    
    // MARK: - processDirectResale
    override func processDirectResale(_ mintParameters: MintParameters) {
        guard let price = mintParameters.price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                titleString: "",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                titleString: "Transaction Options",
                body: [AlertModalDictionary.gasLimit: "", AlertModalDictionary.gasPrice: "", AlertModalDictionary.nonce: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner {
            DispatchQueue.main.async { [weak self] in
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let self = self else { return }
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                            return
                        } // password guard
                        
                        self.dismiss(animated: true, completion: {
                            self.progressModal = ProgressModalViewController(paymentMethod: .directTransfer)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                // Deploy a simple payment contract, mint a token, and transfer it into the contract.
                                self.deploySimplePaymentContractForResale(password: password, mintParamters: mintParameters) { (txResults) in
                                    guard let txResult = txResults.first else { return }
                                    // confirm that the receipt of the transaction is obtained
                                    self.transactionService.confirmReceipt(txHash: txResult.txResult.hash)
                                        .sink { (completion) in
                                            switch completion {
                                                case .failure(let error):
                                                    self.processFailure(error)
                                                default:
                                                    break
                                            }
                                        } receiveValue: { (receipt) in
                                            print(receipt)
                                            // confirm that the block is added to the chain
                                            self.transactionService.confirmTransactions(receipt)
                                                .sink(receiveCompletion: { (completion) in
                                                    switch completion {
                                                        case .failure(let error):
                                                            self.processFailure(error)
                                                        default:
                                                            break
                                                    }
                                                }, receiveValue: { (receipt) in
                                                    // Transfer the existing token into the payment contract
                                                    self.transfer(
                                                        receipt: receipt,
                                                        password: password,
                                                        mintParameters: mintParameters
                                                    )
                                                })
                                                .store(in: &self.storage)
                                        }
                                        .store(in: &self.storage)
                                }
                            }) // self.present for progressModal
                        }) // self.dismiss
                    } // mainVC.buttonAction
                } // alertVC.action
                self?.present(alertVC, animated: true, completion: nil)
            } // Dispatchqueue
        } // hidesSpinner
    }
}

extension PostViewController {
    final func deploySimplePaymentContract(
        password: String,
        mintParamters: MintParameters,
        completion: @escaping ([TxResult2]) -> Void
    ) {
        guard let price = mintParamters.price,
              let amount = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            alert.showDetail("Error", with: "Unable to parse the price into the correct format.", for: self)
            return
        }

        guard let adminAddress = adminAddress else {
            return
        }
        
        let simplePaymentParameters: [AnyObject] = [amount, adminAddress] as [AnyObject]
        
        Deferred {
            Future<TxPackage, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForNewContractWithGasEstimate(
                    contractABI: simplePaymentABI,
                    bytecode: simplePaymentBytecode,
                    parameters: simplePaymentParameters,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        .flatMap { [weak self] (txPackage) -> AnyPublisher<[TxPackage], PostingError> in
            // TxPackage array is needed because calculateTotalGasCost can calculate multiple transactions' gas.
            // In this case, there is only one transaction to be calculated.
            // The minting transaction can't be calculated because it requires the auction contract or the simple payment contract's address.
            self?.txPackageArr.append(txPackage)
            guard let txPackageArr = self?.txPackageArr else {
                return Fail(error: PostingError.generalError(reason: "Unable to calculate the total gas cost."))
                    .eraseToAnyPublisher()
            }
            return Future<[TxPackage], PostingError> { promise in
                let gasEstimateToMintAndTransferAToken: BigUInt = 80000
                self?.transactionService.calculateTotalGasCost(
                    with: txPackageArr,
                    plus: gasEstimateToMintAndTransferAToken,
                    promise: promise
                )
                let update: [String: PostProgress] = ["update": .estimatGas]
                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
            }
            .eraseToAnyPublisher()
        }
        // execute the deployment transaction and get the receipts in an array
        .flatMap { [weak self] (txPackages) -> AnyPublisher<[TxResult2], PostingError> in
            guard let txService = self?.transactionService else {
                return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                    .eraseToAnyPublisher()
            }
            let results = txPackages.map { txService.executeTransaction2(
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
        } receiveValue: { (txResults) in
            completion(txResults)
        }
        .store(in: &storage)
    }
    
    // Resale checks for the ownership of the token by the current wallet first
    final func deploySimplePaymentContractForResale(
        password: String,
        mintParamters: MintParameters,
        completion: @escaping ([TxResult2]) -> Void
    ) {
        guard let price = mintParamters.price,
              let amount = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            alert.showDetail("Error", with: "Unable to parse the price into the correct format.", for: self)
            return
        }
        
        guard let NFTrackAddress = NFTrackAddress else {
            alert.showDetail("Error", with: "Unable to retrieve the smart contract address for checking the ownership.", for: self)
            return
        }
        
        guard let tokenId = post?.tokenID else {
            self.alert.showDetail("Sorry", with: "Failed to load the Token ID for the current item.", for: self)
            return
        }
        
        guard let adminAddress = adminAddress else {
            return
        }
        
        let ownerOfParameters: [AnyObject] = [tokenId] as [AnyObject]
        let simplePaymentParameters: [AnyObject] = [amount, adminAddress] as [AnyObject]
        
        // First ensure that the current wallet address is the owner of the item by invoking the ownerOf method on NFTrack.
        // This is to to be executed first to prevent the SimplePayment contract to be launched only to discover that the token cannot be transferred into it.
        // Since this is a "view" method that doesn't modify any states on the contract, no gas should be consumed and should be left out of the gas estimate.
        // If the comparison proves that the current wallet is the true owner, calculate the total gas, prepare the transaction and deploy the SimplePayment contract.
        Deferred {
            Future<SmartContractProperty, PostingError> { promise in
                self.transactionService.prepareTransactionForReading(
                    method: NFTrackContract.ContractMethods.ownerOf.rawValue,
                    parameters: ownerOfParameters,
                    abi: NFTrackABI,
                    contractAddress: NFTrackAddress,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        .flatMap { (propertyFetchModel) -> AnyPublisher<Bool, PostingError> in
            Future<Bool, PostingError> { promise in
                do {
                    guard let transaction = propertyFetchModel.transaction else {
                        promise(.failure(.generalError(reason: "Unable to prepare the read transaction.")))
                        return
                    }

                    let result: [String: Any] = try transaction.call()
                    guard let ownerAddress = result["0"] as? EthereumAddress else {
                        promise(.failure(PostingError.generalError(reason: "Unable to parse the data from the smart contract.")))
                        return
                    }

                    if ownerAddress == Web3swiftService.currentAddress {
                        // If the owner address matches the current wallet address, then proceed with the resale process
                        promise(.success(true))
                    } else {
                        // If the token doesn't belong to this wallet's address, stop the process
                        promise(.failure(PostingError.generalError(reason: "The current wallet address is not the owner of this item.")))
                    }
                }  catch {
                    promise(.failure(.generalError(reason: "Unable to parse data from the smart contract.")))
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ [weak self] (_) -> AnyPublisher<TxPackage, PostingError> in
            // Now that the ownership is proven, prepare and deploy the SimplePayment contract for resale
            Future<TxPackage, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForNewContractWithGasEstimate(
                    contractABI: simplePaymentABI,
                    bytecode: simplePaymentBytecode,
                    parameters: simplePaymentParameters,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        })
        .flatMap { [weak self] (txPackage) -> AnyPublisher<[TxPackage], PostingError> in
            // TxPackage array is needed because calculateTotalGasCost can calculate multiple transactions' gas.
            // In this case, there is only one transaction to be calculated.
            // The minting transaction can't be calculated because it requires the auction contract or the simple payment contract's address.
            self?.txPackageArr.append(txPackage)
            guard let txPackageArr = self?.txPackageArr else {
                return Fail(error: PostingError.generalError(reason: "Unable to calculate the total gas cost."))
                    .eraseToAnyPublisher()
            }
            return Future<[TxPackage], PostingError> { promise in
                let gasEstimateToMintAndTransferAToken: BigUInt = 80000
                self?.transactionService.calculateTotalGasCost(
                    with: txPackageArr,
                    plus: gasEstimateToMintAndTransferAToken,
                    promise: promise
                )
                let update: [String: PostProgress] = ["update": .estimatGas]
                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
            }
            .eraseToAnyPublisher()
        }
        // execute the deployment transaction and get the receipts in an array
        .flatMap { [weak self] (txPackages) -> AnyPublisher<[TxResult2], PostingError> in
            guard let txService = self?.transactionService else {
                return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                    .eraseToAnyPublisher()
            }
            let results = txPackages.map { txService.executeTransaction2(
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
            print("txResults", txResults)
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
            Future<WriteTransaction, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForMinting(
                    receiverAddress: simplePaymentContractAddress,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        // execute the mint transaction
        .flatMap { [weak self] (transaction) -> AnyPublisher<[TxResult2], PostingError> in
            guard let txService = self?.transactionService else {
                return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                    .eraseToAnyPublisher()
            }
            
            let results = txService.executeTransaction2(
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
    // Upload the item details to Firestore
    final func transfer(
        receipt: TransactionReceipt,
        password: String,
        mintParameters: MintParameters
    ) {
        let update: [String: PostProgress] = ["update": .deployingEscrow]
        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        
        Future<WriteTransaction, PostingError> { [weak self] promise in
            guard let fromAddress = Web3swiftService.currentAddress else {
                promise(.failure(.generalError(reason: "Could not get your wallet address.")))
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
                method: NFTrackContract.ContractMethods.safeTransferFrom.rawValue,
                abi: NFTrackABI,
                param: param,
                contractAddress: NFTrackAddress,
                amountString: nil,
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
