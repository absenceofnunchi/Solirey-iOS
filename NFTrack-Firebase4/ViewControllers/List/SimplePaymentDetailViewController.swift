//
//  SimplePaymentDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-12.
//

/*
 Abstract:
 The list detail VC showing the SimplePayment details (other list detail VCs include the ListDetailVC, which is for the escrow payments, and the AuctionDetailVC, which is for the auction payment).
 The only unique aspect of this VC is that, unlike the aforementioned two, the VC could display both tangible and digital item (not at the same time). This entails that the navigation to edit has to be
 determined accordingly since the edit VC for digital items are limited in what it can edit.
 
 SimplePayment is the most succint form of payment where some level of counterparty risk is tolerated:
    1. The seller deploys the smart contract specifying the beneficiaries, such as the themselves, the admin, and the original artist, as well as the price of the item.
    2. The seller transfer the newly minted token into the smart contract (an existing one for the resale).
    3. The buyer purchases the item buying transferring the fund into the contract, tranferring the ownership of the token to him/herself, and also transferring the payout of the original artist if applicable.
    4. The seller withdraws the fund from the contract.
    5. The admin withdraws the fund
 
 Note:
 1. The SimplePaymentABI has to be changed to the SimplePaymentWithRoyaltyABI for resale in order for the original artists to be attributed.
 2. In order to promote the uniformity among the payment methods, the progress steps are a bit contrived. For example, the escrow progress include three steps: 1) purchase 2) transfer 3) receive.
    The simple payment technically only has 2 steps 1) purchase 2) withdraw. However, in order to show the uniform design in ListVC as well to repurpose the data fetch request to Firestore for escrow, I decided to include the transfer status for SimplePayment (as in PostStatus.transfer.rawValue used for escrow). The steps are 1) purchase 2) transfer 3) complete. Since the purchase and the transfer are done in 1 step, all of the progress nodes are going to be fulfilled at the same time. The progress bar will be shown in either the PurchasesVC or CollectFundsVC.
 3. The SimplePayment contract address hash is saved under escrowHash
 */

import UIKit
import web3swift
import Combine
import BigInt
import FirebaseFirestore

class SimplePaymentDetailViewController: ParentDetailViewController {
    final var historyVC: HistoryViewController!
    lazy final var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    private var payButton: UIButton!
    final lazy var isPending: Bool = false {
        didSet {
            if isPending == true {
                DispatchQueue.main.async { [weak self] in
                    self?.pendingIndicatorView.isHidden = false
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.pendingIndicatorView.isHidden = true
                }
            }
        }
    }
    
    private var pendingIndicatorView: PendingIndicatorView!
    private var simplePaymentContractAddress: EthereumAddress!
    private var activityIndicatorView: UIActivityIndicatorView!
    private var simplePaymentButtonController: SimplePaymentButtonController!
    private var db: Firestore! {
        return FirebaseService.shared.db
    }
    private var socketDelegate: SocketDelegate!
    
    init(deployedContractAddress: EthereumAddress) {
        super.init(nibName: nil, bundle: nil)
        self.simplePaymentContractAddress = deployedContractAddress
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final override func userInfoDidSet() {
        super.userInfoDidSet()
        
        guard let status = post.status,
              status != SimplePaymentStatus.complete.rawValue,
              status != SimplePaymentStatus.aborted.rawValue else { return }
        
        if userInfo.uid != userId {
            configureBuyerNavigationBar()
            fetchSavedPostData()
        } else if post.sellerUserId == userId {
            configureSellerNavigationBar()
        }
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        createSocket()
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // The deployment hash for the Simple Payment smart contract is saved under escrowHash.
        guard let escrowHash = post.escrowHash else { return }
        getContractInfo(
            transactionHash: escrowHash,
            executeReadTransaction: executeReadTransaction,
            contractAddress: simplePaymentContractAddress
        )
        
        // if the socket timed out, reconnect
        if let isSocketConnected = self.socketDelegate.socketProvider?.socket.isConnected,
           isSocketConnected == false {
            self.createSocket()
        }
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if socketDelegate != nil {
            socketDelegate.disconnectSocket()
        }
    }
    
    final override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if let container = container as? HistoryViewController {
            // the height of the child VC's view has to be increased accordingly since it's set to be unscrollable.
            // this is so that the child VC's view doesn't scroll independently of the parent VC's view.
            historyVCHeightConstraint.constant = container.preferredContentSize.height
            
            var adjustedSize: CGSize!
            if let files = post.files, files.count > 0 {
                adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1200)
            } else {
                adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 950)
            }
            
