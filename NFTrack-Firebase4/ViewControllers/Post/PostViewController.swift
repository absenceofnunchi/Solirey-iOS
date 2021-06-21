//
//  PostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit
import web3swift
import FirebaseFirestore

enum PostProgress: Int, CaseIterable {
    case deployingEscrow
    case minting
    case images
    
    func asString() -> String {
        switch self {
            case .deployingEscrow:
                return "Deploying the escrow contract"
            case .minting:
                return "Minting your item on the blockchain"
            case .images:
                return "Checking for images to upload"
        }
    }
}

class PostViewController: ParentPostViewController {
    func mint1() {
        super.mint()
        let progressModal = ProgressModalViewController()
        progressModal.titleString = "Posting In Progress"
        self.present(progressModal, animated: true, completion: {
            self.alert.showDetail("Test", with: "yesss", for: self)
        })
        
//
//        delay(2) {
//            let update: [String: PostProgress] = ["update": .deployingEscrow]
//            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//        }
//
//        delay(4) {
//            let update: [String: PostProgress] = ["update": .minting]
//            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//        }
//
//        delay(6) {
//            let update: [String: PostProgress] = ["update": .images]
//            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//        }
    }
    
    // MARK: - mint
    /// 1. check for existing ID
    /// 2. deploy the escrow contract
    /// 3. mint
    /// 4. upload to the firestore
    /// 5. get the token ID through the subscription to the google functions
    /// 6. update the token ID on firestore
    /// 7. store the photos in the local storage and upload the images to the firebase storage
    /// 8. update the firestore with the urls of the photos
    /// 9. delete the photos from the local storage
     override func mint() {
        if let userId = self.userDefaults.string(forKey: UserDefaultKeys.userId) {
            self.userId = userId
            // create purchase contract
            guard let price = self.priceTextField.text,
                  !price.isEmpty,
                  let title = self.titleTextField.text,
                  !title.isEmpty,
                  let desc = self.descTextView.text,
                  !desc.isEmpty,
                  let category = self.pickerLabel.text,
                  !category.isEmpty,
                  self.tagTextField.tokens.count > 0,
                  let id = self.idTextField.text,
                  !id.isEmpty else {
                self.alert.showDetail("Incomplete", with: "All fields must be filled.", for: self)
                return
            }
            
            guard self.tagTextField.tokens.count < 6 else {
                self.alert.showDetail("Tag Limit", with: "You can input up to 5 tags.", for: self)
                return
            }
            
            // process id
            let whitespaceCharacterSet = CharacterSet.whitespaces
            let convertedId = id.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
            
            self.checkExistingId(id: convertedId) { [weak self](isDuplicate) in
                if isDuplicate {
                    self?.alert.showDetail("Duplicate", with: "The item has already been registered. Please transfer the ownership instead of re-posting it.", for: self)
                } else {
                    // add both the tokens and the title to the tokens field
                    var tokensArr = Set<String>()
                    let strippedString = title.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
                    let searchItems = strippedString.components(separatedBy: " ") as [String]
                    searchItems.forEach { (item) in
                        tokensArr.insert(item)
                    }
                    //                tokensArr.append(contentsOf: searchItems)
                    
                    for token in self!.tagTextField.tokens {
                        if let retrievedToken = token.representedObject as? String {
                            tokensArr.insert(retrievedToken.lowercased())
                            //                        tokensArr.append(retrievedToken.lowercased())
                        }
                    }
                    
                    self?.transactionService.prepareTransactionForNewContract(value: String(price), completion: { (transaction, error) in
                        if let error = error {
                            switch error {
                                case .contractLoadingError:
                                    self?.alert.showDetail("Error", with: "Contract Loading Error", for: self)
                                case .createTransactionIssue:
                                    self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self)
                                default:
                                    self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
                            }
                        }
                        
                        if let transaction = transaction {
                            let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
                            detailVC.titleString = "Enter your password"
                            detailVC.buttonAction = { vc in
                                if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                                    self?.dismiss(animated: true, completion: {
                                        let progressModal = ProgressModalViewController()
                                        progressModal.titleString = "Posting In Progress"
                                        self?.present(progressModal, animated: true, completion: {
                                            DispatchQueue.global().async {
                                                do {
                                                    // create new contract
                                                    let result = try transaction.send(password: password, transactionOptions: nil)
                                                    print("deployment result", result)
                                                    let update: [String: PostProgress] = ["update": .deployingEscrow]
                                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                                    
                                                    // minting
                                                    self?.transactionService.prepareTransactionForMinting { (mintTransaction, mintError) in
                                                        if let error = mintError {
                                                            switch error {
                                                                case .contractLoadingError:
                                                                    self?.alert.showDetail("Error", with: "Contract Loading Error", for: self)
                                                                case .createTransactionIssue:
                                                                    self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self)
                                                                default:
                                                                    self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
                                                            }
                                                        }
                                                        
                                                        if let mintTransaction = mintTransaction {
                                                            do {
                                                                let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
                                                                print("mintResult", mintResult)
                                                                let update: [String: PostProgress] = ["update": .minting]
                                                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                                                
                                                                // firebase
                                                                let senderAddress = result.transaction.sender!.address
                                                                let ref = FirebaseService.shared.db.collection("post")
                                                                let id = ref.document().documentID
                                                                
                                                                // for deleting photos afterwards
                                                                self?.documentId = id
                                                                
                                                                // txHash is either minting or transferring the ownership
                                                                FirebaseService.shared.db.collection("post").document(id).setData([
                                                                    "sellerUserId": userId,
                                                                    "senderAddress": senderAddress,
                                                                    "escrowHash": result.hash,
                                                                    "mintHash": mintResult.hash,
                                                                    "date": Date(),
                                                                    "title": title,
                                                                    "description": desc,
                                                                    "price": price,
                                                                    "category": category,
                                                                    "status": PostStatus.ready.rawValue,
                                                                    "tags": Array(tokensArr),
                                                                    "itemIdentifier": convertedId,
                                                                    "isReviewed": false
                                                                ]) { (error) in
                                                                    if let error = error {
                                                                        print("error4")
                                                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self) {
                                                                            for image in self!.imageNameArr {
                                                                                self?.deleteFile(fileName: image)
                                                                            }
                                                                        }
                                                                    } else {
                                                                        /// no need for a socket if you don't have images to upload?
                                                                        /// show the success alert here
                                                                        /// apply the same for resell
                                                                        self?.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c", id: id)
                                                                        self?.socketDelegate.delegate = self
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
                                                                    self?.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
                                                                }
                                                            } catch Web3Error.processingError(let desc) {
                                                                DispatchQueue.main.async {
                                                                    self?.alert.showDetail("Alert", with: desc, height: 320, for: self)
                                                                }
                                                            } catch {
                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                            }
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
                                                        self?.alert.showDetail("Alert", with: "Failed to locally sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
                                                    }
                                                } catch Web3Error.processingError(let desc) {
                                                    DispatchQueue.main.async {
                                                        self?.alert.showDetail("Alert", with: desc, height: 320, for: self)
                                                    }
                                                } catch {
                                                    self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                }
                                            }
                                        })
                                    })
                                }
                            }
                            self?.present(detailVC, animated: true, completion: nil)
                        }
                    })
                }
            }
        } else {
            self.alert.showDetail("Authorization", with: "You need to be logged in!", for: self)
        }
    }
}

extension PostViewController {
    override func didReceiveMessage(topics: [String]) {
        super.didReceiveMessage(topics: topics)
        self.socketDelegate.disconnectSocket()
        print("did receive")
    }
}
