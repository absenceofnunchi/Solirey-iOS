//
//  DigitalAssetViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-28.
//

import UIKit
import web3swift
import CryptoKit
import BigInt
import Combine

class DigitalAssetViewController: ParentPostViewController {
    lazy final var idContainerViewHeightConstraint: NSLayoutConstraint = idContainerView.heightAnchor.constraint(equalToConstant: 50)
    lazy final var idTitleLabelHeightConstraint: NSLayoutConstraint = idTitleLabel.heightAnchor.constraint(equalToConstant: 50)
    
    final var auctionDurationTitleLabel: UILabel!
    final var auctionDurationLabel: UILabel!
    final var auctionStartingPriceTitleLabel: UILabel!
    final var auctionStartingPriceTextField: UITextField!
    /// for auction duration
    final let auctionDurationPicker = MyPickerVC(currentPep: "3", pep: Array(3...20).map { String($0) })
    /// sale format for digital
    final let saleFormatPicker = MyPickerVC(currentPep: SaleFormat.onlineDirect.rawValue, pep: [SaleFormat.onlineDirect.rawValue, SaleFormat.openAuction.rawValue])
    final let CONTENT_SIZE_HEIGHT_WITH_AUCTION_FIELDS: CGFloat = 1850
    
    // to be used for transferring the token into the auction contract
    final var auctionHash: String!
    final var walletAuthorizationCode: String!
    final var getTxReceipt: AnyCancellable?
    final var storage = Set<AnyCancellable>()
    
    final override var previewDataArr: [PreviewData]! {
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
    
    final override var panelButtons: [PanelButton] {
        let buttonPanels = [
            PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
            PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
        ]
        return buttonPanels
    }
    
    final var saleFormatObserver: NSKeyValueObservation?
    
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
                        self?.priceTextFieldConstraintHeight.constant = 50
                        self?.priceTextField.alpha = 1
                        self?.priceLabelConstraintHeight.constant = 50
                        self?.priceLabel.alpha = 1
                        self?.auctionDurationTitleLabel.alpha = 0
                        self?.auctionDurationLabel.alpha = 0
                        self?.auctionStartingPriceTitleLabel.alpha = 0
                        self?.auctionStartingPriceTextField.alpha = 0
                        UIView.animate(withDuration: 0.5) {
                            self?.view.layoutIfNeeded()
                        }
                        
                        guard let `self` = self else { return }
//                        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.scrollView.contentSize.height - self.AUCTION_FIELDS_HEIGHT)
                        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
                    }
                case .openAuction:
                    self?.paymentMethodLabel.text = PaymentMethod.auctionBeneficiary.rawValue
                    /// show the auction duration and the starting price labels when the sale format is selected to open auction
                    DispatchQueue.main.async { [weak self] in
                        self?.saleMethodContainerConstraintHeight.constant = 290
                        self?.auctionDurationLabel.isUserInteractionEnabled = true
                        self?.priceLabelConstraintHeight.constant = 0
                        self?.priceLabel.alpha = 0
                        self?.priceTextFieldConstraintHeight.constant = 0
                        self?.priceTextField.alpha = 0
                        
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
                            self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.CONTENT_SIZE_HEIGHT_WITH_AUCTION_FIELDS)
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

