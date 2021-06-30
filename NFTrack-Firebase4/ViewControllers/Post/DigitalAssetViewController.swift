//
//  TangibleAssetViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-28.
//

import UIKit
import web3swift
import CryptoKit

class DigitalAssetViewController: ParentPostViewController {
    lazy var idContainerViewHeightConstraint: NSLayoutConstraint = idContainerView.heightAnchor.constraint(equalToConstant: 50)
    lazy var idTitleLabelHeightConstraint: NSLayoutConstraint = idTitleLabel.heightAnchor.constraint(equalToConstant: 50)
    override var previewDataArr: [PreviewData]! {
        didSet {
            if previewDataArr.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.idTitleLabelHeightConstraint.constant = 50
                    self?.idContainerViewHeightConstraint.constant = 50
                    self?.idTitleLabel.isHidden = false
                    self?.idContainerView.isHidden = false
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.idTitleLabel.isHidden = true
                    self?.idTitleLabelHeightConstraint.constant = 0
                    
                    self?.idContainerView.isHidden = true
                    self?.idContainerViewHeightConstraint.constant = 0
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    }
                }
            }
        }
    }
    
    override var panelButtons: [PanelButton] {
        let buttonPanels = [
            PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
            PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
        ]
        return buttonPanels
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerLabel.text = "Digital"
        pickerLabel.isUserInteractionEnabled = false
    }

    override func createIDField() {
        idContainerView = UIView()
        idContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idContainerView)
        
        idTextField = createTextField(delegate: self)
        idTextField.autocapitalizationType = .none
        idTextField.isUserInteractionEnabled = false
        idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
        idContainerView.addSubview(idTextField)
    }
    
    override func setIDFieldConstraints() {
        constraints.append(contentsOf: [
            idTitleLabel.topAnchor.constraint(equalTo: tagContainerView.bottomAnchor, constant: 20),
            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTitleLabelHeightConstraint,
            
            idContainerView.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
            idContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idContainerViewHeightConstraint,
            
            idTextField.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: 1),
            idTextField.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    override func configureImagePreview() {
        configureImagePreview(postType: .digital)
    }
    
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        super.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        
        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        if let imageData = originalImage.pngData() {
            let hashedImage = SHA256.hash(data: imageData)
            let imageHash = hashedImage.description
            if let index = imageHash.firstIndex(of: ":") {
                let newIndex = imageHash.index(after: index)
                let newStr = imageHash[newIndex...]
                idTextField.text = newStr.description
            }
        }
    }
    
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
                    
                    for token in self!.tagTextField.tokens {
                        if let retrievedToken = token.representedObject as? String {
                            tokensArr.insert(retrievedToken.lowercased())
                        }
                    }
                    
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
                            DispatchQueue.main.async {
                                let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
                                detailVC.titleString = "Enter your password"
                                detailVC.buttonAction = { vc in
                                    if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                                        self?.dismiss(animated: true, completion: {
                                            self?.progressModal = ProgressModalViewController(height:  300, postType: .digital)
                                            self?.progressModal.titleString = "Posting In Progress"
                                            self?.present(self!.progressModal, animated: true, completion: {
                                                do {
                                                    let mintResult = try mintTransaction.send(password: password, transactionOptions: nil)
                                                    print("mintResult", mintResult)
                                                    
                                                    // firebase
                                                    let senderAddress = mintResult.transaction.sender!.address
                                                    let ref = self!.db.collection("post")
                                                    let id = ref.document().documentID
                                                    
                                                    // for deleting photos afterwards
                                                    self?.documentId = id
                                                    
                                                    // txHash is either minting or transferring the ownership
                                                    self?.db.collection("post").document(id).setData([
                                                        "sellerUserId": userId,
                                                        "senderAddress": senderAddress,
                                                        "escrowHash": "N/A",
                                                        "mintHash": mintResult.hash,
                                                        "date": Date(),
                                                        "title": title,
                                                        "description": desc,
                                                        "price": price,
                                                        "category": category,
                                                        "status": PostStatus.ready.rawValue,
                                                        "tags": Array(tokensArr),
                                                        "itemIdentifier": convertedId,
                                                        "isReviewed": false,
                                                        "type": "digital"
                                                    ]) { (error) in
                                                        if let error = error {
                                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
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
                                            })
                                        })
                                    }
                                }
                                self?.present(detailVC, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
}
