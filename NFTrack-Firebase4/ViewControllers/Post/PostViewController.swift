//
//  PostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit
import web3swift
import FirebaseFirestore
import BigInt
import Combine

class PostViewController: ParentPostViewController {
    final override var panelButtons: [PanelButton] {
        let buttonPanels = [
            PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
            PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
            PanelButton(imageName: "doc.circle", imageConfig: configuration, tintColor: UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), tag: 10)
        ]
        return buttonPanels
    }
    
    var deliveryMethodObserver: NSKeyValueObservation?
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        deliveryMethodObserver = deliveryMethodLabel.observe(\.text) { [weak self] (label, observedChange) in
            guard let text = label.text, let deliveryMethod = DeliveryMethod(rawValue: text) else { return }
            switch deliveryMethod {
                case .inPerson:
                    self?.paymentMethodLabel.text = PaymentMethod.directTransfer.rawValue
                case .shipping:
                    self?.paymentMethodLabel.text = PaymentMethod.escrow.rawValue
            }
        }
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if deliveryMethodObserver != nil {
            deliveryMethodObserver?.invalidate()
        }
    }
    
    var storage = Set<AnyCancellable>()
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        deliveryInfoButton.tag = 20
        deliveryMethodLabel.isUserInteractionEnabled = true
        deliveryMethodLabel.tag = 1
        
        paymentInfoButton.tag = 21
        
        saleMethodInfoButton.tag = 22
        saleMethodLabel.text = "Online Direct"
        
        pickerLabel.isUserInteractionEnabled = true
        pickerLabel.tag = 2
    }
    
    final override func createIDField() {
        idContainerView = UIView()
        idContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idContainerView)
        
        idTextField = createTextField(delegate: self)
        idTextField.autocapitalizationType = .none
        idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
        idContainerView.addSubview(idTextField)
        
        guard let scanImage = UIImage(systemName: "qrcode.viewfinder") else { return }
        scanButton = UIButton.systemButton(with: scanImage.withTintColor(.black, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonPressed))
        scanButton.layer.cornerRadius = 5
        scanButton.layer.borderWidth = 0.7
        scanButton.layer.borderColor = UIColor.lightGray.cgColor
        scanButton.tag = 7
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        idContainerView.addSubview(scanButton)
    }
    
    final override func setIDFieldConstraints() {
        constraints.append(contentsOf: [
            idTitleLabel.topAnchor.constraint(equalTo: tagContainerView.bottomAnchor, constant: 20),
            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            idContainerView.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
            idContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idContainerView.heightAnchor.constraint(equalToConstant: 50),
            idContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            idTextField.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: 0.75),
            idTextField.heightAnchor.constraint(equalToConstant: 50),
            idTextField.leadingAnchor.constraint(equalTo: idContainerView.leadingAnchor),
            
            scanButton.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: 0.2),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.trailingAnchor.constraint(equalTo: idContainerView.trailingAnchor),
        ])
    }
    
    final override func configureImagePreview() {
        configureImagePreview(postType: .tangible)
    }
    
    final override func buttonPressed(_ sender: UIButton) {
        super.buttonPressed(sender)
        
        switch sender.tag {
            case 20:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Delivery Method", detail: InfoText.deliveryMethod)])
                self.present(infoVC, animated: true, completion: nil)
            case 21:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Escrow", detail: InfoText.escrow), InfoModel(title: "Direct Transfer", detail: InfoText.directTransfer)])
                self.present(infoVC, animated: true, completion: nil)
            case 22:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Sale Format", detail: InfoText.onlineDirect)])
                self.present(infoVC, animated: true, completion: nil)
            default:
                break
        }
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
    
    final override func processMint(price: String?, itemTitle: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
        
        guard let price = price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        // escrow deployment
        self.transactionService.prepareTransactionForNewContract(contractABI: purchaseABI2, bytecode: purchaseBytecode2, value: String(price), completion: { [weak self] (transaction, error) in
            guard let `self` = self else { return }
            if let error = error {
                switch error {
                    case .invalidAmountFormat:
                        self.alert.showDetail("Error", with: "The price is in a wrong format", for: self)
                    case .contractLoadingError:
                        self.alert.showDetail("Error", with: "Escrow Contract Loading Error", for: self)
                    case .createTransactionIssue:
                        self.alert.showDetail("Error", with: "Escrow Contract Transaction Issue", for: self)
                    case .retrievingEstimatedGasError:
                        self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
                    case .retrievingCurrentAddressError:
                        self.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
                    default:
                        self.alert.showDetail("Error", with: "There was an error deploying your escrow contract.", for: self)
                }
            }
            
            // minting
            self.transactionService.prepareTransactionForMinting { (mintTransaction, mintError) in
                if let error = mintError {
                    switch error {
                        case .contractLoadingError:
                            self.alert.showDetail("Error", with: "Minting Contract Loading Error", for: self)
                        case .createTransactionIssue:
                            self.alert.showDetail("Error", with: "Minting Contract Transaction Issue", for: self)
                        case .retrievingEstimatedGasError:
                            self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
                        default:
                            self.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
                    }
                }
                
//                /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
//                let localDatabase = LocalDatabase()
//                guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
//                    self.alert.showDetail("Sorry", with: "There was an error retrieving your wallet.", for: self)
//                    return
//                }
//
//                var balanceResult: BigUInt!
//                do {
//                    balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
//                } catch {
//                    self.alert.showDetail("Sorry", with: "An error retrieving the balance of your wallet.", for: self)
//                    return
//                }
//
//                guard let currentGasPrice = try? Web3swiftService.web3instance.eth.getGasPrice() else {
//                    self.alert.showDetail("Sorry", with: "An error retreiving the current gas price.", for: self)
//                    return
//                }
//
//                guard let estimatedGasForMinting = estimatedGasForMinting,
//                      let estimatedGasForDeploying = estimatedGasForDeploying,
//                      let priceInWei = Web3.Utils.parseToBigUInt(String(price), units: .eth),
//                      ((estimatedGasForMinting + estimatedGasForDeploying) * currentGasPrice + priceInWei) < balanceResult else {
//                    self.alert.showDetail("Sorry", with: "Insufficient funds in your wallet to cover both the gas fee and the deposit for the escrow.", height: 300, for: self)
//                    return
//                }
                
                // escrow deployment transaction
                if let transaction = transaction {
                    self.hideSpinner {}
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
                            titleString: "Details",
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
                    
                    DispatchQueue.main.async {
                        let alertVC = AlertViewController(height: 400, standardAlertContent: content)
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
                                    self.progressModal = ProgressModalViewController(postType: .tangible)
                                    self.progressModal.titleString = "Posting In Progress"
                                    self.present(self.progressModal, animated: true, completion: {
                                        DispatchQueue.global(qos: .userInitiated).async {
                                            do {
                                                // create new contract
                                                let result = try transaction.send(password: password, transactionOptions: nil)
                                                print("deployment result", result)
                                                let update: [String: PostProgress] = ["update": .deployingEscrow]
                                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                                
                                                // mint transaction
                                                if let mintTransaction = mintTransaction {
                                                    do {
                                                        let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
                                                        print("mintResult", mintResult)
                                                        
                                                        // firebase
                                                        let senderAddress = result.transaction.sender!.address
                                                        let ref = self.db.collection("post")
                                                        let id = ref.document().documentID
                                                        
                                                        // for deleting photos afterwards
                                                        self.documentId = id
                                                        
                                                        // txHash is either minting or transferring the ownership
                                                        self.db.collection("post").document(id).setData([
                                                            "sellerUserId": userId,
                                                            "senderAddress": senderAddress,
                                                            "escrowHash": result.hash,
                                                            "mintHash": mintResult.hash,
                                                            "date": Date(),
                                                            "title": itemTitle,
                                                            "description": desc,
                                                            "price": price,
                                                            "category": category,
                                                            "status": PostStatus.ready.rawValue,
                                                            "tags": Array(tokensArr),
                                                            "itemIdentifier": convertedId,
                                                            "isReviewed": false,
                                                            "type": "digital",
                                                            "deliveryMethod": deliveryMethod,
                                                            "saleFormat": saleFormat,
                                                            "paymentMethod": paymentMethod
                                                        ]) { (error) in
                                                            if let error = error {
                                                                self.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                            } else {
                                                                /// no need for a socket if you don't have images to upload?
                                                                /// show the success alert here
                                                                /// apply the same for resell
                                                                //                                                                    self.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c")
                                                                //                                                                    self.socketDelegate.delegate = self
                                                            }
                                                        }
                                                    } catch Web3Error.nodeError(let desc) {
                                                        if let index = desc.firstIndex(of: ":") {
                                                            let newIndex = desc.index(after: index)
                                                            let newStr = desc[newIndex...]
                                                            DispatchQueue.main.async {
                                                                self.alert.showDetail("Alert", with: String(newStr), for: self)
                                                            }
                                                        }
                                                    } catch Web3Error.transactionSerializationError {
                                                        DispatchQueue.main.async {
                                                            self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
                                                        }
                                                    } catch Web3Error.connectionError {
                                                        DispatchQueue.main.async {
                                                            self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
                                                        }
                                                    } catch Web3Error.dataError {
                                                        DispatchQueue.main.async {
                                                            self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
                                                        }
                                                    } catch Web3Error.inputError(_) {
                                                        DispatchQueue.main.async {
                                                            self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
                                                        }
                                                    } catch Web3Error.processingError(let desc) {
                                                        DispatchQueue.main.async {
                                                            self.alert.showDetail("Alert", with: desc, height: 320, for: self)
                                                        }
                                                    } catch {
                                                        self.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                    }
                                                }
                                                
                                            } catch Web3Error.nodeError(let desc) {
                                                if let index = desc.firstIndex(of: ":") {
                                                    let newIndex = desc.index(after: index)
                                                    let newStr = desc[newIndex...]
                                                    DispatchQueue.main.async {
                                                        self.alert.showDetail("Alert", with: String(newStr), for: self)
                                                    }
                                                }
                                            } catch Web3Error.transactionSerializationError {
                                                DispatchQueue.main.async {
                                                    self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
                                                }
                                            } catch Web3Error.connectionError {
                                                DispatchQueue.main.async {
                                                    self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
                                                }
                                            } catch Web3Error.dataError {
                                                DispatchQueue.main.async {
                                                    self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
                                                }
                                            } catch Web3Error.inputError(_) {
                                                DispatchQueue.main.async {
                                                    self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
                                                }
                                            } catch Web3Error.processingError(let desc) {
                                                DispatchQueue.main.async {
                                                    self.alert.showDetail("Alert", with: desc, height: 320, for: self)
                                                }
                                            } catch {
                                                self.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                            }
                                        } // DispatchQueue.global background
                                    }) // end of self.present completion for ProgressModalVC
                                }) // end of self.dismiss completion
                            } // mainVC
                        } // alertVC
                        self.present(alertVC, animated: true, completion: nil)
                    }
                } // transaction
            } // end of prepareTransactionForMinting
        }) // end of prepareTransactionForNewContract
    }
}

//extension PostViewController {
//    final override func didReceiveMessage(topics: [String]) {
//        super.didReceiveMessage(topics: topics)
//        self.socketDelegate.disconnectSocket()
//        print("did receive")
//    }
//}

extension PostViewController {
    override var inputView: UIView? {
        switch pickerTag {
            case 1:
                return self.deliveryMethodPicker.inputView
            case 2:
                return self.pvc.inputView
            default:
                return nil
        }
    }
    
    @objc func doDone() { // user tapped button in accessory view
        switch pickerTag {
            case 1:
                self.deliveryMethodLabel.text = deliveryMethodPicker.currentPep
            case 2:
                self.pickerLabel.text = pvc.currentPep
            default:
                break
        }
        self.resignFirstResponder()
        self.showKeyboard = false
    }
}
