//
//  ListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import FirebaseFirestore
import Combine
import web3swift

class ListViewController: ParentListViewController<Post>, FetchContractAddress {
    private let userDefaults = UserDefaults.standard
    final var segmentedControl: UISegmentedControl!
    private var currentIndex: Int! = 0
    private var db: Firestore! {
        return FirebaseService.shared.db
    }
    var storage: Set<AnyCancellable>! = {
        return Set<AnyCancellable>()
    }()
    private var segmentRetainer: Segment!
    override var PAGINATION_LIMIT: Int {
        get {
            return 10
        }
        set {}
    }

    private var customNavView: BackgroundView5!
    private var colorPatchView = UIView()
    lazy var colorPatchViewHeight: NSLayoutConstraint = colorPatchView.heightAnchor.constraint(equalToConstant: 0)
//    private var newTableView: UITableView!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        applyBarTintColorToTheNavigationBar()
        configureSwitch()
    }
    
    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    private func configureTableView(tableView: UITableView?) {
        guard let tableView = tableView else { return }
        tableView.register(ImageProgressCardCell.self, forCellReuseIdentifier: ImageProgressCardCell.identifier)
        tableView.register(NoImageProgressCardCell.self, forCellReuseIdentifier: NoImageProgressCardCell.identifier)
        tableView.estimatedRowHeight = 450
        tableView.rowHeight = 450
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.contentInset = UIEdgeInsets(top: 65, left: 0, bottom: 0, right: 0)
        view.addSubview(tableView)
        tableView.fill()
        
        customNavView = BackgroundView5()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(customNavView)
        
        colorPatchView.backgroundColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
        colorPatchView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorPatchView)
        
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -65),
            customNavView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50),
            
            colorPatchView.topAnchor.constraint(equalTo: view.topAnchor),
            colorPatchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            colorPatchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            colorPatchViewHeight,
        ])
    }
    
    final override func configureUI() {
        super.configureUI()
        
        tableView = UITableView()
        configureTableView(tableView: tableView)
        configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    @objc func swiped(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
            case .right:
                if currentIndex - 1 >= 0 {
                    currentIndex -= 1
                } else {
                    return
                }
            case .left:
                if currentIndex + 1 < Segment.allCases.count {
                    currentIndex += 1
                } else {
                    return
                }
            default:
                break
        }
        segmentedControl.selectedSegmentIndex = currentIndex
        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = postArr[indexPath.row]
        var newCell: CardCell!
          
        if let files = post.files, files.count > 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ImageProgressCardCell.identifier) as? ImageProgressCardCell else {
                fatalError("Sorry, could not load cell")
            }

            newCell = cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NoImageProgressCardCell.identifier) as? NoImageProgressCardCell else {
                fatalError("Sorry, could not load cell")
            }

            newCell = cell
        }
        
        newCell.selectionStyle = .none
        newCell.updateAppearanceFor(.pending(post))
        return newCell
    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        
        guard let paymentMethod = PaymentMethod(rawValue: post.paymentMethod),
              let postType = PostType(rawValue: post.type),
              let saleType = SaleType(rawValue: post.saleType),
              let deliveryMethod = DeliveryMethod(rawValue: post.deliveryMethod),
              let contractFormat = ContractFormat(rawValue: post.contractFormat) else {
            self.alert.showDetail("Error", with: "There was an error accessing the item data.", for: self)
            return
        }
        
        let saleConfig = SaleConfig.hybridMethod(
            postType: postType,
            saleType: saleType,
            delivery: deliveryMethod,
            payment: paymentMethod,
            contractFormat: contractFormat
        )
        
        switch saleConfig.value {
            case .tangibleNewSaleShippingEscrowIndividual:
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                // refreshes the MainDetailVC table when the user updates the status
                self.navigationController?.pushViewController(listDetailVC, animated: true)
                break
            case .digitalNewSaleOnlineDirectPaymentIndividual, .tangibleNewSaleInPersonDirectPaymentIntegral:
                let simpleVC = IntegratedSimplePaymentDetailViewController()
                simpleVC.post = post
                self.navigationController?.pushViewController(simpleVC, animated: true)
                break
            case .digitalNewSaleAuctionBeneficiaryIntegral:
                guard let currentAddress = Web3swiftService.currentAddress,
                      let auctionContract = ContractAddresses.integralAuctionAddress else {
                    self.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
                    return
                }
                
                let integralAuctionVC = IntegralAuctionViewController(auctionContractAddress: auctionContract, myContractAddress: currentAddress, post: post)
                integralAuctionVC.post = post
                self.navigationController?.pushViewController(integralAuctionVC, animated: true)
                
                break
            case .digitalNewSaleAuctionBeneficiaryIndividual:
                guard let auctionHash = post.auctionHash else { return }
                getContractAddress(with: auctionHash) { [weak self] (contractAddress) in
                    guard let currentAddress = Web3swiftService.currentAddress else {
                        self?.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
                        auctionDetailVC.post = post
                        self?.navigationController?.pushViewController(auctionDetailVC, animated: true)
                    }
                }
                break
            default:
                break
        }
        
