

//
//  ListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//
//
//import UIKit
//
//class ListViewController: UIViewController {
//    private let userDefaults = UserDefaults.standard
//    var segmentedControl: UISegmentedControl!
//    private var childListViewController: ChildListViewController!
//    private var currentIndex: Int! = 0
//
//    final override func viewDidLoad() {
//        super.viewDidLoad()
//
//        configureNavigationBar(vc: self)
//        configureSwitch()
//        //        configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//
//        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
//        swipeLeft.direction = .left
//        view.addGestureRecognizer(swipeLeft)
//
//        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
//        swipeRight.direction = .right
//        view.addGestureRecognizer(swipeRight)
//    }
//
//    @objc func swiped(_ sender: UISwipeGestureRecognizer) {
//        switch sender.direction {
//            case .right:
//                if currentIndex - 1 >= 0 {
//                    currentIndex -= 1
//                } else {
//                    return
//                }
//            case .left:
//                if currentIndex + 1 < Segment.allCases.count {
//                    currentIndex += 1
//                } else {
//                    return
//                }
//            default:
//                break
//        }
//        segmentedControl.selectedSegmentIndex = currentIndex
//        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
//    }
//}
//
//extension ListViewController: SegmentConfigurable {
//    enum Segment: Int, CaseIterable {
//        case buying, selling, auction, posts
//
//        func asString() -> String {
//            switch self {
//                case .buying:
//                    return NSLocalizedString("Buying", comment: "")
//                case .selling:
//                    return NSLocalizedString("Selling", comment: "")
//                case .auction:
//                    return NSLocalizedString("Auction", comment: "")
//                case .posts:
//                    return NSLocalizedString("Postings", comment: "")
//            }
//        }
//
//        static func getSegmentText() -> [String] {
//            let segmentArr = Segment.allCases
//            var segmentTextArr = [String]()
//            for segment in segmentArr {
//                segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
//            }
//            return segmentTextArr
//        }
//    }
//
//    // MARK: - configureSwitch
//    final func configureSwitch() {
//        // Segmented control as the custom title view.
//        let segmentTextContent = Segment.getSegmentText()
//        segmentedControl = UISegmentedControl(items: segmentTextContent)
//        segmentedControl.selectedSegmentIndex = 0
//        segmentedControl.autoresizingMask = .flexibleWidth
//        segmentedControl.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
//        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
//        self.navigationItem.titleView = segmentedControl
//    }
//
//    // MARK: - segmentedControlSelectionDidChange
//    @objc final func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
//        guard let segment = Segment(rawValue: sender.selectedSegmentIndex)
//        else { fatalError("No item at \(sender.selectedSegmentIndex)) exists.") }
//        currentIndex = sender.selectedSegmentIndex
//        switch segment {
//            case .buying:
//                guard var childListViewController = childListViewController else { return }
//                removeBaseViewController(childListViewController)
//                childListViewController = addBaseViewController(ChildListViewController.self, cellType: TangibleCell)
//            //                configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//            //            case .selling:
//            //                configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//            //            case .auction:
//            ////                configureDataFetch(isBuyer: true, status: [PostStatus.complete.rawValue])
//            //                configureAuctionFetch()
//            //            case .posts:
//            //                configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
//            default:
//                break
//        }
//    }
//
//    // MARK: - Switching Between View Controllers
//
//    /// Adds a child view controller to the container.
//    private func addBaseViewController<T: ChildListViewController>(_ viewController: T.Type, cellType: ProgressCell.Type) -> T {
//        let vc = viewController.init(cellType: cellType)
//        addChild(vc)
//        view.addSubview(vc.view)
//        vc.view.fill()
//        vc.didMove(toParent: self)
//        return vc
//    }
//
//    /// Removes a child view controller from the container.
//    private func removeBaseViewController(_ viewController: UIViewController?) {
//        guard let viewController = viewController else { return }
//        viewController.willMove(toParent: nil)
//        viewController.view.removeFromSuperview()
//        viewController.removeFromParent()
//    }
//}

//
//  ProgressCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-06.
//

/*
 Abstract:
 Displays items that require displaying the progression of the purchase status
 1. Tangible, payment method: escrow, sale format: online direct, delivery method: shipping
 2. Digital, payment method: escrow, sale format: online direct, delivery method: online
 3. Digital, payment method: beneficiary, sale format: open auction, delivery method: online
 */

import UIKit

