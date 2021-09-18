//
//  ReviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-20.
//
/*
 List of pending reviews
 */

import UIKit

class ReviewViewController: ParentListViewController<Post>, PostParseDelegate {
    internal var segmentedControl: UISegmentedControl!
    private var userIdField: String!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSwitch()
        configureDataFetch(userIdField: "buyerUserId")
    }
    
    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    final override func configureUI() {
        super.configureUI()
        title = "Pending Reviews"
        
        tableView = configureTableView(delegate: self, dataSource: self, height: 150, cellType: ListCell.self, identifier: ListCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    

    final func configureDataFetch(userIdField: String) {
        guard let userId = userId else {
            self.alert.showDetail("Sorry", with: "Please try re-logging back in.", for: self)
            return
        }
        // only valid for 1 month
        guard let fromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else {return}
        postArr.removeAll()
        FirebaseService.shared.db.collection("post")
            .whereField(userIdField, isEqualTo: userId)
            .whereField("isReviewed", isEqualTo: false)
            .whereField("status", isEqualTo: "complete")
            .whereField("confirmReceivedDate", isGreaterThan: fromDate)
            .order(by: "confirmReceivedDate", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .getDocuments() { [weak self] (querySnapshot, err) in
                if let err = err {
                    print(err)
                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self)
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
                    
                    self?.imageCache.removeAllObjects()
                    
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
    
    final func configureDataRefetch(userIdField: String) {
        guard let userId = userId else {
            self.alert.showDetail("Sorry", with: "Please try re-logging back in.", for: self)
            return
        }
        // only valid for 1 month
        guard let fromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else {return}
        FirebaseService.shared.db.collection("post")
            .whereField(userIdField, isEqualTo: userId)
            .whereField("isReviewed", isEqualTo: false)
            .whereField("status", isEqualTo: "complete")
            .whereField("confirmReceivedDate", isGreaterThan: fromDate)
            .order(by: "confirmReceivedDate", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .getDocuments() { [weak self] (querySnapshot, err) in
                if let err = err {
                    print(err)
                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self)
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
                    
                    self?.imageCache.removeAllObjects()
                    
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
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ListCell.identifier) as? ListCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        let reviewPostVC = ReviewPostViewController()
        reviewPostVC.post = post
        reviewPostVC.delegate = self
        self.navigationController?.pushViewController(reviewPostVC, animated: true)
    }
    
    // MARK: - didRefreshTableView
    final override func didRefreshTableView(index: Int = 0) {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
        switch index {
            case 0:
                userIdField = "buyerUserId"
                configureDataFetch(userIdField: userIdField)
            case 1:
                userIdField = "sellerUserId"
                configureDataFetch(userIdField: userIdField)
            default:
                break
        }
    }
    
    override func executeAfterDragging() {
        configureDataRefetch(userIdField: userIdField)
    }
}

extension ReviewViewController: SegmentConfigurable {
    enum Segment: Int, CaseIterable {
        case buyerUserId, sellerUserId
        
        func asString() -> String {
            switch self {
                case .buyerUserId:
                    return "Purchased"
                case .sellerUserId:
                    return "Sold"
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
        switch segment {
            case .buyerUserId:
                configureDataFetch(userIdField: "buyerUserId")
            case .sellerUserId:
                configureDataFetch(userIdField: "sellerUserId")
        }
    }
}
