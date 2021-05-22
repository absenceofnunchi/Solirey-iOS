//
//  ListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import Firebase
import FirebaseFirestore

class ListViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle!
    var tableView: UITableView!
    var postArr = [Post]()
    let refreshControl = UIRefreshControl()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSwitch()
        configureNavigationBar()
        configureUI()
        configureDataFetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension ListViewController {
    // MARK: - configureSwitch
    func configureSwitch() {
        let segmentTextContent = [
            NSLocalizedString("Progress", comment: ""),
            NSLocalizedString("List", comment: ""),
        ]
        
        // Segmented control as the custom title view.
        let segmentedControl = UISegmentedControl(items: segmentTextContent)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        segmentedControl.addTarget(self, action: #selector(action(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
    }
    
    // MARK: - configureDataFetch
    func configureDataFetch() {
        postArr.removeAll()
        handle = Auth.auth().addStateDidChangeListener { [weak self](auth, user) in
            if user != nil {
                FirebaseService.sharedInstance.db.collection("mint").whereField("userId", isEqualTo: user!.uid)
                    .getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            for document in querySnapshot!.documents {
                                print("\(document.documentID) => \(document.data())")
                                let data = document.data()
                                var postId, userId, title, description, price, txhash, nonce: String!
                                var date: Date!
                                var images: [String]?
                                data.forEach { (item) in
                                    switch item.key {
                                        case "postId":
                                            postId = item.value as? String
                                        case "userId":
                                            userId = item.value as? String
                                        case "title":
                                            title = item.value as? String
                                        case "description":
                                            description = item.value as? String
                                        case "date":
                                            let timeStamp = item.value as? Timestamp
                                            date = timeStamp?.dateValue()
                                        case "images":
                                            images = item.value as? [String]
                                        case "price":
                                            price = item.value as? String
                                        case "transactionHash":
                                            txhash = item.value as? String
                                        case "nonce":
                                            nonce = item.value as? String
                                        default:
                                            break
                                    }
                                }
                                
                                let post = Post(postId: postId, userId: userId, title: title, description: description, date: date, images: images, price: price, txHash: txhash, nonce: nonce)
                                
                                self?.postArr.append(post)
                            }
                            
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                                self?.refreshControl.endRefreshing()
                            }
                        }
                    }
            } else {
                
            }
        }
    }
    
    // MARK: - configureUI
    func configureUI() {
        view.backgroundColor = .white
        tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(ListCell.self, forCellReuseIdentifier: "ListCell")
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
//        edgesForExtendedLayout = .top
//        extendedLayoutIncludesOpaqueBars = true
        
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
        
        // -----------------------------------------------------------
        // NAVIGATION BAR SHADOW
        // -----------------------------------------------------------
//        self.navigationController?.navigationBar.layer.masksToBounds = false
//        self.navigationController?.navigationBar.layer.shadowColor = UIColor.gray.cgColor
//        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2)
//        self.navigationController?.navigationBar.layer.shadowRadius = 5
//        self.navigationController?.navigationBar.layer.shadowOpacity = 0.7
        
        // title
        title = "Item List"
    }
    
    @objc func action(_ sender: AnyObject) {
        Swift.debugPrint("CustomTitleViewController IBAction invoked")
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
        configureDataFetch()
    }
}

extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListCell
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
