//
//  IntegralAuctionViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-02.
//

import UIKit
import Combine
import web3swift
import BigInt
import FirebaseFirestore

class IntegralAuctionViewController: ParentDetailViewController {
    final var historyVC: HistoryViewController!
    lazy final var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    final var auctionDetailTitleLabel: UILabel!
    final var moreDetailsButton: UIButton!
    final var auctionSpecView: SpecDisplayView!
    final var bidContainer: UIView!
    final var bidTextField: UITextField!
    final var auctionButton: UIButton!
    final let LIST_DETAIL_MARGIN: CGFloat = 10
    final var propertiesToLoad: [IntegralAuctionContract.ContractProperties]!
    lazy final var auctionDetailArr: [SmartContractProperty] = IntegralAuctionProperties.AuctionInfo.getAll().map { SmartContractProperty(propertyName: $0, propertyDesc: "loading...") }

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
    
    init(auctionContractAddress: EthereumAddress, myContractAddress: EthereumAddress, post: Post) {
        super.init(nibName: nil, bundle: nil)
        
        self.contractAddress = myContractAddress
        self.auctionContractAddress = auctionContractAddress
        
//        self.propertiesToLoad = [
//            AuctionContract.ContractProperties.startingBid,
//            AuctionContract.ContractProperties.highestBid,
//            AuctionContract.ContractProperties.highestBidder,
//            AuctionContract.ContractProperties.auctionEndTime,
//            AuctionContract.ContractProperties.ended,
//            AuctionContract.ContractProperties.pendingReturns(myContractAddress),
//            AuctionContract.ContractProperties.beneficiary
//        ]
        
        guard let uid = post.solireyUid,
              let convertedUid = BigUInt(uid) else { return }
        
        self.propertiesToLoad = [
            IntegralAuctionContract.ContractProperties._auctionInfo(convertedUid)
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

extension IntegralAuctionViewController: UITextFieldDelegate {
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
            case 5:
                callAuctionMethod(for: .transferToken)
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
                    
                    self?.auctionButton.setTitle("Transfer the Ownership", for: .normal)
                    self?.auctionButton.tag = 5
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
    }
}

extension IntegralAuctionViewController {
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