            self.scrollView.contentSize =  adjustedSize
        }
    }
    
    final override func configureSellerNavigationBar() {
        super.configureSellerNavigationBar()
        
        if self.navigationItem.rightBarButtonItems?.filter({ $0.tag == 11 }).count == 0 {
            self.postEditButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.buttonPressed(_:)))
            self.postEditButtonItem.tag = 11
            guard let postEditButtonItem = self.postEditButtonItem else { return }
            self.navigationItem.rightBarButtonItems?.append(postEditButtonItem)
        }
    }
}

extension SimplePaymentDetailViewController {
    final override func configureUI() {
        super.configureUI()
        title = post.title
        
        pendingIndicatorView = PendingIndicatorView()
        pendingIndicatorView.isHidden = true
        pendingIndicatorView.buttonAction = { [weak self] _ in
            let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Pending Transaction", detail: InfoText.pending)])
            self?.present(infoVC, animated: true, completion: nil)
        }
        pendingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pendingIndicatorView)
        
        payButton = UIButton()
        payButton.backgroundColor = .black
        payButton.layer.cornerRadius = 5
        payButton.isEnabled = false
        payButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        payButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(payButton)
        
        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        historyVC = HistoryViewController()
        historyVC.itemIdentifier = post.id
        addChild(historyVC)
        historyVC.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyVC.view)
        historyVC.didMove(toParent: self)
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            pendingIndicatorView.bottomAnchor.constraint(equalTo: listingSpecView.topAnchor, constant: -10),
            pendingIndicatorView.heightAnchor.constraint(equalTo: listDetailTitleLabel.heightAnchor, multiplier: 1.2),
            pendingIndicatorView.widthAnchor.constraint(equalToConstant: 100),
            pendingIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            payButton.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            payButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            payButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            payButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicatorView.centerYAnchor.constraint(equalTo: payButton.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: payButton.centerXAnchor),
            
            historyVC.view.topAnchor.constraint(equalTo: payButton.bottomAnchor, constant: 40),
            historyVC.view.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyVC.view.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            historyVCHeightConstraint,
        ])
    }
    
    @objc final override func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                callContractMethod(for: .pay)
                break
            case 1:
                callContractMethod(for: .withdraw)
                break
            case 2:
                callContractMethod(for: .withdrawFee)
                break
            case 3:
                callContractMethod(for: .abort)
                break
            case 4:
//                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Transaction Complete!", detail: InfoText.simplePaymentComplete)])
//                self.present(infoVC, animated: true, completion: nil)
                
                
                // sell
                let resaleVC = ResaleViewController()
                resaleVC.post = post
                resaleVC.title = "Resale"
                navigationController?.pushViewController(resaleVC, animated: true)
                break
            case 11:
                let category = Category(rawValue: post.category)
                switch category {
                    case .digital:
                        let listEditVC = DigitalListEditViewController()
                        listEditVC.post = post
                        self.navigationController?.pushViewController(listEditVC, animated: true)
                        break
                    default:
                        let listEditVC = TangibleListEditViewController()
                        listEditVC.delegate = self
                        listEditVC.post = post
                        listEditVC.userId = userId
                        self.navigationController?.pushViewController(listEditVC, animated: true)
                }
                break
            default:
                break
        }
    }
}