//        switch paymentMethod {
//            case .escrow:
//                let listDetailVC = ListDetailViewController()
//                listDetailVC.post = post
//                // refreshes the MainDetailVC table when the user updates the status
//                self.navigationController?.pushViewController(listDetailVC, animated: true)
//                break
//            case .auctionBeneficiary:
//                guard let auctionHash = post.auctionHash else { return }
//                Future<TransactionReceipt, PostingError> { promise in
//                    Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
//                }
//                .sink { [weak self] (completion) in
//                    switch completion {
//                        case .failure(let error):
//                            self?.alert.showDetail("Contract Address Loading Error", with: error.localizedDescription, for: self)
//                        case .finished:
//                            break
//                    }
//                } receiveValue: { [weak self] (receipt) in
//                    guard let contractAddress = receipt.contractAddress,
//                          let currentAddress = Web3swiftService.currentAddress else {
//                        self?.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
//                        return
//                    }
//
//                    DispatchQueue.main.async {
//                        let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
//                        auctionDetailVC.post = post
//                        self?.navigationController?.pushViewController(auctionDetailVC, animated: true)
//                    }
//                }
//                .store(in: &storage)
//                break
//            case .directTransfer:
//                let simpleVC = SimpleRevisedViewController()
//                simpleVC.post = post
//                self.navigationController?.pushViewController(simpleVC, animated: true)
//                break
//            default:
//                break
//        }
    }
    
    // MARK: - didRefreshTableView
    final override func didRefreshTableView(index: Int = 0) {
        segmentedControl.selectedSegmentIndex = index
        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
        view.layoutIfNeeded()
        
        // for swiping left and right so that the index doesn't overflow
        currentIndex = index
  
        if firstListener != nil {
            firstListener.remove()
        }

        if nextListener != nil {
            nextListener.remove()
        }
        
        switch index {
            case 0:
                // buying
                self.configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case 1:
                // selling
                self.configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case 2:
                // auction
                self.configureAuctionFetch()
            case 3:
                // posts
                self.configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
            default:
                break
        }
        
//        transitionView { [weak self] in
//            switch index {
//                case 0:
//                    // buying
//                    self?.configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//                case 1:
//                    // selling
//                    self?.configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//                case 2:
//                    // auction
//                    self?.configureAuctionFetch()
//                case 3:
//                    // posts
//                    self?.configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
//                default:
//                    break
//            }
//        }
    }
    
    final override func executeAfterDragging() {
        guard postArr.count > 0 else { return }
        
        switch segmentRetainer {
            case .buying:
                    configureDataRefetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue], lastSnapshot: lastSnapshot)
            case .selling:
                    configureDataRefetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue], lastSnapshot: lastSnapshot)
            case .auction:
                configureAuctionRefetch()
            case .posts:
                configurePostingsRefetch(isBuyer: false, status: [PostStatus.ready.rawValue, PostStatus.aborted.rawValue], lastSnapshot: lastSnapshot)
            default:
                break
        }
    }
}

extension ListViewController: SegmentConfigurable, PostParseDelegate {
    enum Segment: Int, CaseIterable {
        case buying, selling, auction, posts
        
        func asString() -> String {
            switch self {
                case .buying:
                    return NSLocalizedString("Buying", comment: "")
                case .selling:
                    return NSLocalizedString("Selling", comment: "")
                case .auction:
                    return NSLocalizedString("Auction", comment: "")
                case .posts:
                    return NSLocalizedString("Postings", comment: "")
            }
        }
        
