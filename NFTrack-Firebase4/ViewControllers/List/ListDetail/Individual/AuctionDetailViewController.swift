//
//  AuctionDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-13.
//

/*
 Abstract:
 The individual auction.
 Update the status and the date of each step: bid, ended, and transferred.  These three are for the ProgressCell indicator.
 */

import UIKit
import Combine
import web3swift
import BigInt
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

class AuctionDetailViewController: ParentDetailViewController {
    final var historyVC: HistoryViewController!
    lazy final var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    final var auctionDetailTitleLabel: UILabel!
    final var moreDetailsButton: UIButton!
    final var auctionSpecView: SpecDisplayView!
    final var bidContainer: UIView!
    final var bidTextField: UITextField!
    final var auctionButton: UIButton!
    final let LIST_DETAIL_MARGIN: CGFloat = 10
    final var propertiesToLoad: [AuctionContract.ContractProperties]!
    lazy final var auctionDetailArr: [SmartContractProperty] = propertiesToLoad.map { SmartContractProperty(propertyName: $0.toDisplay(), propertyDesc: "loading...")}
    lazy final var auctionButtonNarrowConstraint: NSLayoutConstraint! = auctionButton.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 0.45)
    lazy final var auctionButtonWideConstraint: NSLayoutConstraint! = auctionButton.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 1)
    final var auctionContractAddress: EthereumAddress!
    final var socketDelegate: SocketDelegate!
    // indicator to show whether the transaction is pending or not
    // it means the current highest bidder/bidding price will likely change
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
    
    final var pendingIndicatorView: PendingIndicatorView!
    final var pendingReturnButton: UIButton!
    final var txResult: TxResult!
    final var auctionButtonController: AuctionButtonController!
    final var pendingReturnButtonConstraints = [NSLayoutConstraint]()
    final var pendingReturnActivityIndicatorView: UIActivityIndicatorView!
    final var db: Firestore! {
        return FirebaseService.shared.db
    }
    
    init(auctionContractAddress: EthereumAddress, myContractAddress: EthereumAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.contractAddress = myContractAddress
        self.auctionContractAddress = auctionContractAddress
        
        self.propertiesToLoad = [
            AuctionContract.ContractProperties.startingBid,
            AuctionContract.ContractProperties.highestBid,
            AuctionContract.ContractProperties.highestBidder,
            AuctionContract.ContractProperties.auctionEndTime,
            AuctionContract.ContractProperties.ended,
            AuctionContract.ContractProperties.pendingReturns(myContractAddress),
            AuctionContract.ContractProperties.beneficiary
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if let container = container as? HistoryViewController {
            // the height of the child VC's view has to be increased accordingly since it's set to be unscrollable.
            // this is so that the child VC's view doesn't scroll independently of the parent VC's view.
            historyVCHeightConstraint.constant = container.preferredContentSize.height
            
            var adjustedSize: CGSize!
            if let files = post.files, files.count > 0 {
                adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1500)
            } else {
                adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1250)
            }
            
            self.scrollView.contentSize =  adjustedSize
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let auctionHash = post.auctionHash else { return }
        getAuctionInfo(
            transactionHash: auctionHash,
            executeReadTransaction: executeReadTransaction,
            contractAddress: auctionContractAddress
        )
        addKeyboardObserver()
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if socketDelegate != nil {
            socketDelegate.disconnectSocket()
        }
        removeKeyboardObserver()
        
        if let timer = auctionButtonController.timer {
            timer.invalidate()
        }
    }
    
    deinit {
        if let timer = auctionButtonController.timer {
            timer.invalidate()
        }
    }
    
    final override func userInfoDidSet() {
        super.userInfoDidSet()
        
        guard let status = post.status,
              status != AuctionStatus.ended.rawValue else { return }
        
        if userInfo.uid != userId {
            configureBuyerNavigationBar()
            fetchSavedPostData()
        } else if post.sellerUserId == userId {
            configureSellerNavigationBar()
        }
    }
}

extension AuctionDetailViewController: UITextFieldDelegate {
    final override func configureUI() {
        super.configureUI()
        self.hideKeyboardWhenTappedAround()
        auctionButtonController = AuctionButtonController()
        
        title = post.title

        historyVC = HistoryViewController()
        historyVC.itemIdentifier = post.id
        addChild(historyVC)
        historyVC.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyVC.view)
        historyVC.didMove(toParent: self)
        
        auctionDetailTitleLabel = createTitleLabel(text: "Auction Detail")
        auctionDetailTitleLabel.isUserInteractionEnabled = true
        auctionDetailTitleLabel.sizeToFit()
        scrollView.addSubview(auctionDetailTitleLabel)
        
