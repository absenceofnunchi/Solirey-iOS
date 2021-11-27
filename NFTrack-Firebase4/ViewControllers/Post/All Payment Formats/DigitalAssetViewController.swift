//
//  DigitalAssetViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-28.
//

import UIKit
import CryptoKit
import Combine

// testing only
import web3swift
import BigInt

class DigitalAssetViewController: ParentPostViewController, ResaleDelegate {
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
    
    final override var panelButtons: [PanelButton] {
        let buttonPanels = [
            PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
            PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
        ]
        return buttonPanels
    }
    
    final var saleFormatObserver: NSKeyValueObservation?
    final var txPackageRetainer = [TxPackage]()
//    final var storageURLsRetainer: [String?]!
    final var closeButtonEnabled: Bool! = true
    override var post: Post? {
        didSet {
            closeButtonEnabled = false
        }
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        saleFormatObserver = saleMethodLabel.observe(\.text) { [weak self] (label, observedChange) in
            guard let text = label.text, let saleFormat = SaleFormat(rawValue: text) else { return }
            switch saleFormat {
                case .onlineDirect:
                    self?.paymentMethodLabel.text = PaymentMethod.directTransfer.rawValue
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
    
    // Set only during resale
    // 1. Set the existing image.
    // 2. Disable the ability to delete the image.
    // 3. Decrease the height of the button panel to 0.
    final override func resaleConfig() {
        guard let files = post?.files,
              let file = files.first,
              let filePath = URL(string: file) else { return }
        
        let retrievedPreviewData = PreviewData(
            header: .remoteImage,
            filePath: filePath,
            originalImage: nil
        )
        
        previewDataArr.append(retrievedPreviewData)
        BUTTON_PANEL_HEIGHT = 0
    }

    // MARK: - configureUI
    final override func configureUI() {
        super.configureUI()
                
        deliveryInfoButton.isHidden = true
        deliveryInfoButton.isEnabled = false
        deliveryMethodLabel.text = DeliveryMethod.onlineTransfer.rawValue
        
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
    final override func createIDField(post: Post? = nil) {
        idContainerView = UIView()
        idContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idContainerView)
        
        idTextField = createTextField(delegate: self)
        idTextField.autocapitalizationType = .none
        idTextField.autocorrectionType = .no
        idTextField.isUserInteractionEnabled = false
        if let post = post {
            idTextField.text = post.id
        } else {
            idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
        }
        
        idContainerView.addSubview(idTextField)
    }
    
    // MARK: - setIDFieldConstraints
    final override func setIDFieldConstraints(post: Post? = nil) {
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
        configureImagePreview(
            postType: .digital,
            superView: scrollView,
            closeButtonEnabled: closeButtonEnabled
        )
    }
    
    // MARK: - imagePickerController
    final override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        super.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        picker.dismiss(animated: true)
        
        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
              let filePath = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            print("No image found")
            return
        }
        
        let previewData = PreviewData(
            header: .image,
            filePath: filePath,
            originalImage: originalImage
        )
        
        previewDataArr.removeAll()
        previewDataArr.append(previewData)
        
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
        guard previewDataArr.count < 2 else {
            alert.showDetail("Image Limit", with: "You have reached the limit of 1 image.", for: self)
            return
        }
        
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
    @objc final override func tapped(_ sender: UITapGestureRecognizer) {
        /// payment method label
        alert.showDetail("Payment Method", with: "The payment method for digital items is determined by the sale format.", alignment: .left, for: self)
    }
    
//    // MARK: - processMint
//    final override func processEscrow(_ mintParameters: MintParameters) {
//        guard let sm = SaleFormat(rawValue: mintParameters.saleFormat) else { return }
//        switch sm {
//            case .onlineDirect:
//                guard let price = mintParameters.price, !price.isEmpty else {
//                    self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
//                    return
//                }
//                
//                onlineDirect(
//                    price: price,
//                    itemTitle: mintParameters.itemTitle,
//                    desc: mintParameters.desc,
//                    category: mintParameters.category,
//                    convertedId: mintParameters.convertedId,
//                    tokensArr: mintParameters.tokensArr,
//                    userId: userId,
//                    deliveryMethod: mintParameters.deliveryMethod,
//                    saleFormat: mintParameters.saleFormat,
//                    paymentMethod: mintParameters.paymentMethod
//                )
//                
//            case .openAuction:
//                guard let auctionDuration = auctionDurationLabel.text,
//                      !auctionDuration.isEmpty else {
//                    self.alert.showDetail("Incomplete", with: "Please specify the auction duration.", for: self)
//                    return
//                }
//                
//                guard let auctionStartingPrice = auctionStartingPriceTextField.text,
//                      !auctionStartingPrice.isEmpty else {
//                    self.alert.showDetail("Incomplete", with: "Please specify the starting price for your auction.", for: self)
//                    return
//                }
//                
//                mintParameters.auctionDuration = auctionDuration
//                mintParameters.auctionStartingPrice = auctionStartingPrice
//
//                processAuction(mintParameters)
//        }
//    }
}

// MARK: - Picker
extension DigitalAssetViewController {
    final override var inputView: UIView? {
        switch pickerTag {
            case 3:
                return self.saleFormatPicker.inputView
            case 49:
                return self.contractFormatPicker.inputView
            case 50:
                return self.auctionDurationPicker.inputView
            default:
                return nil
        }
    }
    
    @objc final func doDone() { // user tapped button in accessory view
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch pickerTag {
            case 3:
                self.saleMethodLabel.text = saleFormatPicker.currentPep
            case 49:
                self.smartContractFormatLabel.text = contractFormatPicker.currentPep
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
