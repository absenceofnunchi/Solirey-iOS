//
//  ListDetailViewController + UpdateState.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-16.
//

import UIKit
import FirebaseFirestore
import web3swift
import Combine

extension ListDetailViewController: CoreSpotlightDelegate {
    final func updateState(method: String, price: String = "0", status: PostStatus? = nil) {
        transactionService.prepareTransactionForWriting(
            method: method,
            abi: purchaseABI2,
            contractAddress: contractAddress,
            amountString: price
        ) { [weak self](transaction, error) in
            if let error = error {
                switch error {
                    case .invalidAmountFormat:
                        self?.alert.showDetail("Error", with: "The ETH amount is not in a correct format!", for: self)
                    case .zeroAmount:
                        self?.alert.showDetail("Error", with: "The ETH amount cannot be negative", for: self)
                    case .insufficientFund:
                        self?.alert.showDetail("Error", with: "There is an insufficient amount of ETH in the wallet.", for: self)
                    case .contractLoadingError:
                        self?.alert.showDetail("Error", with: "There was an error loading your contract.", for: self)
                    case .createTransactionIssue:
                        self?.alert.showDetail("Error", with: "There was an error creating the transaction.", for: self)
                    default:
                        self?.alert.showDetail("Sorry", with: "There was an error. Please try again.", for: self)
                }
            }
            
            if let transaction = transaction {
                let content = [
                    StandardAlertContent(
                        titleString: AlertModalDictionary.passwordTitle,
                        body: [AlertModalDictionary.passwordSubtitle: ""],
                        isEditable: true,
                        fieldViewHeight: 50,
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton
                    )
                ]
                
                DispatchQueue.main.async {
                    let alertVC = AlertViewController(standardAlertContent: content)
                    alertVC.action = { (modal, mainVC) in
                        mainVC.buttonAction = { _ in
                            guard  let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                                   !password.isEmpty else {
                                self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                                return
                            }
                            
                            self?.dismiss(animated: true, completion: {
                                self?.showSpinner {
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        do {
                                            let result = try transaction.send(password: password, transactionOptions: nil)
                                            if let status = status {
                                                switch status {
                                                    case .ready:
                                                        break
                                                    case .pending:
                                                        /// tag 2
                                                        /// confirmedPurchase
                                                        let buyerHash = Web3swiftService.currentAddressString
                                                        FirebaseService.shared.db.collection("post").document(self!.post.documentId).updateData([
                                                            "status": status.rawValue,
                                                            "buyerHash": buyerHash ?? "NA",
                                                            "buyerUserId": self?.userId ?? "NA",
                                                            "\(method)Hash": result.hash,
                                                            "\(method)Date": Date()
                                                        ], completion: { (error) in
                                                            if let error = error {
                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                            } else {
                                                                /// send the push notification to the seller
                                                                guard let `self` = self else { return }
                                                                FirebaseService.shared.sendNotification(
                                                                    sender: self.userId,
                                                                    recipient: self.post.sellerUserId,
                                                                    content: "Your item has been purchased!",
                                                                    docID: self.post.documentId
                                                                ) { [weak self] (error) in
                                                                    if let error = error {
                                                                        print("error", error)
                                                                    }
                                                                    
                                                                    self?.alert.showDetail("Success!", with: "You have confirmed the purchase as buyer. Your ether will be locked until you confirm receiving the item.", alignment: .left, for: self, completion:  {
                                                                        self?.getStatus()
                                                                        self?.navigationController?.popViewController(animated: true)
                                                                    })
                                                                }
                                                            }
                                                        })
                                                    case .complete:
                                                        /// tag 3
                                                        /// confirmRecieved
                                                        FirebaseService.shared.db.collection("post").document(self!.post.documentId).updateData([
                                                            "status": status.rawValue,
                                                            "\(method)Hash": result.hash,
                                                            "\(method)Date": Date()
                                                        ], completion: { (error) in
                                                            if let error = error {
                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                            } else {
                                                                /// send the push notification to the seller
                                                                guard let `self` = self else { return }
                                                                FirebaseService.shared.sendNotification(
                                                                    sender: self.userId,
                                                                    recipient: self.post.sellerUserId,
                                                                    content: "Your item has been received by the buyer!",
                                                                    docID: self.post.documentId
                                                                ) { [weak self] (error) in
                                                                    if let error = error {
                                                                        print("error", error)
                                                                    }
                                                                    self?.alert.showDetail("Success!", with: "You have confirmed that you recieved the item. Your ether will be released back to your account.", alignment: .left, for: self, completion:  {
                                                                        DispatchQueue.main.async {
                                                                            self?.tableViewRefreshDelegate?.didRefreshTableView(index: 2)
                                                                            self?.navigationController?.popViewController(animated: true)
                                                                        }
                                                                    })
                                                                }
                                                            }
                                                        })
                                                    case .aborted:
                                                        FirebaseService.shared.db.collection("post").document(self!.post.documentId).delete() { err in
                                                            if let err = err {
                                                                self?.alert.showDetail("Error", with: err.localizedDescription, for: self)
                                                            } else {
                                                                // deindex from Core Spotlight (CoreSpotlightDelegate)
                                                                if let identifier = self?.post.id {
                                                                    self?.deindexSpotlight(identifier: identifier)
                                                                }
                                                                
                                                                self?.alert.showDetail("Success!", with: "You have aborted the escrow. The deployed contract is now locked and your ether will be sent back to your account.", for: self, completion:  {
                                                                    DispatchQueue.main.async {
                                                                        self?.tableViewRefreshDelegate?.didRefreshTableView(index: 3)
                                                                        self?.navigationController?.popViewController(animated: true)
                                                                    }
                                                                })
                                                            }
                                                        }
                                                    default:
                                                        break
                                                }
                                            }
                                        } catch Web3Error.nodeError(let desc) {
                                            if let index = desc.firstIndex(of: ":") {
                                                let newIndex = desc.index(after: index)
                                                let newStr = desc[newIndex...]
                                                DispatchQueue.main.async {
                                                    self?.alert.showDetail("Alert", with: String(newStr), for: self)
                                                }
                                            }
                                        } catch Web3Error.transactionSerializationError {
                                            DispatchQueue.main.async {
                                                self?.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
                                            }
                                        } catch Web3Error.connectionError {
                                            DispatchQueue.main.async {
                                                self?.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
                                            }
                                        } catch Web3Error.dataError {
                                            DispatchQueue.main.async {
                                                self?.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
                                            }
                                        } catch Web3Error.inputError(_) {
                                            DispatchQueue.main.async {
                                                self?.alert.showDetail("Alert", with: "Failed to sign the transaction. You may be using an incorrect password. \n\nOtherwise, please try logging out of your wallet (not the NFTrack account) and logging back in. Ensure that you remember the password and the private key.", height: 400, alignment: .left, for: self)
                                            }
                                        } catch Web3Error.processingError(let desc) {
                                            DispatchQueue.main.async {
                                                self?.alert.showDetail("Alert", with: desc, height: 320, for: self)
                                            }
                                        } catch {
                                            if let index = error.localizedDescription.firstIndex(of: "(") {
                                                let newStr = error.localizedDescription.prefix(upTo: index)
                                                self?.alert.showDetail("Alert", with: String(newStr), for: self)
                                            }
                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                        }
                                    }
                                }
                            })
                        } // mainVC button action
                    } // alertVC
                    self?.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
}

extension ListDetailViewController {
    final func transferToken(post: Post) {
        let content = [
            StandardAlertContent(
                index: 0,
                titleString: "Password",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 50,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                index: 1,
                titleString: "Transaction Options",
                body: [
                    AlertModalDictionary.gasLimit: "",
                    AlertModalDictionary.gasPrice: "",
                    AlertModalDictionary.nonce: ""
                ],
                isEditable: true,
                fieldViewHeight: 50,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        var documentRetainer: DocumentSnapshot!
        
        let alertVC = AlertViewController(height: 400, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            // responses to the main vc's button
            mainVC.buttonAction = { _ in
                guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                      !password.isEmpty else {
                    self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                    return
                }
                
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner({
                        Future<[AnyObject], PostingError> { promise in
                            let docRef = FirebaseService.shared.db.collection("post").document(post.documentId)
                            docRef.getDocument { (document, error) in
                                if let document = document,
                                   document.exists,
                                   let data = document.data() {
                                    
                                    documentRetainer = document
                                    var buyerHash: String!
                                    var tokenId: String!
                                    data.forEach { (item) in
                                        switch item.key {
                                            case "buyerHash":
                                                buyerHash = item.value as? String
                                            case "tokenId":
                                                tokenId = item.value as? String
                                            default:
                                                break
                                        }
                                    }
                                    
                                    guard let bh = buyerHash else {
                                        promise(.failure(.generalError(reason: "The item has not been purchased by a buyer yet.")))
                                        return
                                    }
                                    
                                    guard let ti = tokenId else {
                                        promise(.failure(.generalError(reason: "The item does not have token ID registered. It may take up to 10 mins to process.")))
                                        return
                                    }
                                    
                                    guard let fromAddress = Web3swiftService.currentAddress,
                                          let toAddress = EthereumAddress(bh) else {
                                        promise(.failure(.generalError(reason: "Could not get the contract address to transfer the token.")))
                                        return
                                    }
                                    
                                    let param: [AnyObject] = [fromAddress, toAddress, ti] as [AnyObject]
                                    promise(.success(param))
                                }
                            }
                        }
                        .eraseToAnyPublisher()
                        .flatMap { [weak self] (param) -> AnyPublisher<WriteTransaction, PostingError> in
                            guard let NFTrackAddress = NFTrackAddress else {
                                return Fail(error: PostingError.generalError(reason: "Unable to load the contract address."))
                                    .eraseToAnyPublisher()
                            }
                            return Future<WriteTransaction, PostingError> { promise in
                                self?.transactionService.prepareTransactionForWriting(
                                    method: "transferFrom",
                                    abi: NFTrackABI,
                                    param: param,
                                    contractAddress: NFTrackAddress,
                                    promise: promise)
                            }
                            .eraseToAnyPublisher()
                        }
                        .flatMap { (transaction) -> AnyPublisher<TransactionSendingResult, PostingError> in
                            Future<TransactionSendingResult, PostingError> { promise in
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
                        .flatMap { (result) -> AnyPublisher<Bool, PostingError> in
                            Future<Bool, PostingError> { promise in
                                FirebaseService.shared.db
                                    .collection("post")
                                    .document(documentRetainer.documentID)
                                    .updateData([
                                        "transferHash": result.hash,
                                        "transferDate": Date(),
                                        "status": PostStatus.transferred.rawValue
                                    ], completion: { (error: Error?) in
                                            if let error = error {
                                                promise(.failure(.generalError(reason: error.localizedDescription)))
                                            } else {
                                                /// send the push notification to the seller
                                                guard let `self` = self, let buyerUserId = self.post.buyerUserId else {
                                                    return promise(.failure(.generalError(reason: "Unable to get the buyer's hash.")))
                                                }
                                                
                                                FirebaseService.shared.sendNotification(
                                                    sender: self.userId,
                                                    recipient: buyerUserId,
                                                    content: "The seller has transferred the item!",
                                                    docID: self.post.documentId
                                                ) { (error) in
                                                    if let error = error {
                                                        print("notification error", error.localizedDescription)
                                                    }
                                                    
                                                    promise(.success(true))
                                                }
                                            }
                                        })
                                    }
                                    .eraseToAnyPublisher()
                                }
                                .sink { [weak self] (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            switch error {
                                                case .generalError(reason: let reason):
                                                    self?.alert.showDetail("Error", with: reason, for: self)
                                                case .emptyAmount:
                                                    self?.alert.showDetail("Error", with: "The amount cannot be empty.", for: self)
                                                case .invalidAmountFormat:
                                                    self?.alert.showDetail("Error", with: "Invalid amount format.", for: self)
                                                case .contractLoadingError:
                                                    self?.alert.showDetail("Error", with: "Unable to load the contract.", for: self)
                                                case .createTransactionIssue:
                                                    self?.alert.showDetail("Error", with: "Unable to create a transaction.", for: self)
                                                default:
                                                    self?.alert.showDetail("Error", with: "There was an error transferring the item.", for: self)
                                            }
                                            break
                                        case .finished:
                                            self?.hideSpinner({
                                                
                                            })
                                            break
                                    }
                                } receiveValue: { (isFinished) in
                                    DispatchQueue.main.async {
                                        self?.tableViewRefreshDelegate?.didRefreshTableView(index: 1)
                                        self?.navigationController?.popViewController(animated: true)
                                    }
                                }
                                .store(in: &self!.storage)
                    })
                })
            }
        }
        self.present(alertVC, animated: true, completion: nil)
    }
}
