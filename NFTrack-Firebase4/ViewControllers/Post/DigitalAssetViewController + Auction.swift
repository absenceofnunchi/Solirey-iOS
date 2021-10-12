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
    final func auction(
        price: String = "0",
        itemTitle: String,
        desc: String,
        category: String,
        convertedId: String,
        tokensArr: Set<String>,
        userId: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String,
        auctionDuration: String,
        auctionStartingPrice: String
    ) {
        
        guard let index = auctionDuration.firstIndex(of: "d") else { return }
        let newIndex = auctionDuration.index(before: index)
        let newStr = auctionDuration[..<newIndex]
        guard let numOfDays = NumberFormatter().number(from: String(newStr)) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction duration into a proper format. Please try again.", for: self)
            return
        }
        
        guard let startingBidInWei = Web3.Utils.parseToBigUInt(auctionStartingPrice, units: .eth),
              let startingBid = NumberFormatter().number(from: startingBidInWei.description) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction starting price into a proper format. Pleas try again.", for: self)
            return
        }
        
//        let biddingTime = numOfDays.intValue * 60 * 60 * 24
        let biddingTime = 400
        
        guard let NFTrackAddress = NFTrackAddress else {
            self.alert.showDetail("Sorry", with: "There was an error loading the minting contract address.", for: self)
            return
        }
        /// 1. obtain the password
        /// 2. prepare the auction deployment and minting transactions
        /// 3. execute the transactions and get the receipts in an array
        /// 4. Upload images and files to Firebase storage, if any, or return an empty array
        /// 5. Get the topics from the socket when the txs are mined and create a Firestore entry
        /// 6. Get the token ID through Cloud Functions and update the Firestore entry with it
        /// 7. Using the tx hash of the deployed auction contract, obtain the auction contract address
        /// 8. Using the auction contract address, token ID, and the current address, transfer the token into the auction contract
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
            )]
        
        self.hideSpinner {
            DispatchQueue.main.async {
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let self = self else { return }
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                            return
                        }
                        
                        self.dismiss(animated: true, completion: {
                            self.progressModal = ProgressModalViewController(postType: .digital(.openAuction))
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                
                                self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress)
                                let parameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                                
                                // to be used for getting the contract address so that the token can be transferred
                                var auctionHash: String!
                                var txPackageArr = [TxPackage]()
                                var txResultArr: [TxResult2]!
                                var topicsRetainer: [String]!
                                
                                print("STEP 1")
                                // prepare the deployment transaction of the auction contract
                                Future<TxPackage, PostingError> { promise in
                                    self.transactionService.prepareTransactionForNewContractWithGasEstimate(
                                        contractABI: auctionABI,
                                        bytecode: auctionBytcode,
                                        parameters: parameters,
                                        promise: promise
                                    )
                                }
                                .flatMap { (txPackage) -> AnyPublisher<[TxPackage], PostingError> in
                                    // TxPackage array is needed because calculateTotalGasCost can calculate multiple transactions' gas.
                                    // In this case, there is only one transaction to be calculated.
                                    // The minting transaction can't be calculated because it requires the auction contract's address.
                                    txPackageArr.append(txPackage)
                                    return Future<[TxPackage], PostingError> { promise in
                                        print("STEP 2")
                                        let gasEstimateToMintAndTransferAToken: BigUInt = 80000
                                        self.transactionService.calculateTotalGasCost(
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
                                .flatMap { (txPackages) -> AnyPublisher<[TxResult2], PostingError> in
                                    let update: [String: PostProgress] = ["update": .images]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    print("STEP 3")
                                    let results = txPackages.map { self.transactionService.executeTransaction2(
                                        transaction: $0.transaction,
                                        password: password,
                                        type: $0.type
                                    )}
                                    return Publishers.MergeMany(results)
                                        .collect()
                                        .eraseToAnyPublisher()
                                }
                                // confirm that the block has been added to the chain
                                .flatMap({ (txResults) -> AnyPublisher<[TransactionReceipt], PostingError> in
                                    txResultArr = txResults
                                    guard let txResult = txResults.first else {
                                        return Fail(error: PostingError.generalError(reason: "Parsing the transaction result error."))
                                            .eraseToAnyPublisher()
                                    }
                                    return self.transactionService.confirmEtherTransactionsNoDelay(txHash: txResult.txResult.hash)
                                })
                                .eraseToAnyPublisher()
                                // mint a token and transfer it to the address of the newly deployed auction contract
                                .flatMap({ (txReceipts) -> AnyPublisher<WriteTransaction, PostingError> in
                                    print("STEP 5")
                                    
                                    let update: [String: PostProgress] = ["update": .deployingAuction]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    guard let txReceipt = txReceipts.first else {
                                        return Fail(error: PostingError.generalError(reason: "Parsing the transaction result error."))
                                            .eraseToAnyPublisher()
                                    }
                                    
                                    guard let auctionContractAddress = txReceipt.contractAddress else {
                                        return Fail(error: PostingError.generalError(reason: "Failed to obtain the auction contract address."))
                                            .eraseToAnyPublisher()
                                    }
                                    
                                    // prepare the transaction to mint and transfer the token
                                    return Future<WriteTransaction, PostingError> { promise in
                                        self.transactionService.prepareTransactionForMinting(
                                            receiverAddress: auctionContractAddress,
                                            promise: promise
                                        )
                                    }
                                    .eraseToAnyPublisher()
                                })
                                // execute the mint transaction
                                .flatMap { (transaction) -> AnyPublisher<[TxResult2], PostingError> in
                                    print("STEP 6")
                                    
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
                                .flatMap { (txResult) -> AnyPublisher<[String: Any], PostingError> in
                                    // retain the mint transaction details for FireStore
                                    txResultArr.append(contentsOf: txResult)
                                    return Future<[String: Any], PostingError> { promise in
                                        print("STEP 7")
                                        self.socketDelegate.promise = promise
                                    }
                                    .eraseToAnyPublisher()
                                }
                                // instantiate the socket, parse the topics, and create the firebase entry as soon as the socket delegate receives the data
                                // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
                                .flatMap({ (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
                                    let update: [String: PostProgress] = ["update": .minting]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    if let topics = webSocketMessage["topics"] as? [String] {
                                        topicsRetainer = topics
                                    }
                                    
                                    // upload images/files to the Firebase Storage and get the array of URLs
                                    if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
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
                                    var mintHash: String!
                                    var senderAddress: String!
                                    for txResult in txResultArr {
                                        if txResult.txType == .deploy {
                                            auctionHash = txResult.txResult.hash
                                        } else {
                                            mintHash = txResult.txResult.hash
                                        }
                                        senderAddress = txResult.senderAddress
                                    }
                                    print("STEP 8")
                                    
                                    return Future<Int, PostingError> { promise in
                                        self.transactionService.createFireStoreEntry(
//                                            documentId: &self.documentId,
                                            senderAddress: senderAddress,
                                            escrowHash: "N/A",
                                            auctionHash: auctionHash,
                                            mintHash: mintHash,
                                            itemTitle: itemTitle,
                                            desc: desc,
                                            price: "N/A",
                                            category: category,
                                            tokensArr: tokensArr,
                                            convertedId: convertedId,
                                            type: "digital",
                                            deliveryMethod: deliveryMethod,
                                            saleFormat: saleFormat,
                                            paymentMethod: paymentMethod,
                                            topics: topicsRetainer,
                                            urlStrings: urlStrings,
                                            ipfsURLStrings: [],
                                            promise: promise
                                        )
                                    }
                                    .eraseToAnyPublisher()
                                }
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            switch error {
                                                case .fileUploadError(.fileNotAvailable):
                                                    self.alert.showDetail("Error", with: "No image file was found.", for: self)
                                                case .retrievingEstimatedGasError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving the gas estimation.", for: self)
                                                case .retrievingGasPriceError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving the current gas price.", for: self)
                                                case .contractLoadingError:
                                                    self.alert.showDetail("Error", with: "There was an error loading your contract ABI.", for: self)
                                                case .retrievingCurrentAddressError:
                                                    self.alert.showDetail("Account Retrieval Error", with: "Error retrieving your account address. Please ensure that you're logged into your wallet.", for: self)
                                                case .createTransactionIssue:
                                                    self.alert.showDetail("Error", with: "There was an error creating a transaction.", for: self)
                                                case .insufficientFund(let msg):
                                                    self.alert.showDetail("Error", with: msg, height: 500, fieldViewHeight: 300, alignment: .left, for: self)
                                                case .emptyAmount:
                                                    self.alert.showDetail("Error", with: "The ETH value cannot be blank for the transaction.", for: self)
                                                case .invalidAmountFormat:
                                                    self.alert.showDetail("Error", with: "The ETH value is in an incorrect format.", for: self)
                                                case .generalError(reason: let msg):
                                                    self.alert.showDetail("Error", with: msg, for: self)
                                                default:
                                                    self.alert.showDetail("Error", with: "There was an error creating your post.", for: self)
                                            }
                                        case .finished:
                                            let update: [String: PostProgress] = ["update": .initializeAuction]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                            
                                            // index Core Spotlight
                                            self.indexSpotlight(
                                                itemTitle: itemTitle,
                                                desc: desc,
                                                tokensArr: tokensArr,
                                                convertedId: convertedId
                                            )
                                            
                                            DispatchQueue.main.async {
                                                self.titleTextField.text?.removeAll()
                                                self.priceTextField.text?.removeAll()
                                                self.descTextView.text?.removeAll()
                                                self.idTextField.text?.removeAll()
                                                self.saleMethodLabel.text?.removeAll()
                                                self.auctionDurationLabel.text?.removeAll()
                                                self.auctionStartingPriceTextField.text?.removeAll()
                                                self.pickerLabel.text?.removeAll()
                                                self.tagTextField.tokens.removeAll()
                                                self.paymentMethodLabel.text?.removeAll()
                                            }
                                            
                                            if self.previewDataArr.count > 0 {
                                                self.previewDataArr.removeAll()
                                                self.imagePreviewVC.data.removeAll()
                                                DispatchQueue.main.async {
                                                    self.imagePreviewVC.collectionView.reloadData()
                                                }
                                            }
                                    }
                                } receiveValue: { (receivedValue) in
                                    
                                    if self.socketDelegate != nil {
                                        self.socketDelegate.disconnectSocket()
                                    }
                                }
                                .store(in: &self.storage)
                            }) // present for progressModal
                        }) // dismiss
                    } // mainVC buttonAction
                } // alertVC
                self.present(alertVC, animated: true, completion: nil)
            } // DispatchQueue
        } // hideSpinner
    }

}
