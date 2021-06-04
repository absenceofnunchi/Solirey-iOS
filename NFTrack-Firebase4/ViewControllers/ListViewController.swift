//
//  ListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import FirebaseFirestore

class ListViewController: UIViewController {
    var tableView: UITableView!
    var postArr = [Post]()
    let refreshControl = UIRefreshControl()
    let alert = Alerts()
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSwitch()
        configureNavigationBar()
        configureUI()
        configureDataFetch(isBuyer: true, status: .pending)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension ListViewController {
    // MARK: - configureSwitch
    func configureSwitch() {
        let segmentTextContent = [
            NSLocalizedString("Pending", comment: ""),
            NSLocalizedString("My Purchases", comment: ""),
            NSLocalizedString("My Posts", comment: ""),
        ]
        
        // Segmented control as the custom title view.
        let segmentedControl = UISegmentedControl(items: segmentTextContent)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
    }
    
    // MARK: - configureDataFetch
    func configureDataFetch(isBuyer: Bool, status: PostStatus?) {
        if let userId = userDefaults.string(forKey: "userId") {
            var ref = FirebaseService.sharedInstance.db.collection("post")
                .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.userId.rawValue, isEqualTo: userId)
            
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
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    // MARK: - configureUI
    func configureUI() {
        view.backgroundColor = .white
        tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(ListCell.self, forCellReuseIdentifier: Cell.listCell)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.fill()
        
        tableView.rowHeight = 100
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
    }
    
    // MARK: - configureNavigationBar
    func configureNavigationBar() {
        // navigation controller
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .white
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            
        } else {
            self.navigationController?.navigationBar.barTintColor = .white
            self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
//        configureDataFetch()
    }
    
    fileprivate enum Segment: Int {
        case pending, purchases, posts
    }
    
    // MARK: - segmentedControlSelectionDidChange
    @objc func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegmentIndex)
        else { fatalError("No item at \(sender.selectedSegmentIndex)) exists.") }
        
        switch segment {
            case .pending:
                // buyer, pending
                configureDataFetch(isBuyer: true, status: .pending)
            case .purchases:
                // buyer, complete
                configureDataFetch(isBuyer: true, status: .complete)
            case .posts:
                // seller, all status
                // userId field means seller
                configureDataFetch(isBuyer: false, status: nil)
        }
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
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
}
