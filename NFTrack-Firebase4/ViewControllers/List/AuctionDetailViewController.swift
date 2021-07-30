//
//  AuctionDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-13.
//

import UIKit
import Combine
import web3swift
import BigInt
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

struct AuctionContract {
    enum AuctionMethods: String {
        case bid
        case withdraw
        case auctionEnd
        case getTheHighestBid
        case transferToken
    }
    
    enum AuctionProperties: String, CaseIterable {
        case startingBid
        case highestBid
        case highestBidder
        case auctionEndTime
        
        static func allCasesString() -> [String] {
            return AuctionProperties.allCases.map { $0.rawValue }
        }
        
        func asFormattedString() -> String {
            switch self {
                case .startingBid:
                    return "Starting Bid"
                case .highestBid:
                    return "Highest Bid"
                case .highestBidder:
                    return "Highest Bidder"
                case .auctionEndTime:
                    return "Auction End Time"
            }
        }
    }
}

class AuctionDetailViewController: ParentDetailViewController {
    final var historyVC: HistoryViewController!
    lazy final var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    final var auctionDetailTitleLabel: UILabel!
    final var auctionDetailRefreshButton: UIButton!
    final var auctionSpecView: SpecDisplayView!
    final var storage = Set<AnyCancellable>()
    final var bidContainer: UIView!
    final var bidTextField: UITextField!
    final var auctionButton: UIButton!
    final let LIST_DETAIL_MARGIN: CGFloat = 10
    final var propertiesToLoad: [String]!
    lazy final var auctionDetailArr: [SmartContractProperty] = propertiesToLoad.map { SmartContractProperty(propertyName: $0, propertyDesc: "loading...")}
    lazy final var auctionButtonNarrowConstraint: NSLayoutConstraint! = auctionButton.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 0.45)
    lazy final var auctionButtonWideConstraint: NSLayoutConstraint! = auctionButton.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 1)
    final var isAuctionEnded: Bool! {
        didSet{
//            guard auctionButtonNarrowConstraint != nil,
//                  auctionButtonWideConstraint != nil else { return }
//            if isAuctionEnded == true {
//                bidTextField.isEnabled = false
//                bidTextField.alpha = 0
//
//                auctionButtonNarrowConstraint.isActive = false
//                auctionButtonWideConstraint.isActive = true
//                auctionButton.setTitle("End Auction", for: .normal)
//                auctionButton.tag = 1
//            } else {
//                bidTextField.isEnabled = true
//                bidTextField.alpha = 1
//
//                // might already be narrow
//                auctionButtonNarrowConstraint.isActive = false
//                auctionButtonWideConstraint.isActive = false
//                auctionButtonNarrowConstraint.isActive = true
//
//                auctionButton.setTitle("Bid Now", for: .normal)
//                auctionButton.tag = 0
//            }
//
//            UIView.animate(withDuration: 0.3) { [weak self] in
//                self?.view.layoutIfNeeded()
//            }
        }
    }
    final var socketDelegate: SocketDelegate!
    // indicator to show whether the transaction is pending or not
    // it means the current highest bidder/bidding price will likely change
    lazy var isPending: Bool = false {
        didSet {
            if isPending {
                DispatchQueue.main.async { [weak self] in
                    self?.pendingContainer.isHidden = false
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.pendingContainer.isHidden = true
                }
            }
        }
    }
    final var pendingContainer: UIView!
    final var pendingLabel: UILabel!
    final var activityIndicatorView: UIActivityIndicatorView!
    final var timer: Timer!
    
    init() {
        self.propertiesToLoad = AuctionContract.AuctionProperties.allCasesString()
        super.init(nibName: nil, bundle: nil)
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
        getAuctionInfo()
        addKeyboardObserver()
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if socketDelegate != nil {
            socketDelegate.disconnectSocket()
        }
        removeKeyboardObserver()
        
        if let timer = timer {
            timer.invalidate()
        }
    }
}

