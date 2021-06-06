//
//  ListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import FirebaseFirestore

class ListViewController: UIViewController {
    private var tableView: UITableView!
    private var postArr = [Post]()
    private let refreshControl = UIRefreshControl()
    private let alert = Alerts()
    private let userDefaults = UserDefaults.standard
    private var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar(vc: self)
        configureSwitch()
        configureUI()
        configureDataFetch(isBuyer: true, status: .complete)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension ListViewController: TableViewConfigurable {
    fileprivate enum Segment: Int, CaseIterable {
        case purchases, posts
        
        func asString() -> String {
            switch self {
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
            case .purchases:
                configureDataFetch(isBuyer: true, status: .complete)
            case .posts:
                configureDataFetch(isBuyer: false, status: .ready)
        }
    }
    
    // MARK: - configureDataFetch
    func configureDataFetch(isBuyer: Bool, status: PostStatus?) {
        if let userId = userDefaults.string(forKey: "userId") {
            var ref = FirebaseService.sharedInstance.db.collection("post")
                .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            
            if status != nil {
                ref = ref.whereField("status", isEqualTo: status!.rawValue)
            }
                
            ref.getDocuments() { [weak self] (querySnapshot, err) in
                    if let err = err {
                        self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self!)
                    } else {
                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.postArr.removeAll()
                            self?.postArr = data

                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                                self?.delay(1.0) {
                                    DispatchQueue.main.async {
                                        self?.refreshControl.endRefreshing()
                                    }
                                }
                            }
                        }
                    }
                }
        } else {
            self.alert.showDetail("Oops!", with: "You have to be logged in!", for: self)
        }
    }
    
    // MARK: - configureUI
    func configureUI() {
        tableView = configureTableView(delegate: self, dataSource: self, height: 100, cellType: ListCell.self, identifier: Cell.listCell)
        view.addSubview(tableView)
        tableView.fill()

        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
    }
    

    
    @objc func refresh(_ sender: UIRefreshControl) {
//        configureDataFetch()
    }
}

extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.listCell, for: indexPath) as! ListCell
        cell.selectionStyle = .none
        
        let title = postArr[indexPath.row].title
        let date = postArr[indexPath.row].date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        
        cell.set(title: title, date: formattedDate)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        listDetailVC.tableViewRefreshDelegate = self
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
}

extension ListViewController: TableViewRefreshDelegate {
    // MARK: - didRefreshTableView
    func didRefreshTableView() {
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
        configureDataFetch(isBuyer: true, status: .complete)
    }
}
