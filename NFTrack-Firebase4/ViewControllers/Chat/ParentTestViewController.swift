//
//  ParentTestViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-13.
//

import UIKit
import FirebaseFirestore

class ParentTestViewController<T>: UIViewController, TableViewConfigurable, UITableViewDataSource, UITableViewDataSourcePrefetching, UITableViewDelegate {
    var dataStore: ImageDataStore<T>!
    var loadingQueue = OperationQueue()
    var loadingOperations = [IndexPath : DataLoadOperation]()
    var postArr = [T]() {
        didSet {
            setDataStore(postArr: postArr)
        }
    }
    var tableView: UITableView!
    var firstListener: ListenerRegistration!
    var nextListener: ListenerRegistration!
    var lastSnapshot: QueryDocumentSnapshot!
    let PAGINATION_LIMIT: Int = 15
    
    var userId: String! {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId)
    }
    
    func setDataStore(postArr: [T]) {
        dataStore = ImageDataStore(posts: postArr)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParentTableCell<T>.identifier) as? ParentTableCell<T> else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ParentTableCell<ChatListCell> else { return }

        // How should the operation update the cell once the data has been loaded?
        let updateCellClosure: (UIImage?) -> () = { [weak self] (image) in
            print("updateCellClosure")
            cell.updateAppearanceFor(.fetched(image))
            guard let self = self else { return }
            self.loadingOperations.removeValue(forKey: indexPath)
        }

        // Try to find an existing data loader
        if let dataLoader = loadingOperations[indexPath] {
            // Has the data already been loaded?
            if let image = dataLoader.image {
                cell.updateAppearanceFor(.fetched(image))
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
            }
        }
    }
//
//    // 1. The entire data is loaded to the data store
//    // 2. For every cell, prefetch the Operation that pertains to indexPath.row
//    // 3. Add the operation to the loading queue (addOperation)
//    // 4. Add the opertaion to the loadingOperation dictionary
//    // 5. If the data has been loaded already, delete it form the loadingOperations queue
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If there's a data loader for this index path we don't need it any more. Cancel and dispose
        if let dataLoader = loadingOperations[indexPath] {
            dataLoader.cancel()
            loadingOperations.removeValue(forKey: indexPath)
        }
    }

    // MARK:- TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

    // MARK:- TableView Prefetching DataSource
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
    
    @objc dynamic func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc dynamic func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //
    }
    
    @objc dynamic func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
    
    @objc dynamic func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
}
