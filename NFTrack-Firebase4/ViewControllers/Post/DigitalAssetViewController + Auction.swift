//
//  DigitalAssetViewController + Auction.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-05.
//

import UIKit
import Combine
import web3swift
import BigInt

extension DigitalAssetViewController {
    // MARK: - auction mint
//    final override func processAuction(_ mintParameters: MintParameters) {
    final func test100() {
        let mintParameters = MintParameters(price: nil, itemTitle: "Test", desc: "Test", category: "Electronics", convertedId: "dsddfgg", tokensArr: [], userId: "343fdf", deliveryMethod: "online", saleFormat: "Auction", paymentMethod: "Auction", contractFormat: "Auction", postType: "Digital", saleConfigValue: .digitalNewSaleAuctionBeneficiaryIndividual)
        
//        guard let auctionDuration = auctionDurationLabel.text,
//              !auctionDuration.isEmpty else {
//            self.alert.showDetail("Incomplete", with: "Please specify the auction duration.", for: self)
//            return
//        }
//        guard let auctionStartingPrice = auctionStartingPriceTextField.text,
//              !auctionStartingPrice.isEmpty else {
//            self.alert.showDetail("Incomplete", with: "Please specify the starting price for your auction.", for: self)
//            return
//        }
//
//        guard let index = auctionDuration.firstIndex(of: "d") else { return }
//
//        let newIndex = auctionDuration.index(before: index)
//        let newStr = auctionDuration[..<newIndex]
//
//        guard let numOfDays = NumberFormatter().number(from: String(newStr)) else {
//            self.alert.showDetail("Sorry", with: "Could not convert the auction duration into a proper format. Please try again.", for: self)
//            return
//        }
//
//        guard let startingBidInWei = Web3.Utils.parseToBigUInt(auctionStartingPrice, units: .eth),
//              let startingBid = NumberFormatter().number(from: startingBidInWei.description) else {
//            self.alert.showDetail("Sorry", with: "Could not convert the auction starting price into a proper format. Pleas try again.", for: self)
//            return
//        }
        
        let startingBid = 100 as NSNumber
        
//        let biddingTime = numOfDays.intValue * 60 * 60 * 24
        let biddingTime = 400

        self.hideSpinner {
            switch mintParameters.saleConfigValue {
                case .digitalNewSaleAuctionBeneficiaryIntegral:
                    self.newIntegralAuction(
                        mintParameters: mintParameters,
                        biddingTime: biddingTime,
                        startingBid: startingBid
                    )
                    break
                case .digitalNewSaleAuctionBeneficiaryIndividual:
                    self.preLaunch(mintParameters: mintParameters) { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                        
                        guard let getIndividualAuctionEstimate = self?.getIndividualAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIndividualAuctionEstimate(transactionParameters)
                    } completion: { [weak self] (estimates) in
                        self?.executeIndividualAuction(
                            estimates: estimates,
                            mintParameters: mintParameters
                        )
                    }

//                    self.newIndividualAuction(
//                        mintParameters: mintParameters,
//                        biddingTime: biddingTime,
//                        startingBid: startingBid
//                    )
                    break
                default:
                    break
            }
        } // hideSpinner
    }

