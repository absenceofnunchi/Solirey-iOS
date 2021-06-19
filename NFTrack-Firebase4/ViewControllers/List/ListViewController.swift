//
//  ListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import FirebaseFirestore

class ListViewController: ParentListViewController<Post> {
    private let userDefaults = UserDefaults.standard
    private var segmentedControl: UISegmentedControl!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar(vc: self)
        configureSwitch()
        configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
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
    
    fileprivate enum Segment: Int, CaseIterable {
        case buying, selling, purchases, posts
        
        func asString() -> String {
            switch self {
                case .buying:
                    return "Buying"
                case .selling:
                    return "Selling"
                case .purchases:
                    return "Purchases"
                case .posts:
                    return "Posts"
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
            case .buying:
                configureDataFetch(isBuyer: true, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case .selling:
                configureDataFetch(isBuyer: false, status: [PostStatus.transferred.rawValue, PostStatus.pending.rawValue])
            case .purchases:
                configureDataFetch(isBuyer: true, status: [PostStatus.complete.rawValue])
            case .posts:
                configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue])
        }
    }
    
    // MARK: - configureDataFetch
    final func configureDataFetch(isBuyer: Bool, status: [String]) {
        if let userId = userDefaults.string(forKey: UserDefaultKeys.userId) {
            FirebaseService.shared.db.collection("post")
                .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
                .whereField("status", in: status)
                .getDocuments() { [weak self] (querySnapshot, err) in
                    if let err = err {
                        self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self!)
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
                            self?.postArr.removeAll()
                            self?.postArr = data
                        }
                    }
                }
        } else {
            self.alert.showDetail("Oops!", with: "You have to be logged in!", for: self)
        }
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
    
//    final override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        guard let cell = cell as? ProgressCell else { return }
//        
//        // How should the operation update the cell once the data has been loaded?
//        let updateCellClosure: (UIImage?) -> () = { [unowned self] (image) in
//            cell.updateAppearanceFor(.fetched(image))
//            self.loadingOperations.removeValue(forKey: indexPath)
//        }
//        
//        // Try to find an existing data loader
//        if let dataLoader = loadingOperations[indexPath] {
//            // Has the data already been loaded?
//            if let image = dataLoader.image {
//                cell.updateAppearanceFor(.fetched(image))
//                loadingOperations.removeValue(forKey: indexPath)
//            } else {
//                // No data loaded yet, so add the completion closure to update the cell once the data arrives
//                dataLoader.loadingCompleteHandler = updateCellClosure
//            }
//        } else {
//            // Need to create a data loaded for this index path
//            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
//                // Provide the completion closure, and kick off the loading operation
//                dataLoader.loadingCompleteHandler = updateCellClosure
//                loadingQueue.addOperation(dataLoader)
//                loadingOperations[indexPath] = dataLoader
//            }
//        }
//    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        listDetailVC.tableViewRefreshDelegate = self
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
    
    // MARK: - didRefreshTableView
    final override func didRefreshTableView() {
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
        configureDataFetch(isBuyer: true, status: [PostStatus.complete.rawValue])
    }
}
