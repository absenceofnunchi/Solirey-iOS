//
//  PostViewController + Escrow.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-19.
//

import UIKit
import Combine
import web3swift
import BigInt

extension PostViewController {
    // MARK: - mint
    /// 1. check for existing ID
    /// 2. deploy the escrow contract
    /// 3. mint
    /// 4. upload to the firestore
    /// 5. get the token ID through the subscription to the google functions
    /// 6. update the firestore with the urls of the photos and the token information
    
    final override func processEscrow(_ mintParameters: MintParameters) {
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
                            self.progressModal = ProgressModalViewController(paymentMethod: .escrow)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress)
                                
                                var txPackageArr = [TxPackage]()
                                print("STEP 1")
                                Future<TxPackage, PostingError> { promise in
                                    self.transactionService.prepareMintTransactionWithGasEstimate(promise)
                                }
                                .flatMap({ (txPackage) -> AnyPublisher<BigUInt, PostingError> in
                                    txPackageArr.append(txPackage)
                                    guard let contractAddress = Web3swiftService.currentAddress else {
                                        return Fail(error: PostingError.retrievingCurrentAddressError)
                                            .eraseToAnyPublisher()
                                    }
                                    
                                    return Future<BigUInt, PostingError> { promise in
                                        do {
                                            // get the current nonce so that we can increment it manually
                                            // the rapid creation of transactions back to back results in the same nonce
                                            // this is true even if nonce is set to .pending
                                            print("STEP 2")
                                            let nonce = try Web3swiftService.web3instance.eth.getTransactionCount(address: contractAddress)
                                            promise(.success(nonce))
                                        } catch {
                                            promise(.failure(.generalError(reason: error.localizedDescription)))
                                        }
                                    }
                                    .eraseToAnyPublisher()
                                })
                                .flatMap { (nonce) -> AnyPublisher<TxPackage, PostingError> in
                                    print("STEP 3")
                                    return Future<TxPackage, PostingError> { promise in
                                        self.transactionService.prepareTransactionForNewContractWithGasEstimate(
                                            contractABI: purchaseABI2,
                                            bytecode: purchaseBytecode2,
                                            value: price,
                                            nonce: nonce.advanced(by: 1),
                                            promise: promise
                                        )
                                    }
                                    .eraseToAnyPublisher()
                                }
                                .flatMap { (txPackage2) -> AnyPublisher<[TxPackage], PostingError> in
                                    txPackageArr.append(txPackage2)
                                    return Future<[TxPackage], PostingError> { promise in
                                        print("STEP 4")
                                        self.transactionService.calculateTotalGasCost(with: txPackageArr, promise: promise)
                                        let update: [String: PostProgress] = ["update": .estimatGas]
                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    }
                                    .eraseToAnyPublisher()
                                }
                                // execute the transactions and get the receipts in an array
                                .flatMap { (txPackages) -> AnyPublisher<[TxResult], PostingError> in
                                    let update: [String: PostProgress] = ["update": .deployingEscrow]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    print("STEP 5")
                                    let results = txPackages.map { self.transactionService.executeTransaction(transaction: $0.transaction, password: password, type: $0.type) }
                                    return Publishers.MergeMany(results)
                                        .collect()
                                        .eraseToAnyPublisher()
                                }
                                // instantiate the socket, parse the receipts, and create the firebase entry as soon as the socket receives the data
                                // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
                                .flatMap { (txResults) -> AnyPublisher<Int, PostingError> in
                                    var topicsRetainer: [String]!
                                    return Future<[String: Any], PostingError> { promise in
                                        print("STEP 6")
                                        self.socketDelegate.promise = promise
                                    }
                                    .flatMap({ (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
                                        let update: [String: PostProgress] = ["update": .minting]
                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                        
                                        if let topics = webSocketMessage["topics"] as? [String] {
                                            topicsRetainer = topics
                                        }
                                        // upload images/files to the Firebase Storage and get the array of URLs
                                        if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
                                            print("STEP 7")
                                            let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                                                return Future<String?, PostingError> { promise in
                                                    self.uploadFileWithPromise(
                                                        fileURL: previewData.filePath,
                                                        userId: self.userId,
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
                                    .flatMap { (urlStrings) -> AnyPublisher<Int, PostingError> in
                                        var escrowHash: String!
                                        var mintHash: String!
                                        var senderAddress: String!
                                        for txResult in txResults {
                                            if txResult.txType == .deploy {
                                                escrowHash = txResult.txHash
                                            } else {
                                                mintHash = txResult.txHash
                                            }
                                            senderAddress = txResult.senderAddress
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
                                                topics: topicsRetainer,
                                                urlStrings: urlStrings,
                                                ipfsURLStrings: [],
                                                shippingInfo: self.shippingInfo,
                                                promise: promise
                                            )
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .eraseToAnyPublisher()
                                } // socket delegate
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            self.processFailure(error)
                                        case .finished:
                                            // update the progress indicator
                                            let update: [String: PostProgress] = ["update": .images]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                            
                                            FirebaseService.shared.sendToTopicsVoid(
                                                title: "New item has been listed on \(mintParameters.category)",
                                                content: mintParameters.itemTitle,
                                                topic: mintParameters.category,
                                                docId: self.documentId
                                            )
                                            
                                            // index Core Spotlight
                                            self.indexSpotlight(
                                                itemTitle: mintParameters.itemTitle,
                                                desc: mintParameters.desc,
                                                tokensArr: mintParameters.tokensArr,
                                                convertedId: mintParameters.convertedId
                                            )
                                            
                                            // reset the fields
                                            self.afterPostReset()
                                    }
                                } receiveValue: { (receivedValue) in
                                    print("receivedValue", receivedValue)
                                    self.socketDelegate.disconnectSocket()
                                }
                                .store(in: &self.storage)
                                
                            }) // progress modal
                        }) // alert VC dismissal
                    } // main VC button action
                    self?.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - processEscrowResale
    override func processEscrowResale(_ mintParameters: MintParameters) {
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
        
        // Since no new token is being minted, an existing token is used from the original post.
        guard let tokenId = post?.tokenID else {
            self.alert.showDetail("Sorry", with: "Failed to load the Token ID for the current item.", for: self)
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
                            self.progressModal = ProgressModalViewController(paymentMethod: .escrow)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                // Prepare a transaction to deploy the escrow contract
                                Future<WriteTransaction, PostingError> { promise in
                                    self.transactionService.prepareTransactionForNewContract(
                                        contractABI: purchaseABI2,
                                        bytecode: purchaseBytecode2,
                                        value: price,
                                        promise: promise
                                    )
                                }
                                .eraseToAnyPublisher()
                                .flatMap { (transaction) -> AnyPublisher<TxResult, PostingError> in
                                    // deploy the escrow contract
                                    return self.transactionService.executeTransaction(transaction: transaction, password: password, type: .deploy)
                                        .eraseToAnyPublisher()
                                }
                                .flatMap { (txResult) -> AnyPublisher<Bool, PostingError> in
                                    return self.uploadFilesResale()
                                        // upload the details to Firestore
                                        .flatMap { (urlStrings) -> AnyPublisher<Bool, PostingError> in
                                            return Future<Bool, PostingError> { promise in
                                                self.transactionService.createFireStoreEntryForResale(
                                                    documentId: &self.documentId,
                                                    senderAddress: txResult.senderAddress,
                                                    escrowHash: txResult.txHash,
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
                                                    shippingInfo: self.shippingInfo,
                                                    promise: promise
                                                )
                                            }
                                            .eraseToAnyPublisher()
                                        }
                                        .eraseToAnyPublisher()
                                }
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            self.processFailure(error)
                                        case .finished:
                                            // update the progress indicator
                                            let update: [String: PostProgress] = ["update": .images]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                            
                                            FirebaseService.shared.sendToTopicsVoid(
                                                title: "New item has been listed on \(mintParameters.category)",
                                                content: mintParameters.itemTitle,
                                                topic: mintParameters.category,
                                                docId: self.documentId
                                            )
                                            
                                            // index Core Spotlight
                                            //                                            self.indexSpotlight(
                                            //                                                itemTitle: itemTitle,
                                            //                                                desc: desc,
                                            //                                                tokensArr: tokensArr,
                                            //                                                convertedId: convertedId
                                            //                                            )
                                            
                                            self.afterPostReset()
                                            
                                    }
                                } receiveValue: { (_) in
                                    
                                }
                                .store(in: &self.storage)
                                
                            }) // self.present(self.progressModal
                        }) // dismiss
                    } // mainVC.buttonAction
                } // alertVC.action
                self?.present(alertVC, animated: true, completion: nil)
            } // DispatchQueue
        }// self.hideSpinner
    } // processEscrowResale
}
