//
//  PostViewController + DirectSaleRevised.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-19.
//

/*
 Abtract:
 Revised SimplePayment embedded in NFTrack so that no new smart contracts need to be deployed for each sale.
 This is for tangible (in-person, no shipping) and digital
 
 Direct sale revised is the most primitive method of payment where the buyer pays for an item and the ownership of the item is transferred right away, which means there is only one step for the buyer for the purchase.
 The seller mints a token and withdraws the fund after the purchase has been made, which means it takes two steps for the seller.
 It uses the NFTrack contract deployed by the admin and requires no deployments from the user's end.
 */

import UIKit
import CryptoKit
import Combine
import web3swift

extension PostViewController {
    // MARK: - processDirectSaleRevised
    override func processDirectSaleRevised(_ mintParameters: ParentPostViewController.MintParameters) {
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
        
        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
            return
        }
        
        guard let NFTrackABIRevisedAddress = NFTrackABIRevisedAddress else {
            self.alert.showDetail("Error", with: "Unable to get the smart contract address.", for: self)
            return
        }
        
        // create an ID for the new item to be saved into the _simplePayment mapping.
        let combinedString = self.ref.document().documentID + mintParameters.userId
        let inputData = Data(combinedString.utf8)
        let hashedId = SHA256.hash(data: inputData)
        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()
        
        // The parameters for the createSimplePayment method
        let param: [AnyObject] = [priceInWei, hashString] as [AnyObject]
        
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
        
        var txResultRetainer: TransactionSendingResult!
        
        self.hideSpinner { [weak self] in
            DispatchQueue.main.async {
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { (modal, mainVC) in
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
                                self.socketDelegate = SocketDelegate(contractAddress: NFTrackABIRevisedAddress)
                                
                                Deferred {
                                    Future<WriteTransaction, PostingError> { [weak self] promise in
                                        self?.transactionService.prepareTransactionForWriting(
                                            method: NFTrackContract.ContractMethods.createSimplePayment.rawValue,
                                            abi: NFTrackABIRevisedABI,
                                            param: param,
                                            contractAddress: NFTrackABIRevisedAddress,
                                            amountString: nil,
                                            promise: promise
                                        )
                                    }
                                }
                                .flatMap { (transaction) -> AnyPublisher<TransactionSendingResult, PostingError> in
                                    let update: [String: PostProgress] = ["update": .estimatGas]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    return Future<TransactionSendingResult, PostingError> { promise in
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
                                // get the topics of the paymentMade event from the socket delegate
                                .flatMap { [weak self] (txResult) -> AnyPublisher<[String: Any], PostingError> in
                                    // retain the mint transaction details for FireStore
                                    txResultRetainer = txResult
                                    return Future<[String: Any], PostingError> { promise in
                                        self?.socketDelegate.promise = promise
                                    }
                                    .eraseToAnyPublisher()
                                }
                                // parse the topics, and create the firebase entry as soon as the socket delegate receives the data
                                // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
                                .flatMap({ [weak self] (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
                                    let update: [String: PostProgress] = ["update": .minting]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    if let topics = webSocketMessage["topics"] as? [String] {
                                        self?.topicsRetainer = topics
                                    }
                                    
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
                                .flatMap { [weak self] (urlStrings) -> AnyPublisher<Int, PostingError> in
                                    let update: [String: PostProgress] = ["update": .images]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    guard let topics = self?.topicsRetainer,
                                          let currentAddressString = Web3swiftService.currentAddressString else {
                                        return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
                                            .eraseToAnyPublisher()
                                    }

                                    return Future<Int, PostingError> { promise in
                                        self?.transactionService.createFireStoreEntry(
                                            senderAddress: currentAddressString,
                                            escrowHash: "N/A",
                                            auctionHash: "N/A",
                                            simplePaymentId: hashString,
                                            mintHash: txResultRetainer.hash,
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
                                .store(in: &self.storage)
                                
                            }) // self.present
                        }) // self.dismiss
                    } // mainVC.buttonAction
                } // alertVC.action
                self?.present(alertVC, animated: true, completion: nil)
            } // DispatchQueue
        } // self.hideSpinner
    }
}

extension PostViewController {
    func createSimplePayment(price: String, uniqueIdentifier: String) {
     
    }
}
