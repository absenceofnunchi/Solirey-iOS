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

enum SaleFormat: String {
    case onlineDirect = "Online Direct"
    case openAuction = "Open Auction"
}

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
    
    final override func configureImagePreview() {
        configureImagePreview(postType: .digital)
    }
    
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
    
    final func onlineDirect(price: String, itemTitle: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
        let escrowFunction = Deferred { [weak self] in
            Future<TxPackage, PostingError> { promise in
                self?.createEscrowTransaction(contractABI: purchaseABI2, price: price, promise: promise)
            }
            .eraseToAnyPublisher()
        }
        
        let mintFunction = Deferred { [weak self] in
            Future<TxPackage, PostingError> { promise in
                self?.createMintTransaction(promise)
            }
            .eraseToAnyPublisher()
        }
        
        self.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c")
        
        // create transactions and gas estimates for escrow and minting
        Publishers.MergeMany([escrowFunction, mintFunction])
            .collect()
            // calculate the gas cost against the balance in the wallet
            .tryMap { [weak self] (txPackages) -> [TxPackage] in
                do {
                    let _ = try self?.calculateTotalGasCost(with: txPackages)
                } catch {
                    throw error
                }
                return txPackages
            }
            .mapError{ $0 as! PostingError }
            // execute the transactions and get the receipts in an array
            .flatMap { (txPackages) -> AnyPublisher<[TxResult], PostingError> in
                let results = txPackages.map { self.executeTransaction(transaction: $0.transaction, password: "111111", type: $0.type) }
                return Publishers.MergeMany(results)
                    .collect()
                    .eraseToAnyPublisher()
            }
            // instantiate the socket, parse the receipts, and create the firebase entry as soon as the socket receives the data
            // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
            .flatMap { [weak self] (txResults) -> AnyPublisher<Int, PostingError> in
                return Future<[String], PostingError> { promise in
                    self?.socketDelegate.promise = promise
                }
                .flatMap({ (topics) -> Publisher in
                    <#code#>
                })
                .flatMap { (topics) -> AnyPublisher<Int, PostingError> in
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
                        self?.createFireStoreEntry(senderAddress: senderAddress, escrowHash: escrowHash, mintHash: mintHash, itemTitle: itemTitle, desc: desc, price: price, category: category, tokensArr: tokensArr, convertedId: convertedId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod, topics: topics, promise: promise)
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            }
            .sink { [weak self] (completion) in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        print("finished")
                        guard let `self` = self else { return }
                        self.socketDelegate.disconnectSocket()
                }
            } receiveValue: { (tokenId) in
                print("tokenId", tokenId)
            }
            .store(in: &storage)

    }
    
    final func createEscrowTransaction(contractABI: String, price: String, promise: @escaping (Result<TxPackage, PostingError>) -> Void) {
        self.transactionService.prepareTransactionForNewContract(contractABI: contractABI, value: price, completion: { (transaction, error) in
            if let error = error {
                promise(.failure(error))
            }
            
            if let transaction = transaction {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let escrowGasEstimate = try transaction.estimateGas()
                        let txPackage = TxPackage(transaction: transaction, gasEstimate: escrowGasEstimate, price: price, type: .deploy)
//                        print("escrow txPackage", txPackage)
                        promise(.success(txPackage))
                    } catch {
                        promise(.failure(.retrievingEstimatedGasError))
                    }
                }
            }
        })
    }
    
    final func createMintTransaction(_ promise: @escaping (Result<TxPackage, PostingError>) -> Void) {
        self.transactionService.prepareTransactionForMinting { (transaction, error) in
            if let error = error {
                promise(.failure(error))
            }
            
            if let transaction = transaction {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let escrowGasEstimate = try transaction.estimateGas()
                        let txPackage = TxPackage(transaction: transaction, gasEstimate: escrowGasEstimate, price: nil, type: .mint)
//                        print("mint txPackage", txPackage)
                        promise(.success(txPackage))
                    } catch {
                        promise(.failure(.retrievingEstimatedGasError))
                    }
                }
            }
        }
    }
    
    final func calculateTotalGasCost(with txPackages: [TxPackage]) throws -> Bool {
        /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
        let localDatabase = LocalDatabase()
        guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
            throw PostingError.generalError(reason: "There was an error retrieving your wallet.")
        }

        var balanceResult: BigUInt!
        do {
            balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
        } catch {
            throw PostingError.generalError(reason: "An error retrieving the balance of your wallet.")
        }

        var currentGasPrice: BigUInt!
        do {
            currentGasPrice = try Web3swiftService.web3instance.eth.getGasPrice()
        } catch {
            throw PostingError.retrievingGasPriceError
        }

        var totalGasUnits: BigUInt! = 0
        var price: String!
        for txPackage in txPackages {
            totalGasUnits += txPackage.gasEstimate
            // only one of the transactions will have price
            if price != nil { continue }
            price = txPackage.price
        }
        
        guard let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth),
              (totalGasUnits * currentGasPrice + priceInWei) < balanceResult else {
            throw PostingError.insufficientFund
        }
        
        return true
    }
    
    final func executeTransaction(transaction: WriteTransaction, password: String, type: TxType) -> Future<TxResult, PostingError> {
        return Future<TxResult, PostingError> { promise in
            do {
                let result = try transaction.send(password: password, transactionOptions: nil)
//                print("executeTransaction", result)
                let senderAddress = result.transaction.sender!.address
                let txResult = TxResult(senderAddress: senderAddress, txHash: result.hash, txType: type)
                promise(.success(txResult))
            } catch {
                if case PostingError.web3Error(let err) = error {
                    promise(.failure(.generalError(reason: err.errorDescription)))
                } else {
                    promise(.failure(.generalError(reason: error.localizedDescription)))
                }
            }
        }
    }
    
    final func createFireStoreEntry(senderAddress: String, escrowHash: String, mintHash: String, itemTitle: String, desc: String, price: String, category: String, tokensArr: Set<String>, convertedId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String, topics: [String], promise: @escaping (Result<Int, PostingError>) -> Void) {
        let ref = self.db.collection("post")
        let id = ref.document().documentID
        // for deleting photos afterwards
        self.documentId = id
        
        // txHash is either minting or transferring the ownership
        self.db.collection("post").document(id).setData([
            "sellerUserId": userId,
            "senderAddress": senderAddress,
            "escrowHash": escrowHash,
            "mintHash": mintHash,
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
                promise(.failure(.generalError(reason: error.localizedDescription)))
            } else {
                return FirebaseService.shared.getTokenId1(topics: topics, documentId: self.documentId, promise: promise)
            }
        }
    }
    
    // MARK: - auction mint
    final func auction(price: String, itemTitle: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String, auctionDuration: String, auctionStartingPrice: String) {
        
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
        print("startingBid", startingBidInWei)
        print("biddingTime", biddingTime)
        print("string", String(biddingTime))
        
        // auction deployment
        self.transactionService.prepareTransactionForNewContract(contractABI: auctionABI, value: String(price), parameters: [biddingTime, startingBidInWei] as [AnyObject], completion: { [weak self](transaction, error) in
            guard let `self` = self else { return }
            if let error = error {
                switch error {
                    case .invalidAmountFormat:
                        self.alert.showDetail("Error", with: "The price is in a wrong format", for: self)
                    case .contractLoadingError:
                        self.alert.showDetail("Error", with: "Auction Contract Loading Error", for: self)
                    case .createTransactionIssue:
                        self.alert.showDetail("Error", with: "Auction Contract Transaction Issue", for: self)
                    case .retrievingEstimatedGasError:
                        self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
                    case .retrievingCurrentAddressError:
                        self.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
                    default:
                        self.alert.showDetail("Error", with: "There was an error deploying your auction contract.", for: self)
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
                        case .retrievingCurrentAddressError:
                            self.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
                        default:
                            self.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
                    }
                }
                
                /// check the balance of the wallet against the gas limit for two transactions: minting and deploying the contract
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
                // gas estimation for transferring the token into the auction contract
                // tricky because impossible to get the exact estimation before minting the very token that you're trying to transfer
//                let estimatedGasForTransferringToken: BigUInt = 64000
                
//                print("estimatedGasForMinting", estimatedGasForMinting)
//                print("estimatedGasForDeploying", estimatedGasForDeploying)
//                print("balanceResult", balanceResult)
                
//                guard let estimatedGasForMinting = estimatedGasForMinting,
//                      let estimatedGasForDeploying = estimatedGasForDeploying,
//                      let balance = balanceResult else {
//                    print("no")
//                    return
//                }
//
//                guard ((estimatedGasForMinting + estimatedGasForTransferringToken) * currentGasPrice) < balanceResult else {
//                    let content = """
//                    Insufficient funds in your wallet to cover the gas fee for deploying the auction contract and minting a token.
//
//                    A. Estimated gas for minting your token: \(estimatedGasForMinting) units
//                    B. Estimated gas for deploying the auction contract: \(estimatedGasForDeploying) units
//                    C. Estimated gas for transferring the token: \(estimatedGasForTransferringToken) units
//                    D. Current gas price: \(currentGasPrice) Gwei
//                    E. Your current balance: \(balance) Wei
//
//                    (A + B + C) * D = \((estimatedGasForMinting + estimatedGasForTransferringToken) * currentGasPrice) Wei
//                    """
//                    self.alert.showDetail("Insufficient Fund", with: content, height: 550, alignment: .left, for: self)
//                    return
//                }
                
                // auction deployment transaction
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
                                                    // create an auction contract
                                                    let result = try transaction.send(password: password, transactionOptions: nil)
                                                    print("auction deployment result", result)
                                                    
                                                    // to be used for transferring the token into the auction contract
                                                    self.auctionHash = result.hash
                                                    let senderAddress = result.transaction.sender!.address

                                                    let update: [String: PostProgress] = ["update": .deployingEscrow]
                                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                                    
                                                    // mint transaction
                                                    if let mintTransaction = mintTransaction {
                                                        do {
                                                            let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
                                                            print("mintResult", mintResult)

                                                            // firebase
//                                                            let senderAddress = result.transaction.sender!.address
                                                            let ref = self.db.collection("post")
                                                            let id = ref.document().documentID

                                                            // for deleting photos afterwards
                                                            self.documentId = id

                                                            // txHash is either minting or transferring the ownership
                                                            self.db.collection("post").document(id).setData([
                                                                "sellerUserId": userId,
                                                                "senderAddress": senderAddress,
                                                                "escrowHash": "N/A",
                                                                "auctionHash": result.hash,
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
                                } // end of let password = dvc.textField.text
                            } // detailVC.buttonAction
                            self.present(detailVC, animated: true, completion: nil)
                        } // hide spinner
                    } // DispathQueue.main.asyc
                } // transaction
            } // prepareTransactionForMinting
        }) // end of prepareTransactionForNewContract
    } // end of auction
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