    // MARK: - newIndividualAuction
    /// 1. obtain the password
    /// 2. prepare the auction deployment and minting transactions
    /// 3. execute the transactions and get the receipts in an array
    /// 4. Upload images and files to Firebase storage, if any, or return an empty array
    /// 5. Get the topics from the socket when the txs are mined and create a Firestore entry
    /// 6. Get the token ID through Cloud Functions and update the Firestore entry with it
    /// 7. Using the tx hash of the deployed auction contract, obtain the auction contract address
    /// 8. Using the auction contract address, token ID, and the current address, transfer the token into the auction contract
    final func getIndividualAuctionEstimate(transactionParameters: [AnyObject]) -> AnyPublisher<TxPackage, PostingError> {
        Future<TxPackage, PostingError> { [weak self] promise in
            self?.transactionService.prepareTransactionForNewContractWithGasEstimate(
                contractABI: auctionABI,
                bytecode: auctionBytcode,
                parameters: transactionParameters,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - newIntegralAuction
    /// Prepare the gas estimate
    final func preLaunch(
        mintParameters: MintParameters,
        transactionToEstimate: @escaping () -> AnyPublisher<TxPackage, PostingError>,
        completion: @escaping ((totalGasCost: String, balance: String, gasPriceInGwei: String)) -> Void
    ) {
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
            return transactionToEstimate()
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
            completion(estimates)
        }
        .store(in: &storage)
    }

    
//    func newIndividualAuction1(
//        mintParameters: MintParameters,
//        biddingTime: Int,
//        startingBid: NSNumber
//    ) {
//        guard let NFTrackAddress = NFTrackAddress else {
//            self.alert.showDetail("Sorry", with: "There was an error loading the minting contract address.", for: self)
//            return
//        }
//
//        self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress)
//        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
//
//        // to be used for getting the contract address so that the token can be transferred
//        var auctionHash: String!
//
//        self.progressModal = ProgressModalViewController(paymentMethod: .auctionBeneficiary)
//        self.progressModal.titleString = "Posting In Progress"
//        self.present(self.progressModal, animated: true, completion: {
//            print("STEP 1")
//            // prepare the deployment transaction of the auction contract
//            return Future<TxPackage, PostingError> { promise in
//                self.transactionService.prepareTransactionForNewContractWithGasEstimate(
//                    contractABI: auctionABI,
//                    bytecode: auctionBytcode,
//                    parameters: transactionParameters,
//                    promise: promise
//                )
//            }
//            .flatMap { (txPackage) -> AnyPublisher<[TxPackage], PostingError> in
//                // TxPackage array is needed because calculateTotalGasCost can calculate multiple transactions' gas.
//                // In this case, there is only one transaction to be calculated.
//                // The minting transaction can't be calculated because it requires the auction contract's address.
//                txPackageArr.append(txPackage)
//                return Future<[TxPackage], PostingError> { promise in
//                    print("STEP 2")
//                    let gasEstimateToMintAndTransferAToken: BigUInt = 80000
//                    self.transactionService.calculateTotalGasCost(
//                        with: txPackageArr,
//                        plus: gasEstimateToMintAndTransferAToken,
//                        promise: promise
//                    )
//                    let update: [String: PostProgress] = ["update": .estimatGas]
//                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                }
//                .eraseToAnyPublisher()
//            }
//            // execute the deployment transaction and get the receipts in an array
//            .flatMap { (txPackages) -> AnyPublisher<[TxResult2], PostingError> in
//                let update: [String: PostProgress] = ["update": .images]
//                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//
//                print("STEP 3")
//                let results = txPackages.map { self.transactionService.executeTransaction2(
//                    transaction: $0.transaction,
//                    password: "",
//                    type: $0.type
//                )}
//                return Publishers.MergeMany(results)
//                    .collect()
//                    .eraseToAnyPublisher()
//            }
//            // confirm that the block has been added to the chain
//            .flatMap({ (txResults) -> AnyPublisher<[TransactionReceipt], PostingError> in
//                txResultArr = txResults
//                guard let txResult = txResults.first else {
//                    return Fail(error: PostingError.generalError(reason: "Parsing the transaction result error."))
//                        .eraseToAnyPublisher()
//                }
//                return self.transactionService.confirmEtherTransactionsNoDelay(txHash: txResult.txResult.hash)
//            })
//            .eraseToAnyPublisher()
//            // mint a token and transfer it to the address of the newly deployed auction contract
//            .flatMap({ (txReceipts) -> AnyPublisher<WriteTransaction, PostingError> in
//                print("STEP 5")
//
//                let update: [String: PostProgress] = ["update": .deployingAuction]
//                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//
//                guard let txReceipt = txReceipts.first else {
//                    return Fail(error: PostingError.generalError(reason: "Parsing the transaction result error."))
//                        .eraseToAnyPublisher()
//                }
//
//                guard let auctionContractAddress = txReceipt.contractAddress else {
//                    return Fail(error: PostingError.generalError(reason: "Failed to obtain the auction contract address."))
//                        .eraseToAnyPublisher()
//                }
//
//                // prepare the transaction to mint and transfer the token
//                return Future<WriteTransaction, PostingError> { promise in
//                    self.transactionService.prepareTransactionForMinting(
//                        receiverAddress: auctionContractAddress,
//                        promise: promise
//                    )
//                }
//                .eraseToAnyPublisher()
//            })
//            // execute the mint transaction
//            .flatMap { (transaction) -> AnyPublisher<[TxResult2], PostingError> in
//                print("STEP 6")
//
//                let results = self.transactionService.executeTransaction2(
//                    transaction: transaction,
//                    password: "",
//                    type: .mint
//                )
//
//                return Publishers.MergeMany(results)
//                    .collect()
//                    .eraseToAnyPublisher()
//            }
//            // get the topics from the socket delegate
//            .flatMap { (txResult) -> AnyPublisher<[String: Any], PostingError> in
//                // retain the mint transaction details for FireStore
//                txResultArr.append(contentsOf: txResult)
//                return Future<[String: Any], PostingError> { promise in
//                    print("STEP 7")
//                    self.socketDelegate.promise = promise
//                }
//                .eraseToAnyPublisher()
//            }
//            // instantiate the socket, parse the topics, and create the firebase entry as soon as the socket delegate receives the data
//            // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
//            .flatMap({ (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
//                let update: [String: PostProgress] = ["update": .minting]
//                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//
//                if let topics = webSocketMessage["topics"] as? [String] {
//                    topicsRetainer = topics
//                }
//
//                // upload images/files to the Firebase Storage and get the array of URLs
//                if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
//                    let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
//                        return Future<String?, PostingError> { promise in
//                            self.uploadFileWithPromise(
//                                fileURL: previewData.filePath,
//                                userId: self.userId,
//                                promise: promise
//                            )
//                        }.eraseToAnyPublisher()
//                    }
//                    return Publishers.MergeMany(fileURLs)
//                        .collect()
//                        .eraseToAnyPublisher()
//                } else {
//                    // if there are none to upload, return an empty array
//                    return Result.Publisher([] as [String]).eraseToAnyPublisher()
//                }
//            })
//            // upload the details to Firestore
//            .flatMap { (urlStrings) -> AnyPublisher<Int, PostingError> in
//                var mintHash: String!
//                var senderAddress: String!
//                for txResult in txResultArr {
//                    if txResult.txType == .deploy {
//                        auctionHash = txResult.txResult.hash
//                    } else {
//                        mintHash = txResult.txResult.hash
//                    }
//                    senderAddress = txResult.senderAddress
//                }
//                print("STEP 8")
//
//                return Future<Int, PostingError> { promise in
//                    self.transactionService.createFireStoreEntry(
//                        documentId: &self.documentId,
//                        senderAddress: senderAddress,
//                        escrowHash: "N/A",
//                        auctionHash: auctionHash,
//                        mintHash: mintHash,
//                        itemTitle: mintParameters.itemTitle,
//                        desc: mintParameters.desc,
//                        price: "N/A",
//                        category: mintParameters.category,
//                        tokensArr: mintParameters.tokensArr,
//                        convertedId: mintParameters.convertedId,
//                        type: "digital",
//                        deliveryMethod: mintParameters.deliveryMethod,
//                        saleFormat: mintParameters.saleFormat,
//                        paymentMethod: mintParameters.paymentMethod,
//                        topics: topicsRetainer,
//                        urlStrings: urlStrings,
//                        ipfsURLStrings: [],
//                        promise: promise
//                    )
//                }
//                .eraseToAnyPublisher()
//            }
//            .sink { (completion) in
//                switch completion {
//                    case .failure(let error):
//                        self.processFailure(error)
//                    case .finished:
//                        let update: [String: PostProgress] = ["update": .initializeAuction]
//                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//
//                        // index Core Spotlight
//                        self.indexSpotlight(
//                            itemTitle: mintParameters.itemTitle,
//                            desc: mintParameters.desc,
//                            tokensArr: mintParameters.tokensArr,
//                            convertedId: mintParameters.convertedId
//                        )
//
//                        DispatchQueue.main.async {
//                            self.titleTextField.text?.removeAll()
//                            self.priceTextField.text?.removeAll()
//                            self.descTextView.text?.removeAll()
//                            self.idTextField.text?.removeAll()
//                            self.saleMethodLabel.text?.removeAll()
//                            self.auctionDurationLabel.text?.removeAll()
//                            self.auctionStartingPriceTextField.text?.removeAll()
//                            self.pickerLabel.text?.removeAll()
//                            self.tagTextField.tokens.removeAll()
//                            self.paymentMethodLabel.text?.removeAll()
//                        }
//
//                        if self.previewDataArr.count > 0 {
//                            self.previewDataArr.removeAll()
//                            self.imagePreviewVC.data.removeAll()
//                            DispatchQueue.main.async {
//                                self.imagePreviewVC.collectionView.reloadData()
//                            }
//                        }
//                }
//            } receiveValue: { (_) in
//                if self.socketDelegate != nil {
//                    self.socketDelegate.disconnectSocket()
//                }
//            }
//            .store(in: &self.storage)
//        }) // present for progressModal
//    }
    
    // MARK: - newIntegralAuction
    func newIntegralAuction(
        mintParameters: MintParameters,
        biddingTime: Int,
        startingBid: NSNumber
    ) {
        guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress else {
            return
        }
        
        // The parameters for the createAuction method
        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]

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
            
            self?.executeIntegralAuction(
                estimates: estimates,
                mintParameters: mintParameters
            )
        }
        .store(in: &storage)
    }
    
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
