//
//  PendingViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-05.
//

import UIKit
import FirebaseFirestore

class PendingViewController: UIViewController {
    private var tableView: UITableView!
    private var postArr = [Post]()
    private let refreshControl = UIRefreshControl()
    private let userDefaults = UserDefaults.standard
    private let alert = Alerts()
    private var segmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar(vc: self)
        configureSwitch()
        configureUI()
        configureDataFetch(isBuyer: true)
    }
}

extension PendingViewController {
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
    func configureSwitch() {
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
    @objc func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegmentIndex)
        else { fatalError("No item at \(sender.selectedSegmentIndex)) exists.") }
        
        switch segment {
            case .buying:
                configureDataFetch(isBuyer: true)
            case .selling:
                configureDataFetch(isBuyer: false)
            case .purchases:
                print("purchases")
            case .posts:
                print("posts")
        }
    }
    
    // MARK: - configureDataFetch
    func configureDataFetch(isBuyer: Bool) {
        if let userId = userDefaults.string(forKey: "userId") {
            let ref = FirebaseService.sharedInstance.db.collection("post")
                .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
                .whereField("status", in: ["transferred", "pending"])
            
//            if isBuyer == true {
//                ref = ref.whereField("status", isNotEqualTo: "completed")
//                         .whereField("status", isNotEqualTo: "ready")
//                         .whereField("status", isNotEqualTo: "aborted")
//                         .whereField("status", isNotEqualTo: "completed")
//                         .whereField("status", isNotEqualTo: "resold")
//            }
            
            ref.getDocuments() { [weak self] (querySnapshot, err) in
                if let err = err {
                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self!)
                } else {
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.removeAll()
                        self?.postArr = data
                        
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
        } else {
            self.alert.showDetail("Oops!", with: "You have to be logged in!", for: self)
        }
    }
}

extension PendingViewController: TableViewConfigurable {
    // MARK: - configureUI
    func configureUI() {
        tableView = configureTableView(delegate: self, dataSource: self, height: 250, cellType: ProgressCell.self, identifier: Cell.progressCell)
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        tableView.fill()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
    }
    
    // MARK: - refresh
    @objc func refresh(_ sender: UIRefreshControl) {
        //        configureDataFetch()
    }
}

extension PendingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.progressCell, for: indexPath) as! ProgressCell
        cell.selectionStyle = .none
        
        let post = postArr[indexPath.row]
        cell.set(post: post)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
}
