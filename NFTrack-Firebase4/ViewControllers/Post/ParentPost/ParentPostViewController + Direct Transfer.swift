//
//  ParentPostViewController + Direct Transfer.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-27.
//

/*
 Abtract:
 Direct sale revised is the most primitive method of payment where the buyer pays for an item and the ownership of the item is transferred right away, which means there is only one step for the buyer for the purchase.
 The seller mints a token and withdraws the fund after the purchase has been made, which means it takes two steps for the seller.
 It uses the NFTrack contract deployed by the admin and requires no deployments from the user's end.
 
 The code is in ParentPostVC because new sale and resale methods are to be used in tangible and digital both.
 */

import UIKit
import web3swift
import Combine

extension ParentPostViewController {
    // Revised SimplePayment embedded in NFTrack
    // MARK: - New Sale
    final func processDirectSaleRevised(_ mintParameters: MintParameters, isAddressRequired: Bool, postType: PostType) {
        guard let price = mintParameters.price,
              !price.isEmpty,
              let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        // change to this after testing
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        if isAddressRequired {
            guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
                self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
                return
            }
        }
        
        guard let NFTrackABIRevisedAddress = ContractAddresses.NFTrackABIRevisedAddress else {
            self.alert.showDetail("Error", with: "Unable to get the smart contract address.", for: self)
            return
        }
        
        // ** important ** this is not deprecated
        // create an ID for the new item to be saved into the _simplePayment mapping.
//        let combinedString = self.ref.document().documentID + mintParameters.userId
//        let inputData = Data(combinedString.utf8)
//        let hashedId = SHA256.hash(data: inputData)
//        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()
//        self.simplePaymentId = hashString
        
        // The parameters for the createSimplePayment method
        let param: [AnyObject] = [priceInWei] as [AnyObject]
        
