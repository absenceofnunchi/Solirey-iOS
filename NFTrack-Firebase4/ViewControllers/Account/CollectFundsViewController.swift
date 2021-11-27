//
//  CollectFundsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-15.
//

/*
 Abstract:
 The sellers have to collect funds from the sold items i.e. the highest bid amount after the auction has ended. The paid amount in the escrow amount after the item has been delivered.
 The buyers have to collected the outbid amount they failed to collect prior to the auction being finished.
 */

import UIKit
import FirebaseFirestore

class CollectFundsViewController: PurchasesViewController {
    internal var segmentedControl: UISegmentedControl!
    private var segmentContainer: Segment!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        title = "Collect Funds"
        configureNavigationBar()
        configureSwitch()
    }
    
    func configureNavigationBar() {
        guard let infoImage = UIImage(systemName: "info.circle") else { return }
        let infoButtonItem = UIBarButtonItem(image: infoImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
        infoButtonItem.tag = 0
        self.navigationItem.rightBarButtonItem = infoButtonItem
    }
    
    // Fetch the data of the sold items
    final override func fetchData() {
        guard let userId = userId else { return }
        
        dataStore = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        postArr.removeAll()
        tableView.reloadData()
        
        FirebaseService.shared.db.collection("post")
            .whereField(PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: [PostStatus.complete.rawValue, AuctionStatus.transferred.rawValue])
            .whereField("isWithdrawn", isEqualTo: false)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .getDocuments() { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
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
                    
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr = data
                    }
                }
            }
    }
    
    final override  func refetchData(lastSnapshot: QueryDocumentSnapshot) {
        guard let userId = userId else { return }
        FirebaseService.shared.db.collection("post")
            .whereField(PositionStatus.buyerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: [PostStatus.complete.rawValue, AuctionStatus.transferred.rawValue])
            .whereField("isWithdrawn", isEqualTo: false)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .getDocuments() { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
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
                    
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.append(contentsOf: data)
                    }
                }
            }
    }
    
    final override func executeAfterDragging() {
        switch segmentContainer {
            case .sellerUserId:
                refetchData(lastSnapshot: lastSnapshot)
                break
            case .buyerUserId:
                configureAuctionRefetch()
                break
            default:
                break
        }
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
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: actionArray)
        }
    }
    
    final override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let post = postArr[indexPath.row]
        let profileAction = navToProfileContextualAction(post)
        let imageAction = imagePreviewContextualAction(post)
        let historyAction = navToHistoryContextualAction(post)
        let reviewAction = navToReviewsContextualAction(post)
        
        profileAction.backgroundColor = UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1)
        imageAction.backgroundColor = UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1)
        historyAction.backgroundColor = UIColor(red: 112/255, green: 176/255, blue: 161/255, alpha: 1)
        reviewAction.backgroundColor = UIColor(red: 110/255, green: 126/255, blue: 175/255, alpha: 1)
        
        let configuration = UISwipeActionsConfiguration(actions: [profileAction, imageAction, historyAction, reviewAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

extension CollectFundsViewController {
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Funds To Collect", detail: InfoText.fundsToCollect)])
                self.present(infoVC, animated: true, completion: nil)
            default:
                break
        }
    }
}

extension CollectFundsViewController: SegmentConfigurable {
    private enum Segment: Int, CaseIterable {
        case sellerUserId, buyerUserId

        func asString() -> String {
            switch self {
                case .sellerUserId:
                    return "Sold"
                case .buyerUserId:
                    return "Purchased"
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
        
        segmentContainer = segment
        
        switch segment {
            case .sellerUserId:
                fetchData()
            case .buyerUserId:
                configureAuctionFetch()
        }
    }
}

extension CollectFundsViewController {
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
        firstListener = FirebaseService.shared.db.collection("post")
            .whereField("bidders", arrayContains: userId)
            .whereField("status", in: [AuctionStatus.transferred.rawValue])
            .whereField("sellerUserId", isNotEqualTo: userId)
            .order(by: "sellerUserId", descending: true)
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
        nextListener = FirebaseService.shared.db.collection("post")
            .whereField("bidders", arrayContains: userId)
            .whereField("status", in: [AuctionStatus.ended.rawValue])
            .whereField("sellerUserId", isNotEqualTo: userId)
            .order(by: "sellerUserId", descending: true)
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
}


// 1. Resell
// 2. The progress bar
// 3. Auction end event
// 4. Collect fund segmented controller for pending returns