// MARK: - Fetch the contract info
extension SimplePaymentDetailViewController {
    private func getContractInfo(
        transactionHash: String,
        executeReadTransaction: @escaping (_ propertyFetchModel: inout SmartContractProperty, _ promise: (Result<SmartContractProperty, PostingError>) -> Void) -> Void,
        contractAddress: EthereumAddress
    ) {
        let simplePaymentInfoLoader = PropertyLoader<SimplePaymentContract>(
            propertiesToLoad: [SimplePaymentContract.ContractProperties.tokenAdded, SimplePaymentContract.ContractProperties.paid, SimplePaymentContract.ContractProperties.price],
            transactionHash: transactionHash,
            executeReadTransaction: executeReadTransaction,
            contractAddress: contractAddress,
            contractABI: simplePaymentABI
        )
        
        isPending = true
            simplePaymentInfoLoader.initiateLoadSequence()
            .sink { [weak self] (completion) in
                self?.isPending = false
                switch completion {
                    case .failure(.retrievingCurrentAddressError):
                        self?.alert.showDetail("Contract Address Error", with: "Unable to retrieve the current address of your wallet", for: self)
                    case .failure(.contractLoadingError):
                        self?.alert.showDetail("Contract Address Error", with: "Unable to load the current address of your wallet", for: self)
                    case .failure(.createTransactionIssue):
                        self?.alert.showDetail("Transaction Error", with: "Unable to create the transaction.", for: self)
                    case .failure(.generalError(reason: let msg)):
                        self?.alert.showDetail("Smart Contract Info Retrieval Error", with: msg, for: self)
                    case .finished:
                        DispatchQueue.main.async {
                            self?.payButton.isUserInteractionEnabled = true
                        }
                        break
                    default:
                        self?.alert.showDetail("Smart contract Info Retrieval Error", with: "Unable to fetch the contract information.", for: self)
                }
            } receiveValue: { [weak self] (propertyFetchModels: [SmartContractProperty]) in
                self?.parseFetchResultToDisplay(propertyFetchModels)
                self?.isPending = false

                // SimplePaymentButtonController configures the button and posts the resulting data here
                guard let tokenAdded = self?.simplePaymentButtonController.tokenAdded, tokenAdded == true else { return }

                if let status = self?.simplePaymentButtonController.configure() {
                    // abort, pay, withdraw, withdraw fee methods, all of which are the methods on the smart contract
                    self?.configureStatusButton(buttonTitle: status.methodName.0, tag: status.methodName.1)
                } else {
                    // If the status doesn't exist, it means the status isn't going to be any of the methods on the smart contract
                    // This is specifically for the buyer.
                    self?.configureStatusButton(buttonTitle: "Sell", tag: 4)
                }
            }
            .store(in: &self.storage)
    }
    
    private func executeReadTransaction(
        propertyFetchModel: inout SmartContractProperty,
        promise: (Result<SmartContractProperty, PostingError>) -> Void
    ) {
        do {
            guard let transaction = propertyFetchModel.transaction else {
                promise(.failure(.generalError(reason: "Unable to create a read transaction.")))
                return
            }
            
            let result: [String: Any] = try transaction.call()
            
            switch propertyFetchModel.propertyName {
                case SimplePaymentContract.ContractProperties.tokenAdded.value.0:
                    if let tokenAdded = result["0"] as? Bool {
                        propertyFetchModel.propertyDesc = tokenAdded
                        promise(.success(propertyFetchModel))
                    } else {
                        promise(.failure(.generalError(reason: "Unable to fetch the token status from the smart contract.")))
                    }
                    break
                case SimplePaymentContract.ContractProperties.paid.value.0:
                    if let paid = result["0"] as? Bool {
                        propertyFetchModel.propertyDesc = paid
                        promise(.success(propertyFetchModel))
                    } else {
                        promise(.failure(.generalError(reason: "Unable to fetch the payment status from the smart contract.")))
                    }
                case SimplePaymentContract.ContractProperties.price.value.0:
                    if let price = result["0"] as? BigUInt,
                       let priceInEth = Web3.Utils.formatToEthereumUnits(price, toUnits: .eth, decimals: 17) {
                        // remove the unnecessary zeros in the decimal
                        let trimmed = self.transactionService.stripZeros(priceInEth)
                        propertyFetchModel.propertyDesc = "\(trimmed) ETH"
                        promise(.success(propertyFetchModel))
                    } else {
                        promise(.failure(.generalError(reason: "Unable to fetch the price from the smart contract.")))
                    }
                default:
                    break
            }
        } catch {
            promise(.failure(.generalError(reason: "Unable to create a read transaction.")))
        }
    }
    