        static func getSegmentText() -> [String] {
            let segmentArr = Segment.allCases
            var segmentTextArr = [String]()
            for segment in segmentArr {
                segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
            }
            return segmentTextArr
        }
    }
    
    // MARK: - configureSwitch
    final func configureSwitch() {
        // Segmented control as the custom title view.
        let segmentTextContent = Segment.getSegmentText()
        segmentedControl = UISegmentedControl(items: segmentTextContent)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
    }
    
    // MARK: - segmentedControlSelectionDidChange
    @objc final func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegmentIndex)
        else { fatalError("No item at \(sender.selectedSegmentIndex)) exists.") }
        
        // for the swipe gestures
        currentIndex = sender.selectedSegmentIndex
        
        // for pagination
        segmentRetainer = segment
        lastSnapshot = nil
        
        // any leftover operations will still be shown on the wrong tab expecially if the new tab is shorter
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        
        if firstListener != nil {
            firstListener.remove()
        }

        if nextListener != nil {
            nextListener.remove()
        }
        
        switch segment {
            case .buying:
                self.configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case .selling:
                self.configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case .auction:
                self.configureAuctionFetch()
            case .posts:
                self.configurePostingsFetch(isBuyer: false, status: [PostStatus.ready.rawValue, PostStatus.aborted.rawValue])
        }
        
//        transitionView { [weak self] in
//            switch segment {
//                case .buying:
//                    self?.configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//                case .selling:
//                    self?.configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//                case .auction:
//                    self?.configureAuctionFetch()
//                case .posts:
//                    self?.configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
//            }
//        }
    }
    
    // MARK: - configureDataFetch
    final func configureDataFetch(isBuyer: Bool, status: [String]) {
        guard let userId = userId else { return }
        
        dataStore = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        postArr.removeAll()
        tableView.reloadData()

        firstListener = db.collection("post")
            .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: status)
            .whereField("paymentMethod", isNotEqualTo: PaymentMethod.auctionBeneficiary.rawValue)
            .order(by: "paymentMethod", descending: true)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error in Fetching Data", with: "There was an error fetching the posts.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                            self?.delay(1.0) {
                                DispatchQueue.main.async {
                                    self?.refreshControl.endRefreshing()
                                }
                            }
                        }
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        DispatchQueue.main.async {
                            self?.postArr = data
                        }
                    }
                }
            }
    }
    
    func configureDataRefetch(isBuyer: Bool, status: [String], lastSnapshot: QueryDocumentSnapshot) {
        guard let userId = userId else { return }
        nextListener = db.collection("post")
            .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: status)
            .whereField("paymentMethod", isNotEqualTo: PaymentMethod.auctionBeneficiary.rawValue)
            .order(by: "paymentMethod", descending: true)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error", with: "Unable to fetch data. Please try again.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                            self?.delay(1.0) {
                                DispatchQueue.main.async {
                                    self?.refreshControl.endRefreshing()
                                }
                            }
                        }
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        DispatchQueue.main.async {
                            self?.postArr.append(contentsOf: data)
                        }
                    }
                }
            }
    }
        
    // MARK: - configureAuctionFetch()
    final func configureAuctionFetch() {
        guard let userId = userId else { return }
        dataStore = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        postArr.removeAll()
        tableView.reloadData()

        // The order of the auction progress: bid, ended, transfer
        // When the auctionEnd is called the transfer is done at the same time, which means "ended" and "transfer" happen at the same time.
        // Therefore, you only need to fetch the "bid" status.
        firstListener = db.collection("post")
            .whereField("bidders", arrayContains: userId)
            .whereField("status", in: [AuctionStatus.bid.rawValue, AuctionStatus.ended.rawValue])
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error", with: "Unable to fetch data. Please try again.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                            self?.delay(1.0) {
                                DispatchQueue.main.async {
                                    self?.refreshControl.endRefreshing()
                                }
                            }
                        }
                    }
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        DispatchQueue.main.async {
                            self?.postArr = data
                        }
                    }
                }
            }
    }
    
    // MARK: - configureAuctionRefetch()
    final func configureAuctionRefetch() {
        guard let userId = userId else { return }
        
        // The order of the auction progress: bid, ended, transfer
        // When the auctionEnd is called the transfer is done at the same time, which means "ended" and "transfer" happen at the same time.
        // Therefore, you only need to fetch the "bid" status.
        nextListener = db.collection("post")
            .whereField("bidders", arrayContains: userId)
            .whereField("status", in: [AuctionStatus.bid.rawValue, AuctionStatus.ended.rawValue])
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error", with: "Unable to fetch data. Please try again.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                            self?.delay(1.0) {
                                DispatchQueue.main.async {
                                    self?.refreshControl.endRefreshing()
                                }
                            }
                        }
                    }
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        DispatchQueue.main.async {
                            self?.postArr.append(contentsOf: data)
                        }
                    }
                }
            }
    }
    
    // MARK: - configurePostingsFetch
    final func configurePostingsFetch(isBuyer: Bool, status: [String]) {
        guard let userId = userId else { return }
        
        dataStore = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        postArr.removeAll()
        tableView.reloadData()
        
        firstListener = db.collection("post")
            .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: status)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error in Fetching Data", with: "There was an error fetching the posts.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                            self?.delay(1.0) {
                                DispatchQueue.main.async {
                                    self?.refreshControl.endRefreshing()
                                }
                            }
                        }
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        DispatchQueue.main.async {
                            self?.postArr = data
                        }
                    }
                }
            }
    }
    
    func configurePostingsRefetch(isBuyer: Bool, status: [String], lastSnapshot: QueryDocumentSnapshot) {
        guard let userId = userId else { return }
        nextListener = db.collection("post")
            .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: status)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error", with: "Unable to fetch data. Please try again.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                            self?.delay(1.0) {
                                DispatchQueue.main.async {
                                    self?.refreshControl.endRefreshing()
                                }
                            }
                        }
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        DispatchQueue.main.async {
                            self?.postArr.append(contentsOf: data)
                        }
                    }
                }
            }
    }
    
