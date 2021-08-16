//
//  ListDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import web3swift
import Firebase
import FirebaseFirestore
import Combine

class ListDetailViewController: ParentDetailViewController {
    final override var post: Post! {
        didSet {
            self.getStatus()
        }
    }
    final var optionsBarItem: UIBarButtonItem!
    private var statusTitleLabel: UILabel!
    final var statusLabel: UILabelPadding!
    final var updateStatusButton = UIButton()
    final var activityIndicatorView: UIActivityIndicatorView!
    final var userId: String! {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId)
    }
    
    // history table view below the status update button
//    final var historyTableViewHeight: CGFloat! = 0
//    final var historyTableView: UITableView!
//    final lazy var historyTableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: HistoryCell.self, identifier: HistoryCell.identifier)
//    final var historicData = [Post]()
//    final let CELL_HEIGHT: CGFloat = 100
    final var historyVC: HistoryViewController!
    lazy var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)

    final var isSaved: Bool! = false {
        didSet {
            configureNavigationBar()
        }
    }
    final var chatButtonItem: UIBarButtonItem!
    final var starButtonItem: UIBarButtonItem!
    weak var delegate: RefetchDataDelegate?
    final var observation: NSKeyValueObservation?
    final var storage = Set<AnyCancellable>()
    private var socketDelegate: SocketDelegate!

    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if observation != nil {
            observation?.invalidate()
        }
        
        if let isSocketConnected = self.socketDelegate.socketProvider?.socket.isConnected,
           isSocketConnected == false {
            self.createSocket()
        }
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if observation != nil {
            observation?.invalidate()
        }
        
        if socketDelegate != nil {
            socketDelegate.disconnectSocket()
        }
    }
    
//    final override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        var contentHeight: CGFloat!
//        if let files = post.files, files.count > 0 {
//            contentHeight = descLabel.bounds.size.height + 800 + historyTableViewHeight + 250
//        } else {
//            contentHeight = descLabel.bounds.size.height + 800 + historyTableViewHeight
//        }
//
//        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: contentHeight)
//    }
    
    final override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if let container = container as? HistoryViewController {
            historyVCHeightConstraint.constant = container.preferredContentSize.height            
            if let files = post.files, files.count > 0 {
                let adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1000 + 250 )
                self.scrollView.contentSize =  adjustedSize
            } else {
                let adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1000 )
                self.scrollView.contentSize =  adjustedSize
            }
        }
    }
    
    final override func userInfoDidSet() {
        super.userInfoDidSet()
        if userInfo.uid != userId {
            configureNavigationBar()
            fetchSavedPostData()
        }
    }
}

extension ListDetailViewController {
    final func fetchSavedPostData() {
        if let savedBy = post.savedBy, savedBy.contains(userId) {
            isSaved = true
        } else {
            isSaved = false
        }
    }
    
    final func configureNavigationBar() {
        guard let chatImage = UIImage(systemName: "message"),
              let starImage = UIImage(systemName: "star"),
              let starImageFill = UIImage(systemName: "star.fill") else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        var buttonItemsArr = [UIBarButtonItem]()
        chatButtonItem = UIBarButtonItem(image: chatImage.withTintColor(.gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed))
        chatButtonItem.tag = 6
        buttonItemsArr.append(chatButtonItem)
        
        let finalImage = isSaved ? starImageFill : starImage
        starButtonItem = UIBarButtonItem(image: finalImage.withTintColor(isSaved ? .red : .gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed))
        starButtonItem.tag = 7
        buttonItemsArr.append(starButtonItem)
        
        self.navigationItem.rightBarButtonItems = buttonItemsArr
    }
    
