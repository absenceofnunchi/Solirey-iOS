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
    var dataStore: ImageDataStore!
    var loadingQueue = OperationQueue()
    var loadingOperations = [IndexPath : DataLoadOperation]()
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
    @objc func configureUI() {
        view.backgroundColor = .white
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
        //        configureDataFetch()
    }
}

extension ParentListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArr.count
    }
    
    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParentTableCell.identifier) as? ParentTableCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
}

// MARK:- TableView Delegate
extension ParentListViewController: UITableViewDelegate {
    @objc func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

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
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        listDetailVC.tableViewRefreshDelegate = self
        self.navigationController?.pushViewController(listDetailVC, animated: true)
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
