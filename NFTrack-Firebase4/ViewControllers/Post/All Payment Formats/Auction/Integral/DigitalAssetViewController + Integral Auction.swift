//
//  DigitalAssetViewController + Integral Auction.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-04.
//

import UIKit
import Combine
import web3swift

extension DigitalAssetViewController {
    final func getIntegralAuctionEstimate(transactionParameters: [AnyObject]) -> AnyPublisher<TxPackage, PostingError> {
        Future<TxPackage, PostingError> { [weak self] promise in
            guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress else {
                promise(.failure(PostingError.generalError(reason: "Unable to prepare the contract address.")))
                return
            }
            
            self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                method: IntegralAuctionContract.ContractMethods.createAuction.rawValue,
                abi: integralAuctionABI,
                param: transactionParameters,
                contractAddress: integralAuctionAddress,
                amountString: nil,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
    }
    
//    // MARK: - newIntegralAuction
//    func getIntegralAuctionEstimate1(
//        mintParameters: MintParameters,
//        biddingTime: Int,
//        startingBid: NSNumber
//    ) {
//        guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress else {
//            return
//        }
//
//        // The parameters for the createAuction method
//        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
//
//        Deferred { [weak self] in
//            Future<Bool, PostingError> { promise in
//                self?.db.collection("post")
//                    .whereField("itemIdentifier", isEqualTo: mintParameters.convertedId)
//                    .whereField("status", isNotEqualTo: "complete")
//                    .getDocuments() { (querySnapshot, err) in
//                        if let err = err {
//                            print("error from the duplicate check", err)
//                            promise(.failure(PostingError.generalError(reason: "Unable to check for the Unique Identifier duplicates")))
//                            return
//                        }
//
//                        if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
//                            promise(.success(true))
//                        } else {
//                            promise(.failure(PostingError.generalError(reason: "The item already exists. Please resell it through the app instead of selling it as a new item.")))
//                        }
//                    }
//            }
//        }
//        .flatMap { (_) -> AnyPublisher<TxPackage, PostingError> in
//            Future<TxPackage, PostingError> { [weak self] promise in
//                self?.transactionService.prepareTransactionForWritingWithGasEstimate(
//                    method: IntegralAuctionContract.ContractMethods.createAuction.rawValue,
//                    abi: integralAuctionABI,
//                    param: transactionParameters,
//                    contractAddress: integralAuctionAddress,
//                    amountString: nil,
//                    promise: promise
//                )
//            }
//            .eraseToAnyPublisher()
//        }
//        .flatMap({ [weak self] (txPackage) -> AnyPublisher<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> in
//            self?.txPackageArr.append(txPackage)
//            return Future<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> { promise in
//                self?.transactionService.estimateGas(
//                    gasEstimate: txPackage.gasEstimate,
//                    promise: promise
//                )
//            }
//            .eraseToAnyPublisher()
//        })
//        .sink { [weak self] (completion) in
//            switch completion {
//                case .finished:
//                    break
//                case .failure(let error):
//                    self?.processFailure(error)
//                    break
//            }
//        } receiveValue: { [weak self] (estimates) in
//            self?.hideSpinner()
//
//            self?.executeIntegralAuction(
//                estimates: estimates,
//                mintParameters: mintParameters
//            )
//        }
//        .store(in: &storage)
//    }
    
    func executeIntegralAuction(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters
    ) {
        var txResultRetainer: TransactionSendingResult!
        // To be used for the event topics from the socket
        var postUid: String!
        var tokenId: String!
        // To retain the above information for Firestore
        var topicsInfoRetainer: (uid: String, tokenId: String)!
        
        guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress,
              let txPackageRetainer = self.txPackageArr.first else {
            return
        }
        
        let content = [
            StandardAlertContent(
                titleString: "Enter Your Password",
                body: [AlertModalDictionary.walletPasswordRequired: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                index: 1,
                titleString: "Gas Estimate",
                titleColor: UIColor.white,
                body: [
                    "Total Gas Units": txPackageRetainer.gasEstimate.description,
                    "Gas Price": "\(estimates.gasPriceInGwei) Gwei",
                    "Total Gas Cost": "\(estimates.totalGasCost) Ether",
                    "Your Current Balance": "\(estimates.balance) Ether"
                ],
                isEditable: false,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        DispatchQueue.main.async { [weak self] in
            let alertVC = AlertViewController(height: 350, standardAlertContent: content)
            alertVC.action = { [weak self] (modal, mainVC) in
                mainVC.buttonAction = { _ in
                    guard let password = modal.dataDict[AlertModalDictionary.walletPasswordRequired],
                          !password.isEmpty else {
                        self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                        return
                    }
                    
                    self?.dismiss(animated: true, completion: {
                        let progressModal = ProgressModalViewController(paymentMethod: .directTransfer)
                        progressModal.titleString = "Posting In Progress"
                        self?.present(progressModal, animated: true, completion: {
                            self?.socketDelegate = SocketDelegate(
                                contractAddress: integralAuctionAddress,
                                topics: [Topics.IntegralAuction.auctionCreated, Topics.IntegralAuction.transfer]
                            )
                            
                            Deferred { [weak self] () -> AnyPublisher<TxResult2, PostingError> in
                                guard let transactionService = self?.transactionService else {
                                    return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                                        .eraseToAnyPublisher()
                                }
                                
                                return transactionService.executeTransaction2(transaction: txPackageRetainer.transaction, password: password, type: .auctionContract)
                                    .eraseToAnyPublisher()
                            }
                            // get the topics of the AuctionCreated event from the socket delegate and parse it
                            .flatMap { [weak self] (txResult) -> AnyPublisher<(uid: String, tokenId: String), PostingError> in
                                let update: [String: PostProgress] = ["update": .estimatGas]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                txResultRetainer = txResult.txResult
                                
                                return Future<(uid: String, tokenId: String), PostingError> { promise in
                                    self?.socketDelegate.didReceiveTopics = { webSocketMessage in
                                        print("webSocketMessage", webSocketMessage)
                                        guard let transactionHash = webSocketMessage["transactionHash"] as? String,
                                              transactionHash == txResult.txResult.hash,
                                              let topics = webSocketMessage["topics"] as? [String] else { return }
                                        
                                        switch topics[0] {
                                            case Topics.IntegralAuction.auctionCreated:
                                                guard let _postUid = Web3Utils.hexToBigUInt(topics[1]) else {
                                                    promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
                                                    return
                                                }
                                                postUid = _postUid.description
                                                break
                                            case Topics.IntegralAuction.transfer:
                                                guard let _tokenId = Web3Utils.hexToBigUInt(topics[3]) else {
                                                    promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
                                                    return
                                                }
                                                tokenId = _tokenId.description
                                                break
                                            default:
                                                break
                                        }
                                        
                                        // Pass only when both are fetched
                                        if let uid = postUid, let tid = tokenId {
                                            promise(.success((uid: uid, tokenId: tid)))
                                        }
                                    }
                                }
                                .eraseToAnyPublisher()
                            }
                            .flatMap({ [weak self] (topicsInfo) -> AnyPublisher<[String?], PostingError> in
                                topicsInfoRetainer = topicsInfo
                                
                                let update: [String: PostProgress] = ["update": .minting]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                
                                // upload images/files to the Firebase Storage and get the array of URLs
                                if let previewDataArr = self?.previewDataArr, previewDataArr.count > 0 {
                                    let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                                        return Future<String?, PostingError> { promise in
                                            self?.uploadFileWithPromise(
                                                fileURL: previewData.filePath,
                                                userId: mintParameters.userId,
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
                            .flatMap { [weak self] (urlStrings) -> AnyPublisher<Bool, PostingError> in
                                let update: [String: PostProgress] = ["update": .images]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                
                                guard let self = self,
                                      let currentAddressString = Web3swiftService.currentAddressString else {
                                    return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
                                        .eraseToAnyPublisher()
                                }
                                
                                return Future<Bool, PostingError> { promise in
                                    self.transactionService.createFireStoreEntryRevised(
                                        documentId: &self.documentId,
                                        senderAddress: currentAddressString,
                                        escrowHash: "N/A",
                                        auctionHash: txResultRetainer.hash,
                                        mintHash: "N/A",
                                        itemTitle: mintParameters.itemTitle,
                                        desc: mintParameters.desc,
                                        price: mintParameters.price ?? "N/A",
                                        category: mintParameters.category,
                                        tokensArr: mintParameters.tokensArr,
                                        convertedId: mintParameters.convertedId,
                                        type: mintParameters.postType,
                                        deliveryMethod: mintParameters.deliveryMethod,
                                        saleFormat: mintParameters.saleFormat,
                                        paymentMethod: mintParameters.paymentMethod,
                                        tokenId: topicsInfoRetainer.tokenId,
                                        urlStrings: urlStrings,
                                        ipfsURLStrings: [],
                                        shippingInfo: self.shippingInfo,
                                        solireyUid: topicsInfoRetainer.uid,
                                        contractFormat: mintParameters.contractFormat,
                                        promise: promise
                                    )
                                }
                                .eraseToAnyPublisher()
                            }
                            .sink { [weak self] (completion) in
                                if self?.socketDelegate != nil {
                                    self?.socketDelegate.disconnectSocket()
                                }
                                
                                switch completion {
                                    case .failure(let error):
                                        self?.processFailure(error)
                                    case .finished:
                                        self?.afterPostReset()
                                        
                                        DispatchQueue.main.async { [weak self] in
                                            self?.saleMethodContainerConstraintHeight.constant = 50
                                            self?.priceTextFieldConstraintHeight.constant = 50
                                            self?.priceTextField.alpha = 1
                                            self?.priceLabelConstraintHeight.constant = 50
                                            self?.priceLabel.alpha = 1
                                            self?.auctionDurationTitleLabel.alpha = 0
                                            self?.auctionDurationLabel.alpha = 0
                                            self?.auctionDurationLabel.text = nil
                                            self?.auctionStartingPriceTitleLabel.alpha = 0
                                            self?.auctionStartingPriceTextField.alpha = 0
                                            self?.auctionStartingPriceTextField.text = nil
                                            self?.saleMethodLabel.text = nil
                                            self?.deliveryMethodLabel.text = DeliveryMethod.onlineTransfer.rawValue
                                            self?.pickerLabel.text = Category.digital.asString()

                                            UIView.animate(withDuration: 0.5) {
                                                self?.view.layoutIfNeeded()
                                            }
                                            
                                            guard let `self` = self else { return }
                                            self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
                                        }
                                        
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
                            .store(in: &self!.storage)
                        })
                    })
                } // mainVC
            } // alertVC.action
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
}