class ProgressCell1: CardCell {
    class override var identifier: String {
        return "ProgressCell"
    }
    final let selectedColor = UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1)
    
    final let INSET: CGFloat = 45
    final var strokeColor: UIColor = .gray {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }
    final var lineWidth: CGFloat = 0.5 {
        didSet {
            updatePath()
        }
    }
    
    final lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final lazy var circleShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final lazy var circleShapeLayer2: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final lazy var circleShapeLayer3: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final var statusLabel1: UILabel!
    final var dateLabel1: UILabel!
    final var statusLabel2: UILabel!
    final var dateLabel2: UILabel!
    final var statusLabel3: UILabel!
    final var dateLabel3: UILabel!
    final var indicatorPanel: UIView!
    final var meterContainer: UIView!
    
    override func configure(_ post: Post?) {
        super.configure(post)
        guard let post = post else { return }
        
        meterContainer = UIView()
        meterContainer.layer.addSublayer(shapeLayer)
        meterContainer.layer.addSublayer(circleShapeLayer)
        meterContainer.layer.addSublayer(circleShapeLayer2)
        meterContainer.layer.addSublayer(circleShapeLayer3)
        meterContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(meterContainer)
        
        // category: all except digital
        // sale format: online direct
        // delivery method: shipping(Purchased, Transferred, Received), in person
        
        // category: digital
        // sale format: online direct(Purchased, Transferred, Received), open auction(Bid, Auction Ended, Transferred)
        // delivery method: online transfer
        
        if post.saleFormat == SaleFormat.openAuction.rawValue {
            statusLabel1 = createStatusLabel(text: AuctionStatus.bid.toDisplay)
            statusLabel2 = createStatusLabel(text: AuctionStatus.ended.toDisplay)
            statusLabel3 = createStatusLabel(text: AuctionStatus.transferred.toDisplay)
        } else {
            statusLabel1 = createStatusLabel(text: "Purchased")
            statusLabel2 = createStatusLabel(text: "Transferred")
            statusLabel3 = createStatusLabel(text: "Received")
        }
        
        statusLabel1.textAlignment = .center
        meterContainer.addSubview(statusLabel1)
        
        dateLabel1 = createStatusLabel(text: "")
        dateLabel1.textAlignment = .center
        meterContainer.addSubview(dateLabel1)
        
        statusLabel2.textAlignment = .center
        meterContainer.addSubview(statusLabel2)
        
        dateLabel2 = createStatusLabel(text: "")
        dateLabel2.textAlignment = .center
        meterContainer.addSubview(dateLabel2)
        
        statusLabel3.textAlignment = .center
        meterContainer.addSubview(statusLabel3)
        
        dateLabel3 = createStatusLabel(text: "")
        dateLabel3.textAlignment = .center
        meterContainer.addSubview(dateLabel3)
        
        var progressConstraints = [NSLayoutConstraint]()
        if let files = post.files, files.count > 0 {
            progressConstraints += [
                meterContainer.topAnchor.constraint(equalTo: thumbImageView.bottomAnchor, constant: 10),
            ]
        } else {
            progressConstraints += [
                meterContainer.topAnchor.constraint(equalTo: descContainer.bottomAnchor, constant: 10),
            ]
        }
        
        progressConstraints += [
            meterContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            meterContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            meterContainer.heightAnchor.constraint(equalToConstant: 100),
            
            dateLabel1.leadingAnchor.constraint(equalTo: meterContainer.leadingAnchor, constant: 0),
            dateLabel1.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor, constant: -5),
            dateLabel1.heightAnchor.constraint(equalToConstant: 30),
            dateLabel1.widthAnchor.constraint(equalTo: meterContainer.widthAnchor, multiplier: 0.33),
            
            statusLabel1.leadingAnchor.constraint(equalTo: meterContainer.leadingAnchor, constant: 0),
            statusLabel1.bottomAnchor.constraint(equalTo: dateLabel1.topAnchor, constant: 0),
            statusLabel1.widthAnchor.constraint(equalTo: meterContainer.widthAnchor, multiplier: 0.33),
            
            dateLabel2.centerXAnchor.constraint(equalTo: meterContainer.centerXAnchor, constant: 20),
            dateLabel2.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor, constant: -5),
            dateLabel2.heightAnchor.constraint(equalToConstant: 30),
            dateLabel2.widthAnchor.constraint(equalTo: meterContainer.widthAnchor, multiplier: 0.33),
            
            statusLabel2.centerXAnchor.constraint(equalTo: meterContainer.centerXAnchor),
            statusLabel2.bottomAnchor.constraint(equalTo: dateLabel2.topAnchor, constant: -0),
            statusLabel2.widthAnchor.constraint(equalTo: meterContainer.widthAnchor, multiplier: 0.33),
            
            dateLabel3.trailingAnchor.constraint(equalTo: meterContainer.trailingAnchor, constant: 0),
            dateLabel3.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor, constant: -5),
            dateLabel3.heightAnchor.constraint(equalToConstant: 30),
            dateLabel3.widthAnchor.constraint(equalTo: meterContainer.widthAnchor, multiplier: 0.33),
            
            statusLabel3.trailingAnchor.constraint(equalTo: meterContainer.trailingAnchor, constant: 0),
            statusLabel3.bottomAnchor.constraint(equalTo: dateLabel3.topAnchor, constant: 0),
            statusLabel3.widthAnchor.constraint(equalTo: meterContainer.widthAnchor, multiplier: 0.33),
        ]
        
        NSLayoutConstraint.activate(progressConstraints)
        meterContainer.layoutIfNeeded()
        dateLabel1.layoutIfNeeded()
        statusLabel1.layoutIfNeeded()
        updatePath()
        set(post: post)
    }
}