//    final func transitionView(completion: @escaping () -> Void) {
//        if firstListener != nil {
//            firstListener.remove()
//        }
//
//        if nextListener != nil {
//            nextListener.remove()
//        }
//
//        if newTableView == nil {
//            newTableView = UITableView()
//            configureTableView(tableView: newTableView)
//        }
//
//        UIView.transition(from: tableView, to: newTableView, duration: 0, options: .transitionCrossDissolve) { [weak self] (_) in
//            DispatchQueue.main.async {
//                self?.tableView = self?.newTableView
//                self?.configureTableView(tableView: self!.newTableView)
//                self?.newTableView = nil
//                completion()
//            }
//        }
//    }
}

extension ListViewController: ContextAction {
    final override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        animator.addAnimations { [weak self] in
            self?.show(destinationViewController, sender: self)
        }
    }
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    final override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let post = postArr[indexPath.row]
        var actionArray = [UIAction]()
        
        let profile = UIAction(title: "Profile", image: UIImage(systemName: "person.crop.circle")) { [weak self] action in
            self?.navToProfile(post)
        }
        actionArray.append(profile)
        
        if let files = post.files, files.count > 0 {
            let profile = UIAction(title: "Images", image: UIImage(systemName: "photo")) { [weak self] action in
                self?.imagePreivew(post)
            }
            actionArray.append(profile)
        }
        
        let history = UIAction(title: "Tx Detail", image: UIImage(systemName: "rectangle.stack")) { [weak self] action in
            self?.navToHistory(post)
        }
        actionArray.append(history)
        
        let reviews = UIAction(title: "Reviews", image: UIImage(systemName: "square.and.pencil")) { [weak self] action in
            self?.navToReviews(post)
        }
        actionArray.append(reviews)
        
        if userId != post.sellerUserId {
            let chat = UIAction(title: "Chat", image: UIImage(systemName: "message")) { [weak self] action in
                self?.navToChatVC(userId: self?.userId, post: post)
            }
            actionArray.append(chat)
            
            let report = UIAction(title: "Report", image: UIImage(systemName: "flag")) { [weak self] action in
                guard let userId = self?.userId else { return }
                self?.navToReport(userId: userId, post: post)
            }
            actionArray.append(report)
        }
        
        return UIContextMenuConfiguration(identifier: "ListPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: actionArray)
        }
    }
}

extension ListViewController {
    final func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if -scrollView.contentOffset.y > 0 {
            colorPatchViewHeight.constant = -scrollView.contentOffset.y
        }
    }
}