extension AuctionDetailViewController: UITextFieldDelegate {
    final override func configureUI() {
        super.configureUI()
        self.hideKeyboardWhenTappedAround()
        
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
        
        guard let refreshImage = UIImage(systemName: "arrow.clockwise") else { return }
        auctionDetailRefreshButton = UIButton.systemButton(with: refreshImage, target: self, action: #selector(buttonPressed(_:)))
        auctionDetailRefreshButton.tag = 2
        auctionDetailRefreshButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(auctionDetailRefreshButton)
        
        pendingContainer = UIView()
        pendingContainer.isHidden = true
        pendingContainer.translatesAutoresizingMaskIntoConstraints = false
        pendingContainer.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 204/255, alpha: 1)
        pendingContainer.layer.cornerRadius = 8
        pendingContainer.tag = 3
        let pendingContainerTap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        pendingContainer.addGestureRecognizer(pendingContainerTap)
        scrollView.addSubview(pendingContainer)
        
        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.startAnimating()
        activityIndicatorView.color = UIColor(red: 0/255, green: 155/255, blue: 0/255, alpha: 1)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        pendingContainer.addSubview(activityIndicatorView)
        
        pendingLabel = createTitleLabel(text: "Pending", weight: .light)
        pendingLabel.font = UIFont.systemFont(ofSize: 12)
        pendingLabel.textColor = UIColor(red: 0/255, green: 155/255, blue: 0/204, alpha: 1)
        pendingContainer.addSubview(pendingLabel)
        
        auctionSpecView = SpecDisplayView(listingDetailArr: auctionDetailArr)
        auctionSpecView.tag = 2
        let auctionSpecTap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        auctionSpecView.addGestureRecognizer(auctionSpecTap)
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
//            auctionDetailTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            pendingContainer.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            pendingContainer.leadingAnchor.constraint(equalTo: auctionDetailTitleLabel.trailingAnchor, constant: 20),
            pendingContainer.heightAnchor.constraint(equalTo: auctionDetailTitleLabel.heightAnchor),
            pendingContainer.widthAnchor.constraint(equalToConstant: 100),
            
            activityIndicatorView.leadingAnchor.constraint(equalTo: pendingContainer.leadingAnchor),
            activityIndicatorView.heightAnchor.constraint(equalToConstant: 30),
            activityIndicatorView.centerYAnchor.constraint(equalTo: pendingContainer.centerYAnchor),
            activityIndicatorView.widthAnchor.constraint(equalTo: activityIndicatorView.heightAnchor),
            
            pendingLabel.leadingAnchor.constraint(equalTo: activityIndicatorView.trailingAnchor, constant: 5),
            pendingLabel.trailingAnchor.constraint(equalTo: pendingContainer.trailingAnchor),
            pendingLabel.heightAnchor.constraint(equalTo: pendingContainer.heightAnchor),
            
            auctionDetailRefreshButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            auctionDetailRefreshButton.heightAnchor.constraint(equalTo: auctionDetailTitleLabel.heightAnchor),
            auctionDetailRefreshButton.widthAnchor.constraint(equalTo: auctionDetailRefreshButton.heightAnchor),
            auctionDetailRefreshButton.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            
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
    
    @objc final func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                bid()
                break
            case 1:
                callAuctionMethod(for: AuctionContract.AuctionMethods.auctionEnd)
            case 2:
                // refresh auction detail
                print("refresh")
                break
            case 3:
                print("claim the final price")
                setButtonStatus(as: .getTheHighestBid)
            case 4:
                print("withdraw your previous bid")
                setButtonStatus(as: .withdraw)
            case 5:
                print("transfer the ownership")
                setButtonStatus(as: .transferToken)
            default:
                break
        }
    }
    
    @objc override func tapped(_ sender: UITapGestureRecognizer!) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        super.tapped(sender)
        let tag = sender.view?.tag

        switch tag {
            case 2:
                guard let auctionContractAddress = contractAddress else { return }
                
                let webVC = WebViewController()
                webVC.urlString = "https://rinkeby.etherscan.io/address/\(auctionContractAddress.address)"
                self.navigationController?.pushViewController(webVC, animated: true)
            case 3:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Pending Transaction", detail: InfoText.pending)])
                self.present(infoVC, animated: true, completion: nil)
            default:
                break
        }
    }
    
    final func setButtonStatus(as status: AuctionContract.AuctionMethods) {
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
                    self?.auctionButton.setTitle("Claim the final price", for: .normal)
                    self?.auctionButton.tag = 3
                case .withdraw:
                    self?.auctionButton.setTitle("Withdraw your preview bid", for: .normal)
                    self?.auctionButton.tag = 4
                case .transferToken:
                    self?.auctionButton.setTitle("Transfer the ownership", for: .normal)
                    self?.auctionButton.tag = 5
            }
            
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    final func fetchContractAddress(txHash: String) {
        Future<TransactionReceipt, PostingError> { promise in
            Web3swiftService.getReceipt(hash: txHash, promise: promise)
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.generalError(reason: let msg)):
                    self?.alert.showDetail("Error", with: msg, for: self)
                    break
                case .finished:
                    print("contract retrieved")
                    break
                default:
                    break
            }
        } receiveValue: { [weak self] (receipt) in
            guard let contractAddress = receipt.contractAddress else { return }
            self?.contractAddress = contractAddress
        }
        .store(in: &storage)
    }
    
    final func bid() {
        guard isAuctionEnded == false else {
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
        
        callAuctionMethod(for: AuctionContract.AuctionMethods.bid, amountString: bidAmount)
    }
    
    func callAuctionMethod(for method: AuctionContract.AuctionMethods, amountString: String? = nil) {
        let content = [
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
        self.showSpinner {
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
                        Future<WriteTransaction, PostingError> { promise in
                            guard let contractAddress = self.contractAddress else {
                                promise(.failure(.generalError(reason: "Unable to load the address for the auction contract.")))
                                return
                            }
                            self.transactionService.prepareTransactionForWriting(
                                method: method.rawValue,
                                abi: auctionABI,
                                contractAddress: contractAddress,
                                amountString: amountString ?? "0",
                                promise: promise
                            )
                        }
                        .flatMap { (transaction) -> Future<TxResult, PostingError> in
                            self.transactionService.executeTransaction(
                                transaction: transaction,
                                password: password,
                                type: .endAuction
                            )
                        }
                        .flatMap({ (txResult) -> AnyPublisher<Data, PostingError> in
                            switch method {
                                case .bid:
                                    let ref = FirebaseService.shared.db.collection("post").document(self.post.documentId)
                                    if let fcmToken = UserDefaults.standard.string(forKey: UserDefaultKeys.fcmToken) {
                                        ref.updateData([
                                            "bidderTokens": FieldValue.arrayUnion([fcmToken])
                                        ])
                                    }
                                    
                                    Messaging.messaging().unsubscribe(fromTopic: self.post.documentId) { error in
                                        print("unsubscribed to \(self.post.documentId ?? "")")
                                    }
                                    
                                    return FirebaseService.shared.sendToTopics(
                                        title: "Auction Bid",
                                        topic: self.post.documentId,
                                        content: "A new bid was made in your auction."
                                    )
                                case .auctionEnd:
                                    print("unsub")
                                    return FirebaseService.shared.unsubscribeToTopic(topic: self.post.documentId)
                                default:
                                    return Result.Publisher(Data()).eraseToAnyPublisher()
                            }
                        })
                        .sink { (completion) in
                            switch completion {
                                case .failure(let error):
                                    print("error", error)
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
                                            self.alert.showDetail("Auction Ended", with: "Congratulations. You have officially ended the auction! The winner can now transfer the item and the beneficiary can withdraw the fund.", for: self)
                                            
                                        case .bid:
                                            self.alert.showDetail("Bid Success!", with: "You have made a successful bid. It'll take a few moment to be reflected on the blockchain.", for: self, completion:  {
                                                self.bidTextField.text?.removeAll()
                                                
                                                Messaging.messaging().subscribe(toTopic: self.post.documentId) { error in
                                                    print("Subscribed to \(self.post.documentId ?? "") topic")
                                                }
                                            })
                                        case .getTheHighestBid:
                                            self.alert.showDetail("Success!", with: "You have successfully withdrawn the final bid. It'll be reflected on your wallet soon.", for: self)
                                        case .transferToken:
                                            self.alert.showDetail("Congratulations!", with: "You are now the proud owner of the item. It'll take a few moment to be reflected on the app.", for: self)
                                        case .withdraw:
                                            self.alert.showDetail("Bid Withdraw", with: "You have successfully withdrawn the previous bid amount.", for: self)
                                    }
                                    break
                            }
                        } receiveValue: { (_) in }
                        .store(in: &self.storage)
                    }) // self.dismiss
                } // mainVC
            } // alertVC
            self.present(alertVC, animated: true, completion: nil)
        }
    } // callAuctionMethod
}

