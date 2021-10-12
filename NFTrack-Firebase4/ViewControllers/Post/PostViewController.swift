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
    var topicsRetainer: [String]!
    var txResultArr = [TxResult2]()
    var txPackageArr = [TxPackage]()
    
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
//                    self?.paymentMethodLabel.text = PaymentMethod.directTransfer.rawValue
                    self?.addressTitleLabel.text = "Pickup Location"
                    self?.isShipping = true
                    self?.paymentMethodLabel.isUserInteractionEnabled = true
                    self?.paymentMethodLabel.text = nil
                case .shipping:
//                    self?.paymentMethodLabel.text = PaymentMethod.escrow.rawValue
                    self?.addressTitleLabel.text = "Shipping Restriction"
                    self?.isShipping = true
                    self?.paymentMethodLabel.text = "Escrow"
                    self?.paymentMethodLabel.isUserInteractionEnabled = false
                default:
                    break
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
        // picker for the deliver method: in-person, shipping
        deliveryMethodLabel.isUserInteractionEnabled = true
        deliveryMethodLabel.tag = 1
        
        paymentInfoButton.tag = 21
        
        saleMethodInfoButton.tag = 22
        saleMethodLabel.text = "Online Direct"
        
        pickerLabel.isUserInteractionEnabled = true
        pickerLabel.tag = 2
        
        // picker for the payment method: escrow, direct
        paymentMethodLabel.tag = 3
    }
    
    final override func createIDField(post: Post? = nil) {
        idContainerView = UIView()
        idContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idContainerView)
        
        idTextField = createTextField(delegate: self)
        idTextField.autocapitalizationType = .none
        idTextField.autocorrectionType = .no
        // If post is not nil, it means this is resale
        if let post = post {
            idTextField.text = post.id
            idTextField.isUserInteractionEnabled = false
        } else {
            idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
        }
        
        idContainerView.addSubview(idTextField)
        
        guard let scanImage = UIImage(systemName: "qrcode.viewfinder") else { return }
        scanButton = UIButton.systemButton(with: scanImage.withTintColor(.black, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonPressed))
        scanButton.layer.cornerRadius = 5
        scanButton.layer.borderWidth = 0.7
        scanButton.layer.borderColor =   UIColor.lightGray.cgColor
        scanButton.tag = 7
        scanButton.isUserInteractionEnabled = post != nil ? false : true
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        idContainerView.addSubview(scanButton)
    }
    
    final override func setIDFieldConstraints(post: Post? = nil) {
        constraints.append(contentsOf: [
            idTitleLabel.topAnchor.constraint(equalTo: tagContainerView.bottomAnchor, constant: 20),
            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            idContainerView.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
            idContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idContainerView.heightAnchor.constraint(equalToConstant: 50),
            idContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            idTextField.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: post != nil ? 1 : 0.75),
            idTextField.heightAnchor.constraint(equalToConstant: 50),
            idTextField.leadingAnchor.constraint(equalTo: idContainerView.leadingAnchor),
            
            scanButton.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: post != nil ? 0 : 0.2),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.trailingAnchor.constraint(equalTo: idContainerView.trailingAnchor),
        ])
    }
    
    final override func configureImagePreview() {
        configureImagePreview(postType: .tangible, superView: scrollView)
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
    /// 6. update the firestore with the urls of the photos and the token information
    
    final override func processMint(_ mintParameters: MintParameters) {
        guard let price = mintParameters.price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
//        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
//            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
//            return
//        }
        
        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
            return
        }
        
        guard let NFTrackAddress = NFTrackAddress else {
            self.alert.showDetail("Sorry", with: "There was an error loading the minting contract address.", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                titleString: "",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                titleString: "Transaction Options",
                body: [AlertModalDictionary.gasLimit: "", AlertModalDictionary.gasPrice: "", AlertModalDictionary.nonce: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner {
            DispatchQueue.main.async {
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let self = self else { return }
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                            return
                        }
                        
                        self.dismiss(animated: true, completion: {
                            self.progressModal = ProgressModalViewController(postType: .tangible)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress)
                                
                                var txPackageArr = [TxPackage]()
                                print("STEP 1")
                                Future<TxPackage, PostingError> { promise in
                                    self.transactionService.prepareMintTransactionWithGasEstimate(promise)
                                }
                                .flatMap({ (txPackage) -> AnyPublisher<BigUInt, PostingError> in
                                    txPackageArr.append(txPackage)
                                    guard let contractAddress = Web3swiftService.currentAddress else {
                                        return Fail(error: PostingError.retrievingCurrentAddressError)
                                            .eraseToAnyPublisher()
                                    }

                                    return Future<BigUInt, PostingError> { promise in
                                        do {
                                            // get the current nonce so that we can increment it manually
                                            // the rapid creation of transactions back to back results in the same nonce
                                            // this is true even if nonce is set to .pending
                                            print("STEP 2")
                                            let nonce = try Web3swiftService.web3instance.eth.getTransactionCount(address: contractAddress)
                                            promise(.success(nonce))
                                        } catch {
                                            promise(.failure(.generalError(reason: error.localizedDescription)))
                                        }
                                    }
                                    .eraseToAnyPublisher()
                                })
                                .flatMap { (nonce) -> AnyPublisher<TxPackage, PostingError> in
                                    print("STEP 3")
                                    return Future<TxPackage, PostingError> { promise in
                                        self.transactionService.prepareTransactionForNewContractWithGasEstimate(
                                            contractABI: purchaseABI2,
                                            bytecode: purchaseBytecode2,
                                            value: price,
                                            nonce: nonce.advanced(by: 1),
                                            promise: promise
                                        )
                                    }
                                    .eraseToAnyPublisher()
                                }
                                .flatMap { (txPackage2) -> AnyPublisher<[TxPackage], PostingError> in
                                    txPackageArr.append(txPackage2)
                                    return Future<[TxPackage], PostingError> { promise in
                                        print("STEP 4")
                                        self.transactionService.calculateTotalGasCost(with: txPackageArr, promise: promise)
                                        let update: [String: PostProgress] = ["update": .estimatGas]
                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    }
                                    .eraseToAnyPublisher()
                                }
                                // execute the transactions and get the receipts in an array
                                .flatMap { (txPackages) -> AnyPublisher<[TxResult], PostingError> in
                                    let update: [String: PostProgress] = ["update": .deployingEscrow]
                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                    
                                    print("STEP 5")
                                    let results = txPackages.map { self.transactionService.executeTransaction(transaction: $0.transaction, password: password, type: $0.type) }
                                    return Publishers.MergeMany(results)
                                        .collect()
                                        .eraseToAnyPublisher()
                                }
                                // instantiate the socket, parse the receipts, and create the firebase entry as soon as the socket receives the data
                                // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
                                .flatMap { (txResults) -> AnyPublisher<Int, PostingError> in
                                    var topicsRetainer: [String]!
                                    return Future<[String: Any], PostingError> { promise in
                                        print("STEP 6")
                                        self.socketDelegate.promise = promise
                                    }
                                    .flatMap({ (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
                                        let update: [String: PostProgress] = ["update": .minting]
                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                        
                                        if let topics = webSocketMessage["topics"] as? [String] {
                                            topicsRetainer = topics
                                        }
                                        // upload images/files to the Firebase Storage and get the array of URLs
                                        if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
                                            print("STEP 7")
                                            let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                                                return Future<String?, PostingError> { promise in
                                                    self.uploadFileWithPromise(
                                                        fileURL: previewData.filePath,
                                                        userId: self.userId,
                                                        promise: promise
                                                    )
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
                                        print("STEP 8")
                                        
                                        return Future<Int, PostingError> { promise in
                                            self.transactionService.createFireStoreEntry(
//                                                documentId: &self.documentId,
                                                senderAddress: senderAddress,
                                                escrowHash: escrowHash,
                                                auctionHash: "N/A",
                                                mintHash: mintHash,
                                                itemTitle: mintParameters.itemTitle,
                                                desc: mintParameters.desc,
                                                price: price,
                                                category: mintParameters.category,
                                                tokensArr: mintParameters.tokensArr,
                                                convertedId: mintParameters.convertedId,
                                                type: "tangible",
                                                deliveryMethod: mintParameters.deliveryMethod,
                                                saleFormat: mintParameters.saleFormat,
                                                paymentMethod: mintParameters.paymentMethod,
                                                topics: topicsRetainer,
                                                urlStrings: urlStrings,
                                                ipfsURLStrings: [],
                                                shippingInfo: self.shippingInfo,
                                                promise: promise
                                            )
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .eraseToAnyPublisher()
                                } // socket delegate
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            self.processFailure(error)
                                        case .finished:
                                            // update the progress indicator
                                            let update: [String: PostProgress] = ["update": .images]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                            
                                            FirebaseService.shared.sendToTopicsVoid(
                                                title: "New item has been listed on \(mintParameters.category)",
                                                content: mintParameters.itemTitle,
                                                topic: mintParameters.category,
                                                docId: self.documentId
                                            )
                                            
                                            // index Core Spotlight
                                            self.indexSpotlight(
                                                itemTitle: mintParameters.itemTitle,
                                                desc: mintParameters.desc,
                                                tokensArr: mintParameters.tokensArr,
                                                convertedId: mintParameters.convertedId
                                            )
                                            
                                            // reset the fields
                                            self.afterPostReset()
                                    }
                                } receiveValue: { (receivedValue) in
                                    print("receivedValue", receivedValue)
                                    self.socketDelegate.disconnectSocket()
                                }
                                .store(in: &self.storage)
                                
                            }) // progress modal
                        }) // alert VC dismissal
                    } // main VC button action
                    self?.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    // MARK: - Direct Sale
//    override func mint() {
//        print("let's mint")
//        let mintParameters = MintParameters(
//            price: "0.00000000000002",
//            itemTitle: "Pogo stick",
//            desc: "Very springy",
//            category: "Electronics",
//            convertedId: "lsdjfkldjldi2",
//            tokensArr: ["hello"] as Set<String>,
//            userId: userDefaults.string(forKey: "userId")!,
//            deliveryMethod: DeliveryMethod.inPerson.rawValue,
//            saleFormat: SaleFormat.onlineDirect.rawValue,
//            paymentMethod: PaymentMethod.directTransfer.rawValue
//        )
//
//
//
//        deploySimplePaymentContract(password: "111111", mintParamters: mintParameters) { [weak self] (txResult) in
//            guard let tx = txResult.first else { return }
//            Future<TransactionReceipt, PostingError> { promise in
//                Web3swiftService.getReceipt(hash: tx.txResult.hash, promise: promise)
//            }
//            .eraseToAnyPublisher()
//            .retryIfWithDelay(
//                retries: 5,
//                delay: .seconds(5),
//                scheduler: RunLoop.main
//            ) { (error) -> Bool in
//                // the tx hash returns no receipt right after the transaction
//                // retry if none returns, but with delay
//                print("error in retryIfWithDelay", error)
//                if case let PostingError.generalError(reason: msg) = error,
//                   msg == "Invalid value from Ethereum node" {
//                    return true
//                }
//                return false
//            }
//            .sink { (completion) in
//                print(completion)
//            } receiveValue: { (bool) in
//                print(bool)
//            }
//            .store(in: &self!.storage)
//        }
//    }
    
    // MARK: - processDirectSale
    final override func processDirectSale(_ mintParameters: MintParameters) {
        guard let price = mintParameters.price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
            return
        }
        
        guard let NFTrackAddress = NFTrackAddress else {
            self.alert.showDetail("Sorry", with: "There was an error loading the minting contract address.", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                titleString: "",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                titleString: "Transaction Options",
                body: [AlertModalDictionary.gasLimit: "", AlertModalDictionary.gasPrice: "", AlertModalDictionary.nonce: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner {
            DispatchQueue.main.async {
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let self = self else { return }
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                            return
                        }
                        
                        self.dismiss(animated: true, completion: {
                            self.progressModal = ProgressModalViewController(postType: .tangible)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                self.socketDelegate = SocketDelegate(contractAddress: NFTrackAddress)
                                // Deploy a simple payment contract, mint a token, and transfer it into the contract.
                                self.deploySimplePaymentContract(password: password, mintParamters: mintParameters) { (txResults) in
                                    guard let txResult = txResults.first else { return }
                                    // confirm that the receipt of the transaction is obtained
                                    self.transactionService.confirmReceipt(txHash: txResult.txResult.hash)
                                        .sink { (completion) in
                                            print(completion)
                                        } receiveValue: { (receipt) in
                                            print(receipt)
                                            // confirm that the block is added to the chain
                                            self.transactionService.confirmTransactions(receipt)
                                                .sink(receiveCompletion: { (completion) in
                                                    print(completion)
                                                }, receiveValue: { (receipt) in
                                                    // mint a new token and transfer it to the payment contract
                                                    self.mintAndTransfer(receipt, password: password, mintParameters: mintParameters)
                                                })
                                                .store(in: &self.storage)
                                        }
                                        .store(in: &self.storage)
                                } // deploySimplePaymentcontract
                            }) // self.present for ProgressModalVC
                        }) // self.dismiss
                    } //buttonAction
                } // alertVC.Action
                self.present(alertVC, animated: true, completion: nil)
            } // DispatchQueue
        } // hideSpinner
    } // processDirectSale
    
    // MARK: - processEscrowResale
    override func processEscrowResale(_ mintParameters: MintParameters) {
        guard let price = mintParameters.price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
            return
        }
        
        // Since no new token is being minted, an existing token is used from the original post.
        guard let tokenId = post?.tokenID else {
            self.alert.showDetail("Sorry", with: "Failed to load the Token ID for the current item.", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                titleString: "",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                titleString: "Transaction Options",
                body: [AlertModalDictionary.gasLimit: "", AlertModalDictionary.gasPrice: "", AlertModalDictionary.nonce: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner {
            DispatchQueue.main.async { [weak self] in
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let self = self else { return }
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                            return
                        } // password guard
                        
                        self.dismiss(animated: true, completion: {
                            self.progressModal = ProgressModalViewController(postType: .tangible)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                // Prepare a transaction to deploy the escrow contract
                                Future<WriteTransaction, PostingError> { promise in
                                    self.transactionService.prepareTransactionForNewContract(
                                        contractABI: purchaseABI2,
                                        bytecode: purchaseBytecode2,
                                        value: price,
                                        promise: promise
                                    )
                                }
                                .eraseToAnyPublisher()
                                .flatMap { (transaction) -> AnyPublisher<TxResult, PostingError> in
                                    // deploy the escrow contract
                                    return self.transactionService.executeTransaction(transaction: transaction, password: password, type: .deploy)
                                        .eraseToAnyPublisher()
                                }
                                .flatMap { (txResult) -> AnyPublisher<Bool, PostingError> in
                                    return self.uploadFilesResale()
                                        // upload the details to Firestore
                                        .flatMap { (urlStrings) -> AnyPublisher<Bool, PostingError> in
                                            return Future<Bool, PostingError> { promise in
                                                self.transactionService.createFireStoreEntryForResale(
                                                    documentId: &self.documentId,
                                                    senderAddress: txResult.senderAddress,
                                                    escrowHash: txResult.txHash,
                                                    auctionHash: "N/A",
                                                    mintHash: "Resale",
                                                    itemTitle: mintParameters.itemTitle,
                                                    desc: mintParameters.desc,
                                                    price: price,
                                                    category: mintParameters.category,
                                                    tokensArr: mintParameters.tokensArr,
                                                    convertedId: mintParameters.convertedId,
                                                    type: "tangible",
                                                    deliveryMethod: mintParameters.deliveryMethod,
                                                    saleFormat: mintParameters.saleFormat,
                                                    paymentMethod: mintParameters.paymentMethod,
                                                    tokenId: tokenId,
                                                    urlStrings: urlStrings,
                                                    ipfsURLStrings: [],
                                                    shippingInfo: self.shippingInfo,
                                                    promise: promise
                                                )
                                            }
                                            .eraseToAnyPublisher()
                                        }
                                        .eraseToAnyPublisher()
                                }
                                .sink { (completion) in
                                    switch completion {
                                        case .failure(let error):
                                            self.processFailure(error)
                                        case .finished:
                                            // update the progress indicator
                                            let update: [String: PostProgress] = ["update": .images]
                                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                            
                                            FirebaseService.shared.sendToTopicsVoid(
                                                title: "New item has been listed on \(mintParameters.category)",
                                                content: mintParameters.itemTitle,
                                                topic: mintParameters.category,
                                                docId: self.documentId
                                            )
                                            
                                            // index Core Spotlight
                                            //                                            self.indexSpotlight(
                                            //                                                itemTitle: itemTitle,
                                            //                                                desc: desc,
                                            //                                                tokensArr: tokensArr,
                                            //                                                convertedId: convertedId
                                            //                                            )
                                            
                                            self.afterPostReset()

                                    }
                                } receiveValue: { (_) in
                                    
                                }
                                .store(in: &self.storage)
                                
                            }) // self.present(self.progressModal
                        }) // dismiss
                    } // mainVC.buttonAction
                } // alertVC.action
                self?.present(alertVC, animated: true, completion: nil)
            } // DispatchQueue
        }// self.hideSpinner
    } // processEscrowResale
}

