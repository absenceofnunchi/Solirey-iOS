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

class ListViewController: ParentListViewController<Post> {
    private let userDefaults = UserDefaults.standard
    final var segmentedControl: UISegmentedControl!
    private var currentIndex: Int! = 0
    private var db: Firestore! {
        return FirebaseService.shared.db
    }
    private var storage = Set<AnyCancellable>()
    private var segmentRetainer: Segment!
    override var PAGINATION_LIMIT: Int {
        get {
            return 10
        }
        set {}
    }
    private var customNavView: BackgroundView5!

    final override func viewDidLoad() {
        super.viewDidLoad()
        applyBarTintColorToTheNavigationBar()
        configureSwitch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if tableView == nil {
            configureTableView()
        }
        
        didRefreshTableView(index: currentIndex)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lastSnapshot = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        
        if firstListener != nil {
            firstListener.remove()
        }
        
        if nextListener != nil {
            nextListener.remove()
        }
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
    
    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    private func configureTableView() {
        tableView = configureTableView(delegate: self, dataSource: self, height: 450, cellType: ProgressCell.self, identifier: ProgressCell.identifier)
        tableView.prefetchDataSource = self
        tableView.contentInset = UIEdgeInsets(top: 65, left: 0, bottom: 0, right: 0)
        view.addSubview(tableView)
        tableView.fill()
        
        customNavView = BackgroundView5()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(customNavView)
        setCustomNavConstraints()
    }
    
    final override func configureUI() {
        super.configureUI()
        
        if tableView == nil {
            configureTableView()
        }
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    final func setCustomNavConstraints() {
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -65),
            customNavView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProgressCell.identifier) as? ProgressCell else {
            fatalError("Sorry, could not load cell")
        }
        
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        
        guard let saleFormat = SaleFormat(rawValue: post.saleFormat) else {
            self.alert.showDetail("Error", with: "There was an error accessing the item data.", for: self)
            return
        }
        
        switch saleFormat {
            case .onlineDirect:
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                self.navigationController?.pushViewController(listDetailVC, animated: true)
            case .openAuction:
                guard let auctionHash = post.auctionHash else { return }
                Future<TransactionReceipt, PostingError> { promise in
                    Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
                }
                .sink { [weak self] (completion) in
                    switch completion {
                        case .failure(let error):
                            self?.alert.showDetail("Contract Address Loading Error", with: error.localizedDescription, for: self)
                        case .finished:
                            break
                    }
                } receiveValue: { [weak self] (receipt) in
                    guard let contractAddress = receipt.contractAddress,
                          let currentAddress = Web3swiftService.currentAddress else {
                        self?.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
                        auctionDetailVC.post = post
                        self?.navigationController?.pushViewController(auctionDetailVC, animated: true)
                    }
                }
                .store(in: &storage)
        }
    }
    
    // MARK: - didRefreshTableView
    final override func didRefreshTableView(index: Int = 0) {
        segmentedControl.selectedSegmentIndex = index
        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
        view.layoutIfNeeded()
        
        // for swiping left and right so that the index doesn't overflow
        currentIndex = index
  
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
            case .posts:
                    configureDataRefetch(isBuyer: false, status: [PostStatus.ready.rawValue], lastSnapshot: lastSnapshot)
            case .auction:
                    configureAuctionRefetch()
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
        
        switch segment {
            case .buying:
                self.configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case .selling:
                self.configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case .auction:
                self.configureAuctionFetch()
            case .posts:
                self.configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
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
    
    func configureDataRefetch(isBuyer: Bool, status: [String], lastSnapshot: QueryDocumentSnapshot) {
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
        
    // MARK: - configureAuctionFetch()
    final func configureAuctionFetch() {
        guard let userId = userId else { return }
        
        dataStore = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        postArr.removeAll()

        firstListener = db.collection("post")
            .whereField("bidders", arrayContains: userId)
            .whereField("status", in: [AuctionStatus.bid.rawValue, AuctionStatus.ended.rawValue, AuctionStatus.transferred.rawValue])
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
                            self?.postArr = data
                        }
                    }
                }
            }
    }
    
    // MARK: - configureAuctionRefetch()
    final func configureAuctionRefetch() {
        guard let userId = userId else { return }
        
        nextListener = db.collection("post")
            .whereField("bidders", arrayContains: userId)
            .whereField("status", in: [AuctionStatus.bid.rawValue, AuctionStatus.ended.rawValue, AuctionStatus.transferred.rawValue])
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
    
    final func transitionView(completion: @escaping () -> Void) {
        if firstListener != nil {
            firstListener.remove()
        }
        
        if nextListener != nil {
            nextListener.remove()
        }
        
        let newTableView = configureTableView(delegate: self, dataSource: self, height: 450, cellType: ProgressCell.self, identifier: ProgressCell.identifier)
        newTableView.prefetchDataSource = self
        UIView.transition(from: tableView, to: newTableView, duration: 0, options: .transitionCrossDissolve) { [weak self] (_) in
            DispatchQueue.main.async {
                newTableView.fill()
                self?.tableView = newTableView
                self?.customNavView = BackgroundView5()
                self?.customNavView.translatesAutoresizingMaskIntoConstraints = false
                guard let cnv = self?.customNavView else { return }
                self?.tableView.addSubview(cnv)
                self?.setCustomNavConstraints()
                completion()
            }
        }
    }
}

extension ListViewController: FetchUserConfigurable {
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
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
        
        let profile = UIAction(title: "Profile", image: UIImage(systemName: "person.crop.circle")) { [weak self] action in
            guard let post = self?.postArr[indexPath.row] else { return }
            self?.navToProfile(post)
        }
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: [profile])
        }
    }
    
    private func navToProfile(_ post: Post) {
        showSpinner { [weak self] in
            Future<UserInfo, PostingError> { promise in
                self?.fetchUserData(userId: post.sellerUserId, promise: promise)
            }
            .sink { (completion) in
                switch completion {
                    case .failure(.generalError(reason: let err)):
                        self?.alert.showDetail("Error", with: err, for: self)
                        break
                    case .finished:
                        break
                    default:
                        break
                }
            } receiveValue: { (userInfo) in
                self?.hideSpinner({
                    DispatchQueue.main.async {
                        let profileDetailVC = ProfileDetailViewController()
                        profileDetailVC.userInfo = userInfo
                        self?.navigationController?.pushViewController(profileDetailVC, animated: true)
                    }
                })
            }
            .store(in: &self!.storage)
        }
    }
    
    private func getPreviewVC(post: Post) -> ListDetailViewController {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        return listDetailVC
    }
}
