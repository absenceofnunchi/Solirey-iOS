//
//  TangibleAssetViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-28.
//

import UIKit
import web3swift
import CryptoKit
import BigInt

enum SaleFormat: String {
    case onlineDirect = "Online Direct"
    case openAuction = "Open Auction"
}

class DigitalAssetViewController: ParentPostViewController {
    lazy var idContainerViewHeightConstraint: NSLayoutConstraint = idContainerView.heightAnchor.constraint(equalToConstant: 50)
    lazy var idTitleLabelHeightConstraint: NSLayoutConstraint = idTitleLabel.heightAnchor.constraint(equalToConstant: 50)
    
    var auctionDurationTitleLabel: UILabel!
    var auctionDurationLabel: UILabel!
    var auctionStartingPriceTitleLabel: UILabel!
    var auctionStartingPriceTextField: UITextField!
    /// for auction duration
    let auctionDurationPicker = MyPickerVC(currentPep: "3", pep: Array(3...20).map { String($0) })
    /// sale format for digital
    let saleFormatPicker = MyPickerVC(currentPep: SaleFormat.onlineDirect.rawValue, pep: [SaleFormat.onlineDirect.rawValue, SaleFormat.openAuction.rawValue])
    let AUCTION_FIELDS_HEIGHT: CGFloat = 200
    
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
    