    // MARK: - configureUI
    final override func configureUI() {
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
    
    // MARK: - setConstraints
    final override func setConstraints() {
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
    
    // MARK: - createIDField
    final override func createIDField() {
        idContainerView = UIView()
        idContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idContainerView)
        
        idTextField = createTextField(delegate: self)
        idTextField.autocapitalizationType = .none
        idTextField.isUserInteractionEnabled = false
        idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
        idContainerView.addSubview(idTextField)
    }
    
    // MARK: - setIDFieldConstraints
    final override func setIDFieldConstraints() {
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
    
    // MARK: - configureImagePreview
    final override func configureImagePreview() {
        configureImagePreview(postType: .digital(.onlineDirect))
    }
    
    // MARK: - imagePickerController
    final override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
    
    // MARK: - buttonPressed
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

    // MARK: - tapped
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
    
    // MARK: - processMint
    final override func processMint(price: String?, itemTitle: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
        
        guard let sm = SaleFormat(rawValue: saleFormat) else { return }
        switch sm {
            case .onlineDirect:
                guard let price = price, !price.isEmpty else {
                    self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
                    return
                }
                
                onlineDirect(price: price, itemTitle: itemTitle, desc: desc, category: category, convertedId: convertedId, tokensArr: tokensArr, userId: userId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod)
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

                auction(price: "0", itemTitle: itemTitle, desc: desc, category: category, convertedId: convertedId, tokensArr: tokensArr, userId: userId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod, auctionDuration: auctionDuration, auctionStartingPrice: auctionStartingPrice)
        }
    }
    
    // MARK: - onlineDirect
    final func onlineDirect(price: String, itemTitle: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
        let escrowFunction = Deferred { [weak self] in
            Future<TxPackage, PostingError> { promise in
                self?.transactionService.createDeploymentTransaction(contractABI: purchaseABI2, bytecode: purchaseBytecode2, price: price, promise: promise)
            }
            .eraseToAnyPublisher()
        }
        
        let mintFunction = Deferred { [weak self] in
            Future<TxPackage, PostingError> { promise in
                self?.transactionService.createMintTransaction(promise)
            }
            .eraseToAnyPublisher()
        }
        
        guard let contractAddress = NFTrackAddress?.address else {
            self.alert.showDetail("Sorry", with: "There was an error loading the contract address.", for: self)
            return
        }
        self.socketDelegate = SocketDelegate(contractAddress: contractAddress)
        
        self.hideSpinner { [weak self] in
            guard let `self` = self else { return }
            let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
            detailVC.titleString = "Enter your password"
            detailVC.buttonAction = { vc in
                // get the password
                if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                    self.dismiss(animated: true, completion: {
                        self.progressModal = ProgressModalViewController(postType: .digital(.onlineDirect))
                        self.progressModal.titleString = "Posting In Progress"
                        self.present(self.progressModal, animated: true, completion: {
                            
                            // create transactions and gas estimates for escrow and minting
                            Publishers.MergeMany([escrowFunction, mintFunction])
                                .collect()
                                .eraseToAnyPublisher()
                                // calculate the gas cost against the balance in the wallet
                                .flatMap { (txPackages) -> AnyPublisher<[TxPackage], PostingError> in
                                    return Future<[TxPackage], PostingError> { promise in
                                        self.transactionService.calculateTotalGasCost(with: txPackages, promise: promise)
                                        let update: [String: PostProgress] = ["update": .estimatGas]
                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    }
                                    .eraseToAnyPublisher()
                                }
                                // execute the transactions and get the receipts in an array
                                .flatMap { (txPackages) -> AnyPublisher<[TxResult], PostingError> in
                                    // update notification has to be one step behind the actual update since it can fail
                                    let update: [String: PostProgress] = ["update": .images]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    let results = txPackages.map { self.transactionService.executeTransaction(transaction: $0.transaction, password: password, type: $0.type) }
                                    return Publishers.MergeMany(results)
                                        .collect()
                                        .eraseToAnyPublisher()
                                }
                                // instantiate the socket, parse the receipts, and create the firebase entry as soon as the socket receives the data
                                // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
                                .flatMap { (txResults) -> AnyPublisher<Int, PostingError> in
                                    var topicsRetainer: [String]!
                                    return Future<[String], PostingError> { promise in
                                        self.socketDelegate.promise = promise
                                    }
                                    .flatMap({ (topics) -> AnyPublisher<[String?], PostingError> in
                                        topicsRetainer = topics
                                        
                                        if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
                                            let fileURLS = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                                                return Future<String?, PostingError> { promise in
                                                    self.uploadFileWithPromise(fileURL: previewData.filePath, userId: self.userId, promise: promise)
                                                }.eraseToAnyPublisher()
                                            }
                                            return Publishers.MergeMany(fileURLS)
                                                .collect()
                                                .eraseToAnyPublisher()
                                        } else {
                                            return Result.Publisher([] as [String]).eraseToAnyPublisher()
                                        }
                                    })
                                    // using the urlStrings from Firebase Storage and the user input, create a Firebase entry
                                    // A Cloud Functions method will be invoked to update the entry with the minted token's ID at the end
                                    .flatMap { (urlStrings) -> AnyPublisher<Int, PostingError> in
                                        var escrowHash: String!
                                        var mintHash: String!
                                        var senderAddress: String!
                                        for txResult in txResults {
                                            if txResult.txType == .deploy {
                                                escrowHash = txResult.txHash
                                            } else {
                                                mintHash = txResult.txHash
                                            }
                                            senderAddress = txResult.senderAddress
                                        }
                                        
                                        return Future<Int, PostingError> { promise in
                                            self.transactionService.createFireStoreEntry(documentId: &self.documentId, senderAddress: senderAddress, escrowHash: escrowHash, auctionHash: "N/A", mintHash: mintHash, itemTitle: itemTitle, desc: desc, price: price, category: category, tokensArr: tokensArr, convertedId: convertedId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod, topics: topicsRetainer, urlStrings: urlStrings, promise: promise)
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .eraseToAnyPublisher()
                                }
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            switch error {
                                                case .fileUploadError(.fileNotAvailable):
                                                    self.alert.showDetail("Error", with: "No image file was found.", for: self)
                                                case .retrievingEstimatedGasError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving the gas estimation.", for: self)
                                                case .retrievingGasPriceError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving the current gas price.", for: self)
                                                case .contractLoadingError:
                                                    self.alert.showDetail("Error", with: "There was an error loading your contract ABI.", for: self)
                                                case .retrievingCurrentAddressError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving your current account address.", for: self)
                                                case .createTransactionIssue:
                                                    self.alert.showDetail("Error", with: "There was an error creating a transaction.", for: self)
                                                case .insufficientFund(let msg):
                                                    self.alert.showDetail("Error", with: msg, height: 500, alignment: .left, for: self)
                                                case .emptyAmount:
                                                    self.alert.showDetail("Error", with: "The ETH value cannot be blank for the transaction.", for: self)
                                                case .invalidAmountFormat:
                                                    self.alert.showDetail("Error", with: "The ETH value is in an incorrect format.", for: self)
                                                case .generalError(reason: let msg):
                                                    self.alert.showDetail("Error", with: msg, for: self)
                                                default:
                                                    self.alert.showDetail("Error", with: "There was an error creating your post.", for: self)
                                            }
                                        case .finished:
                                            self.socketDelegate.disconnectSocket()
                                            let update: [String: PostProgress] = ["update": .deployingEscrow]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                            
                                            let mintUpdate: [String: PostProgress] = ["update": .minting]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: mintUpdate)
                                    }
                                } receiveValue: { (tokenId) in
                                    print("tokenId", tokenId)
                                }
                                .store(in: &self.storage)
                        }) // progress modal
                    }) // dismiss
                } // dvc textfield
            }
            self.present(detailVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - auction mint
    final func auction(price: String = "0", itemTitle: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String, auctionDuration: String, auctionStartingPrice: String) {
        
        guard let index = auctionDuration.firstIndex(of: "d") else { return }
        let newIndex = auctionDuration.index(before: index)
        let newStr = auctionDuration[..<newIndex]
        guard let numOfDays = NumberFormatter().number(from: String(newStr)) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction duration into a proper format. Please try again.", for: self)
            return
        }
        
        guard let startingBidInWei = Web3.Utils.parseToBigUInt(auctionStartingPrice, units: .eth) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction starting price into a proper format. Pleas try again.", for: self)
            return
        }
        
