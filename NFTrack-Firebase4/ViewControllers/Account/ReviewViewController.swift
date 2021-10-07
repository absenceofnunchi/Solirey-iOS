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
import Combine

class ReviewViewController: ParentListViewController<Post>, PostParseDelegate {
    internal var segmentedControl: UISegmentedControl!
    private var userIdField: String!
    private var customNavView: BackgroundView5!
    private var currentIndex: Int! = 0
    final var storage: Set<AnyCancellable>! = {
        return Set<AnyCancellable>()
    }()
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        setConstraints()
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
        tableView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
        
        customNavView = BackgroundView5()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(customNavView)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -60),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50)
        ])
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
    private enum Segment: Int, CaseIterable {
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

extension ReviewViewController: ContextAction {
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
            guard let post = self?.postArr[indexPath.row] else { return }
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
        
        return UIContextMenuConfiguration(identifier: "ReviewPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: actionArray)
        }
    }
    
    final override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    final override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [])
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
        let configuration = UISwipeActionsConfiguration(actions: [profileAction, imageAction, historyAction, reviewAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
