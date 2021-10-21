//
//  ResaleViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-01.
//

import UIKit

class ResaleViewController: NewPostViewController {
    override func initialConfig() {
        if let post = post, post.type == "tangible" {
            addBaseViewController(postVC)
        } else {
            addBaseViewController(digitalVC)
        }
    }
    
    /// Adds a child view controller to the container.
    override func addBaseViewController<T: ParentPostViewController>(_ viewController: T) {
        // Value to be passed from ListDetailVC during resale
        // The non-nil post indicates that this is a resale not a brand new sale
        super.addBaseViewController(viewController)
    }
}








//
//extension ResaleViewController {
//    override func configureUI() {
//        super.configureUI()
//        
//        closeButtonContainer = UIView()
//        closeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(closeButtonContainer)
//        
//        let closeImage = UIImage(systemName: "multiply")!.withTintColor(.gray, renderingMode: .alwaysOriginal)
//        closeButton = UIButton.systemButton(with: closeImage, target: self, action: #selector(buttonHandler(_:)))
//        closeButton.translatesAutoresizingMaskIntoConstraints = false
//        closeButtonContainer.addSubview(closeButton)
//        
//        idTextField.text = post.id
//        idTextField.isEnabled = false
//    }
//    
//    override func setConstraints() {
//        super.setConstraints()
//        
//        NSLayoutConstraint.activate([
//            closeButtonContainer.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 15),
//            closeButtonContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
//            closeButtonContainer.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            closeButtonContainer.heightAnchor.constraint(equalToConstant: 50),
//            
//            closeButton.topAnchor.constraint(equalTo: closeButtonContainer.topAnchor, constant: 0),
//            closeButton.trailingAnchor.constraint(equalTo: closeButtonContainer.trailingAnchor, constant: 0)
//        ])
//    }
//
//    @objc func buttonHandler(_ sender: UIButton!) {
//        self.dismiss(animated: true, completion: nil)
//    }
//}
//
//extension ResaleViewController {
//    override func mint() {
//        super.mint()
//        if let userId = self.userDefaults.string(forKey: "userId") {
//            self.userId = userId
//            // create purchase contract
//            guard let price = self.priceTextField.text,
//                  !price.isEmpty,
//                  let title = self.titleTextField.text,
//                  !title.isEmpty,
//                  let desc = self.descTextView.text,
//                  !desc.isEmpty,
//                  let category = self.pickerLabel.text,
//                  !category.isEmpty,
//                  self.tagTextField.tokens.count > 0,
//                  let id = self.idTextField.text,
//                  !id.isEmpty else {
//                self.alert.showDetail("Incomplete", with: "All fields must be filled.", for: self)
//                return
//            }
//            
//            guard self.tagTextField.tokens.count < 6 else {
//                self.alert.showDetail("Tag Limit", with: "You can input up to 5 tags.", for: self)
//                return
//            }
//            
//            // process id
//            let whitespaceCharacterSet = CharacterSet.whitespaces
//            let convertedId = id.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
//            
//            // add both the tokens and the title to the tokens field
//            var tokensArr = Set<String>()
//            let strippedString = title.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
//            let searchItems = strippedString.components(separatedBy: " ") as [String]
//            searchItems.forEach { (item) in
//                tokensArr.insert(item)
//            }
//            //                tokensArr.append(contentsOf: searchItems)
//            
//            for token in self.tagTextField.tokens {
//                if let retrievedToken = token.representedObject as? String {
//                    tokensArr.insert(retrievedToken.lowercased())
//                    //                        tokensArr.append(retrievedToken.lowercased())
//                }
//            }
//            
//            self.transactionService.prepareTransactionForNewContract(value: String(price), completion: { [weak self] (transaction, error) in
//                if let error = error {
//                    switch error {
//                        case .contractLoadingError:
//                            self?.alert.showDetail("Error", with: "Contract Loading Error", for: self)
//                        case .createTransactionIssue:
//                            self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self)
//                        default:
//                            self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
//                    }
//                }
//                
//                if let transaction = transaction {
//                    let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
//                    detailVC.titleString = "Enter your password"
//                    detailVC.buttonAction = { vc in
//                        if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
//                            self?.dismiss(animated: true, completion: {
//                                self?.showSpinner {
//                                    DispatchQueue.global().async {
//                                        do {
//                                            // create new contract
//                                            let result = try transaction.send(password: password, transactionOptions: nil)
//                                            // minting
//                                            self?.transactionService.prepareTransactionForMinting { [self] (mintTransaction, mintError) in
//                                                if let error = mintError {
//                                                    switch error {
//                                                        case .contractLoadingError:
//                                                            self?.alert.showDetail("Error", with: "Contract Loading Error", for: self)
//                                                        case .createTransactionIssue:
//                                                            self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self)
//                                                        default:
//                                                            self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
//                                                    }
//                                                }
//                                                
//                                                if let mintTransaction = mintTransaction {
//                                                    do {
//                                                        let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
//                                                        print("mintResult", mintResult)
//                                                        
//                                                        // firebase
//                                                        let senderAddress = result.transaction.sender!.address
//                                                        let postId = UUID().uuidString
//                                                        let ref = FirebaseService.shared.db.collection("mint")
//                                                        let id = ref.document().documentID
//                                                        
//                                                        // for deleting photos afterwards
//                                                        self?.documentId = id
//                                                        
//                                                        // txHash is either minting or transferring the ownership
//                                                        FirebaseService.shared.db.collection("post").document(id).setData([
//                                                            "postId": postId,
//                                                            "sellerUserId": userId,
//                                                            "senderAddress": senderAddress,
//                                                            "escrowHash": result.hash,
//                                                            "mintHash": mintResult.hash,
//                                                            "date": Date(),
//                                                            "title": title,
//                                                            "description": desc,
//                                                            "price": price,
//                                                            "category": category,
//                                                            "status": PostStatus.ready.rawValue,
//                                                            "tags": Array(tokensArr),
//                                                            "itemIdentifier": convertedId,
//                                                            "isReviewed": false
//                                                        ]) { (error) in
//                                                            if let error = error {
//                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self) {
//                                                                    for image in self!.imageNameArr {
//                                                                        self?.deleteFile(fileName: image)
//                                                                    }
//                                                                }
//                                                            } else {
//                                                                self?.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c", id: id)
//                                                                self?.socketDelegate.delegate = self
//                                                                
//                                                                // update the previous post to "resold" status
//                                                                FirebaseService.shared.db.collection("post").document(self!.post.documentId).updateData([
//                                                                    "status": PostStatus.resold.rawValue,
//                                                                ]) { (error) in
//                                                                    if let error = error {
//                                                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                                    }
//                                                                }
//                                                            }
//                                                        }
//                                                    } catch Web3Error.nodeError(let desc) {
//                                                        if let index = desc.firstIndex(of: ":") {
//                                                            let newIndex = desc.index(after: index)
//                                                            let newStr = desc[newIndex...]
//                                                            self?.alert.showDetail("Alert", with: String(newStr), for: self)
//                                                        }
//                                                    } catch {
//                                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self) {
//                                                            for image in self!.imageNameArr {
//                                                                self?.deleteFile(fileName: image)
//                                                            }
//                                                        }
//                                                    }
//                                                }
//                                            }
//                                        } catch Web3Error.nodeError(let desc) {
//                                            if let index = desc.firstIndex(of: ":") {
//                                                let newIndex = desc.index(after: index)
//                                                let newStr = desc[newIndex...]
//                                                DispatchQueue.main.async {
//                                                    self?.alert.showDetail("Alert", with: String(newStr), for: self)
//                                                }
//                                            }
//                                        } catch {
//                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self) {
//                                                for image in self!.imageNameArr {
//                                                    self?.deleteFile(fileName: image)
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            })
//                        }
//                    }
//                    self?.present(detailVC, animated: true, completion: nil)
//                }
//            })
//        } else {
//            self.alert.showDetail("Authorization", with: "You need to be logged in!", for: self)
//        }
//    }
//}
//
//extension ResaleViewController {
//    override func didReceiveMessage(topics: [String]) {
//        super.didReceiveMessage(topics: topics)
//        self.socketDelegate.disconnectSocket()
//        self.dismiss(animated: true, completion: nil)
//        print("did receive")
//    }
//}
