//
//  ParentPostViewController + IntegralEscrow.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-30.
//

import UIKit
import Combine
import web3swift
import BigInt

extension ParentPostViewController {
    // MARK: - escrowIntegral
    func escrowIntegral(_ mintParameters: MintParameters, price: String, isResale: Bool = false) {
        self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
            guard let getIntegralEscrowEstimate = self?.getIntegralEscrowEstimate else {
                return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                    .eraseToAnyPublisher()
            }
            return getIntegralEscrowEstimate(.createEscrow, price, isResale)
            
        }) { [weak self] (estimates, txPackage, error) in
            if let error = error {
                self?.processFailure(error)
            }
            
            if let estimates = estimates,
               let txPackage = txPackage {
                
                if isResale == false {
                    self?.executeIntegralEscrow(
                        estimates: estimates,
                        mintParameters: mintParameters,
                        txPackage: txPackage
                    )
                } else {
                    self?.executeIntegralEscrowResale(
                        estimates: estimates,
                        mintParameters: mintParameters,
                        txPackage: txPackage
                    )
                }
            }
        }
    }
    
    // MARK: - getIntegralEscrowEstimate
    final func getIntegralEscrowEstimate(
        method: PurchaseContract.ContractMethods,
        price: String,
        isResale: Bool
    ) -> AnyPublisher<TxPackage, PostingError> {
        return Future<TxPackage, PostingError> { [weak self] promise in
            guard let integralEscrowAddress = ContractAddresses.integralEscrowAddress,
                  let solireyContractAddress = ContractAddresses.solireyContractAddress else {
                promise(.failure(PostingError.generalError(reason: "Unable to prepare the contract address.")))
                return
            }
            
            if isResale == false {
                self?.socketDelegate = SocketDelegate(contractAddress: solireyContractAddress, topics: [Topics.Solirey.transfer])
            }
            
            self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                method: method.methodName,
                abi: integralEscrowABI,
                contractAddress: integralEscrowAddress,
                amountString: price,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - executeIntegralEscrow
    func executeIntegralEscrow(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters,
        txPackage: TxPackage
    ) {
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
                        let progressModal = ProgressModalViewController(deliveryAndPaymentMethod: .tangibleNewSaleShippingEscrowIntegral)
                        progressModal.titleString = "Posting In Progress"
                        self?.present(progressModal, animated: true, completion: {
                            let update: [String: PostProgress] = ["update": .estimatGas]
                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                            
                            Deferred { [weak self] () -> AnyPublisher<TxResult2, PostingError> in
                                guard let transactionService = self?.transactionService else {
                                    return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                                        .eraseToAnyPublisher()
                                }
                                
                                return transactionService.executeTransaction2(transaction: txPackage.transaction, password: password, type: .auctionContract)
                                    .eraseToAnyPublisher()
                            }
                            .flatMap({ [weak self] (txPackage) -> AnyPublisher<(txPackage: TxResult2, tokenId: String), PostingError> in
                                // Listen to the Transfer even emitted from the mint method of Solirey in order to get the tokenId
                                return Future<(txPackage: TxResult2, tokenId: String), PostingError> { promise in
                                    self?.socketDelegate.didReceiveTopics = { webSocketMessage in
                                        guard let topics = webSocketMessage["topics"] as? [String],
                                              let txHash = webSocketMessage["transactionHash"] as? String else { return }
                                        
                                        let paddedTokenId = topics[3]
                                        
                                        guard let tokenId = Web3Utils.hexToBigUInt(paddedTokenId) else {
                                            promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
                                            return
                                        }
                                        
                                        if txPackage.txResult.hash == txHash {
                                            promise(.success((txPackage: txPackage, tokenId: tokenId.description)))
                                        }
                                    }
                                }
                                .eraseToAnyPublisher()
                            })
                            .sink(receiveCompletion: { (completion) in
                                self?.socketDelegate.disconnectSocket()
                                switch completion {
                                    case .failure(let error):
                                        self?.processFailure(error)
                                    case .finished:
                                        break
                                }
                            }, receiveValue: { (returnedValue) in
                                self?.socketDelegate.disconnectSocket()
                                let update: [String: PostProgress] = ["update": .minting]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                
                                // Get the token ID by parsing the receipt from the minting transaction
                                guard let self = self else { return }
                                
                                self.transactionService.confirmReceipt(txHash: returnedValue.txPackage.txResult.hash)
                                    .flatMap { (receipt) -> AnyPublisher<(txPackage: TxResult2, tokenId: String, id: String), PostingError> in
                                        Future<(txPackage: TxResult2, tokenId: String, id: String), PostingError> { promise in
                                            // There are two events that are being emitted:
                                            // 1. CreateEscrow: From the Auction contract. The Id from the CreateEscrow has to be captured.
                                            // 2. Transfer: From the Solirey contract. The tokenId from the Transfer event which is emitted from the mint method has to be captured.
                                            let web3 = Web3swiftService.web3instance
                                            guard let contract = web3.contract(integralEscrowABI, at: ContractAddresses.integralEscrowAddress, abiVersion: 2) else {
                                                self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                                                return
                                            }
                                            
                                            for i in 0..<receipt.logs.count {
                                                let parsedEvent = contract.parseEvent(receipt.logs[i])
                                                switch parsedEvent.eventName {
                                                    case "CreateEscrow":
                                                        if let parsedData = parsedEvent.eventData,
                                                           let id = parsedData["id"] as? BigUInt {
                                                            promise(.success((txPackage: returnedValue.txPackage, tokenId: returnedValue.tokenId, id: id.description)))
                                                            //                                                            if let seller = parsedData["seller"] as? EthereumAddress,
                                                            //                                                               seller == Web3swiftService.currentAddress {
                                                            //                                                                promise(.success((txPackage: returnedValue.txPackage, tokenId: returnedValue.tokenId, id: id.description)))
                                                            //                                                            }
                                                        } else {
                                                            promise(.failure(.emptyResult))
                                                        }
                                                        break
                                                    default:
                                                        break
                                                }
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
                                    } receiveValue: { [weak self] (txInfo) in
                                        guard let postType = self?.postType else { return }
                                        self?.updateFirestore(
                                            txInfo: txInfo,
                                            mintParameters: mintParameters,
                                            postType: postType
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
    
    // MARK: - executeIntegralResaleEscrow
    func executeIntegralEscrowResale(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters,
        txPackage: TxPackage
    ) {
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
                        let progressModal = ProgressModalViewController(deliveryAndPaymentMethod: .tangibleNewSaleShippingEscrowIntegral)
                        progressModal.titleString = "Posting In Progress"
                        self?.present(progressModal, animated: true, completion: {
                            let update: [String: PostProgress] = ["update": .estimatGas]
                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                            
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
                            }, receiveValue: { (txPackage) in
                                let update: [String: PostProgress] = ["update": .minting]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                
                                // Get the token ID by parsing the receipt from the minting transaction
                                guard let self = self else { return }
                                
                                self.transactionService.confirmReceipt(txHash: txPackage.txResult.hash)
                                    .flatMap { (receipt) -> AnyPublisher<(txPackage: TxResult2, tokenId: String, id: String), PostingError> in
                                        Future<(txPackage: TxResult2, tokenId: String, id: String), PostingError> { promise in
                                            // There are two events that are being emitted:
                                            // 1. CreateEscrow: From the Auction contract. The Id from the CreateEscrow has to be captured.
                                            // 2. Transfer: From the Solirey contract. The tokenId from the Transfer event which is emitted from the mint method has to be captured.
                                            let web3 = Web3swiftService.web3instance
                                            guard let contract = web3.contract(integralEscrowABI, at: ContractAddresses.integralEscrowAddress, abiVersion: 2) else {
                                                self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                                                return
                                            }
                                            
                                            for i in 0..<receipt.logs.count {
                                                let parsedEvent = contract.parseEvent(receipt.logs[i])
                                                switch parsedEvent.eventName {
                                                    case "CreateEscrow":
                                                        if let parsedData = parsedEvent.eventData,
                                                           let id = parsedData["id"] as? BigUInt,
                                                           let tokenId = self.post?.tokenID {
                                                            promise(.success((txPackage: txPackage, tokenId: tokenId, id: id.description)))
                                                        } else {
                                                            promise(.failure(.emptyResult))
                                                        }
                                                        break
                                                    default:
                                                        break
                                                }
                                            }
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .sink { [weak self] (completion) in
                                        switch completion {
                                            case .failure(let error):
                                                self?.processFailure(error)
                                            case .finished:
                                                DispatchQueue.main.async {
                                                    self?.navigationController?.popToRootViewController(animated: true)
                                                }
                                                break
                                        }
                                    } receiveValue: { [weak self] (txInfo) in
                                        guard let postType = self?.postType else { return }
                                        self?.updateFirestore(
                                            txInfo: txInfo,
                                            mintParameters: mintParameters,
                                            postType: postType
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
    
    func updateFirestore(
        txInfo: (txPackage: TxResult2, tokenId: String, id: String),
        mintParameters: MintParameters,
        postType: PostType // to determine whether the image upload is going to be for digital or tangible
    ) {
        guard let previewDataArr = self.previewDataArr, previewDataArr.count <= 6 else {
            alert.showDetail("Error", with: "A single digital asset is required.", for: self)
            return
        }
        
        var fileURLs: [AnyPublisher<String?, PostingError>]!
        
        if postType == .digital {
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
                        escrowHash: txInfo.txPackage.txResult.hash,
                        auctionHash: "N/A",
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
                        tokenId: txInfo.tokenId,
                        urlStrings: urlStrings,
                        ipfsURLStrings: [],
                        shippingInfo: self.shippingInfo,
                        isWithdrawn: false,
                        isAdminWithdrawn: false,
                        solireyUid: txInfo.id,
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
                            self?.isShipping = false
                            guard let self = self else { return }
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