    private func parseFetchResultToDisplay(_ propertyFetchModels: [SmartContractProperty]) {
        var buttonConfig: [String: Any] = [:]
        propertyFetchModels.forEach { [weak self] (model) in
            DispatchQueue.main.async {
                self?.activityIndicatorView.stopAnimating()
            }
            
            switch model.propertyName {
                // Value is how the property is spelled on the smart contract and 0 since it's not mapping and doesn't require a key.
                case SimplePaymentContract.ContractProperties.tokenAdded.value.0:
                    guard let tokenAdded = model.propertyDesc as? Bool, tokenAdded == true else {
                        // The token should be added at the time of the deployment.
                        self?.alert.showDetail("Error", with: "The token for the item has not been added to the payment contract.", for: self)
                        return
                    }
                    
                    buttonConfig[SimplePaymentContract.ContractProperties.tokenAdded.value.0] = tokenAdded
                    break
                case SimplePaymentContract.ContractProperties.paid.value.0:
                    guard let paid = model.propertyDesc as? Bool else { return }
                    buttonConfig[SimplePaymentContract.ContractProperties.paid.value.0] = paid
                    break
                case SimplePaymentContract.ContractProperties.price.value.0:
                    guard let price = model.propertyDesc as? String else { return }
                    buttonConfig[SimplePaymentContract.ContractProperties.price.value.0] = price
                default:
                    break
            }
        }
        
        // Configures the button (i.e. Buy Now or Withdraw, etc) depending on the variables like "paid", "tokenAdded", etc.
        guard let tokenAdded = buttonConfig[SimplePaymentContract.ContractProperties.tokenAdded.value.0] as? Bool,
              let paid = buttonConfig[SimplePaymentContract.ContractProperties.paid.value.0] as? Bool,
              let price = buttonConfig[SimplePaymentContract.ContractProperties.price.value.0] as? String else { return }
        
        simplePaymentButtonController = SimplePaymentButtonController(
            post: post,
            userId: userId,
            tokenAdded: tokenAdded,
            paid: paid,
            price: price
        )
    }

    // MARK: - configureStatusButton
    private func configureStatusButton(buttonTitle: String, tag: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.payButton.tag = tag
            self?.payButton.isEnabled = true
            self?.payButton.setTitle(buttonTitle, for: .normal)
        }
    }
}

// MARK: - Call the contract methods
extension SimplePaymentDetailViewController {
    // Dynamically determine what Simple Payment contract method to call
    private func callContractMethod(for method: SimplePaymentContract.ContractMethods) {
        guard let currentAddressString = Web3swiftService.currentAddressString else {
            self.alert.showDetail("Wallet Info Required", with: "Please ensure that you're signed into your wallet.", for: self)
            return
        }
        
        guard let userId = self.userId else {
            self.alert.showDetail("User Info Required.", with: "Unable to retrieve the user info. Please sign out of the account and sign back in.", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                index: 0,
                titleString: "Password",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            )
        ]

        let alertVC = AlertViewController(height: 350, standardAlertContent: content)
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
                    self.showSpinner {
                        Deferred {
                            Future<WriteTransaction, PostingError> { promise in
                                guard let simplePaymentContractAddress = self.simplePaymentContractAddress else {
                                    promise(.failure(.generalError(reason: "Unable to load the address for the payment contract.")))
                                    return
                                }
    
                                // if the socket timed out, reconnect
                                if let isSocketConnected = self.socketDelegate.socketProvider?.socket.isConnected,
                                   isSocketConnected == false {
                                    self.createSocket()
                                }
                                
                                self.transactionService.prepareTransactionForWriting(
                                    method: method.rawValue,
                                    abi: simplePaymentABI, // The ABI has to be changed to the royalty one for resale
                                    contractAddress: simplePaymentContractAddress,
                                    amountString: method == .pay ? self.post.price : "0",
                                    promise: promise
                                )
                            }
                        }
                        .flatMap { (transaction) -> Future<TxResult, PostingError> in
                            self.transactionService.executeTransaction(
                                transaction: transaction,
                                password: password,
                                type: .simplePayment
                            )
                        }
                        .flatMap { (txResult) -> AnyPublisher<Data, PostingError> in
                            switch method {
                                case .abort:
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "status": SimplePaymentStatus.aborted.rawValue,
                                    ], completion: { (error) in
                                        if let error = error {
                                            print("firebase error", error)
                                        }
                                    })
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .pay:
                                    // All three dates have to be fulfilled because the nodes will show as completed in the purchased section.
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "status": SimplePaymentStatus.complete.rawValue,
                                        "confirmPurchaseDate": Date(),
                                        "transferDate": Date(),
                                        "buyerHash": currentAddressString,
                                        "buyerUserId": userId,
                                        "confirmReceivedDate": Date()
                                    ], completion: { (error) in
                                        if let error = error {
                                            print("firebase error", error)
                                        }
                                    })
                                    
