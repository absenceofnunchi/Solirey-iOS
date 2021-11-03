//
//  PostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit

// for testing only
import web3swift
import Combine
import CryptoKit
import BigInt

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
        // When the DeliveryMethod is In Person Pickup, Category cannot be Digital
        // When the post is for resale,
        deliveryMethodObserver = deliveryMethodLabel.observe(\.text) { [weak self] (label, observedChange) in
            guard let text = label.text, let deliveryMethod = DeliveryMethod(rawValue: text) else { return }
            switch deliveryMethod {
                case .inPerson:
//                    self?.paymentMethodLabel.text = PaymentMethod.directTransfer.rawValue
                    self?.addressTitleLabel.text = "Pickup Location"
                    self?.isShipping = true
                    self?.paymentMethodLabel.isUserInteractionEnabled = true
                    self?.paymentMethodLabel.text = nil
                    self?.pvc = MyPickerVC(currentPep: Category.electronics.asString(), pep: Category.getTangibleResaleOptions())
                    self?.pickerLabel.text = self?.pickerLabel.text == Category.digital.asString() ? "" : self?.pickerLabel.text
                case .shipping:
//                    self?.paymentMethodLabel.text = PaymentMethod.escrow.rawValue
                    self?.addressTitleLabel.text = "Shipping Restriction"
                    self?.isShipping = true
                    self?.paymentMethodLabel.text = "Escrow"
                    self?.paymentMethodLabel.isUserInteractionEnabled = false
                    self?.pvc = MyPickerVC(currentPep: Category.electronics.asString(), pep: self?.post != nil ? Category.getTangibleResaleOptions() : Category.getAll())
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
        
        if self.socketDelegate != nil {
            self.socketDelegate.disconnectSocket()
        }
    }
    
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
    
    func test() {
        let price = "0.000000000000002"
        guard let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
  
        guard let NFTrackABIRevisedAddress = ContractAddresses.NFTrackABIRevisedAddress else {
            self.alert.showDetail("Error", with: "Unable to get the smart contract address.", for: self)
            return
        }
        
        // create an ID for the new item to be saved into the _simplePayment mapping.
        let combinedString = self.ref.document().documentID
        let inputData = Data(combinedString.utf8)
        let hashedId = SHA256.hash(data: inputData)
        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()
        
        let param: [AnyObject] = [priceInWei, hashString] as [AnyObject]

        self.socketDelegate = SocketDelegate(contractAddress: NFTrackABIRevisedAddress, topics: [Topics.SimplePaymentMint])
        
        Deferred {
            Future<WriteTransaction, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForWriting(
                    method: NFTrackContract.ContractMethods.createSimplePayment.rawValue,
                    abi: NFTrackABIRevisedABI,
                    param: param,
                    contractAddress: NFTrackABIRevisedAddress,
                    amountString: nil,
                    promise: promise
                )
            }
        }
        .flatMap { (transaction) -> AnyPublisher<TransactionSendingResult, PostingError> in
            let update: [String: PostProgress] = ["update": .estimatGas]
            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
            
            return Future<TransactionSendingResult, PostingError> { promise in
                do {
                    let receipt = try transaction.send(password: "111111", transactionOptions: nil)
                    
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
        // get the topics of the paymentMade event from the socket delegate
        .flatMap { [weak self] (txResult) -> AnyPublisher<BigUInt, PostingError> in
            // retain the mint transaction details for FireStore
            return Future<BigUInt, PostingError> { promise in
                self?.socketDelegate.didReceiveTopics = { webSocketMessage in
                    
                    guard let topics = webSocketMessage["topics"] as? [String] else { return }

                    let fromAddress = topics[2]
                    let paddedTokenId = topics[3]
                    
                    guard let tokenId = Web3Utils.hexToBigUInt(paddedTokenId) else {
                        promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
                        return
                    }
                    
                    let data = Data(hex: fromAddress)
                    guard let decodedFromAddress = ABIDecoder.decode(types: [.address], data:data)?.first as? EthereumAddress else {
                        promise(.failure(.generalError(reason: "Unable to decode the contract address.")))
                        return
                    }
                    
                    if decodedFromAddress == Web3swiftService.currentAddress {
                        promise(.success(tokenId))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        .sink { (completion) in
            print(completion)
        } receiveValue: { (finalValue) in
            print("finalValue", finalValue)
        }
        .store(in: &storage)
    }
        
    func test1() {
        let price = "0.0000000000002"
        guard !price.isEmpty,
              let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }

        guard let NFTrackABIRevisedAddress = ContractAddresses.NFTrackABIRevisedAddress else {
            self.alert.showDetail("Error", with: "Unable to get the smart contract address.", for: self)
            return
        }
        
        guard let userId = userId else {
            return
        }

        // create an ID for the new item to be saved into the _simplePayment mapping.
        let combinedString = self.ref.document().documentID + userId
        let inputData = Data(combinedString.utf8)
        let hashedId = SHA256.hash(data: inputData)
        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()

        let param: [AnyObject] = [priceInWei, hashString] as [AnyObject]
        
        Deferred {
            Future<WriteTransaction, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForWriting(
                    method: NFTrackContract.ContractMethods.createSimplePayment.rawValue,
                    abi: NFTrackABIRevisedABI,
                    param: param,
                    contractAddress: NFTrackABIRevisedAddress,
                    amountString: nil,
                    promise: promise
                )
            }
        }
        .flatMap { (transaction) -> AnyPublisher<TransactionSendingResult, PostingError> in
            let update: [String: PostProgress] = ["update": .estimatGas]
            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)

            return Future<TransactionSendingResult, PostingError> { promise in
                do {
                    let receipt = try transaction.send(password: "111111", transactionOptions: nil)
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
        .sink(receiveCompletion: { (completion) in
            switch completion {
                case .failure(let error):
                    self.processFailure(error)
                case .finished:
                    print("finished")
            }
        }, receiveValue: { (finalValue) in
            print("Final Value", finalValue)
        })
        .store(in: &self.storage)
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
}

extension PostViewController {
    final override var inputView: UIView? {
        switch pickerTag {
            case 1:
                return self.deliveryMethodPicker.inputView
            case 2:
                return self.pvc.inputView
            case 3:
                return self.paymentMethodPicker.inputView
            case 49:
                return self.contractFormatPicker.inputView
            default:
                return nil
        }
    }
    
    @objc final func doDone() { // user tapped button in accessory view
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch pickerTag {
            case 1:
                self.deliveryMethodLabel.text = deliveryMethodPicker.currentPep
            case 2:
                self.pickerLabel.text = pvc.currentPep
            case 3:
                self.paymentMethodLabel.text = paymentMethodPicker.currentPep
            case 49:
                self.smartContractFormatLabel.text = contractFormatPicker.currentPep
            default:
                break
        }
        self.resignFirstResponder()
        self.showKeyboard = false
    }
}