        Deferred { [weak self] in
            Future<Bool, PostingError> { promise in
                self?.db.collection("post")
                    .whereField("itemIdentifier", isEqualTo: mintParameters.convertedId)
                    .whereField("status", isNotEqualTo: "complete")
                    .getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print("error from the duplicate check", err)
                            promise(.failure(PostingError.generalError(reason: "Unable to check for the Unique Identifier duplicates")))
                            return
                        }
                        
                        if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
                            promise(.success(true))
                        } else {
                            promise(.failure(PostingError.generalError(reason: "The item already exists. Please resell it through the app instead of selling it as a new item.")))
                        }
                    }
            }
        }
        .flatMap { (_) -> AnyPublisher<TxPackage, PostingError> in
            Future<TxPackage, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                    method: NFTrackContract.ContractMethods.createSimplePayment.rawValue,
                    abi: NFTrackABIRevisedABI,
                    param: param,
                    contractAddress: NFTrackABIRevisedAddress,
                    amountString: nil,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ [weak self] (txPackage) -> AnyPublisher<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> in
            self?.txPackageArr.append(txPackage)
            return Future<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> { promise in
                self?.transactionService.estimateGas(
                    gasEstimate: txPackage.gasEstimate,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        })
        .sink { [weak self] (completion) in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.processFailure(error)
                    break
            }
        } receiveValue: { [weak self] (estimates) in
            self?.hideSpinner()
            self?.executeTransaction(
                estimates: estimates,
                mintParameters: mintParameters,
                postType: postType
            )
        }
        .store(in: &storage)
    }
    
    private func executeTransaction(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters,
        postType: PostType
    ) {
        var txResultRetainer: TransactionSendingResult!
        var tokenIdRetainer: String!
        
        guard let txPackageRetainer = self.txPackageArr.first,
              let NFTrackABIRevisedAddress = ContractAddresses.NFTrackABIRevisedAddress else { return }
        
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
                    
                    self?.showSpinner()
                    self?.socketDelegate = SocketDelegate(contractAddress: NFTrackABIRevisedAddress, topics: [Topics.SimplePaymentMint])
                    
                    self?.dismiss(animated: true, completion: {
                        let progressModal = ProgressModalViewController(paymentMethod: .directTransfer)
                        progressModal.titleString = "Posting In Progress"
                        self?.present(progressModal, animated: true, completion: {
                            Deferred {
                                Future<TransactionSendingResult, PostingError> { promise in
                                    DispatchQueue.global().async {
                                        do {
                                            let result = try txPackageRetainer.transaction.send(password: password, transactionOptions: nil)
                                            promise(.success(result))
                                        } catch {
                                            promise(.failure(.generalError(reason: "Unable to execute the transaction.")))
                                        }
                                    }
                                }
                                .eraseToAnyPublisher()
                            }
                            // get the topics of the paymentMade event from the socket delegate and parse it
                            .flatMap { [weak self] (txResult) -> AnyPublisher<String, PostingError> in
                                let update: [String: PostProgress] = ["update": .estimatGas]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                
                                txResultRetainer = txResult
                                
                                return Future<String, PostingError> { promise in
                                    self?.socketDelegate.didReceiveTopics = { webSocketMessage in
                                        guard let topics = webSocketMessage["topics"] as? [String] else { return }
                                        
                                        let fromAddress = topics[2]
                                        let paddedTokenId = topics[3]
                                        
                                        guard let tokenId = Web3Utils.hexToBigUInt(paddedTokenId) else {
                                            promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
                                            return
                                        }
                                        
                                        let data = Data(hex: fromAddress)
                                        guard let decodedFromAddress = ABIDecoder.decode(types: [.address], data:data)?.first as? EthereumAddress else {
                                            promise(.failure(.generalError(reason: "Unable to decode the contract address.")))
                                            return
                                        }
                                        
                                        if decodedFromAddress == Web3swiftService.currentAddress {
                                            promise(.success(tokenId.description))
                                        }
                                    }
                                }
                                .eraseToAnyPublisher()
                            }
                            .flatMap({ [weak self] (tokenId) -> AnyPublisher<[String?], PostingError> in
                                tokenIdRetainer = tokenId
                                
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
                                        auctionHash: "N/A",
                                        mintHash: txResultRetainer.hash,
                                        itemTitle: mintParameters.itemTitle,
                                        desc: mintParameters.desc,
                                        price: mintParameters.price!,
                                        category: mintParameters.category,
                                        tokensArr: mintParameters.tokensArr,
                                        convertedId: mintParameters.convertedId,
                                        type: postType.asString(),
                                        deliveryMethod: mintParameters.deliveryMethod,
                                        saleFormat: mintParameters.saleFormat,
                                        paymentMethod: mintParameters.paymentMethod,
                                        tokenId: tokenIdRetainer,
                                        urlStrings: urlStrings,
                                        ipfsURLStrings: [],
                                        shippingInfo: self.shippingInfo,
                                        solireyUid: "something",
                                        contractFormat: mintParameters.contractFormat,
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
                            } receiveValue: { [weak self] (_) in
                                if self?.socketDelegate != nil {
                                    self?.socketDelegate.disconnectSocket()
                                }
                            }
                            .store(in: &self!.storage)
                        }) // ProgressVC
                    }) // self.dismiss
                } // mainVC
            } // alertVC
            self?.present(alertVC, animated: true, completion: nil)
        } // DispatchQueue
    }
}

// MARK: - Resale
extension ParentPostViewController {
    final func processDirectResaleRevised(_ mintParameters: MintParameters, isAddressRequired: Bool, postType: PostType) {
        
        // ** important now deprecated
        // create an ID for the existing item to be saved into the _simplePayment mapping as a new posting.
//        let combinedString = self.ref.document().documentID + mintParameters.userId
//        let inputData = Data(combinedString.utf8)
//        let hashedId = SHA256.hash(data: inputData)
//        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()
//        self.simplePaymentId = hashString
        
        guard let tokenID = post?.tokenID,
              let tokenIDNumber = NumberFormatter().number(from: tokenID) else {
            self.alert.showDetail("Error", with: "Unable to retrieve the token ID to resell. Please try restarting the app.", for: self)
            return
        }
        
        guard let price = mintParameters.price,
              !price.isEmpty,
              let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        // change to this after testing
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        if isAddressRequired {
            guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
                self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
                return
            }
        }
        
        guard let NFTrackABIRevisedAddress = ContractAddresses.NFTrackABIRevisedAddress else {
            self.alert.showDetail("Error", with: "Unable to get the smart contract address.", for: self)
            return
        }
        
        let param: [AnyObject] = [priceInWei, tokenIDNumber] as [AnyObject]
        
