//
//  MainDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import FirebaseFirestore

class MainDetailViewController: UIViewController {
    private var dataStore: ImageDataStore!
    private lazy var loadingQueue = OperationQueue()
    private lazy var loadingOperations = [IndexPath : DataLoadOperation]()
    var postArr = [Post]() {
        didSet {
            dataStore = ImageDataStore(posts: postArr)
        }
    }
    var tableView: UITableView!
    var category: String! {
        didSet {
            title = category!
            FirebaseService.sharedInstance.db.collection("post")
                .whereField("category", isEqualTo: category! as String)
                .whereField("status", isEqualTo: "ready")
                .getDocuments() { [weak self](querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.postArr = data
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    }
                }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
}

extension MainDetailViewController {
    // MARK: - configureUI
    func configureUI() {
        view.backgroundColor = .white
        
        tableView = UITableView()
        tableView.register(MainDetailCell.self, forCellReuseIdentifier: Cell.mainDetailCell)
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = 100
        tableView.prefetchDataSource = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.fill()
    }
}

extension MainDetailViewController: UITableViewDataSource {
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
extension MainDetailViewController: UITableViewDelegate {
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
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
}

// MARK:- TableView Prefetching DataSource
extension MainDetailViewController: UITableViewDataSourcePrefetching {
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



//for document in querySnapshot!.documents {
//    //                            print("\(document.documentID) => \(document.data())")
//    let data = document.data()
//    var postId, userId, title, description, price, mintHash, escrowHash, id: String!
//    var ownersId, ownersHash: [String]!
//    var date: Date!
//    var images: [String]?
//    data.forEach { (item) in
//        switch item.key {
//            case "postId":
//                postId = item.value as? String
//            case "userId":
//                userId = item.value as? String
//            case "title":
//                title = item.value as? String
//            case "description":
//                description = item.value as? String
//            case "date":
//                let timeStamp = item.value as? Timestamp
//                date = timeStamp?.dateValue()
//            case "images":
//                images = item.value as? [String]
//            case "price":
//                price = item.value as? String
//            case "mintHash":
//                mintHash = item.value as? String
//            case "escrowHash":
//                escrowHash = item.value as? String
//            case "id":
//                id = item.value as? String
//            case "ownersId":
//                ownersId = item.value as? [String]
//            case "ownersHash":
//                ownersHash = item.value as? [String]
//            default:
//                break
//        }
//    }
//    
//    let post = Post(documentId: document.documentID, postId: postId, userId: userId, title: title, description: description, date: date, images: images, price: price, mintHash: mintHash, escrowHash: escrowHash, id: id, ownersId: ownersId, ownersHash: ownersHash)
//    
//    self?.postArr.append(post)
//}