        pendingIndicatorView = PendingIndicatorView()
        pendingIndicatorView.isHidden = true
        pendingIndicatorView.buttonAction = { [weak self] _ in
            let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Pending Transaction", detail: InfoText.pending)])
            self?.present(infoVC, animated: true, completion: nil)
        }
        pendingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pendingIndicatorView)
        
        moreDetailsButton = UIButton(type: .system)
        moreDetailsButton.setTitle("More Details", for: .normal)
        moreDetailsButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        moreDetailsButton.layer.borderWidth = 0.5
        moreDetailsButton.layer.borderColor = UIColor.lightGray.cgColor
        moreDetailsButton.layer.cornerRadius = 7
        moreDetailsButton.tag = 2
        moreDetailsButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        moreDetailsButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(moreDetailsButton)
        
        auctionSpecView = SpecDisplayView(listingDetailArr: auctionDetailArr)
        auctionSpecView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(auctionSpecView)
        
        bidContainer = UIView()
        bidContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(bidContainer)
        
        bidTextField = createTextField(placeHolder: "In ETH", delegate: self)
        bidTextField.keyboardType = .decimalPad
        bidContainer.addSubview(bidTextField)
        
        auctionButton = UIButton()
        auctionButton.backgroundColor = .black
        auctionButton.layer.cornerRadius = 5
        auctionButton.setTitle("Bid Now", for: .normal)
        auctionButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        auctionButton.translatesAutoresizingMaskIntoConstraints = false
        bidContainer.addSubview(auctionButton)
    }
    
    final override func setConstraints() {
        super.setConstraints()
        
        auctionButtonNarrowConstraint.isActive = true

        NSLayoutConstraint.activate([
            auctionDetailTitleLabel.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            auctionDetailTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            
            pendingIndicatorView.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            pendingIndicatorView.leadingAnchor.constraint(equalTo: auctionDetailTitleLabel.trailingAnchor, constant: 20),
            pendingIndicatorView.heightAnchor.constraint(equalTo: auctionDetailTitleLabel.heightAnchor),
            pendingIndicatorView.widthAnchor.constraint(equalToConstant: 100),

            moreDetailsButton.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            moreDetailsButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            moreDetailsButton.heightAnchor.constraint(equalTo: auctionDetailTitleLabel.heightAnchor),
            moreDetailsButton.widthAnchor.constraint(equalToConstant: 100),
            
            auctionSpecView.topAnchor.constraint(equalTo: auctionDetailTitleLabel.bottomAnchor, constant: 10),
            auctionSpecView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            auctionSpecView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            auctionSpecView.heightAnchor.constraint(equalToConstant: CGFloat(auctionDetailArr.count) * LIST_DETAIL_HEIGHT + LIST_DETAIL_MARGIN),
            
            bidContainer.topAnchor.constraint(equalTo: auctionSpecView.bottomAnchor, constant: 40),
            bidContainer.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            bidContainer.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            bidContainer.heightAnchor.constraint(equalToConstant: 50),
            
            bidTextField.leadingAnchor.constraint(equalTo: bidContainer.leadingAnchor),
            bidTextField.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 0.45),
            bidTextField.heightAnchor.constraint(equalTo: bidContainer.heightAnchor),
            
            auctionButton.trailingAnchor.constraint(equalTo: bidContainer.trailingAnchor),
            auctionButton.heightAnchor.constraint(equalTo: bidContainer.heightAnchor),

            historyVC.view.topAnchor.constraint(equalTo: auctionButton.bottomAnchor, constant: 40),
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
                bid()
                break
            case 1:
                callAuctionMethod(for: .auctionEnd)
                break
            case 2:
                // more details button
                guard let auctionContractAddress = auctionContractAddress else { return }
                let webVC = WebViewController()
                webVC.urlString = "https://rinkeby.etherscan.io/address/\(auctionContractAddress.address)"
                self.navigationController?.pushViewController(webVC, animated: true)
                break
            case 3:
                callAuctionMethod(for: .getTheHighestBid)
                break
            case 5:
//                callAuctionMethod(for: .transferToken)
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Auction Ended", detail: InfoText.auctionEnded)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 11:
                let listEditVC = DigitalListEditViewController()
                listEditVC.post = post
                self.navigationController?.pushViewController(listEditVC, animated: true)
                break
            case 60:
                callAuctionMethod(for: .withdraw)
            case 61:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Withdrawal", detail: InfoText.withdrawPrior)])
                self.present(infoVC, animated: true, completion: nil)
            case 62:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.auctionStatus)])
                self.present(infoVC, animated: true, completion: nil)
            default:
                break
        }
    }
    
    // the big main button
    final func setButtonStatus(as status: AuctionContract.ContractMethods) {
        DispatchQueue.main.async { [weak self] in
            guard self?.auctionButtonNarrowConstraint != nil,
                  self?.auctionButtonWideConstraint != nil else { return }
            
            switch status {
                case .bid:
                    self?.bidTextField.isEnabled = true
                    self?.bidTextField.alpha = 1
                    
                    // might already be narrow
                    self?.auctionButtonNarrowConstraint.isActive = false
                    self?.auctionButtonWideConstraint.isActive = false
                    self?.auctionButtonNarrowConstraint.isActive = true
                    
                    self?.auctionButton.setTitle("Bid Now", for: .normal)
                    self?.auctionButton.tag = 0
                case .auctionEnd:
                    self?.bidTextField.isEnabled = false
                    self?.bidTextField.alpha = 0
                    
                    self?.auctionButtonNarrowConstraint.isActive = false
                    self?.auctionButtonWideConstraint.isActive = true
                    self?.auctionButton.setTitle("End Auction", for: .normal)
                    self?.auctionButton.tag = 1
                case .getTheHighestBid:
                    self?.auctionButtonNarrowConstraint.isActive = false
                    self?.auctionButtonWideConstraint.isActive = true
                    self?.auctionButton.setTitle("Claim The Final Bid", for: .normal)
                    self?.auctionButton.tag = 3
                case .transferToken:
                    self?.bidTextField.isEnabled = false
                    self?.bidTextField.alpha = 0
                    
                    self?.auctionButtonNarrowConstraint.isActive = false
                    self?.auctionButtonWideConstraint.isActive = true
                    
                    if self?.auctionButtonController.highestBidder == self?.auctionButtonController.beneficiary {
                        self?.auctionButton.setTitle("Claim The Final Bid", for: .normal)
                        self?.auctionButton.tag = 3
                    } else {
                        self?.auctionButton.setTitle("Auction Ended", for: .normal)
                        self?.auctionButton.tag = 5
                    }
                default:
                    break
            }
            
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    final func bid() {
        guard auctionButtonController.isAuctionEnded == false else {
            self.alert.showDetail("Sorry", with: "The auction has already ended", for: self)
            return
        }
        
        guard let bidAmount = bidTextField.text, !bidAmount.isEmpty else {
            self.alert.showDetail("Bid Amount Error", with: "The bid amount cannot be empty.", for: self)
            return
        }

        guard Double(bidAmount) != nil else {
            self.alert.showDetail("Bid Format Error", with: "The bid amount has to be in a numeric form", for: self)
            return
        }
        
        guard let bidAmountNumber = NumberFormatter().number(from: bidAmount), bidAmountNumber.doubleValue > 0 else {
            self.alert.showDetail("Bid Amount Error", with: "The bid amount has to be greater than zero.", for: self)
            return
        }
        
        callAuctionMethod(for: AuctionContract.ContractMethods.bid, amountString: bidAmount)
    }
    
    // Dynamically determine what auction method to call 
    func callAuctionMethod(for method: AuctionContract.ContractMethods, amountString: String? = nil) {
        var content = [
            StandardAlertContent(
                index: 0,
                titleString: "Password",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
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
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        // auxiliary info to be displayed to the user before the execution
        let withDrawInfo = StandardAlertContent(
            index: 2,
            titleString: "Withdrawal",
            body: [
                "": InfoText.withdraw
            ],
            messageTextAlignment: .left
        )
        
        switch method {
            case .withdraw:
                content.append(withDrawInfo)
            default:
                break
        }
        
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
                        
                        // use Deferred?
                        Future<WriteTransaction, PostingError> { promise in
                            guard let auctionContractAddress = self.auctionContractAddress else {
                                promise(.failure(.generalError(reason: "Unable to load the address for the auction contract.")))
                                return
                            }
                            
                            // if the socket timed out, reconnect
                            if let isSocketConnected = self.socketDelegate.socketProvider?.socket.isConnected,
                               isSocketConnected == false {
                                self.createSocket()
                            }
                            
                            self.transactionService.prepareTransactionForWriting(
                                method: method.rawValue,
                                abi: auctionABI,
                                contractAddress: auctionContractAddress,
                                amountString: amountString ?? "0",
                                promise: promise
                            )
                        }
                        .flatMap { (transaction) -> Future<TxResult, PostingError> in
                            self.transactionService.executeTransaction(
                                transaction: transaction,
                                password: password,
                                type: .auctionContract
                            )
                        }
                        .flatMap({ (txResult) -> AnyPublisher<Data, PostingError> in
                            self.txResult = txResult
                            switch method {
                                case .bid:
                                    // let's every user involved in the auction (who has previously bid before) know through the push notification that there's been a new bid
                                    if let fcmToken = UserDefaults.standard.string(forKey: UserDefaultKeys.fcmToken),
                                       let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) {
                                        
                                        // the update of the status and the date is to display the progress on ProgressCell
                                        self.db.collection("post").document(self.post.documentId).updateData([
                                            "bidderTokens": FieldValue.arrayUnion([fcmToken]),
                                            "bidders": FieldValue.arrayUnion([userId]),
                                            "status": AuctionStatus.bid.rawValue,
                                            "bidDate": Date()
                                        ], completion: { (error) in
                                            if let error = error {
                                                print("firebase error", error)
                                            }
                                        })
                                    }

                                    // unsubscribe so that you don't get the push notification for your own update
                                    // but later resubscribe for the notification for the counterparty
                                    // firebase doesn't have a way to opt out of the notification directed at yourself
                                    Messaging.messaging().unsubscribe(fromTopic: self.post.documentId) { error in
                                        print("unsubscribed to \(self.post.documentId ?? "")")
                                    }

                                    return FirebaseService.shared.sendToTopics(
                                        title: "Auction Bid",
                                        content: "A new bid was made in your auction.",
                                        topic: self.post.documentId,
                                        docId: self.post.documentId
                                    )
                                case .auctionEnd:
                                    // socket will utimately pick up the topics of the event emitted at the time the "auctionEnd" method is called
                                    // but setting the isAuctionOfficiallyEnded property here to true as an insurance in case the socket doesn't pick up the topics (i.e. the internet connection failure)
                                    self.auctionButtonController.isAuctionOfficiallyEnded = true
                                    
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "status": AuctionStatus.transferred.rawValue,
                                        "auctionEndDate": Date(),
                                        "auctionTransferredDate": Date()
                                    ])
                                    return FirebaseService.shared.unsubscribeToTopic(topic: self.post.documentId)
                                case .withdraw:
                                    NotificationCenter.default.post(name: .auctionDidWithdraw, object: true)
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .transferToken:
//                                    self.db.collection("post").document(self.post.documentId).updateData([
//                                        "status": AuctionStatus.transferred.rawValue,
//                                        "auctionTransferredDate": Date()
//                                    ])
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .abort:
                                    self.db.collection("post").document(self.post.documentId).updateData([
                                        "status": AuctionStatus.aborted.rawValue,
                                    ])
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                case .resell:
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                                default:
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                            }
                        })
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
                                        case .auctionEnd:
                                            self.alert.showDetail("Auction Ended", with: "Congratulations. You have officially ended the auction! The item has been transferred and the beneficiary can now withdraw the winning bid.", for: self)
                                            break
                                        case .bid:
                                            self.alert.showDetail("Bid Success!", with: "You have made a successful bid. It'll take a few moment to be reflected on the blockchain.", for: self, completion:  {
                                                self.bidTextField.text?.removeAll()
                                                
                                                // Sub for the first time or re-sub if unsubbed to avoid texting oneself
                                                Messaging.messaging().subscribe(toTopic: self.post.documentId) { error in
                                                    print("Subscribed to \(self.post.documentId ?? "") topic")
                                                }
                                            })
                                            break
                                        case .getTheHighestBid:
                                            self.alert.showDetail("Success!", with: "You have successfully withdrawn the final bid. It'll be reflected on your wallet soon.", for: self)
                                            break
                                        case .transferToken:
                                            self.alert.showDetail("Congratulations!", with: "You are now the proud owner of the item. It'll take a few moment to be reflected on the app.", for: self)
                                            break
                                        case .withdraw:
                                            self.alert.showDetail("Bid Withdraw", with: "You have successfully withdrawn the previous bid amount.", for: self)
                                            // the properties has to be manually refetched because the withDraw method doesn't have the events (which means no topics), therefore doesn't trigger the socket event
                                            DispatchQueue.main.async {
                                                self.getAuctionInfo(
                                                    transactionHash: self.txResult.txHash,
                                                    executeReadTransaction: self.executeReadTransaction,
                                                    contractAddress: self.auctionContractAddress
                                                )
                                            }
                                            break
                                        case .abort:
                                            self.alert.showDetail(
                                                "Success!",
                                                with: "You have successfully withdrawn the final bid. It'll be reflected on your wallet soon.",
                                                for: self) { [weak self] in
                                                DispatchQueue.main.async {
                                                    self?.navigationController?.popViewController(animated: true)
                                                }
                                            } completion: {}
                                            break
                                        case .resell:
                                            break
                                    }
                                    break
                            }
                        } receiveValue: { (_) in }
                        .store(in: &self.storage)
                    } // showSpinner
                }) // self.dismiss
            } // mainVC
        } // alertVC
        self.present(alertVC, animated: true, completion: nil)
    } // callAuctionMethod
}

extension AuctionDetailViewController {
    // MARK: - addKeyboardObserver
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    private func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        //Need to calculate keyboard exact size due to Apple suggestions
        let info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize!.height, right: 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeField = self.bidTextField {
            if (!aRect.contains(activeField.frame.origin)){
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        //Once keyboard disappears, restore original positions
        self.scrollView.contentInset = .zero
        self.scrollView.scrollIndicatorInsets = .zero
        self.view.endEditing(true)
    }
}