// starting bid
// current highest bid
// current highest bidder
// auction end time
extension AuctionDetailViewController {
    final func getAuctionInfo() {
        guard let auctionHash = post.auctionHash else { return }
        
        let auctionInfoLoader = PropertyLoader(
            propertiesToLoad: self.propertiesToLoad,
            deploymentHash: auctionHash
        )
        
        isPending = true
        auctionInfoLoader.initiateLoadSequence()
            .sink { [weak self] (completion) in
                switch completion {
                    case .failure(let error):
                        print("auctionInfoLoader error", error)
                    case .finished:
                        print("get auction info finished", self?.userInfo.uid as Any)
                }
                self?.isPending = false
            } receiveValue: { [weak self] (propertyFetchModels: [SmartContractProperty]) in
                DispatchQueue.main.async {
                    // if the count is different, then the arrangedSubview in the stack view of auctionSpecView will go out of bound
                    if self?.propertiesToLoad.count == propertyFetchModels.count  {
                        self?.auctionSpecView.fetchedDataArr = propertyFetchModels
                    }
                    
                    // contract address for bidding
                    self?.contractAddress = auctionInfoLoader.contractAddress
                    
                    // socket to receive topics so that the auction specs could be re-updated
                    // whenever the current user or anybody else calls the method on the auction contract
                    // the socket will respond
                    // needs to be in the main thread, otherwise won't work
                    self?.createSocket(for: auctionInfoLoader.contractAddress)
                }
                                
                // check the auction end time to see if the auction is still active
                // present the bid button accordingly
                for case let model in propertyFetchModels where model.propertyName == AuctionContract.AuctionProperties.auctionEndTime.rawValue {
                    guard let auctionEndDate = model.propertyDesc as? Date else { return }
                    if auctionEndDate < Date() {
                        DispatchQueue.main.async {
                            self?.isAuctionEnded = true
                        }
                        self?.setButtonStatus(as: .auctionEnd)
                        
                    } else {
                        self?.setButtonStatus(as: .bid)
                        
                        var differenceInSeconds = auctionEndDate.timeIntervalSince(Date())
                        DispatchQueue.main.async {
                            self?.isAuctionEnded = false
                            self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (Timer) in
                                if differenceInSeconds > 0 {
                                    print ("\(differenceInSeconds) seconds")
                                    differenceInSeconds -= 1
                                } else {
                                    self?.isAuctionEnded = true
                                    self?.setButtonStatus(as: .auctionEnd)
                                    Timer.invalidate()
                                }
                            }
                        }
                    }
                }
            }
            .store(in: &self.storage)
    }
    
    func createSocket(for auctionContractAddress: EthereumAddress, topics: [String]? = nil) {
        guard socketDelegate == nil else { return }
        socketDelegate = SocketDelegate(
            contractAddress: auctionContractAddress,
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
                      let self = self else { return }

                switch topics {
                    case _ where topics.contains(Topics.HighestBidIncreased):
                        self.isPending = true
                        
                        print("HighestBidIncreased")
                        print("txHash", txHash)
                        // if the auction info is fetched right away, it wouldn't fetch the info from the newly added block
                        // the transaction needs to be completed before the proper info can be reflected
                        self.transactionService.confirmEtherTransactionsNoDelay(txHash: txHash)
                            .sink { (completion) in
                                switch completion {
                                    case .failure(let err):
                                        self.alert.showDetail("Auction Detail Fetch Error", with: err.localizedDescription, for: self)
                                    case .finished:
                                        print("spec fetched after mined")
                                        self.getAuctionInfo()
                                        break
                                }
                                self.isPending = false
                            } receiveValue: {(_) in
                            }
                            .store(in: &self.storage)
                    default:
                        print("other events")
                }
            })
            .store(in: &storage)
    }
    
    func createEventListener() {
        guard let auctionHash = post.auctionHash else { return }
        Future<TransactionReceipt, PostingError> { promise in
            Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
        }
        .flatMap({ (receipt) -> AnyPublisher<[EventParserResultProtocol], PostingError> in
            return Future<[EventParserResultProtocol], PostingError> { promise in
                let web3 = Web3swiftService.web3instance
                guard let auctionContractAddress = receipt.contractAddress else {
                    return promise(.failure(.generalError(reason: "Unable to retrieve the auction contract")))
                }
                
                let contract = web3.contract(auctionABI, at: auctionContractAddress, abiVersion: 2)
                
//                var filter = EventFilter()
//                filter.fromBlock = .blockNumber(0)
//                filter.toBlock = .latest
                
                let eventParser = contract?.createEventParser("HighestBidIncreased", filter: nil)
                
                var blockNumber: BigUInt!
                do {
                    blockNumber = try web3.eth.getBlockNumber()
                } catch {
                    promise(.failure(.generalError(reason: "Unable to get the block number.")))
                }

                do {
                    if let event = try eventParser?.parseBlockByNumber(UInt64(blockNumber)) {
                        print("event parser", event)
                        promise(.success(event))
                    } else {
                        promise(.failure(.generalError(reason: "No event.")))
                    }
                } catch {
                    promise(.failure(.generalError(reason: "Unable to parse event.")))
                }
            }
            .eraseToAnyPublisher()
        })
        .sink { (completion) in
            switch completion {
                case .finished:
                    break
                case .failure(let err):
                    print(err)
            }
        } receiveValue: { (event) in
            print("final event", event)
        }
        .store(in: &storage)
    }
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
