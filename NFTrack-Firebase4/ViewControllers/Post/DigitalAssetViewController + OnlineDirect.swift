//
//  DigitalAssetViewController + OnlineDirect.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-05.
//

//import UIKit
//import Combine
//import BigInt
//
//extension DigitalAssetViewController {
//    // MARK: - onlineDirect
//    final func onlineDirect(
//        price: String,
//        itemTitle: String,
//        desc: String,
//        category: String,
//        convertedId: String,
//        tokensArr: Set<String>,
//        userId: String,
//        deliveryMethod: String,
//        saleFormat: String,
//        paymentMethod: String
//    ) {
//        //        guard let contractAddress = NFTrackAddress?.address else {
//        //            self.alert.showDetail("Sorry", with: "There was an error loading the contract address.", for: self)
//        //            return
//        //        }
//        //        self.socketDelegate = SocketDelegate(contractAddress: contractAddress)
//        
//        guard !price.isEmpty else {
//            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
//            return
//        }
//        
//        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
//        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
//        //            return
//        //        }
//        
//        guard let convertedPrice = Double(price), convertedPrice > 0.0000000000000001 else {
//            self.alert.showDetail("Price Limit", with: "The price has to be greater than 0.01 ETH.", for: self)
//            return
//        }
//        
//        guard let NFTrackAddress = NFTrackAddress else {
//            self.alert.showDetail("Sorry", with: "There was an error loading the minting contract address.", for: self)
//            return
//        }
//        
//        self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress)
//        
//        let content = [
//            StandardAlertContent(
//                titleString: "",
//                body: [AlertModalDictionary.passwordSubtitle: ""],
//                isEditable: true,
//                fieldViewHeight: 50,
//                messageTextAlignment: .left,
//                alertStyle: .withCancelButton
//            ),
//            StandardAlertContent(
//                titleString: "Transaction Options",
//                body: [AlertModalDictionary.gasLimit: "", AlertModalDictionary.gasPrice: "", AlertModalDictionary.nonce: ""],
//                isEditable: true,
//                fieldViewHeight: 50,
//                messageTextAlignment: .left,
//                alertStyle: .noButton
//            )]
//        
//        
//        self.hideSpinner {
//            DispatchQueue.main.async {
//                let alertVC = AlertViewController(height: 400, standardAlertContent: content)
//                alertVC.action = { [weak self] (modal, mainVC) in
//                    mainVC.buttonAction = { _ in
//                        guard let self = self else { return }
//                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
//                              !password.isEmpty else {
//                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
//                            return
//                        }
//                        
//                        self.dismiss(animated: true, completion: {
//                            self.progressModal = ProgressModalViewController(paymentMethod: .escrow)
//                            self.progressModal.titleString = "Posting In Progress"
//                            self.present(self.progressModal, animated: true, completion: {
//                                Future<TxPackage, PostingError> { promise in
//                                    self.transactionService.prepareMintTransactionWithGasEstimate(promise)
//                                }
//                                .eraseToAnyPublisher()
//                                .flatMap({ (txPackage) -> AnyPublisher<BigUInt, PostingError> in
//                                    self.txPackageRetainer.append(txPackage)
//                                    guard let contractAddress = Web3swiftService.currentAddress else {
//                                        return Fail(error: PostingError.retrievingCurrentAddressError)
//                                            .eraseToAnyPublisher()
//                                    }
//                                    return Future<BigUInt, PostingError> { promise in
//                                        do {
//                                            // get the current nonce so that we can increment it manually
//                                            // the rapid creation of transactions back to back results in the same nonce
//                                            // this is true even if nonce is set to .pending
//                                            print("STEP 2")
//                                            let nonce = try Web3swiftService.web3instance.eth.getTransactionCount(address: contractAddress)
//                                            promise(.success(nonce))
//                                        } catch {
//                                            promise(.failure(.generalError(reason: error.localizedDescription)))
//                                        }
//                                    }
//                                    .eraseToAnyPublisher()
//                                })
//                                .flatMap { (nonce) -> AnyPublisher<TxPackage, PostingError> in
//                                    return Future<TxPackage, PostingError> { promise in
//                                        self.transactionService.prepareTransactionForNewContractWithGasEstimate(
//                                            contractABI: purchaseABI2,
//                                            bytecode: purchaseBytecode2,
//                                            value: price,
//                                            nonce: nonce.advanced(by: 1),
//                                            promise: promise
//                                        )
//                                    }
//                                    .eraseToAnyPublisher()
//                                }
//                                .flatMap { (txPackage) -> AnyPublisher<[TxPackage], PostingError> in
//                                    self.txPackageRetainer.append(txPackage)
//                                    
//                                    return Future<[TxPackage], PostingError> { promise in
//                                        self.transactionService.calculateTotalGasCost(with: self.txPackageRetainer, promise: promise)
//                                        let update: [String: PostProgress] = ["update": .estimatGas]
//                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                                    }
//                                    .eraseToAnyPublisher()
//                                }
//                                // execute the transactions and get the receipts in an array
//                                .flatMap { (txPackages) -> AnyPublisher<[TxResult], PostingError> in
//                                    let results = txPackages.map { self.transactionService.executeTransaction(transaction: $0.transaction, password: password, type: $0.type) }
//                                    
//                                    let update: [String: PostProgress] = ["update": .images]
//                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                                    return Publishers.MergeMany(results)
//                                        .collect()
//                                        .eraseToAnyPublisher()
//                                }
//                                // instantiate the socket, parse the receipts, and create the firebase entry as soon as the socket receives the data
//                                // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
//                                .flatMap { (txResults) -> AnyPublisher<Int, PostingError> in
//                                    var topicsRetainer: [String]!
//                                    return Future<[String: Any], PostingError> { promise in
//                                        self.socketDelegate.promise = promise
//                                    }
//                                    .flatMap({ (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
//                                        if let topics = webSocketMessage["topics"] as? [String] {
//                                            topicsRetainer = topics
//                                        }
//                                        
//                                        if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
//                                            let fileURLS = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
//                                                return Future<String?, PostingError> { promise in
//                                                    self.uploadFileWithPromise(fileURL: previewData.filePath, userId: self.userId, promise: promise)
//                                                }
//                                                .eraseToAnyPublisher()
//                                            }
//                                            
//                                            return Publishers.MergeMany(fileURLS)
//                                                .collect()
//                                                .eraseToAnyPublisher()
//                                        } else {
//                                            return Result.Publisher([] as [String]).eraseToAnyPublisher()
//                                        }
//                                    })
//                                    // upload to IPFS and get the URLs
//                                    //                                    .flatMap({ (urlStrings) -> AnyPublisher<[String?], PostingError> in
//                                    //                                        self.storageURLsRetainer = urlStrings
//                                    //                                        if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
//                                    //                                            let ipfsURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
//                                    //                                                guard let image = previewData.originalImage else {
//                                    //                                                    return Fail(error: PostingError.generalError(reason: "Failed to convert data to image."))
//                                    //                                                        .eraseToAnyPublisher()
//                                    //                                                }
//                                    //
//                                    //                                                return Future<String?, PostingError> { promise in
//                                    //                                                    IPFSService.shared.uploadImage(image: image, promise: promise)
//                                    //                                                }
//                                    //                                                .eraseToAnyPublisher()
//                                    //                                            }
//                                    //
//                                    //                                            return Publishers.MergeMany(ipfsURLs)
//                                    //                                                .collect()
//                                    //                                                .eraseToAnyPublisher()
//                                    //                                        } else {
//                                    //                                            return Result.Publisher([] as [String]).eraseToAnyPublisher()
//                                    //                                        }
//                                    //                                    })
//                                    // using the urlStrings from Firebase Storage and the user input, create a Firebase entry
//                                    // A Cloud Functions method will be invoked to update the entry with the minted token's ID at the end
//                                    .flatMap { (urlStrings) -> AnyPublisher<Int, PostingError> in
//                                        var escrowHash: String!
//                                        var mintHash: String!
//                                        var senderAddress: String!
//                                        for txResult in txResults {
//                                            if txResult.txType == .deploy {
//                                                escrowHash = txResult.txHash
//                                            } else {
//                                                mintHash = txResult.txHash
//                                            }
//                                            senderAddress = txResult.senderAddress
//                                        }
//                                        
//                                        return Future<Int, PostingError> { promise in
//                                            self.transactionService.createFireStoreEntry(
//                                                documentId: &self.documentId,
//                                                senderAddress: senderAddress,
//                                                escrowHash: escrowHash,
//                                                auctionHash: "N/A",
//                                                mintHash: mintHash,
//                                                itemTitle: itemTitle,
//                                                desc: desc,
//                                                price: price,
//                                                category: category,
//                                                tokensArr: tokensArr,
//                                                convertedId: convertedId,
//                                                type: "digital",
//                                                deliveryMethod: deliveryMethod,
//                                                saleFormat: saleFormat,
//                                                paymentMethod: paymentMethod,
//                                                topics: topicsRetainer,
//                                                urlStrings: urlStrings,
//                                                ipfsURLStrings: urlStrings,
//                                                promise: promise
//                                            )
//                                        }
//                                        .eraseToAnyPublisher()
//                                    }
//                                    .eraseToAnyPublisher()
//                                }
//                                .sink { (completion) in
//                                    switch completion {
//                                        case .failure(let error):
//                                            switch error {
//                                                case .fileUploadError(.fileNotAvailable):
//                                                    self.alert.showDetail("Error", with: "No image file was found.", for: self)
//                                                case .retrievingEstimatedGasError:
//                                                    self.alert.showDetail("Error", with: "There was an error retrieving the gas estimation.", for: self)
//                                                case .retrievingGasPriceError:
//                                                    self.alert.showDetail("Error", with: "There was an error retrieving the current gas price.", for: self)
//                                                case .contractLoadingError:
//                                                    self.alert.showDetail("Error", with: "There was an error loading your contract ABI.", for: self)
//                                                case .retrievingCurrentAddressError:
//                                                    self.alert.showDetail("Error", with: "There was an error retrieving your current account address.", for: self)
//                                                case .createTransactionIssue:
//                                                    self.alert.showDetail("Error", with: "There was an error creating a transaction.", for: self)
//                                                case .insufficientFund(let msg):
//                                                    self.alert.showDetail("Error", with: msg, height: 500, fieldViewHeight: 300, alignment: .left, for: self)
//                                                case .emptyAmount:
//                                                    self.alert.showDetail("Error", with: "The ETH value cannot be blank for the transaction.", for: self)
//                                                case .invalidAmountFormat:
//                                                    self.alert.showDetail("Error", with: "The ETH value is in an incorrect format.", for: self)
//                                                case .generalError(reason: let msg):
//                                                    self.alert.showDetail("Error", with: msg, for: self)
//                                                case .apiError(.generalError(reason: let err)):
//                                                    self.alert.showDetail("Error", with: err, for: self)
//                                                default:
//                                                    self.alert.showDetail("Error", with: "There was an error creating your post.", for: self)
//                                            }
//                                        case .finished:
//                                            DispatchQueue.main.async {
//                                                self.titleTextField.text?.removeAll()
//                                                self.priceTextField.text?.removeAll()
//                                                self.descTextView.text?.removeAll()
//                                                self.idTextField.text?.removeAll()
//                                                self.saleMethodLabel.text?.removeAll()
//                                                self.auctionDurationLabel.text?.removeAll()
//                                                self.auctionStartingPriceTextField.text?.removeAll()
//                                                self.pickerLabel.text?.removeAll()
//                                                self.tagTextField.tokens.removeAll()
//                                                self.paymentMethodLabel.text?.removeAll()
//                                            }
//                                            
//                                            // index Core Spotlight
//                                            self.indexSpotlight(
//                                                itemTitle: itemTitle,
//                                                desc: desc,
//                                                tokensArr: tokensArr,
//                                                convertedId: convertedId
//                                            )
//                                            
//                                            if self.previewDataArr.count > 0 {
//                                                self.previewDataArr.removeAll()
//                                                self.imagePreviewVC.data.removeAll()
//                                                DispatchQueue.main.async {
//                                                    self.imagePreviewVC.collectionView.reloadData()
//                                                }
//                                            }
//                                            
//                                            self.socketDelegate.disconnectSocket()
//                                            let update: [String: PostProgress] = ["update": .deployingEscrow]
//                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                                            
//                                            let mintUpdate: [String: PostProgress] = ["update": .minting]
//                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: mintUpdate)
//                                    }
//                                } receiveValue: { (tokenId) in
//                                    print("tokenId", tokenId)
//                                }
//                                .store(in: &self.storage)
//                                
//                            }) // present for progresModel
//                        }) // dismiss
//                    } // mainVC button action
//                } // alertVC
//                self.present(alertVC, animated: true, completion: nil)
//            } // dispatchqueue
//        } // hideSpinner
//    }
//    
//}