extension DigitalAssetViewController {
    final override func didReceiveMessage(topics: [String]) {
        guard let saleFormat = self.saleMethodLabel.text,
              let sm = SaleFormat(rawValue: saleFormat) else { return }
        
        switch sm {
            case .onlineDirect:
                super.didReceiveMessage(topics: topics)
                break
            case .openAuction:
//                Future<TransactionReceipt, PostingError> { promise in
//                    Web3swiftService.getReceipt(hash: self.auctionHash, promise: promise)
//                }
//                .tryMap{ (receipt) -> AnyPublisher<Int, PostingError> in
//                    guard let address = receipt.contractAddress?.address else {
//                        throw PostingError.generalError(reason: "Unable to get the deployed contract address")
//                    }
//                    print("address from receipt", address)
//
//                    return FirebaseService.shared.getTokenId1(topics: topics, documentId: self.documentId)
//                }
//                .sink { (completion) in
//                    switch completion {
//                        case .finished:
//                            print("finished1")
//                        case .failure(_):
//                            self.alert.showDetail("Error", with: "There was an error getting the auction contract address.", for: self)
//                    }
//                } receiveValue: { (receipt) in
//                    print("receipt", receipt)
//
//                }
            break
        }
    }
    
    final func transferTokenIntoAuction(topics: [String], auctionContractAddress: String) {
        // get the token ID from Clouds Function
        // safeTransferFrom seller to the auction contract
        
        let _ = FirebaseService.shared.getTokenId(topics: topics, documentId: self.documentId)
            .sink { (completion) in
                switch completion {
                    case .failure(let apiError):
                        print(apiError)
                    case .finished:
                        print("finished2")
                }
            } receiveValue: { (data) in
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    guard let convertedJson = json as? NSNumber else {
                        // default error
                        self.alert.showDetail("Error", with: "Decoding Token Error", for: self)
                        return
                    }
                    print("*********convertedJson.intValue", convertedJson.intValue)
                } catch {
                    self.alert.showDetail("Error", with: "Decoding Token Error", for: self)
                }
            }

        
            
        
//        getTokenId(topics: topics) { [weak self](tokenId, res) in
//            guard let res = res else { return }
//            switch res {
//                case is HTTPStatusCode:
//                    switch res as! HTTPStatusCode {
//                        case .badRequest:
//                            self?.alert.showDetail("Error", with: "Bad request. Please contact the support.", for: self)
//                        case .unauthorized:
//                            self?.alert.showDetail("Error", with: "Unauthorized request. Please contact the support.", for: self)
//                        case .internalServerError:
//                            self?.alert.showDetail("Error", with: "Internal Server Error. Please contact the support.", for: self)
//                        case .serviceUnavailable:
//                            self?.alert.showDetail("Error", with: "Service Unavailable. Please contact the support.", for: self)
//                        case .ok, .created, .accepted:
//                            let update: [String: PostProgress] = ["update": .minting]
//                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//
//                            // upload images
//                            self?.uploadFiles()
//
//                            print("Web3swiftService.currentAddress", Web3swiftService.currentAddress as Any)
//                            print("tokenId", tokenId as Any)
//                            print("erc721ContractAddress", erc721ContractAddress as Any)
//
//                            guard let fromAddress = Web3swiftService.currentAddress,
//                                  let tokenId = tokenId,
//                                  let erc721ContractAddress = erc721ContractAddress else {
//                                self?.alert.showDetail("Error", with: "Could not set the parameters to transfer the token into the auction contract.", for: self)
//                                return
//                            }
//
////                            print("fromAddress", fromAddress as Any)
////                            print("tokenId", tokenId as Any)
////                            print("erc721ContractAddress", erc721ContractAddress as Any)
//
//                            let param: [AnyObject] = [fromAddress, auctionContractAddress, tokenId] as [AnyObject]
//                            self?.transactionService.prepareTransactionForWriting(method: "safeTransferFrom", abi: NFTrackABI, param: param, contractAddress: erc721ContractAddress, completion: { (transaction, error) in
//                                if let error = error {
//                                    switch error {
//                                        case .invalidAmountFormat:
//                                            self?.alert.showDetail("Error", with: "The ETH amount is not in a correct format!", for: self)
//                                        case .zeroAmount:
//                                            self?.alert.showDetail("Error", with: "The ETH amount cannot be negative", for: self)
//                                        case .insufficientFund:
//                                            self?.alert.showDetail("Error", with: "There is an insufficient amount of ETH in the wallet.", for: self)
//                                        case .contractLoadingError:
//                                            self?.alert.showDetail("Error", with: "There was an error loading your contract.", for: self)
//                                        case .createTransactionIssue:
//                                            self?.alert.showDetail("Error", with: "There was an error creating the transaction.", for: self)
//                                        default:
//                                            self?.alert.showDetail("Sorry", with: "There was an error. Please try again.", for: self)
//                                    }
//                                }
//
//                                if let transaction = transaction {
//                                    DispatchQueue.global().async {
//                                        do {
//                                            guard let walletAuthorizationCode = self?.walletAuthorizationCode, let documentID = self?.documentId else {
//                                                self?.alert.showDetail("Sorry", with: "Could not get the wallet authorization passcode.", for: self)
//                                                return
//                                            }
//
//                                            let receipt = try transaction.send(password: walletAuthorizationCode, transactionOptions: nil)
//                                            FirebaseService.shared.db.collection("post").document(documentID).updateData([
//                                                "initialAuctionTokenTransferHash": receipt.hash,
//                                            ], completion: { (error) in
//                                                if let error = error {
//                                                    self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                } else {
//                                                    self?.alert.showDetail("Success!", with: "You have successfully listed your item.", for: self)
//                                                }
//                                            })
//                                        } catch Web3Error.nodeError(let desc) {
//                                            if let index = desc.firstIndex(of: ":") {
//                                                let newIndex = desc.index(after: index)
//                                                let newStr = desc[newIndex...]
//                                                self?.alert.showDetail("Alert", with: String(newStr), for: self)
//                                            }
//                                        } catch Web3Error.transactionSerializationError {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                            }
//                                        } catch Web3Error.connectionError {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                            }
//                                        } catch Web3Error.dataError {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                            }
//                                        } catch Web3Error.inputError(_) {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Alert", with: "Failed to sign the transaction. You may be using an incorrect password. \n\nOtherwise, please try logging out of your wallet (not the NFTrack account) and logging back in. Ensure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                            }
//                                        } catch Web3Error.processingError(let desc) {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Alert", with: "\(desc). Ensure that you're using the same address used in the original transaction.", height: 320, alignment: .left, for: self)
//                                            }
//                                        } catch {
//                                            self?.alert.showDetail("Error", with: "There was an error with the transfer transaction.", for: self)
//                                        }
//                                    } // dispatchQueue
//                                }
//                            })
//
//                            DispatchQueue.main.async {
//                                self?.titleTextField.text?.removeAll()
//                                self?.priceTextField.text?.removeAll()
//                                self?.deliveryMethodLabel.text?.removeAll()
//                                self?.descTextView.text?.removeAll()
//                                self?.idTextField.text?.removeAll()
//                                self?.pickerLabel.text?.removeAll()
//                                self?.tagTextField.tokens.removeAll()
//                                self?.paymentMethodLabel.text?.removeAll()
//                            }
//                        default:
//                            self?.alert.showDetail("Error", with: "Unknown Network Error. Please contact the admin.", for: self)
//                    }
//                case is GeneralErrors:
//                    switch res as! GeneralErrors {
//                        case .decodingError:
//                            self?.alert.showDetail("Error", with: "There was an error decoding the token ID. Please contact the admin.", for: self)
//                        default:
//                            break
//                    }
//                default:
//                    self?.alert.showDetail("Error in Minting", with: res.localizedDescription, for: self)
//            }
//        }
    }
}


enum PostingError: Error {
    case generalError(reason: String)
    case invalidDestinationAddress
    case invalidAmountFormat
    case emptyDestinationAddress
    case emptyAmount
    case contractLoadingError
    case retrievingGasPriceError
    case retrievingEstimatedGasError
    case emptyResult
    case noAvailableKeys
    case createTransactionIssue
    case zeroAmount
    case insufficientFund
    case retrievingCurrentAddressError
    case web3Error(Web3Error)
    case apiError(APIError)
}

enum TxType {
    case mint
    case deploy
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