    var saleFormatObserver: NSKeyValueObservation?
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        saleFormatObserver = saleMethodLabel.observe(\.text) { [weak self] (label, observedChange) in
            guard let text = label.text, let saleFormat = SaleFormat(rawValue: text) else { return }
            switch saleFormat {
                case .onlineDirect:
                    self?.paymentMethodLabel.text = PaymentMethod.escrow.rawValue
                    self?.auctionDurationLabel.isUserInteractionEnabled = false
                    
                    /// hide the auction duration and the starting price labels when the sale format is selected to open auction
                    DispatchQueue.main.async { [weak self] in
                        self?.saleMethodContainerConstraintHeight.constant = 50
                        self?.auctionDurationTitleLabel.alpha = 0
                        self?.auctionDurationLabel.alpha = 0
                        
                        self?.auctionStartingPriceTitleLabel.alpha = 0
                        self?.auctionStartingPriceTextField.alpha = 0
                        UIView.animate(withDuration: 0.5) {
                            self?.view.layoutIfNeeded()
                        }
                        
                        guard let `self` = self else { return }
                        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.scrollView.contentSize.height - self.AUCTION_FIELDS_HEIGHT)
                    }
                case .openAuction:
                    self?.paymentMethodLabel.text = PaymentMethod.auctionBeneficiary.rawValue
                    /// show the auction duration and the starting price labels when the sale format is selected to open auction
                    DispatchQueue.main.async { [weak self] in
                        self?.saleMethodContainerConstraintHeight.constant = 290
                        self?.auctionDurationLabel.isUserInteractionEnabled = true
                        
                        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {
                            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                                self?.view.layoutIfNeeded()
                            }
                            
                            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.3) {
                                self?.auctionDurationTitleLabel.alpha = 1
                                self?.auctionDurationLabel.alpha = 1
                                
                                self?.auctionStartingPriceTitleLabel.alpha = 1
                                self?.auctionStartingPriceTextField.alpha = 1
                            }
                        } completion: { (_) in
                            guard let `self` = self else { return }
                            self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.scrollView.contentSize.height + self.AUCTION_FIELDS_HEIGHT)
                        }
                    }
            }
        }
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if saleFormatObserver != nil {
            saleFormatObserver?.invalidate()
        }
    }

    override func configureUI() {
        super.configureUI()
        
        deliveryInfoButton.isHidden = true
        deliveryInfoButton.isEnabled = false
        deliveryMethodLabel.text = "Online Transfer"
        
        paymentInfoButton.tag = 21
        paymentMethodLabel.isUserInteractionEnabled = true
        paymentMethodLabel.tag = 50
        let paymentMethodTap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        paymentMethodLabel.addGestureRecognizer(paymentMethodTap)
        
        saleMethodInfoButton.tag = 23
        
        saleMethodLabel.isUserInteractionEnabled = true
        saleMethodLabel.tag = 3
        let saleMethodTap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
        saleMethodLabel.addGestureRecognizer(saleMethodTap)
        
        pickerLabel.text = "Digital"
        
        auctionDurationTitleLabel = createTitleLabel(text: "Auction Duration")
        auctionDurationTitleLabel.alpha = 0
        saleMethodLabelContainer.addSubview(auctionDurationTitleLabel)
        
        auctionDurationLabel = createLabel(text: "")
        auctionDurationLabel.alpha = 0
        /// for picker
        auctionDurationLabel.tag = 50
        auctionDurationLabel.textColor = .lightGray
        auctionDurationLabel.text = "Number of days"
        saleMethodLabelContainer.addSubview(auctionDurationLabel)
        
        let auctionDurationTap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy(_:)))
        auctionDurationLabel.addGestureRecognizer(auctionDurationTap)
        
        auctionStartingPriceTitleLabel = createTitleLabel(text: "Auction Starting Price")
        auctionStartingPriceTitleLabel.alpha = 0
        saleMethodLabelContainer.addSubview(auctionStartingPriceTitleLabel)
        
        auctionStartingPriceTextField = createTextField(placeHolder: "In ETH", content: nil, delegate: self)
        auctionStartingPriceTextField.keyboardType = .decimalPad
        auctionStartingPriceTextField.alpha = 0
        saleMethodLabelContainer.addSubview(auctionStartingPriceTextField)
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            auctionDurationTitleLabel.topAnchor.constraint(equalTo: saleMethodLabel.bottomAnchor, constant: 20),
            auctionDurationTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            auctionDurationTitleLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
            auctionDurationTitleLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
            
            auctionDurationLabel.topAnchor.constraint(equalTo: auctionDurationTitleLabel.bottomAnchor),
            auctionDurationLabel.heightAnchor.constraint(equalToConstant: 50),
            auctionDurationLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
            auctionDurationLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
            
            auctionStartingPriceTitleLabel.topAnchor.constraint(equalTo: auctionDurationLabel.bottomAnchor, constant: 20),
            auctionStartingPriceTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            auctionStartingPriceTitleLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
            auctionStartingPriceTitleLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
            
            auctionStartingPriceTextField.topAnchor.constraint(equalTo: auctionStartingPriceTitleLabel.bottomAnchor),
            auctionStartingPriceTextField.heightAnchor.constraint(equalToConstant: 50),
            auctionStartingPriceTextField.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
            auctionStartingPriceTextField.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
        ])
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
    
    final override func buttonPressed(_ sender: UIButton) {
        super.buttonPressed(sender)
        
        switch sender.tag {
            case 21:
                /// payment method info button
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Auction Beneficiary", detail: InfoText.auctionBeneficiary), InfoModel(title: "Escrow", detail: InfoText.escrow)])
                self.present(infoVC, animated: true, completion: nil)
            case 23:
                /// sale format info button
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Online Direct", detail: InfoText.onlineDigital), InfoModel(title: "Open Auction", detail: InfoText.auction)])
                self.present(infoVC, animated: true, completion: nil)
            default:
                break
        }
    }

    @objc final func tapped(_ sender: UITapGestureRecognizer) {
        /// payment method label
        let detailVC = DetailViewController(messageTextAlignment: .left)
        detailVC.titleString = "Payment Method"
        detailVC.message = "The payment method for digital items is determined by the sale format. Please select from the picker right below the payment method's field."
        detailVC.buttonAction = { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        self.present(detailVC, animated: true, completion: nil)
    }
    
    final override func processMint(price: String, title: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
        
        guard let sm = SaleFormat(rawValue: saleFormat) else { return }
        switch sm {
            case .onlineDirect:
                onlineDirect(price: price, title: title, desc: desc, category: category, convertedId: convertedId, tokensArr: tokensArr, userId: userId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod)
            case .openAuction:
                guard let auctionDuration = auctionDurationLabel.text,
                      !auctionDuration.isEmpty else {
                    self.alert.showDetail("Incomplete", with: "Please specify the auction duration.", for: self)
                    return
                }
                guard let auctionStartingPrice = auctionStartingPriceTextField.text,
                      !auctionStartingPrice.isEmpty else {
                    self.alert.showDetail("Incomplete", with: "Please specify the starting price for your auction.", for: self)
                    return
                }
                auction(price: price, title: title, desc: desc, category: category, convertedId: convertedId, tokensArr: tokensArr, userId: userId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod, auctionDuration: auctionDuration, auctionStartingPrice: auctionStartingPrice)
        }
    }
    
    final func onlineDirect(price: String, title: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
        // escrow deployment
        self.transactionService.prepareTransactionForNewContract(contractABI: purchaseABI2, value: String(price), completion: { (transaction, error, estimatedGasForDeploying) in
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
                    default:
                        self.alert.showDetail("Error", with: "There was an error deploying your escrow contract.", for: self)
                }
            }
            
            // minting
            self.transactionService.prepareTransactionForMinting { (mintTransaction, mintError, estimatedGasForMinting) in
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
                
                /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
                let localDatabase = LocalDatabase()
                guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
                    self.alert.showDetail("Sorry", with: "There was an error retrieving your wallet.", for: self)
                    return
                }
                
                var balanceResult: BigUInt!
                do {
                    balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
                } catch {
                    self.alert.showDetail("Sorry", with: "An error retrieving the balance of your wallet.", for: self)
                    return
                }
                
                guard let estimatedGasForMinting = estimatedGasForMinting,
                      let estimatedGasForDeploying = estimatedGasForDeploying,
                      let priceInWei = Web3.Utils.parseToBigUInt(String(price), units: .eth),
                      (estimatedGasForMinting + estimatedGasForDeploying + priceInWei) < balanceResult else {
                    self.alert.showDetail("Sorry", with: "Insufficient funds in your wallet to cover both the gas fee and the deposit for the escrow.", height: 300, for: self)
                    return
                }
                
                // escrow deployment transaction
                if let transaction = transaction {
                    self.hideSpinner {
                        DispatchQueue.main.async {
                            let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
                            detailVC.titleString = "Enter your password"
                            detailVC.buttonAction = { vc in
                                if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                                    self.dismiss(animated: true, completion: {
                                        self.progressModal = ProgressModalViewController(postType: .tangible)
                                        self.progressModal.titleString = "Posting In Progress"
                                        self.present(self.progressModal, animated: true, completion: {
                                            DispatchQueue.global(qos: .background).async {
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
                                                                "title": title,
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
                                                                    self.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c", id: id)
                                                                    self.socketDelegate.delegate = self
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
                                } // end of let password = dvc.textField.text
                            } // detailVC.buttonAction
                            self.present(detailVC, animated: true, completion: nil)
                        } // hide spinner
                    } // DispathQueue.main.asyc
                } // transaction
            } // end of prepareTransactionForMinting
        }) // end of prepareTransactionForNewContract
    }
    
    final func auction(price: String, title: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String, auctionDuration: String, auctionStartingPrice: String) {
        
        guard let numOfDays = Int(auctionDuration) else {
            self.alert.showDetail("Sorry", with: "Could not conver the audition duration into proper format. Please try again.", for: self)
            return
        }
        
        let biddingTime = numOfDays * 60 * 60 * 24
        
        // escrow deployment
        self.transactionService.prepareTransactionForNewContract(contractABI: auctionABI, value: String(price), parameters: [biddingTime] as [AnyObject], completion: { (transaction, error, estimatedGasForDeploying) in
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
                    default:
                        self.alert.showDetail("Error", with: "There was an error deploying your escrow contract.", for: self)
                }
            }
            
            // minting
            self.transactionService.prepareTransactionForMinting { (mintTransaction, mintError, estimatedGasForMinting) in
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
                
                /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
                let localDatabase = LocalDatabase()
                guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
                    self.alert.showDetail("Sorry", with: "There was an error retrieving your wallet.", for: self)
                    return
                }
                
                var balanceResult: BigUInt!
                do {
                    balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
                } catch {
                    self.alert.showDetail("Sorry", with: "An error retrieving the balance of your wallet.", for: self)
                    return
                }
                
                guard let estimatedGasForMinting = estimatedGasForMinting,
                      let estimatedGasForDeploying = estimatedGasForDeploying,
                      let priceInWei = Web3.Utils.parseToBigUInt(String(price), units: .eth),
                      (estimatedGasForMinting + estimatedGasForDeploying + priceInWei) < balanceResult else {
                    self.alert.showDetail("Sorry", with: "Insufficient funds in your wallet to cover both the gas fee and the deposit for the escrow.", height: 300, for: self)
                    return
                }
                
                // escrow deployment transaction
                if let transaction = transaction {
                    self.hideSpinner {
                        DispatchQueue.main.async {
                            let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
                            detailVC.titleString = "Enter your password"
                            detailVC.buttonAction = { vc in
                                if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                                    self.dismiss(animated: true, completion: {
                                        self.progressModal = ProgressModalViewController(postType: .tangible)
                                        self.progressModal.titleString = "Posting In Progress"
                                        self.present(self.progressModal, animated: true, completion: {
                                            DispatchQueue.global(qos: .background).async {
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
                                                                "title": title,
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
                                                                    self.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c", id: id)
                                                                    self.socketDelegate.delegate = self
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
                                } // end of let password = dvc.textField.text
                            } // detailVC.buttonAction
                            self.present(detailVC, animated: true, completion: nil)
                        } // hide spinner
                    } // DispathQueue.main.asyc
                } // transaction
            } // end of prepareTransactionForMinting
        }) // end of prepareTransactionForNewContract
    }
}

// MARK: - Picker
extension DigitalAssetViewController {
    override var inputView: UIView? {
        switch pickerTag {
            case 3:
                return self.saleFormatPicker.inputView
            case 50:
                return self.auctionDurationPicker.inputView
            default:
                return nil
        }
    }
    
    @objc func doDone() { // user tapped button in accessory view
        switch pickerTag {
            case 3:
                self.saleMethodLabel.text = saleFormatPicker.currentPep
            case 50:
                self.auctionDurationLabel.textColor = .black
                self.auctionDurationLabel.text = auctionDurationPicker.currentPep + " days"
            default:
                break
        }
        self.resignFirstResponder()
        self.showKeyboard = false
    }
}