extension ProgressCell1 {
    final func createStatusLabel(text: String) -> UILabel {
        let statusLabel = UILabel()
        statusLabel.text = text
        statusLabel.textColor = .lightGray
        statusLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        statusLabel.sizeToFit()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }
    
    final func processDate(date: Date?) -> String? {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
    
    final func set(post: Post) {
        // progress sequence for the following:
        
        // tangible (escrow) and digital online direct (escrow)
        // 1. ready (doesn't show on ProgressCell)
        // 2. pending
        // 3. transferred
        // 4. complete
        
        // open auction
        // 1. ready (doesn't show on ProgressCell)
        // 2. bid
        // 3. ended (the auctionEnd method after the expiry)
        // 4. transferred (the digital asset transfer)
        switch post.status {
            case PostStatus.ready.rawValue:
                circleShapeLayer.fillColor = UIColor.white.cgColor
                circleShapeLayer.strokeColor = UIColor.lightGray.cgColor
                statusLabel1.textColor = .lightGray
                
                dateLabel1.text = ""
                dateLabel1.textColor = .lightGray
            // first node
            case PostStatus.pending.rawValue, AuctionStatus.bid.rawValue:
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel1.textColor = selectedColor
                
                if let confirmPurchaseDate = post.confirmPurchaseDate {
                    dateLabel1.text = processDate(date: confirmPurchaseDate)
                } else if let bidDate = post.bidDate  {
                    dateLabel1.text = processDate(date: bidDate)
                }
                
                dateLabel1.textColor = selectedColor
            // second node
            case PostStatus.transferred.rawValue, AuctionStatus.ended.rawValue:
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel1.textColor = selectedColor
                
                if let confirmPurchaseDate = post.confirmPurchaseDate {
                    dateLabel1.text = processDate(date: confirmPurchaseDate)
                } else if let bidDate = post.bidDate {
                    dateLabel1.text = processDate(date: bidDate)
                }
                dateLabel1.textColor = selectedColor
                
                circleShapeLayer2.fillColor = selectedColor.cgColor
                circleShapeLayer2.strokeColor = selectedColor.cgColor
                statusLabel2.textColor = selectedColor
                
                if let transferDate = post.transferDate {
                    dateLabel2.text = processDate(date: transferDate)
                } else if let auctionEndDate = post.auctionEndDate {
                    dateLabel2.text = processDate(date: auctionEndDate)
                }
                dateLabel2.textColor = selectedColor
            case PostStatus.complete.rawValue, AuctionStatus.transferred.rawValue:
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel1.textColor = selectedColor
                
                if let confirmPurchaseDate = post.confirmPurchaseDate {
                    dateLabel1.text = processDate(date: confirmPurchaseDate)
                } else if let auctionTransferredDate = post.auctionTransferredDate {
                    dateLabel1.text = processDate(date: auctionTransferredDate)
                }
                dateLabel1.textColor = selectedColor
                
                circleShapeLayer2.fillColor = selectedColor.cgColor
                circleShapeLayer2.strokeColor = selectedColor.cgColor
                statusLabel2.textColor = selectedColor
                
                if let transferDate = post.transferDate {
                    dateLabel2.text = processDate(date: transferDate)
                } else if let auctionEndDate = post.auctionEndDate {
                    dateLabel2.text = processDate(date: auctionEndDate)
                }
                dateLabel2.textColor = selectedColor
                
                circleShapeLayer3.fillColor = selectedColor.cgColor
                circleShapeLayer3.strokeColor = selectedColor.cgColor
                statusLabel3.textColor = selectedColor
                
                if let confirmReceived = post.confirmReceivedDate {
                    dateLabel3.text = processDate(date: confirmReceived)
                } else if let auctionTransferredDate = post.auctionTransferredDate {
                    dateLabel3.text = processDate(date: auctionTransferredDate)
                }
            default:
                circleShapeLayer.fillColor = UIColor.white.cgColor
                circleShapeLayer.strokeColor = UIColor.lightGray.cgColor
                statusLabel1.textColor = .lightGray
                
                dateLabel1.text = ""
                dateLabel1.textColor = .lightGray
        }
    }
    
    // 2 points
    // (1 / 2) * (1 / 2) = 1 / 4
    // 1 / 4, 3 / 4
    
    // 3 points
    // (1 / 3) * (1 / 2) = 1 / 6
    // 1 / 6, 5 / 5
    
    // 4 points
    // (1 / 4) * (1 / 2) = 1 / 8
    // 1 / 8, 7 / 8
    
    
    
    // MARK: - updatePath
    final func updatePath() {
        let offset: CGFloat = -20
        let path = UIBezierPath()
        path.move(to: CGPoint(x: meterContainer.bounds.width / 6, y: meterContainer.bounds.midY + offset))
        path.addLine(to: CGPoint(x: (meterContainer.bounds.width / 6) * 5, y: meterContainer.bounds.midY + offset))
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: meterContainer.bounds.width / 6, y: meterContainer.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer.path = circlePath.cgPath
        circleShapeLayer.lineWidth = lineWidth
        
        let circlePath2 = UIBezierPath(arcCenter: CGPoint(x: meterContainer.bounds.midX, y: meterContainer.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer2.path = circlePath2.cgPath
        circleShapeLayer2.lineWidth = lineWidth
        
        let circlePath3 = UIBezierPath(arcCenter: CGPoint(x: (meterContainer.bounds.width / 6) * 5, y: meterContainer.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer3.path = circlePath3.cgPath
        circleShapeLayer3.lineWidth = lineWidth
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        circleShapeLayer.fillColor = UIColor.white.cgColor
        circleShapeLayer.strokeColor = UIColor.lightGray.cgColor
        statusLabel1.textColor = .lightGray
        
        dateLabel1.text = ""
        dateLabel1.textColor = .lightGray
        
        circleShapeLayer2.fillColor = UIColor.white.cgColor
        circleShapeLayer2.strokeColor = UIColor.lightGray.cgColor
        statusLabel2.textColor = selectedColor
        
        dateLabel1.text = ""
        dateLabel1.textColor = selectedColor
        
        circleShapeLayer3.fillColor = UIColor.white.cgColor
        circleShapeLayer3.strokeColor = UIColor.lightGray.cgColor
        statusLabel3.textColor = selectedColor
        
        dateLabel1.text = ""
        dateLabel1.textColor = selectedColor
    }
}

//// auction first node
//if let bidDate = post.bidDate {
//    let bidNode = ProgressMeterNode(statusLabelText: AuctionStatus.bid.toDisplay, dateLabelText: processDate(date: bidDate))
//    progressMeterNodeArr.append(bidNode)
//    // escrow first node
//} else if let confirmPurchaseDate = post.confirmPurchaseDate {
//    let purchaseDateNode = ProgressMeterNode(statusLabelText: "Purchased", dateLabelText: processDate(date: confirmPurchaseDate))
//    progressMeterNodeArr.append(purchaseDateNode)
//    // auction second node
//} else if let auctionEndDate = post.auctionEndDate {
//    let endedNode = ProgressMeterNode(statusLabelText: AuctionStatus.ended.toDisplay, dateLabelText: processDate(date: auctionEndDate))
//    progressMeterNodeArr.append(endedNode)
//    // escrow second node
//} else if let transferDate = post.transferDate {
//    let transferNode = ProgressMeterNode(statusLabelText: "Transferred", dateLabelText: processDate(date: transferDate))
//    progressMeterNodeArr.append(transferNode)
//    // auction third node
//} else if let auctionTransferredDate = post.auctionTransferredDate {
//    let auctionTransferNode = ProgressMeterNode(statusLabelText: AuctionStatus.transferred.toDisplay, dateLabelText: processDate(date: auctionTransferredDate))
//    progressMeterNodeArr.append(auctionTransferNode)
//    // escrow second node
//} else if let confirmReceived = post.confirmReceivedDate {
//    let receivedNode = ProgressMeterNode(statusLabelText: "Received", dateLabelText: processDate(date: confirmReceived))
//    progressMeterNodeArr.append(receivedNode)
//}

// escrow deployment
//self.transactionService.prepareTransactionForNewContract(contractABI: purchaseABI2, bytecode: purchaseBytecode2, value: String(price), completion: { [weak self] (transaction, error) in
//    guard let `self` = self else { return }
//    if let error = error {
//        switch error {
//            case .invalidAmountFormat:
//                self.alert.showDetail("Error", with: "The price is in a wrong format", for: self)
//            case .contractLoadingError:
//                self.alert.showDetail("Error", with: "Escrow Contract Loading Error", for: self)
//            case .createTransactionIssue:
//                self.alert.showDetail("Error", with: "Escrow Contract Transaction Issue", for: self)
//            case .retrievingEstimatedGasError:
//                self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
//            case .retrievingCurrentAddressError:
//                self.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
//            default:
//                self.alert.showDetail("Error", with: "There was an error deploying your escrow contract.", for: self)
//        }
//    }
//
//    // minting
//    self.transactionService.prepareTransactionForMinting { (mintTransaction, mintError) in
//        if let error = mintError {
//            switch error {
//                case .contractLoadingError:
//                    self.alert.showDetail("Error", with: "Minting Contract Loading Error", for: self)
//                case .createTransactionIssue:
//                    self.alert.showDetail("Error", with: "Minting Contract Transaction Issue", for: self)
//                case .retrievingEstimatedGasError:
//                    self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
//                default:
//                    self.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
//            }
//        }
//
//        //                /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
//        //                let localDatabase = LocalDatabase()
//        //                guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
//        //                    self.alert.showDetail("Sorry", with: "There was an error retrieving your wallet.", for: self)
//        //                    return
//        //                }
//        //
//        //                var balanceResult: BigUInt!
//        //                do {
//        //                    balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
//        //                } catch {
//        //                    self.alert.showDetail("Sorry", with: "An error retrieving the balance of your wallet.", for: self)
//        //                    return
//        //                }
//        //
//        //                guard let currentGasPrice = try? Web3swiftService.web3instance.eth.getGasPrice() else {
//        //                    self.alert.showDetail("Sorry", with: "An error retreiving the current gas price.", for: self)
//        //                    return
//        //                }
//        //
//        //                guard let estimatedGasForMinting = estimatedGasForMinting,
//        //                      let estimatedGasForDeploying = estimatedGasForDeploying,
//        //                      let priceInWei = Web3.Utils.parseToBigUInt(String(price), units: .eth),
//        //                      ((estimatedGasForMinting + estimatedGasForDeploying) * currentGasPrice + priceInWei) < balanceResult else {
//        //                    self.alert.showDetail("Sorry", with: "Insufficient funds in your wallet to cover both the gas fee and the deposit for the escrow.", height: 300, for: self)
//        //                    return
//        //                }
//
//        // escrow deployment transaction
//        if let transaction = transaction {
//            self.hideSpinner {}
//            let content = [
//                StandardAlertContent(
//                    index: 0,
//                    titleString: "Password",
//                    body: [AlertModalDictionary.passwordSubtitle: ""],
//                    isEditable: true,
//                    fieldViewHeight: 50,
//                    messageTextAlignment: .left,
//                    alertStyle: .withCancelButton
//                ),
//                StandardAlertContent(
//                    index: 1,
//                    titleString: "Details",
//                    body: [
//                        AlertModalDictionary.gasLimit: "",
//                        AlertModalDictionary.gasPrice: "",
//                        AlertModalDictionary.nonce: ""
//                    ],
//                    isEditable: true,
//                    fieldViewHeight: 50,
//                    messageTextAlignment: .left,
//                    alertStyle: .noButton
//                )
//            ]
//
//            DispatchQueue.main.async {
//                let alertVC = AlertViewController(height: 400, standardAlertContent: content)
//                alertVC.action = { [weak self] (modal, mainVC) in
//                    // responses to the main vc's button
//                    mainVC.buttonAction = { _ in
//                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
//                              !password.isEmpty else {
//                            self?.alert.fading(text: "Email cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
//                            return
//                        }
//
//                        guard let self = self else { return }
//                        self.dismiss(animated: true, completion: {
//                            self.progressModal = ProgressModalViewController(postType: .tangible)
//                            self.progressModal.titleString = "Posting In Progress"
//                            self.present(self.progressModal, animated: true, completion: {
//                                DispatchQueue.global(qos: .userInitiated).async {
//                                    do {
//                                        // create new contract
//                                        let result = try transaction.send(password: password, transactionOptions: nil)
//                                        print("deployment result", result)
//                                        let update: [String: PostProgress] = ["update": .deployingEscrow]
//                                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//
//                                        // mint transaction
//                                        if let mintTransaction = mintTransaction {
//                                            do {
//                                                let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
//                                                print("mintResult", mintResult)
//
//                                                // firebase
//                                                let senderAddress = result.transaction.sender!.address
//                                                let ref = self.db.collection("post")
//                                                let id = ref.document().documentID
//
//                                                // for deleting photos afterwards
//                                                self.documentId = id
//
//                                                // txHash is either minting or transferring the ownership
//                                                self.db.collection("post").document(id).setData([
//                                                    "sellerUserId": userId,
//                                                    "senderAddress": senderAddress,
//                                                    "escrowHash": result.hash,
//                                                    "mintHash": mintResult.hash,
//                                                    "date": Date(),
//                                                    "title": itemTitle,
//                                                    "description": desc,
//                                                    "price": price,
//                                                    "category": category,
//                                                    "status": PostStatus.ready.rawValue,
//                                                    "tags": Array(tokensArr),
//                                                    "itemIdentifier": convertedId,
//                                                    "isReviewed": false,
//                                                    "type": "digital",
//                                                    "deliveryMethod": deliveryMethod,
//                                                    "saleFormat": saleFormat,
//                                                    "paymentMethod": paymentMethod
//                                                ]) { (error) in
//                                                    if let error = error {
//                                                        self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                    } else {
//                                                        /// no need for a socket if you don't have images to upload?
//                                                        /// show the success alert here
//                                                        /// apply the same for resell
//                                                        //                                                                    self.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c")
//                                                        //                                                                    self.socketDelegate.delegate = self
//                                                    }
//                                                }
//                                            } catch Web3Error.nodeError(let desc) {
//                                                if let index = desc.firstIndex(of: ":") {
//                                                    let newIndex = desc.index(after: index)
//                                                    let newStr = desc[newIndex...]
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Alert", with: String(newStr), for: self)
//                                                    }
//                                                }
//                                            } catch Web3Error.transactionSerializationError {
//                                                DispatchQueue.main.async {
//                                                    self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                                }
//                                            } catch Web3Error.connectionError {
//                                                DispatchQueue.main.async {
//                                                    self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                                }
//                                            } catch Web3Error.dataError {
//                                                DispatchQueue.main.async {
//                                                    self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                                }
//                                            } catch Web3Error.inputError(_) {
//                                                DispatchQueue.main.async {
//                                                    self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                                }
//                                            } catch Web3Error.processingError(let desc) {
//                                                DispatchQueue.main.async {
//                                                    self.alert.showDetail("Alert", with: desc, height: 320, for: self)
//                                                }
//                                            } catch {
//                                                self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                            }
//                                        }
//
//                                    } catch Web3Error.nodeError(let desc) {
//                                        if let index = desc.firstIndex(of: ":") {
//                                            let newIndex = desc.index(after: index)
//                                            let newStr = desc[newIndex...]
//                                            DispatchQueue.main.async {
//                                                self.alert.showDetail("Alert", with: String(newStr), for: self)
//                                            }
//                                        }
//                                    } catch Web3Error.transactionSerializationError {
//                                        DispatchQueue.main.async {
//                                            self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                        }
//                                    } catch Web3Error.connectionError {
//                                        DispatchQueue.main.async {
//                                            self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                        }
//                                    } catch Web3Error.dataError {
//                                        DispatchQueue.main.async {
//                                            self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                        }
//                                    } catch Web3Error.inputError(_) {
//                                        DispatchQueue.main.async {
//                                            self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                        }
//                                    } catch Web3Error.processingError(let desc) {
//                                        DispatchQueue.main.async {
//                                            self.alert.showDetail("Alert", with: desc, height: 320, for: self)
//                                        }
//                                    } catch {
//                                        self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                    }
//                                } // DispatchQueue.global background
//                            }) // end of self.present completion for ProgressModalVC
//                        }) // end of self.dismiss completion
//                    } // mainVC
//                } // alertVC
//                self.present(alertVC, animated: true, completion: nil)
//            }
//        } // transaction
//    } // end of prepareTransactionForMinting
//}) // end of prepareTransactionForNewContract
//}
