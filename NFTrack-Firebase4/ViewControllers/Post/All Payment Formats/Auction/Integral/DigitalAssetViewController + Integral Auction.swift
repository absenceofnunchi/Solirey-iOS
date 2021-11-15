//
//  DigitalAssetViewController + Integral Auction.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-04.
//

import UIKit
import Combine
import web3swift
import BigInt

extension DigitalAssetViewController {
    final func getIntegralAuctionEstimate(
        method: IntegralAuctionContract.ContractMethods,
        transactionParameters: [AnyObject]
    ) -> AnyPublisher<TxPackage, PostingError> {
        Future<TxPackage, PostingError> { [weak self] promise in
            guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress else {
                promise(.failure(PostingError.generalError(reason: "Unable to prepare the contract address.")))
                return
            }
            
            self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                method: method.rawValue,
                abi: integralAuctionABI,
                param: transactionParameters,
                contractAddress: integralAuctionAddress,
                amountString: nil,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
    }
    
    func executeIntegralAuction(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters,
        txPackage: TxPackage
    ) {
        var txResultRetainer: TransactionSendingResult!
        
        guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress else {
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
                    "Total Gas Units": txPackage.gasEstimate.description,
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
        
        self.hideSpinner()
        
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
                        let progressModal = ProgressModalViewController(paymentMethod: .integralAuction)
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
                                
                                return transactionService.executeTransaction2(transaction: txPackage.transaction, password: password, type: .auctionContract)
                                    .eraseToAnyPublisher()
                            }
                            .sink(receiveCompletion: { (completion) in
                                switch completion {
                                    case .failure(let error):
                                        self?.processFailure(error)
                                    case .finished:
                                        break
                                }
                            }, receiveValue: { (txResult) in
                                let update: [String: PostProgress] = ["update": .estimatGas]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                txResultRetainer = txResult.txResult
                                
                                // Get the token ID by parsing the receipt from the minting transaction
                                guard let self = self else { return }
                                
                                self.transactionService.confirmReceipt(txHash: txResult.txResult.hash)
                                    .flatMap { (receipt) -> AnyPublisher<(id: String, tokenId: String), PostingError> in
                                        Future<(id: String, tokenId: String), PostingError> { promise in
                                            
                                            let web3 = Web3swiftService.web3instance
                                            guard let contract = web3.contract(integralAuctionABI, at: ContractAddresses.integralAuctionAddress, abiVersion: 2) else {
                                                return
                                            }
                                            
                                            // Two events will be emitted (AuctionCreated, Transfer).
                                            // Following determines which event in the logs array is which so that the order shouldn't matter. i.e. logs[0] could be either AuctionCreated or Transfer.
                                            let parsedEvent1 = contract.parseEvent(receipt.logs[0])
                                            let parsedEvent2 = contract.parseEvent(receipt.logs[1])
                                            
                                            if parsedEvent1.eventName == "AuctionCreated" {
                                                guard let eventData1 = parsedEvent1.eventData,
                                                      let id = eventData1["id"] as? BigUInt,
                                                      let eventData2 = parsedEvent2.eventData,
                                                      let tokenId = eventData2["tokenId"] as? BigUInt else {
                                                    return
                                                }

                                                promise(.success((id: id.description, tokenId: tokenId.description)))
                                            } else {
                                                guard let eventData1 = parsedEvent1.eventData,
                                                      let id = eventData1["tokenId"] as? BigUInt,
                                                      let eventData2 = parsedEvent2.eventData,
                                                      let tokenId = eventData2["id"] as? BigUInt else {
                                                    return
                                                }
                                                
                                                promise(.success((id: id.description, tokenId: tokenId.description)))
                                            }
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .sink { [weak self] (completion) in
                                        switch completion {
                                            case .failure(let error):
                                                self?.processFailure(error)
                                            case .finished:
                                                break
                                        }
                                    } receiveValue: { [weak self] (topicsInfo) in
                                        
                                        self?.updateFirestore(
                                            topicsInfo: topicsInfo,
                                            mintParameters: mintParameters,
                                            txResultRetainer: txResultRetainer
                                        )
                                    }
                                    .store(in: &self.storage)
                            })
                            .store(in: &self!.storage)
                        })
                    })
                } // mainVC
            } // alertVC.action
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
    
    private func updateFirestore(
        topicsInfo: (id: String, tokenId: String),
        mintParameters: MintParameters,
        txResultRetainer: TransactionSendingResult
    ) {
        let update: [String: PostProgress] = ["update": .minting]
        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        
        guard let previewDataArr = self.previewDataArr, previewDataArr.count == 1 else {
            alert.showDetail("Error", with: "A single digital asset is required.", for: self)
            return
        }
        
        var fileURLs: [AnyPublisher<String?, PostingError>]!
        
        // Use the existing file path if this is reselling. No need to upload to the Storage.
        // Since the remote image's url is used to display the digital image during the resale (not the local directory URL)
        // the attempt to use uploadFileWithPromise will result in no image found.
        if let post = self.post,
           let files = post.files,
           let filePath = files.first {
            
            let resellURLPromise = Future<String?, PostingError> { promise in
                promise(.success(filePath))
            }
            .eraseToAnyPublisher()
            
            fileURLs = [resellURLPromise]
        } else {
            fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                return Future<String?, PostingError> { promise in
                    self.uploadFileWithPromise(
                        fileURL: previewData.filePath,
                        userId: mintParameters.userId,
                        promise: promise
                    )
                }.eraseToAnyPublisher()
            }
        }
        
        Publishers.MergeMany(fileURLs)
            .collect()
            .eraseToAnyPublisher()
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
                    tokenId: topicsInfo.tokenId,
                    urlStrings: urlStrings,
                    ipfsURLStrings: [],
                    shippingInfo: self.shippingInfo,
                    isWithdrawn: false,
                    isAdminWithdrawn: false,
                    solireyUid: topicsInfo.id,
                    contractFormat: mintParameters.contractFormat,
                    bidders: [self.userId],
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
                    
                    self?.storage.removeAll()
                //  register spotlight?
            }
        } receiveValue: { (_) in
        }
        .store(in: &self.storage)
    }
}
