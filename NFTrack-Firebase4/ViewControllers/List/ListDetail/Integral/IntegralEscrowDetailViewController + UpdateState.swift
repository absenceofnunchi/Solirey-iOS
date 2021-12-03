//
//  IntegralEscrowDetailViewController + UpdateState.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-28.
//

import UIKit
import FirebaseFirestore
import web3swift
import Combine

extension IntegralEscrowDetailViewController: HandleError, CoreSpotlightDelegate {
    func callEscrowMethod(for method: IntegralEscrowContract.ContractMethods, price: String? = nil) {
        self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
            guard let getIntegralEscrowEstimate = self?.getIntegralEscrowEstimate else {
                return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                    .eraseToAnyPublisher()
            }
            return getIntegralEscrowEstimate(method, price)
            
        }) { [weak self] (estimates, txPackage, error) in
            if let error = error {
                self?.processFailure(error)
            }
            
            if let estimates = estimates,
               let txPackage = txPackage {
                
                self?.executeIntegralEscrow(
                    estimates: estimates,
                    txPackage: txPackage,
                    method: method
                )
            }
        }
    }
    
    final func getIntegralEscrowEstimate(
        method: IntegralEscrowContract.ContractMethods,
        price: String?
    ) -> AnyPublisher<TxPackage, PostingError> {
        return Future<TxPackage, PostingError> { [weak self] promise in
            guard let integralEscrowAddress = ContractAddresses.integralEscrowAddress else {
                promise(.failure(PostingError.generalError(reason: "Unable to prepare the contract address.")))
                return
            }
            
            guard let param = self?.post.solireyUid else {
                promise(.failure(PostingError.generalError(reason: "Unable to get the ID for the smart contract.")))
                    return
            }
                
            self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                method: method.rawValue,
                abi: integralEscrowABI,
                param: [param] as [AnyObject],
                contractAddress: integralEscrowAddress,
                amountString: price,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
    }
    
    func executeIntegralEscrow(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        txPackage: TxPackage,
        method: IntegralEscrowContract.ContractMethods
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
            ),
            StandardAlertContent(
                index: 2,
                titleString: "Tip",
                titleColor: UIColor.white,
                body: [
                    "": "\"Failed to locally sign a transaction\" usually means wrong password.",
                ],
                isEditable: false,
                fieldViewHeight: 100,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner()
        var successMsg: String!
        
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

                        Deferred { [weak self] () -> AnyPublisher<TxResult2, PostingError> in
                            guard let transactionService = self?.transactionService else {
                                return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                                    .eraseToAnyPublisher()
                            }
                            
                            return transactionService.executeTransaction2(transaction: txPackage.transaction, password: password, type: .auctionContract)
                                .eraseToAnyPublisher()
                        }
                        .flatMap({ [weak self] (txPackage) -> AnyPublisher<String, PostingError> in
                            guard let documentId = self?.post.documentId else {
                                return Fail(error: PostingError.generalError(reason: "Unable to get the document ID to update the database."))
                                    .eraseToAnyPublisher()
                            }
                            
                            // Listen to the Transfer even emitted from the mint method of Solirey in order to get the tokenId
                            return Future<String, PostingError> { promise in
                                switch method {
                                    case .createEscrow:
                                        break
                                    case .confirmPurchase:
                                        /// tag 2
                                        /// confirmedPurchase
                                        let buyerHash = Web3swiftService.currentAddressString
                                        FirebaseService.shared.db.collection("post").document(documentId).updateData([
                                            "status": PostStatus.pending.rawValue,
                                            "buyerHash": buyerHash ?? "NA",
                                            "buyerUserId": self?.userId ?? "NA",
                                            "\(method.rawValue)Hash": txPackage.txResult.hash,
                                            "\(method.rawValue)Date": Date()
                                        ], completion: { (error) in
                                            if let _ = error {
                                                promise(.failure(.generalError(reason: "Unable to update the database")))
                                            } else {
                                                /// send the push notification to the seller
                                                guard let self = self else { return }
                                                FirebaseService.shared.sendNotification(
                                                    sender: self.userId,
                                                    recipient: self.post.sellerUserId,
                                                    content: "Your item has been purchased!",
                                                    docID: self.post.documentId
                                                ) { (error) in
                                                    successMsg = "You have confirmed the purchase as buyer. Your deposit will be locked until you confirm receiving the item."
                                                    promise(.success(txPackage.txResult.hash))
                                                }
                                            }
                                        })
                                        break
                                    case .confirmReceived:
                                        /// tag 3
                                        /// confirmRecieved
                                        FirebaseService.shared.db.collection("post").document(documentId).updateData([
                                            "status": PostStatus.complete.rawValue,
                                            "\(method.rawValue)Hash": txPackage.txResult.hash,
                                            "\(method.rawValue)Date": Date()
                                        ], completion: { (error) in
                                            if let _ = error {
                                                promise(.failure(.generalError(reason: "Unable to update the status.")))
                                            } else {
                                                /// send the push notification to the seller
                                                guard let self = self else { return }
                                                FirebaseService.shared.sendNotification(
                                                    sender: self.userId,
                                                    recipient: self.post.sellerUserId,
                                                    content: "Your item has been received by the buyer!",
                                                    docID: self.post.documentId
                                                ) { (error) in
                                                    if let error = error {
                                                        print("error", error)
                                                    }
                                                    
                                                    successMsg = "You have confirmed that you recieved the item. Your deposit will be released back to your account."
                                                    promise(.success(txPackage.txResult.hash))
                                                }
                                            }
                                        })
                                        break
                                    case .abort:
                                        FirebaseService.shared.db.collection("post").document(documentId).updateData([
                                            "status": PostStatus.aborted.rawValue,
                                            "\(method.rawValue)Hash": txPackage.txResult.hash,
                                            "\(method.rawValue)Date": Date()
                                        ], completion: { (error) in
                                            successMsg = "You have aborted the sale. The deployed contract is now locked and your deposit will be sent back to your wallet."
                                            promise(.success(txPackage.txResult.hash))
                                        })
                                        break
                                    case .resell:
                                        break
                                }
                            }
                            .eraseToAnyPublisher()
                        })
                        .sink(receiveCompletion: { (completion) in
                            switch completion {
                                case .failure(let error):
                                    self?.processFailure(error)
                                case .finished:
                                    self?.alert.showDetail(
                                        "Success!",
                                        with: successMsg,
                                        for: self) {
                                        DispatchQueue.main.async {
                                            self?.navigationController?.popViewController(animated: true)
                                        }
                                    } completion: {}
                                    break
                            }
                        }, receiveValue: { (returnedValue) in
                            guard let executeReadTx = self?.executeReadTransaction else {
                                self?.alert.showDetail("Error", with: "Unable to execute the refetch of the updated information.", for: self)
                                return
                            }
                            
                            guard let contractAddress = ContractAddresses.integralEscrowAddress else {
                                self?.alert.showDetail("Error", with: "Unable to fetch the escrow contract address.", for: self)
                                return
                            }
                            
                            self?.getStatus(
                                transactionHash: returnedValue,
                                executeReadTransaction: executeReadTx,
                                contractAddress: contractAddress
                            )
                        })
                        .store(in: &self!.storage)
                    })
                } // mainVC
            } // alertVC.action
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
    
    func transferToken(method: SolireyContract.ContractMethods) {
        self.transactionService.preLaunch (transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
            guard let getSolireyMethodEstimate = self?.transactionService.getSolireyMethodEstimate else {
                return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                    .eraseToAnyPublisher()
            }
            
            guard let tokenId = self?.post.tokenID else {
                return Fail(error: PostingError.generalError(reason: "Unable to get the ID for the smart contract."))
                    .eraseToAnyPublisher()
            }
            
            guard let currentAddress = Web3swiftService.currentAddress else {
                return Fail(error: PostingError.generalError(reason: "Unable to fetch the user's current wallet address."))
                    .eraseToAnyPublisher()
            }
            
            guard let buyerAddressString = self?.post.buyerHash,
                  let buyerAddress = EthereumAddress(buyerAddressString) else {
                return Fail(error: PostingError.generalError(reason: "Unable to fetch the buyer's wallet address."))
                    .eraseToAnyPublisher()
            }
                        
            let transactionParameters: [AnyObject] = [currentAddress, buyerAddress, tokenId] as [AnyObject]
            return getSolireyMethodEstimate(method, transactionParameters)
            
        }) { [weak self] (estimates, txPackage, error) in
            if let error = error {
                self?.processFailure(error)
            }
            
            if let estimates = estimates,
               let txPackage = txPackage {
                
                self?.executeSolirey(
                    estimates: estimates,
                    txPackage: txPackage,
                    method: method
                )
            }
        }
    }
    
    func executeSolirey(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        txPackage: TxPackage,
        method: SolireyContract.ContractMethods
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
            ),
            StandardAlertContent(
                index: 2,
                titleString: "Tip",
                titleColor: UIColor.white,
                body: [
                    "": "\"Failed to locally sign a transaction\" usually means wrong password.",
                ],
                isEditable: false,
                fieldViewHeight: 100,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner()
        var successMsg: String!
        
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
                        
                        Deferred { [weak self] () -> AnyPublisher<TxResult2, PostingError> in
                            guard let transactionService = self?.transactionService else {
                                return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                                    .eraseToAnyPublisher()
                            }
                            
                            return transactionService.executeTransaction2(transaction: txPackage.transaction, password: password, type: .auctionContract)
                                .eraseToAnyPublisher()
                        }
                        .flatMap({ [weak self] (txPackage) -> AnyPublisher<String, PostingError> in
                            guard let documentId = self?.post.documentId else {
                                return Fail(error: PostingError.generalError(reason: "Unable to get the document ID to update the database."))
                                    .eraseToAnyPublisher()
                            }
                            
                            // Listen to the Transfer even emitted from the mint method of Solirey in order to get the tokenId
                            return Future<String, PostingError> { promise in
                                switch method {
                                    case .transferFrom:
                                        /// tag 2
                                        /// confirmedPurchase
                                        FirebaseService.shared.db.collection("post").document(documentId).updateData([
                                            "status": PostStatus.transferred.rawValue,
                                            "transferHash": txPackage.txResult.hash,
                                            "transferDate": Date()
                                        ], completion: { (error) in
                                            if let _ = error {
                                                promise(.failure(.generalError(reason: "Unable to update the database")))
                                            } else {
                                                guard let self = self,
                                                      let buyerUserId = self.post.buyerUserId else { return }
                                                
                                                FirebaseService.shared.sendNotification(
                                                    sender: self.userId,
                                                    recipient: buyerUserId,
                                                    content: "Your item has been transferred!",
                                                    docID: self.post.documentId
                                                ) { (error) in
                                                    successMsg = "You have successfully transferred the item to the buyer."
                                                    promise(.success(txPackage.txResult.hash))
                                                }
                                            }
                                        })
                                    default:
                                        break
                                }
                            }
                            .eraseToAnyPublisher()
                        })
                        .sink(receiveCompletion: { (completion) in
                            switch completion {
                                case .failure(let error):
                                    self?.processFailure(error)
                                case .finished:
                                    self?.hideSpinner()
                                    self?.alert.showDetail(
                                        "Success!",
                                        with: successMsg,
                                        for: self) {
                                        DispatchQueue.main.async {
                                            self?.navigationController?.popViewController(animated: true)
                                        }
                                    } completion: {}
                                    break
                            }
                        }, receiveValue: { (returnedValue) in
                            guard let executeReadTx = self?.executeReadTransaction else {
                                self?.alert.showDetail("Error", with: "Unable to execute the refetch of the updated information.", for: self)
                                return
                            }
                            
                            guard let contractAddress = ContractAddresses.integralEscrowAddress else {
                                self?.alert.showDetail("Error", with: "Unable to fetch the escrow contract address.", for: self)
                                return
                            }
                            
                            self?.getStatus(
                                transactionHash: returnedValue,
                                executeReadTransaction: executeReadTx,
                                contractAddress: contractAddress
                            )
                        })
                        .store(in: &self!.storage)
                    })
                } // mainVC
            } // alertVC.action
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
}