extension PostViewController {
    // MARK: - afterPostReset
    func afterPostReset() {
        // reset the fields
        DispatchQueue.main.async {
            self.titleTextField.text?.removeAll()
            self.priceTextField.text?.removeAll()
            self.descTextView.text?.removeAll()
            self.idTextField.text?.removeAll()
            self.deliveryMethodLabel.text?.removeAll()
            self.pickerLabel.text?.removeAll()
            self.tagTextField.tokens.removeAll()
            self.paymentMethodLabel.text?.removeAll()
            self.addressLabel.text?.removeAll()
            self.addressLabelConstraintHeight.constant = 0
            self.addressTitleLabel.alpha = 0
            self.addressLabel.alpha = 0
            self.addressLabel.isUserInteractionEnabled = false
            self.addressTitleLabelConstraintHeight.constant = 0
            self.addressLabelConstraintHeight.constant = 0
        }
        
        // remove the image and file previews
        if self.previewDataArr.count > 0 {
            self.previewDataArr.removeAll()
            self.imagePreviewVC.data.removeAll()
            DispatchQueue.main.async {
                self.imagePreviewVC.collectionView.reloadData()
            }
        }
    }
    
    // MARK: - processFailure
    func processFailure(_ error: PostingError) {
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
                self.alert.showDetail("Account Retrieval Error", with: "Error retrieving your account address. Please ensure that you're logged into your wallet.", for: self)
            case .createTransactionIssue:
                self.alert.showDetail("Error", with: "There was an error creating a transaction.", for: self)
            case .insufficientFund(let msg):
                self.alert.showDetail("Error", with: msg, height: 500, fieldViewHeight: 300, alignment: .left, for: self)
            case .emptyAmount:
                self.alert.showDetail("Error", with: "The ETH value cannot be blank for the transaction.", for: self)
            case .invalidAmountFormat:
                self.alert.showDetail("Error", with: "The ETH value is in an incorrect format.", for: self)
            case .generalError(reason: let msg):
                self.alert.showDetail("Error", with: msg, for: self)
            default:
                self.alert.showDetail("Error", with: "There was an error creating your post.", for: self)
        }
    }
}

extension PostViewController {
    override var inputView: UIView? {
        switch pickerTag {
            case 1:
                return self.deliveryMethodPicker.inputView
            case 2:
                return self.pvc.inputView
            case 3:
                return self.paymentMothedPicker.inputView
            default:
                return nil
        }
    }
    
    @objc func doDone() { // user tapped button in accessory view
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch pickerTag {
            case 1:
                self.deliveryMethodLabel.text = deliveryMethodPicker.currentPep
            case 2:
                self.pickerLabel.text = pvc.currentPep
            case 3:
                self.paymentMethodLabel.text = paymentMothedPicker.currentPep
            default:
                break
        }
        self.resignFirstResponder()
        self.showKeyboard = false
    }
}