    final override func configureUI() {
        super.configureUI()
        title = post.title
        
        statusTitleLabel = UILabel()
        statusTitleLabel.text = "Status"
        statusTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(statusTitleLabel)
        
        statusLabel = UILabelPadding()
        statusLabel.layer.borderColor = UIColor.lightGray.cgColor
        statusLabel.layer.borderWidth = 0.5
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(statusLabel)
        
        updateStatusButton.backgroundColor = .black
        updateStatusButton.isEnabled = false
        updateStatusButton.layer.cornerRadius = 5
        updateStatusButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        updateStatusButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(updateStatusButton)
        
        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        updateStatusButton.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        historyVC = HistoryViewController()
        historyVC.itemIdentifier = post.id
        addChild(historyVC)
        historyVC.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyVC.view)
        historyVC.didMove(toParent: self)
    }
    
    final override func setConstraints() {
        super.setConstraints()
        NSLayoutConstraint.activate([
            statusTitleLabel.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            statusTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 50),
            
            updateStatusButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            updateStatusButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            updateStatusButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            updateStatusButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicatorView.centerYAnchor.constraint(equalTo: updateStatusButton.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: updateStatusButton.centerXAnchor),
            
            historyVC.view.topAnchor.constraint(equalTo: updateStatusButton.bottomAnchor, constant: 40),
            historyVC.view.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyVC.view.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            historyVCHeightConstraint,
        ])
    }
}

extension ListDetailViewController {
    // MARK: - buttonPressed
    @objc final func buttonPressed(_ sender: UIButton!) {
        switch sender.tag {
            case 1:
                // abort by the seller
                updateState(method: PurchaseMethods.abort.methodName, status: .aborted)
            case 2:
                // confirm purchase or "buy"
                updateState(method: PurchaseMethods.confirmPurchase.methodName, price: String(post.price), status: .pending)
            case 3:
                // confirm received
                updateState(method: PurchaseMethods.confirmReceived.methodName, status: .complete)
            case 4:
                // sell
                let resellVC = ResellViewController()
                resellVC.modalPresentationStyle = .fullScreen
                resellVC.post = post
                self.present(resellVC, animated: true, completion: nil)
            case 5:
                // transfer ownership
                guard let post = post else { return }
                transferToken(post: post)
            case 6:
                let chatVC = ChatViewController()
                chatVC.userInfo = userInfo
                chatVC.post = post
                // to display the title on ChatList when multiple items under the same owner
                // or maybe search for pre-existing chat room first and join the same one
                // chatVC.itemName = title
                self.navigationController?.pushViewController(chatVC, animated: true)
            case 7:
                // saving the favourite post
                isSaved = !isSaved
                FirebaseService.shared.db.collection("post").document(post.documentId).updateData([
                    "savedBy": isSaved ? FieldValue.arrayUnion(["\(userId!)"]) : FieldValue.arrayRemove(["\(userId!)"])
                ]) {(error) in
                    if let error = error {
                        self.alert.showDetail("Sorry", with: error.localizedDescription, for: self) { [weak self] in
                            DispatchQueue.main.async {
                                self?.navigationController?.popViewController(animated: true)
                            }
                        } completion: {}
                    } else {
                        self.delegate?.didFetchData()
                    }
                }
            case 8:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.transferPending)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 9:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.receiptPending)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 10:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.transferCompleted)])
                self.present(infoVC, animated: true, completion: nil)
                break
            default:
                break
        }
    }
    
    // MARK: - configureStatusButton
    final func configureStatusButton(buttonTitle: String = "Buy", tag: Int = 2) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusButton.tag = tag
            self?.updateStatusButton.isEnabled = true
            self?.updateStatusButton.setTitle(buttonTitle, for: .normal)
        }
    }
}