                                    let content = "Your \(self.post.title ?? "item") was purchased by a buyer!"
                                    return FirebaseService.shared.sendNotification(
                                        sender: self.userId,
                                        recipient: self.post.sellerUserId,
                                        content: content,
                                        docID: self.post.documentId
                                    )
                                case .withdraw:
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "isWithdrawn": true
                                    ], completion: { (error) in
                                        if let error = error {
                                            print("firebase error", error)
                                        }
                                    })
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .withdrawFee:
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                            }
                        }
                        .sink { (completion) in
                            switch completion {
                                case .failure(let error):
                                    switch error {
                                        case .generalError(reason: let msg):
                                            self.alert.showDetail("Error", with: msg, for: self)
                                        case .apiError(.decodingError):
                                            self.alert.showDetail("Decoding Error", with: "There was a decoding error from HTTP's response.", for: self)
                                        case .apiError(.generalError(reason: let err)):
                                            self.alert.showDetail("Network Error", with: err, for: self)
                                        default:
                                            self.alert.showDetail("Error", with: "There was an error executing this process.", for: self)
                                    }
                                    break
                                case .finished:
                                    switch method {
                                        case .abort:
                                            self.alert.showDetail("Success!", with: "Your sale has been successfully aborted.", for: self)
                                        case .pay:
                                            self.alert.showDetail("Success!", with: "You have successfully purchased the item.", for: self)
                                        case .withdraw:
                                            self.alert.showDetail("Success!", with: "You have successfully withdrawn the fund.", for: self)
                                            self.configureStatusButton(buttonTitle: "Success!", tag: 100)
                                            DispatchQueue.main.async {
                                                self.navigationController?.popViewController(animated: true)
                                            }
                                        case .withdrawFee:
                                            self.alert.showDetail("Success!", with: "You have successfully collected the fee.", for: self)
                                    }
                                    break
                            }
                        } receiveValue: { (_) in
                            
                        }
                        .store(in: &self.storage)
                    }
                }) // self.dismiss for alertVC
            } // mainVC.buttonAction
        } // alertVC.action
        present(alertVC, animated: true, completion: nil)
    } // callContractMethod
}

extension SimplePaymentDetailViewController {
    private func createSocket() {
        guard let contractAddress = self.simplePaymentContractAddress else { return }
        
        Deferred {
            Future<[String:Any], PostingError> { [weak self] promise in
                self?.socketDelegate = SocketDelegate(contractAddress: contractAddress, promise: promise)
            }
        }
        .sink { (completion) in
            print(completion)
        } receiveValue: { [weak self] (WebSocketMessage) in
            guard let topics = WebSocketMessage["topics"] as? [String],
                  let txHash = WebSocketMessage["transactionHash"] as? String else { return }
            
            switch topics {
                case _ where topics.contains(Topics.SimplePaymentPurchased):
                    self?.isPending = true
                    self?.activityIndicatorView.startAnimating()
                    self?.payButton.isEnabled = false
                    self?.payButton.setTitle("", for: .normal)
                    guard let executeReadTransaction = self?.executeReadTransaction else { return }
                    self?.getContractInfo(transactionHash: txHash, executeReadTransaction: executeReadTransaction, contractAddress: contractAddress)
                default:
                    print("other events")
            }
        }
        .store(in: &storage)
    }
}
