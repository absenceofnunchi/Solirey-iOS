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
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar(vc: self)
        configureSwitch()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if firstListener != nil {
            firstListener.remove()
        }
        
        if nextListener != nil {
            nextListener.remove()
        }
        
        lastSnapshot = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
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
    
    final override func configureUI() {
        super.configureUI()
        
        tableView = configureTableView(delegate: self, dataSource: self, height: 450, cellType: ProgressCell.self, identifier: ProgressCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
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
    
//    // MARK: - didRefreshTableView
//    final override func didRefreshTableView(index: Int = 0) {
//        segmentedControl.selectedSegmentIndex = index
//        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
//        view.layoutIfNeeded()
//        
//        // for swiping left and right so that the index doesn't overflow
//        currentIndex = index
//        
//        switch index {
//            case 0:
//                // buying
//                configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//            case 1:
//                // selling
//                configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
//            case 2:                
//                // auction
//                configureAuctionFetch()
//            case 3:
//                // posts
//                configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
//            default:
//                break
//        }
//    }
    
    final override func executeAfterDragging() {
        switch segmentRetainer {
            case .buying:
                    configureDataRefetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue], lastSnapshot: lastSnapshot)
            case .selling:
                    configureDataRefetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue], lastSnapshot: lastSnapshot)
            case .posts:
                    configureDataRefetch(isBuyer: false, status: [PostStatus.ready.rawValue], lastSnapshot: lastSnapshot)
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
                transitionView { [weak self] in
                    self?.configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
                }
            case .selling:
                transitionView { [weak self] in
                    self?.configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
                }
            case .auction:
                transitionView { [weak self] in
                    self?.configureAuctionFetch()
                }
            case .posts:
                transitionView { [weak self] in
                    self?.configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
                }
        }
    }
    
    // MARK: - configureDataFetch
    final func configureDataFetch(isBuyer: Bool, status: [String]) {
        guard let userId = userId else { return }
        self.dataStore = nil
        self.postArr.removeAll()
        
        firstListener = db.collection("post")
            .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: status)
            .order(by: "date", descending: true)
            .limit(to: 10)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error in Fetching Data", with: "There was an error fetching the posts", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
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
    
    func configureDataRefetch(isBuyer: Bool, status: [String], lastSnapshot: QueryDocumentSnapshot) {
        guard let userId = userId else { return }
        
        nextListener = db.collection("post")
            .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: status)
            .order(by: "date", descending: true)
            .limit(to: 10)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener() { [weak self] (querySnapshot, error) in
                if let error = error {
                    print(error.localizedDescription)
                    self?.alert.showDetail("Error in Fetching Data", with: error.localizedDescription, for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
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
    
    
    
    // MARK: - configureAuctionFetch()
    final func configureAuctionFetch() {
        guard let userId = userId else { return }
        self.dataStore = nil
        self.postArr.removeAll()
        
        db.collection("post")
            .whereField("bidders", arrayContains: userId)
            .whereField("status", in: [AuctionStatus.bid.rawValue, AuctionStatus.ended.rawValue, AuctionStatus.transferred.rawValue])
            .order(by: "date", descending: true)
            .getDocuments() { [weak self] (querySnapshot, error) in
                if let error = error {
                    self?.alert.showDetail("Error in Fetching Data", with: error.localizedDescription, for: self)
                } else {
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
    
    final func transitionView(completion: @escaping () -> Void) {
        let newTableView = configureTableView(delegate: self, dataSource: self, height: 450, cellType: ProgressCell.self, identifier: ProgressCell.identifier)
        newTableView.prefetchDataSource = self
        UIView.transition(from: tableView, to: newTableView, duration: 0, options: .transitionCrossDissolve) { (_) in
            newTableView.fill()
            self.tableView = newTableView
            completion()
        }
    }
}