extension ListDetailViewController {
    final func updateState(method: String, price: String = "0", status: PostStatus? = nil) {
        transactionService.prepareTransactionForWriting(method: method, abi: purchaseABI2, contractAddress: contractAddress, amountString: price) { [weak self](transaction, error) in
            if let error = error {
                switch error {
                    case .invalidAmountFormat:
                        self?.alert.showDetail("Error", with: "The ETH amount is not in a correct format!", for: self)
                    case .zeroAmount:
                        self?.alert.showDetail("Error", with: "The ETH amount cannot be negative", for: self)
                    case .insufficientFund:
                        self?.alert.showDetail("Error", with: "There is an insufficient amount of ETH in the wallet.", for: self)
                    case .contractLoadingError:
                        self?.alert.showDetail("Error", with: "There was an error loading your contract.", for: self)
                    case .createTransactionIssue:
                        self?.alert.showDetail("Error", with: "There was an error creating the transaction.", for: self)
                    default:
                        self?.alert.showDetail("Sorry", with: "There was an error. Please try again.", for: self)
                }
            }
            
            if let transaction = transaction {
                let content = [
                    StandardAlertContent(
                        titleString: AlertModalDictionary.passwordTitle,
                        body: [AlertModalDictionary.passwordSubtitle: ""],
                        isEditable: true,
                        fieldViewHeight: 50,
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton
                    )
                ]
                
                DispatchQueue.main.async {
                    let alertVC = AlertViewController(standardAlertContent: content)
                    alertVC.action = { (modal, mainVC) in
                        mainVC.buttonAction = { _ in
                            guard  let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                                   !password.isEmpty else {
                                self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                                return
                            }
                            
                            self?.dismiss(animated: true, completion: {
                                self?.showSpinner {
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        do {
                                            let result = try transaction.send(password: password, transactionOptions: nil)
                                            if let status = status {
                                                switch status {
                                                    case .ready:
                                                        break
                                                    case .pending:
                                                        /// tag 2
                                                        /// confirmedPurchase
                                                        let buyerHash = Web3swiftService.currentAddressString
                                                        FirebaseService.shared.db.collection("post").document(self!.post.documentId).updateData([
                                                            "status": status.rawValue,
                                                            "buyerHash": buyerHash ?? "NA",
                                                            "buyerUserId": self?.userId ?? "NA",
                                                            "\(method)Hash": result.hash,
                                                            "\(method)Date": Date()
                                                        ], completion: { (error) in
                                                            if let error = error {
                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                            } else {
                                                                /// send the push notification to the seller
                                                                guard let `self` = self else { return }
                                                                self.sendNotification(sender: self.userId, recipient: self.post.sellerUserId, content: "Your item has been purchased!", docID: self.post.documentId) { [weak self] (error) in
                                                                    if let error = error {
                                                                        print("error", error)
                                                                    }
                                                                    
                                                                    self?.alert.showDetail("Success!", with: "You have confirmed the purchase as buyer. Your ether will be locked until you confirm receiving the item.", alignment: .left, for: self, completion:  {
                                                                        self?.getStatus()
                                                                        self?.navigationController?.popViewController(animated: true)
                                                                    })
                                                                }
                                                            }
                                                        })
                                                    case .complete:
                                                        /// tag 3
                                                        /// confirmRecieved
                                                        FirebaseService.shared.db.collection("post").document(self!.post.documentId).updateData([
                                                            "status": status.rawValue,
                                                            "\(method)Hash": result.hash,
                                                            "\(method)Date": Date()
                                                        ], completion: { (error) in
                                                            if let error = error {
                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                                            } else {
                                                                /// send the push notification to the seller
                                                                guard let `self` = self else { return }
                                                                self.sendNotification(sender: self.userId, recipient: self.post.sellerUserId, content: "Your item has been received by the buyer!", docID: self.post.documentId) { [weak self] (error) in
                                                                    if let error = error {
                                                                        print("error", error)
                                                                    }
                                                                    self?.alert.showDetail("Success!", with: "You have confirmed that you recieved the item. Your ether will be released back to your account.", alignment: .left, for: self, completion:  {
                                                                        self?.tableViewRefreshDelegate?.didRefreshTableView(index: 2)
                                                                        self?.navigationController?.popViewController(animated: true)
                                                                    })
                                                                }
                                                            }
                                                        })
                                                    case .aborted:
                                                        FirebaseService.shared.db.collection("post").document(self!.post.documentId).delete() { err in
                                                            if let err = err {
                                                                self?.alert.showDetail("Error", with: err.localizedDescription, for: self)
                                                            } else {
                                                                self?.alert.showDetail("Success!", with: "You have aborted the escrow. The deployed contract is now locked and your ether will be sent back to your account.", for: self, completion:  {
                                                                    self?.tableViewRefreshDelegate?.didRefreshTableView(index: 3)
                                                                    self?.navigationController?.popViewController(animated: true)
                                                                })
                                                            }
                                                        }
                                                    default:
                                                        break
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
                                                self?.alert.showDetail("Alert", with: "Failed to sign the transaction. You may be using an incorrect password. \n\nOtherwise, please try logging out of your wallet (not the NFTrack account) and logging back in. Ensure that you remember the password and the private key.", height: 400, alignment: .left, for: self)
                                            }
                                        } catch Web3Error.processingError(let desc) {
                                            DispatchQueue.main.async {
                                                self?.alert.showDetail("Alert", with: desc, height: 320, for: self)
                                            }
                                        } catch {
                                            if let index = error.localizedDescription.firstIndex(of: "(") {
                                                let newStr = error.localizedDescription.prefix(upTo: index)
                                                self?.alert.showDetail("Alert", with: String(newStr), for: self)
                                            }
                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                        }
                                    }
                                }
                            })
                        } // mainVC button action
                    } // alertVC
                    self?.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
}

extension ListDetailViewController {
    final func transferToken(post: Post) {
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
                titleString: "Transaction Options",
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
        
        var documentRetainer: DocumentSnapshot!
        
        let alertVC = AlertViewController(height: 400, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            // responses to the main vc's button
            mainVC.buttonAction = { _ in
                guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                      !password.isEmpty else {
                    self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                    return
                }
                
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner({
                        Future<[AnyObject], PostingError> { promise in
                            let docRef = FirebaseService.shared.db.collection("post").document(post.documentId)
                            docRef.getDocument { (document, error) in
                                if let document = document,
                                   document.exists,
                                   let data = document.data() {
                                    
                                    documentRetainer = document
                                    var buyerHash: String!
                                    var tokenId: String!
                                    data.forEach { (item) in
                                        switch item.key {
                                            case "buyerHash":
                                                buyerHash = item.value as? String
                                            case "tokenId":
                                                tokenId = item.value as? String
                                            default:
                                                break
                                        }
                                    }
                                    
                                    guard let bh = buyerHash else {
                                        promise(.failure(.generalError(reason: "The item has not been purchased by a buyer yet.")))
                                        return
                                    }
                                    
                                    guard let ti = tokenId else {
                                        promise(.failure(.generalError(reason: "The item does not have token ID registered. It may take up to 10 mins to process.")))
                                        return
                                    }
                                    
                                    guard let fromAddress = Web3swiftService.currentAddress,
                                          let toAddress = EthereumAddress(bh) else {
                                        promise(.failure(.generalError(reason: "Could not get the contract address to transfer the token.")))
                                        return
                                    }

                                    let param: [AnyObject] = [fromAddress, toAddress, ti] as [AnyObject]
                                    promise(.success(param))
                                }
                            }
                        }
                        .eraseToAnyPublisher()
                        .flatMap { [weak self] (param) -> AnyPublisher<WriteTransaction, PostingError> in
                            guard let NFTrackAddress = NFTrackAddress else {
                                return Fail(error: PostingError.generalError(reason: "Unable to load the contract address."))
                                    .eraseToAnyPublisher()
                            }
                            return Future<WriteTransaction, PostingError> { promise in
                                self?.transactionService.prepareTransactionForWriting(
                                    method: "transferFrom",
                                    abi: NFTrackABI,
                                    param: param,
                                    contractAddress: NFTrackAddress,
                                    promise: promise)
                            }
                            .eraseToAnyPublisher()
                        }
                        .flatMap { (transaction) -> AnyPublisher<TransactionSendingResult, PostingError> in
                            Future<TransactionSendingResult, PostingError> { promise in
                                do {
                                    let receipt = try transaction.send(password: password, transactionOptions: nil)
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
                        .flatMap { (result) -> AnyPublisher<Bool, PostingError> in
                            Future<Bool, PostingError> { promise in
                                FirebaseService.shared.db.collection("post").document(documentRetainer.documentID).updateData([
                                    "transferHash": result.hash,
                                    "transferDate": Date(),
                                    "status": PostStatus.transferred.rawValue
                                ], completion: { (error) in
                                    if let error = error {
                                        promise(.failure(.generalError(reason: error.localizedDescription)))
                                    } else {
                                        /// send the push notification to the seller
                                        guard let `self` = self, let buyerUserId = self.post.buyerUserId else {
                                            return promise(.failure(.generalError(reason: "Unable to get the buyer's hash.")))
                                        }
                                        
                                        self.sendNotification(
                                            sender: self.userId,
                                            recipient: buyerUserId,
                                            content: "The seller has transferred the item!",
                                            docID: self.post.documentId
                                        ) { (error) in
                                            if let error = error {
                                                print("notification error", error.localizedDescription)
                                            }
                                            
                                            promise(.success(true))
                                        }
                                    }
                                })
                            }
                            .eraseToAnyPublisher()
                        }
                        .sink { [weak self] (completion) in
                            switch completion {
                                case .failure(let error):
                                    switch error {
                                        case .generalError(reason: let reason):
                                            self?.alert.showDetail("Error", with: reason, for: self)
                                        case .emptyAmount:
                                            self?.alert.showDetail("Error", with: "The amount cannot be empty.", for: self)
                                        case .invalidAmountFormat:
                                            self?.alert.showDetail("Error", with: "Invalid amount format.", for: self)
                                        case .contractLoadingError:
                                            self?.alert.showDetail("Error", with: "Unable to load the contract.", for: self)
                                        case .createTransactionIssue:
                                            self?.alert.showDetail("Error", with: "Unable to create a transaction.", for: self)
                                        default:
                                            self?.alert.showDetail("Error", with: "There was an error transferring the item.", for: self)
                                    }
                                    break
                                case .finished:
                                    self?.hideSpinner({
                                        print("finished")
                                    })
                                    break
                            }
                        } receiveValue: { (isFinished) in
                            self?.tableViewRefreshDelegate?.didRefreshTableView(index: 1)
                            self?.navigationController?.popViewController(animated: true)
                        }
                        .store(in: &self!.storage)
                    })
                 })
            }
        }
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension ListDetailViewController {
    /// sender, recipient: firebase userId
    /// content: the message to be show on the push notification
    /// docID: the ID that'll be used to fetch the firebase entry once the recipient taps on the message
    /// Post is not sent along with the message because 1) it's a class and 2) FCM only allows strings in the properties
    final func sendNotification(sender: String, recipient: String, content: String, docID: String, completion: @escaping (Error?) -> Void) {
        // build request URL
        guard let requestURL = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/sendStatusNotification-sendStatusNotification") else {
            return
        }
//        guard let requestURL = URL(string: "http://localhost:5001/nftrack-69488/us-central1/sendStatusNotification-sendStatusNotification") else {
//            return
//        }
        
        // prepare request
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        print("sender", sender)
        print("recipient", recipient)
        print("content", content)
        print("docID", docID)
        let parameter: [String: Any] = [
            "sender": sender,
            "recipient": recipient,
            "content": content,
            "docID": docID
        ]
        
        let paramData = try? JSONSerialization.data(withJSONObject: parameter, options: [])
        request.httpBody = paramData
        
        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (_, response, error) -> Void in
            if let error = error {
                completion(error)
            }
            
            if let response = response as? HTTPURLResponse {
                print("response", response)
                
                let httpStatusCode = APIError.HTTPStatusCode(rawValue: response.statusCode)
                completion(httpStatusCode)
                
                //                if !(200...299).contains(response.statusCode) {
                //                    print("start1")
                //                    // handle HTTP server-side error
                //                }
            }
        })
        
        observation = task.progress.observe(\.fractionCompleted) {(progress, _) in
            print("progress", progress)
        }
        
        task.resume()
    }
}

extension ListDetailViewController {
    func createSocket(topics: [String]? = nil) {
        guard socketDelegate == nil else { return }
        socketDelegate = SocketDelegate(
            contractAddress: self.contractAddress,
            topics: topics,
            passThroughSubject: PassthroughSubject<[String: Any], PostingError>()
        )
        
        socketDelegate.passThroughSubject
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                    case .failure(let err):
                        self?.alert.showDetail("Auction Detail Fetch Error", with: err.localizedDescription, for: self)
                    case .finished:
                        print("")
                        break
                }
            }, receiveValue: { [weak self] (WebSocketMessage) in
                guard let topics = WebSocketMessage["topics"] as? [String],
                      let txHash = WebSocketMessage["transactionHash"] as? String,
                      let contractAddress = self?.contractAddress else { return }
                
                switch topics {
                    case _ where topics.contains(Topics.Transfer) || topics.contains(Topics.Transfer2):
//                        self?.isPending = true
//                        guard let executeReadTransaction = self?.executeReadTransaction else { return }
//                        self?.getAuctionInfo(
//                            transactionHash: txHash,
//                            executeReadTransaction: executeReadTransaction,
//                            contractAddress: contractAddress
//                        )
                        break
                    default:
                        print("other events")
                }
            })
            .store(in: &storage)
    }
}
