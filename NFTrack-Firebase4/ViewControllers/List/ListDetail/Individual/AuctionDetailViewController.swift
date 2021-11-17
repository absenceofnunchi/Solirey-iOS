//
//  AuctionDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-13.
//

/*
 Abstract:
 The individual auction.
 Update the status and the date of each step: bid, ended, and transferred.  These three are for the ProgressCell indicator.
 */

import UIKit
import Combine
import web3swift
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

class AuctionDetailViewController: ParentAuctionDetailViewController {
    final var propertiesToLoad: [AuctionContract.ContractProperties]!
    
    init(auctionContractAddress: EthereumAddress, myContractAddress: EthereumAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.contractAddress = myContractAddress
        self.auctionContractAddress = auctionContractAddress
        
        self.propertiesToLoad = [
            AuctionContract.ContractProperties.startingBid,
            AuctionContract.ContractProperties.highestBid,
            AuctionContract.ContractProperties.highestBidder,
            AuctionContract.ContractProperties.auctionEndTime,
            AuctionContract.ContractProperties.ended,
            AuctionContract.ContractProperties.pendingReturns(myContractAddress),
            AuctionContract.ContractProperties.beneficiary
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let auctionHash = post.auctionHash else { return }
        getAuctionInfo(
            transactionHash: auctionHash,
            executeReadTransaction: executeReadTransaction,
            contractAddress: auctionContractAddress
        )
        addKeyboardObserver()
    }

    // MARK: - callAuctionMethod
    // Dynamically determine what auction method to call 
    override final func callAuctionMethod(for method: AuctionContract.ContractMethods, amountString: String? = nil) {
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
        
        var content = [
            StandardAlertContent(
                index: 0,
                titleString: "Password",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                index: 1,
                titleString: "Details",
                body: [
                    AlertModalDictionary.gasLimit: "",
                    AlertModalDictionary.gasPrice: "",
                    AlertModalDictionary.nonce: ""
                ],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        // auxiliary info to be displayed to the user before the execution
        let withDrawInfo = StandardAlertContent(
            index: 2,
            titleString: "Withdrawal",
            body: [
                "": InfoText.withdraw
            ],
            messageTextAlignment: .left
        )
        
        switch method {
            case .withdraw:
                content.append(withDrawInfo)
            default:
                break
        }
        
        let alertVC = AlertViewController(height: 350, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            // responses to the main vc's button
            mainVC.buttonAction = { _ in
                guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                      !password.isEmpty else {
                    self?.alert.fading(text: "Email cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                    return
                }
                
                guard let self = self else { return }
                self.dismiss(animated: true, completion: {
                    self.showSpinner {
                        // use Deferred?
                        Future<WriteTransaction, PostingError> { promise in
                            guard let auctionContractAddress = self.auctionContractAddress else {
                                promise(.failure(.generalError(reason: "Unable to load the address for the auction contract.")))
                                return
                            }
                            
                            // if the socket timed out, reconnect
                            if let isSocketConnected = self.socketDelegate.socketProvider?.socket.isConnected,
                               isSocketConnected == false {
                                self.createSocket()
                            }
                            
                            self.transactionService.prepareTransactionForWriting(
                                method: method.rawValue,
                                abi: individualAuctionABI,
                                contractAddress: auctionContractAddress,
                                amountString: amountString ?? "0",
                                promise: promise
                            )
                        }
                        .flatMap { (transaction) -> Future<TxResult, PostingError> in
                            self.transactionService.executeTransaction(
                                transaction: transaction,
                                password: password,
                                type: .auctionContract
                            )
                        }
                        .flatMap({ (txResult) -> AnyPublisher<Data, PostingError> in
                            self.txResult = txResult
                            switch method {
                                case .bid:
                                    // let's every user involved in the auction (who has previously bid before) know through the push notification that there's been a new bid
                                    let fcmToken = UserDefaults.standard.string(forKey: UserDefaultKeys.fcmToken)
                                    
                                    // the update of the status and the date is to display the progress on ProgressCell
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "bidderTokens": FieldValue.arrayUnion([fcmToken ?? ""]),
                                        "bidders": FieldValue.arrayUnion([userId]),
                                        "bidderWalletAddress": [currentAddress: userId],
                                        "status": AuctionStatus.bid.rawValue,
                                        "bidDate": Date()
                                    ], completion: { (error) in
                                        if let error = error {
                                            print("firebase error", error)
                                        }
                                    })

                                    // unsubscribe so that you don't get the push notification for your own update
                                    // but later resubscribe for the notification for the counterparty
                                    // firebase doesn't have a way to opt out of the notification directed at yourself
                                    Messaging.messaging().unsubscribe(fromTopic: self.post.documentId) { error in
                                        print("unsubscribed to \(self.post.documentId ?? "")")
                                    }

                                    return FirebaseService.shared.sendToTopics(
                                        title: "Auction Bid",
                                        content: "A new bid was made in your auction.",
                                        topic: self.post.documentId,
                                        docId: self.post.documentId
                                    )
                                case .auctionEnd:
                                    // socket will utimately pick up the topics of the event emitted at the time the "auctionEnd" method is called
                                    // but setting the isAuctionOfficiallyEnded property here to true as an insurance in case the socket doesn't pick up the topics (i.e. the internet connection failure)
                                    self.auctionButtonController.isAuctionOfficiallyEnded = true
                                    
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "status": AuctionStatus.transferred.rawValue,
                                        "auctionEndDate": Date(),
                                        "auctionTransferredDate": Date()
                                    ])
                                    return FirebaseService.shared.unsubscribeToTopic(topic: self.post.documentId)
                                case .withdraw:
                                    NotificationCenter.default.post(name: .auctionDidWithdraw, object: true)
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .transferToken:
//                                    self.db.collection("post").document(self.post.documentId).updateData([
//                                        "status": AuctionStatus.transferred.rawValue,
//                                        "auctionTransferredDate": Date()
//                                    ])
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .abort:
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "status": AuctionStatus.aborted.rawValue,
                                    ])
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .resell:
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                default:
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                            }
                        })
                        .sink { (completion) in
                            switch completion {
                                case .failure(let error):
                                    switch error {
                                        case .generalError(reason: let msg):
                                            self.alert.showDetail("Error", with: msg, for: self)
                                        case .apiError(.decodingError):
                                            self.alert.showDetail("Decoding Error", with: "There was a decoding error from HTTP's response.", for: self)
                                        case .apiError(.generalError(reason: let err)):
                                            self.alert.showDetail("Network Error", with: err, for: self)
                                        default:
                                            self.alert.showDetail("Error", with: "There was an error executing this process.", for: self)
                                    }
                                    break
                                case .finished:
                                    switch method {
                                        case .auctionEnd:
                                            self.alert.showDetail(
                                                "Auction Ended",
                                                with: "Congratulations. You have officially ended the auction! The item has been transferred and the beneficiary can now withdraw the winning bid.",
                                                for: self) {
                                                DispatchQueue.main.async {
                                                    self.navigationController?.popViewController(animated: true)
                                                }
                                            } completion: {}
                                            
                                            Future<String, PostingError> { [weak self] promise in
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
                                                
                                                // Sub for the first time or re-sub if unsubbed to avoid texting oneself
                                                Messaging.messaging().subscribe(toTopic: self.post.documentId) { error in
                                                    print("Subscribed to \(self.post.documentId ?? "") topic")
                                                }
                                            })
                                            break
                                        case .getTheHighestBid:
                                            self.alert.showDetail("Success!", with: "You have successfully withdrawn the final bid. It'll be reflected on your wallet soon.", for: self)
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
                                        case .resell:
                                            break
                                    }
                                    break
                            }
                        } receiveValue: { (_) in }
                        .store(in: &self.storage)
                    } // showSpinner
                }) // self.dismiss
            } // mainVC
        } // alertVC
        self.present(alertVC, animated: true, completion: nil)
    } // callAuctionMethod
}