        let biddingTime = numOfDays.intValue * 60 * 60 * 24
        
        let auctionFunction = Deferred { [weak self] in
            Future<TxPackage, PostingError> { promise in
                self?.transactionService.createDeploymentTransaction(contractABI: auctionABI, bytecode: auctionBytcode, price: price, parameters: [biddingTime, startingBidInWei] as [AnyObject], promise: promise)
            }
            .eraseToAnyPublisher()
        }
        let mintFunction = Deferred { [weak self] in
            Future<TxPackage, PostingError> { promise in
                self?.transactionService.createMintTransaction(promise)
            }
            .eraseToAnyPublisher()
        }
      
        guard let NFTrackAddress = NFTrackAddress else {
            self.alert.showDetail("Sorry", with: "There was an error loading the contract address.", for: self)
            return
        }
        self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress.address)
        
        // to be used for getting the contract address so that the token can be transferred
        var auctionHash: String!
        
        /// 1. obtain the password
        /// 2. prepare the auction deployment and minting transactions
        /// 3. execute the transactions and get the receipts in an array
        /// 4. Upload images and files to Firebase storage, if any, or return an empty array
        /// 5. Get the topics from the socket when the txs are mined and create a Firestore entry
        /// 6. Get the token ID through Cloud Functions and update the Firestore entry with it
        /// 7. Using the tx hash of the deployed auction contract, obtain the auction contract address
        /// 8. Using the auction contract address, token ID, and the current address, transfer the token into the auction contract
        self.hideSpinner { [weak self] in
            guard let `self` = self else { return }
            let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
            detailVC.titleString = "Enter your password"
            detailVC.buttonAction = { vc in
                // get the password
                if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                    self.dismiss(animated: true, completion: {
                        self.progressModal = ProgressModalViewController(height: 400, postType: .digital(.openAuction))
                        self.progressModal.titleString = "Posting In Progress"
                        self.present(self.progressModal, animated: true, completion: {
                            // prepare the auction deployment contract and the minting contract
                            Publishers.MergeMany([auctionFunction, mintFunction])
                                .collect()
                                .eraseToAnyPublisher()
                                .flatMap { (txPackages) -> AnyPublisher<[TxPackage], PostingError> in
                                    return Future<[TxPackage], PostingError> { promise in
                                        let estimatedGasForTransferringToken: BigUInt = 64000
                                        self.transactionService.calculateTotalGasCost(with: txPackages, plus: estimatedGasForTransferringToken, promise: promise)
                                        let update: [String: PostProgress] = ["update": .estimatGas]
                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    }
                                    .eraseToAnyPublisher()
                                }
                                // execute the transactions and get the receipts in an array
                                .flatMap { (txPackages) -> AnyPublisher<[TxResult], PostingError> in
                                    let update: [String: PostProgress] = ["update": .images]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    let results = txPackages.map { self.transactionService.executeTransaction(transaction: $0.transaction, password: password, type: $0.type) }
                                    return Publishers.MergeMany(results)
                                        .collect()
                                        .eraseToAnyPublisher()
                                }
                                // instantiate the socket, parse the receipts, and create the firebase entry as soon as the socket receives the data
                                // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
                                .flatMap { (txResults) -> AnyPublisher<Int, PostingError> in
                                    var topicsRetainer: [String]!
                                    return Future<[String], PostingError> { promise in
                                        self.socketDelegate.promise = promise
                                    }
                                    .flatMap({ (topics) -> AnyPublisher<[String?], PostingError> in
                                        topicsRetainer = topics
                                        // upload images/files to the Firebase Storage and get the array of URLs
                                        if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
                                            let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                                                return Future<String?, PostingError> { promise in
                                                    self.uploadFileWithPromise(fileURL: previewData.filePath, userId: self.userId, promise: promise)
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
                                    .flatMap { (urlStrings) -> AnyPublisher<Int, PostingError> in
                                        var mintHash: String!
                                        var senderAddress: String!
                                        for txResult in txResults {
                                            if txResult.txType == .deploy {
                                                auctionHash = txResult.txHash
                                            } else {
                                                mintHash = txResult.txHash
                                            }
                                            senderAddress = txResult.senderAddress
                                        }
                                        
                                        return Future<Int, PostingError> { promise in
                                            self.transactionService.createFireStoreEntry(documentId: &self.documentId, senderAddress: senderAddress, escrowHash: "N/A", auctionHash: auctionHash, mintHash: mintHash, itemTitle: itemTitle, desc: desc, price: price, category: category, tokensArr: tokensArr, convertedId: convertedId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod, topics: topicsRetainer, urlStrings: urlStrings, promise: promise)
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .eraseToAnyPublisher()
                                }
                                // get the address of the deployed Auction contract using the deployment transaction hash
                                .flatMap{ (tokenId) -> AnyPublisher<WriteTransaction, PostingError> in
                                    return Future<TransactionReceipt, PostingError> { promise in
                                        Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
                                    }
                                    .flatMap { (receipt) -> AnyPublisher<WriteTransaction, PostingError> in
                                        return Future<WriteTransaction, PostingError> { promise in
                                            guard let fromAddress = Web3swiftService.currentAddress else {
                                                promise(.failure(.generalError(reason: "Failed to fetched the address of your wallet")))
                                                return
                                            }
                                            
                                            guard let auctionContractAddress = receipt.contractAddress?.address else {
                                                promise(.failure(.generalError(reason: "Failed to obtain the auction contract address.")))
                                                return
                                            }
                                            
                                            let parameters: [AnyObject] = [fromAddress, auctionContractAddress, tokenId] as [AnyObject]
                                            self.transactionService.prepareTransactionForWriting(method: "transferFrom", abi: NFTrackABI, param: parameters, contractAddress: NFTrackAddress, promise: promise)
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .eraseToAnyPublisher()
                                }
                                .flatMap { (transaction) -> AnyPublisher<[TxResult], PostingError> in
                                    let update: [String: PostProgress] = ["update": .deployingAuction]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    let mintUpdate: [String: PostProgress] = ["update": .minting]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: mintUpdate)
                                    
                                    let results = self.transactionService.executeTransaction(transaction: transaction, password: password, type: .transferToken)
                                    return Publishers.MergeMany(results)
                                        .collect()
                                        .eraseToAnyPublisher()
                                }
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            switch error {
                                                case .fileUploadError(.fileNotAvailable):
                                                    self.alert.showDetail("Error", with: "No image file was found.", for: self)
                                                case .retrievingEstimatedGasError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving the gas estimation.", for: self)
                                                case .retrievingGasPriceError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving the current gas price.", for: self)
                                                case .contractLoadingError:
                                                    self.alert.showDetail("Error", with: "There was an error loading your contract ABI.", for: self)
                                                case .retrievingCurrentAddressError:
                                                    self.alert.showDetail("Error", with: "There was an error retrieving your current account address.", for: self)
                                                case .createTransactionIssue:
                                                    self.alert.showDetail("Error", with: "There was an error creating a transaction.", for: self)
                                                case .insufficientFund(let msg):
                                                    self.alert.showDetail("Error", with: msg, height: 500, alignment: .left, for: self)
                                                case .emptyAmount:
                                                    self.alert.showDetail("Error", with: "The ETH value cannot be blank for the transaction.", for: self)
                                                case .invalidAmountFormat:
                                                    self.alert.showDetail("Error", with: "The ETH value is in an incorrect format.", for: self)
                                                case .generalError(reason: let msg):
                                                    self.alert.showDetail("Error", with: msg, for: self)
                                                default:
                                                    self.alert.showDetail("Error", with: "There was an error creating your post.", for: self)
                                            }
                                        case .finished:
                                            let update: [String: PostProgress] = ["update": .initializeAuction]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                            
                                            self.titleTextField.text?.removeAll()
                                            self.priceTextField.text?.removeAll()
                                            self.descTextView.text?.removeAll()
                                            self.idTextField.text?.removeAll()
                                            self.saleMethodLabel.text?.removeAll()
                                            self.auctionDurationLabel.text?.removeAll()
                                            self.auctionStartingPriceTextField.text?.removeAll()
                                            self.pickerLabel.text?.removeAll()
                                            self.tagTextField.tokens.removeAll()
                                            self.paymentMethodLabel.text?.removeAll()
                                            
                                            if self.previewDataArr.count > 0 {
                                                self.previewDataArr.removeAll()
                                                self.imagePreviewVC.data.removeAll()
                                                DispatchQueue.main.async {
                                                    self.imagePreviewVC.collectionView.reloadData()
                                                }
                                            }
                                            
                                            self.socketDelegate.disconnectSocket()
                                    }
                                } receiveValue: { (receivedValue) in
                                    print("receivedValue", receivedValue)
                                }
                                .store(in: &self.storage)
                        }) // progress modal
                    }) // dismiss
                } // dvc textfield
            }
            self.present(detailVC, animated: true, completion: nil)
        }
    }
}

// MARK: - Picker
extension DigitalAssetViewController {
    final override var inputView: UIView? {
        switch pickerTag {
            case 3:
                return self.saleFormatPicker.inputView
            case 50:
                return self.auctionDurationPicker.inputView
            default:
                return nil
        }
    }
    
    @objc final func doDone() { // user tapped button in accessory view
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

enum TxType {
    case mint
    case deploy
    case transferToken
}

struct TxResult {
    let senderAddress: String
    let txHash: String
    let txType: TxType
}

struct TxPackage {
    let transaction: WriteTransaction
    let gasEstimate: BigUInt
    let price: String?
    let type: TxType
}

//let auctionFunction = Future<WriteTransaction, PostingError> { [weak self] promise in
//    self?.transactionService.prepareTransactionForNewContract(contractABI: auctionABI, bytecode: auctionBytcode, value: "0", parameters: [biddingTime, startingBidInWei] as [AnyObject], promise: promise)
//}
//
//let mintFunction = Future<WriteTransaction, PostingError> { [weak self] promise in
//    self?.transactionService.prepareTransactionForMinting(promise: promise)
//}
//Publishers.MergeMany([auctionFunction, mintFunction])
//    .collect()
//    .eraseToAnyPublisher()
//    .flatMap({ (transactions) -> AnyPublisher<[BigUInt], PostingError> in
//        let gasEstimates = transactions.map { (transaction) -> AnyPublisher<BigUInt, PostingError> in
//            return Future<BigUInt, PostingError> { promise in
//                var gasEstimate: BigUInt!
//                do {
//                    gasEstimate = try transaction.estimateGas()
//                    promise(.success(gasEstimate))
//                } catch {
//                    promise(.failure(.retrievingEstimatedGasError))
//                }
//            }
//            .eraseToAnyPublisher()
//        }
//        return Publishers.MergeMany(gasEstimates)
//            .collect()
//            .eraseToAnyPublisher()
//            .flatMap { (gasEsimates) -> AnyPublisher<Bool, PostingError>  in
//                let estimatedGasForTransferringToken: BigUInt = 64000
//                self.calculateTotalGasCost(with: gasEstimates, price: price, plus: estimatedGasForTransferringToken, promise: promise)
//            }
//            .flatMap { (_) -> Publisher in
//                <#code#>
//            }
//    })