        Deferred { [weak self] in
            Future<Bool, PostingError> { promise in
                self?.db.collection("post")
                    .whereField("itemIdentifier", isEqualTo: mintParameters.convertedId)
                    .whereField("status", isNotEqualTo: "complete")
                    .getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print(err)
                            promise(.failure(PostingError.generalError(reason: "Unable to check for the Unique Identifier duplicates")))
                            return
                        }
                        
                        if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
                            promise(.success(true))
                        } else {
                            promise(.failure(PostingError.generalError(reason: "The item already exists. Please resell it through the app instead of selling it as a new item.")))
                        }
                    }
            }
        }
        .flatMap { (isDuplicate) -> AnyPublisher<TxPackage, PostingError> in
            Future<TxPackage, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                    method: NFTrackContract.ContractMethods.resell.rawValue,
                    abi: NFTrackABIRevisedABI,
                    param: param,
                    contractAddress: NFTrackABIRevisedAddress,
                    amountString: nil,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ [weak self] (txPackage) -> AnyPublisher<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> in
            self?.txPackageArr.append(txPackage)
            return Future<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> { promise in
                self?.transactionService.estimateGas(
                    gasEstimate: txPackage.gasEstimate,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        })
        .sink { [weak self] (completion) in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.processFailure(error)
                    break
            }
        } receiveValue: { [weak self] (estimates) in
            self?.hideSpinner()
            self?.executeTransactionForResale(
                estimates: estimates,
                mintParameters: mintParameters,
                postType: postType
            )
        }
        .store(in: &storage)
    }
    
    private func executeTransactionForResale(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters,
        postType: PostType
    ) {
        var txResultRetainer: TransactionSendingResult!
        
        guard let txPackageRetainer = self.txPackageArr.first,
              let NFTrackABIRevisedAddress = ContractAddresses.NFTrackABIRevisedAddress else { return }
        
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
                    
                    self?.showSpinner()
                    self?.socketDelegate = SocketDelegate(contractAddress: NFTrackABIRevisedAddress, topics: [Topics.SimplePaymentMint])
                    
                    self?.dismiss(animated: true, completion: {
                        Deferred {
                            Future<TransactionSendingResult, PostingError> { promise in
                                DispatchQueue.global().async {
                                    do {
                                        let result = try txPackageRetainer.transaction.send(password: password, transactionOptions: nil)
                                        promise(.success(result))
                                    } catch {
                                        promise(.failure(.generalError(reason: "Unable to execute the transaction.")))
                                    }
                                }
                            }
                            .eraseToAnyPublisher()
                        }
                        .flatMap({ [weak self] (txResult) -> AnyPublisher<[String?], PostingError> in
                            txResultRetainer = txResult
                            
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
                            guard let self = self,
                                  let currentAddressString = Web3swiftService.currentAddressString,
                                  let tokenId = self.post?.tokenID else {
                                return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
                                    .eraseToAnyPublisher()
                            }
                            
                            return Future<Bool, PostingError> { promise in
                                self.transactionService.createFireStoreEntryRevised(
                                    documentId: &self.documentId,
                                    senderAddress: currentAddressString,
                                    escrowHash: "N/A",
                                    auctionHash: "N/A",
                                    mintHash: txResultRetainer.hash,
                                    itemTitle: mintParameters.itemTitle,
                                    desc: mintParameters.desc,
                                    price: mintParameters.price!,
                                    category: mintParameters.category,
                                    tokensArr: mintParameters.tokensArr,
                                    convertedId: mintParameters.convertedId,
                                    type: postType.asString(),
                                    deliveryMethod: mintParameters.deliveryMethod,
                                    saleFormat: mintParameters.saleFormat,
                                    paymentMethod: mintParameters.paymentMethod,
                                    tokenId: tokenId,
                                    urlStrings: urlStrings,
                                    ipfsURLStrings: [],
                                    shippingInfo: self.shippingInfo,
                                    solireyUid: "something",
                                    contractFormat: mintParameters.contractFormat,
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
                                    self?.alert.showDetail(
                                        "Success!",
                                        with: "You have successfully posted your item.",
                                        for: self,
                                        buttonAction: {
                                            self?.dismiss(animated: true, completion: {
                                                self?.navigationController?.popToRootViewController(animated: true)
                                            })
                                        }
                                    )
                                    
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
                        } receiveValue: { [weak self] (_) in
                            if self?.socketDelegate != nil {
                                self?.socketDelegate.disconnectSocket()
                            }
                        }
                        .store(in: &self!.storage)
                    }) // self.dismiss
                } // mainVC
            } // alertVC
            self?.present(alertVC, animated: true, completion: nil)
        } // DispatchQueue
    }
}
