//
//  IntegralAuctionViewController + CreateAuctionMethod.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-06.
//

import UIKit
import Combine
import FirebaseFirestore
import FirebaseMessaging

extension IntegralAuctionViewController: HandleError, PostParseDelegate {
    // Dynamically determine what auction method to call
    func callAuctionMethod(for method: AuctionContract.ContractMethods, amountString: String? = nil) {
        guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress else {
            self.alert.showDetail("Error", with: "Unable to get the auction contract address.", for: self)
            return
        }
        
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) else {
            self.alert.showDetail("Error", with: "Unable to retrieve the user ID. Please try re-starting the app.", for: self)
            return
        }
        
        guard let currentAddress = Web3swiftService.currentAddressString else {
            self.alert.showDetail("Error", with: "Unable to update the database.", for: self)
            return
        }
        
        guard let documentId = self.post.documentId else {
            self.alert.showDetail("Error", with: "Unable to get the document ID of the database.", for: self)
            return
        }
        
        let parameters: [AnyObject] = [post.solireyUid] as [AnyObject]
        
        self.transactionService.preLaunch { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
            Future<TxPackage, PostingError> { promise in
                self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                    method: method.rawValue,
                    abi: integralAuctionABI,
                    param: parameters,
                    contractAddress: integralAuctionAddress,
                    amountString: amountString ?? "0",
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        } completionHandler: { [weak self] (estimates, txPackage, error) in
            if let error = error {
                self?.processFailure(error)
            }
            
            if let estimates = estimates,
               let txPackage = txPackage {
                
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
                
                self?.hideSpinner()
                
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
                                self?.showSpinner()
                                
                                guard let transactionService = self?.transactionService else {
                                    self?.alert.showDetail("Error", with: "Unable to execute the transaction.", for: self)
                                    return
                                }

                                Deferred {
                                    transactionService.executeTransaction(
                                        transaction: txPackage.transaction,
                                        password: password,
                                        type: .auctionContract
                                    )
                                }
                                .flatMap({ (txResult) -> AnyPublisher<Data, PostingError> in
                                    self?.txResult = txResult

                                    switch method {
                                        case .abort:
                                            self?.db.collection("post").document(documentId).updateData([
                                                "status": AuctionStatus.aborted.rawValue,
                                            ])
                                            return Result.Publisher(Data()).eraseToAnyPublisher()
                                        case .bid:
                                            // let's every user involved in the auction (who has previously bid before) know through the push notification that there's been a new bid
                                            let fcmToken = UserDefaults.standard.string(forKey: UserDefaultKeys.fcmToken)

                                            // The update of the status and the date is to display the progress on ProgressCell
                                            // The wallet address/userId pairing is necessary to update the buyerUserId with the highest bidder account address.
                                            self?.db.collection("post").document(documentId).updateData([
                                                "bidderTokens": FieldValue.arrayUnion([fcmToken ?? ""]),
                                                "bidders": FieldValue.arrayUnion([userId]),
                                                "status": AuctionStatus.bid.rawValue,
                                                "bidDate": Date(),
                                                "bidderWalletAddress": [currentAddress: userId]
                                            ], completion: { (error) in
                                                if let error = error {
                                                    print("firebase error", error)
                                                }
                                            })

                                            // unsubscribe so that you don't get the push notification for your own update
                                            // but later resubscribe for the notification for the counterparty
                                            // firebase doesn't have a way to opt out of the notification directed at yourself?
                                            Messaging.messaging().unsubscribe(fromTopic: documentId) { error in
                                                print("unsubscribed to \(self?.post.documentId ?? "")")
                                            }

                                            return FirebaseService.shared.sendToTopics(
                                                title: "Auction Bid",
                                                content: "A new bid was made in your auction.",
                                                topic: documentId,
                                                docId: documentId
                                            )
                                        case .auctionEnd:
                                            // socket will utimately pick up the topics of the event emitted at the time the "auctionEnd" method is called
                                            // but setting the isAuctionOfficiallyEnded property here to true as an insurance in case the socket doesn't pick up the topics (i.e. the internet connection failure)
                                            self?.auctionButtonController.isAuctionOfficiallyEnded = true
                                            
                                            // The progress indicator of the auction is bid, ended, transferred
                                            self?.db.collection("post").document(documentId).updateData([
                                                "status": AuctionStatus.transferred.rawValue,
                                                "auctionEndDate": Date(),
                                                "auctionTransferredDate": Date(),
                                            ])
                                            return FirebaseService.shared.unsubscribeToTopic(topic: documentId)
                                        case .withdraw:
                                            NotificationCenter.default.post(name: .auctionDidWithdraw, object: true)
                                            return Result.Publisher(Data()).eraseToAnyPublisher()
                                        case .transferToken:
//                                            self?.db.collection("post").document(documentId).updateData([
//                                                "status": AuctionStatus.transferred.rawValue,
//                                                "auctionTransferredDate": Date()
//                                            ])
                                            return Result.Publisher(Data()).eraseToAnyPublisher()
                                        case .getTheHighestBid:
                                            self?.db.collection("post").document(documentId).updateData([
                                                "isWithdrawn": true,
                                            ])
                                            return Result.Publisher(Data()).eraseToAnyPublisher()
                                        case .resell:
                                            return Result.Publisher(Data()).eraseToAnyPublisher()
                                    }
                                })
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            switch error {
                                                case .generalError(reason: let msg):
                                                    self?.alert.showDetail("Error", with: msg, for: self)
                                                case .apiError(.decodingError):
                                                    self?.alert.showDetail("Decoding Error", with: "There was a decoding error from HTTP's response.", for: self)
                                                case .apiError(.generalError(reason: let err)):
                                                    self?.alert.showDetail("Network Error", with: err, for: self)
                                                default:
                                                    self?.alert.showDetail("Error", with: "There was an error executing this process.", for: self)
                                            }
                                            break
                                        case .finished:
                                            guard let self = self else { return }

                                            switch method {
                                                case .abort:
                                                    self.alert.showDetail(
                                                        "Success!",
                                                        with: "You have successfully withdrawn the final bid. It'll be reflected on your wallet soon.",
                                                        for: self) { [weak self] in
                                                        DispatchQueue.main.async {
                                                            self?.navigationController?.popViewController(animated: true)
                                                        }
                                                    } completion: {}
                                                    break
                                                case .auctionEnd:
                                                    // Since the bidding is recorded on Firstore with the Firebase User ID and the highest bidder is recorded with the wallet address on the blockchain,
                                                    // we need to find out the user ID with the highest bidder's wallet address at the end.
                                                    // This is so that the buyerUserId is recorded with the Firestore User ID on Firestore in order for the PurchaseVC to query posts using the user ID.
                                                    Future<String, PostingError> { [weak self] promise in
//                                                        guard let documentId = self?.post.documentId else {
//                                                            promise(.failure(.generalError(reason: "Unable to update the database.")))
//                                                            return
//                                                        }
                                                        
                                                        FirebaseService.shared.db
                                                            .collection("post")
                                                            .document(documentId)
                                                            .getDocument(completion: { (document, error) in
                                                                guard let document = document else {
                                                                    promise(.failure(.generalError(reason: "Unable to update the database.")))
                                                                    return
                                                                }
                                                                
                                                                if let _ = error {
                                                                    promise(.failure(.generalError(reason: "Unable to update the database.")))
                                                                    return
                                                                }
                                                                
                                                                if let post = self?.parseDocument(document: document),
                                                                   let bidderWalletAddress = post.bidderWalletAddress,
                                                                   let highestBidder = self?.auctionButtonController.highestBidder,
                                                                   let highestBidderUserId = bidderWalletAddress[highestBidder] {
                                                            
                                                                    promise(.success(highestBidderUserId))
                                                                } else {
                                                                    promise(.failure(.generalError(reason: "Unable to update the database.")))
                                                                }
                                                            })
                                                    }
                                                    .eraseToAnyPublisher()
                                                    .flatMap { [weak self] (userId) -> AnyPublisher<Bool, PostingError> in
                                                        Future<Bool, PostingError> { promise in
//                                                            guard let documentId = self?.post.documentId else {
//                                                                promise(.failure(.generalError(reason: "Unable to update the database.")))
//                                                                return
//                                                            }
                                                            
                                                            self?.db.collection("post").document(documentId).updateData([
                                                                "buyerUserId": userId
                                                            ], completion: { (error) in
                                                                if let _ = error {
                                                                    promise(.failure(.generalError(reason: "Unable to update the database.")))
                                                                } else {
                                                                    promise(.success(true))
                                                                }
                                                            })
                                                        }
                                                        .eraseToAnyPublisher()
                                                    }
                                                    .sink { [weak self] (completion) in
                                                        switch completion {
                                                            case .failure(let error):
                                                                self?.processFailure(error)
                                                                break
                                                            case .finished:
                                                                self?.alert.showDetail(
                                                                    "Auction Ended",
                                                                    with: "Congratulations. You have officially ended the auction! The item has been transferred and the beneficiary can now withdraw the winning bid.",
                                                                    for: self) {
                                                                    DispatchQueue.main.async {
                                                                        self?.navigationController?.popViewController(animated: true)
                                                                    }
                                                                } completion: {}
                                                                break
                                                        }
                                                    } receiveValue: { (_) in
                                                        
                                                    }
                                                    .store(in: &self.storage)
                                                    break
                                                case .bid:
                                                    self.alert.showDetail("Bid Success!", with: "You have made a successful bid. It'll take a few moment to be reflected on the blockchain.", for: self, completion:  {
                                                        self.bidTextField.text?.removeAll()

                                                        // Sub for the first time or re-sub if unsubbed to avoid texting oneself?
                                                        Messaging.messaging().subscribe(toTopic: self.post.documentId) { error in
                                                            print("Subscribed to \(self.post.documentId ?? "") topic")
                                                        }
                                                    })
                                                    break
                                                case .getTheHighestBid:
                                                    self.alert.showDetail(
                                                        "Success!",
                                                        with: "You have successfully withdrawn the final bid. It'll be reflected on your wallet soon.",
                                                        for: self) { [weak self] in
                                                        DispatchQueue.main.async {
                                                            self?.navigationController?.popViewController(animated: true)
                                                        }
                                                    } completion: {}
                                                    break
                                                case .transferToken:
                                                    self.alert.showDetail("Congratulations!", with: "You are now the proud owner of the item. It'll take a few moment to be reflected on the app.", for: self)
                                                    break
                                                case .withdraw:
                                                    self.alert.showDetail("Bid Withdraw", with: "You have successfully withdrawn the previous bid amount.", for: self)
                                                    // the properties has to be manually refetched because the withDraw method doesn't have the events (which means no topics), therefore doesn't trigger the socket event
                                                    DispatchQueue.main.async {
                                                        self.getAuctionInfo(
                                                            transactionHash: self.txResult.txHash,
                                                            executeReadTransaction: self.executeReadTransaction,
                                                            contractAddress: self.auctionContractAddress
                                                        )
                                                    }
                                                    break
                                                case .resell:
                                                    break
                                            }
                                            break
                                    }
                                } receiveValue: { (_) in }
                                .store(in: &self!.storage)
                            }) // self?.dismiss
                        } // mainVC
                    } // alertVC.action
                    self?.present(alertVC, animated: true, completion: nil)
                } // DispatchQueue
            }
        }
    }
}
