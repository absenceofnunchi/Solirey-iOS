//
//  ParentListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-09.
//

/*
 Abstract: ParencVC for MainDetailVC and ListVC. Former fetches data according to the category passed on from MainVC. The latter fetches data according to the segmented switch.
 */

import UIKit
import FirebaseFirestore

class ParentListViewController: UIViewController, TableViewConfigurable {
    private var dataStore: ImageDataStore!
    private lazy var loadingQueue = OperationQueue()
    private lazy var loadingOperations = [IndexPath : DataLoadOperation]()
    let refreshControl = UIRefreshControl()
    let alert = Alerts()
    var postArr = [Post]() {
        didSet {
            dataStore = ImageDataStore(posts: postArr)
        }
    }
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
}

extension ParentListViewController {
    // MARK: - configureUI
    func configureUI() {
        view.backgroundColor = .white
        
        //        tableView = UITableView()
        //        tableView.register(MainDetailCell.self, forCellReuseIdentifier: Cell.mainDetailCell)
        //        tableView.estimatedRowHeight = 100
        //        tableView.rowHeight = 100
        //        tableView.dataSource = self
        //        tableView.delegate = self
        
        tableView = configureTableView(delegate: self, dataSource: self, height: 100, cellType: MainDetailCell.self, identifier: Cell.mainDetailCell)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    func fetchUserData(id: String, completion: @escaping (UserInfo?) -> Void) {
        showSpinner {
            let docRef = FirebaseService.sharedInstance.db.collection("user").document(id)
            docRef.getDocument { [weak self] (document, error) in
                if let document = document, document.exists {
                    if let data = document.data() {
                        let displayName = data[UserDefaultKeys.displayName] as? String
                        let photoURL = data[UserDefaultKeys.photoURL] as? String
                        let userInfo = UserInfo(email: nil, displayName: displayName!, photoURL: photoURL, uid: nil)
                        self?.hideSpinner {
                            completion(userInfo)
                        }
                    }
                } else {
                    self?.hideSpinner {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
        //        configureDataFetch()
    }
}

extension ParentListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.mainDetailCell) as? MainDetailCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        cell.updateAppearanceFor(.pending)
        return cell
    }
}

// MARK:- TableView Delegate
extension ParentListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? MainDetailCell else { return }
        let post = postArr[indexPath.row]
        
        // How should the operation update the cell once the data has been loaded?
        let updateCellClosure: (UIImage?) -> () = { [unowned self] (image) in
            cell.updateAppearanceFor(.fetched(image, post))
            self.loadingOperations.removeValue(forKey: indexPath)
        }
        
        // Try to find an existing data loader
        if let dataLoader = loadingOperations[indexPath] {
            // Has the data already been loaded?
            if let image = dataLoader.image {
                cell.updateAppearanceFor(.fetched(image, post))
                loadingOperations.removeValue(forKey: indexPath)
            } else {
                // No data loaded yet, so add the completion closure to update the cell once the data arrives
                dataLoader.loadingCompleteHandler = updateCellClosure
            }
        } else {
            // Need to create a data loaded for this index path
            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
                // Provide the completion closure, and kick off the loading operation
                dataLoader.loadingCompleteHandler = updateCellClosure
                loadingQueue.addOperation(dataLoader)
                loadingOperations[indexPath] = dataLoader
            } else {
                cell.updateAppearanceFor(.none(post))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If there's a data loader for this index path we don't need it any more. Cancel and dispose
        if let dataLoader = loadingOperations[indexPath] {
            dataLoader.cancel()
            loadingOperations.removeValue(forKey: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        fetchUserData(id: post.sellerUserId) { [weak self] (userInfo) in
            if let userInfo = userInfo {
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                listDetailVC.userInfo = userInfo
                listDetailVC.tableViewRefreshDelegate = self
                self?.navigationController?.pushViewController(listDetailVC, animated: true)
            } else {
                self?.alert.showDetail("Sorry", with: "There was an error fetching Data. Please try again", for: self!)
            }
        }
    }
}

// MARK:- TableView Prefetching DataSource
extension ParentListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let _ = loadingOperations[indexPath] { return }
            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
                loadingQueue.addOperation(dataLoader)
                loadingOperations[indexPath] = dataLoader
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let dataLoader = loadingOperations[indexPath] {
                dataLoader.cancel()
                loadingOperations.removeValue(forKey: indexPath)
            }
        }
    }
}


extension ParentListViewController: TableViewRefreshDelegate {
    // MARK: - didRefreshTableView
    @objc func didRefreshTableView() {

    }
}
