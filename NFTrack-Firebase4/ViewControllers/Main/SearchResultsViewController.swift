//
//  SearchResultsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import FirebaseFirestore

class SearchResultsController: ParentListViewController<Post> {
    private var lastSnapshot: QueryDocumentSnapshot!
    private let db = FirebaseService.shared
    typealias FetchResult = Post

    override func viewDidLoad() {
        super.viewDidLoad()
        db.searchResultDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func configureUI() {
        super.configureUI()
        
        tableView = configureTableView(delegate: self, dataSource: self, height: 330, cellType: CardCell.self, identifier: CardCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.identifier) as? CardCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
//    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        guard let cell = cell as? CardCell else { return }
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
    
}

extension SearchResultsController: PaginateFetchDelegate {
    func didGetLastSnapshot(_ lastSnapshot: QueryDocumentSnapshot) {
        self.lastSnapshot = lastSnapshot
    }
    
    func didFetchPaginate(postArr: [Post]?,  error: Error?) {
        if let error = error {
            self.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
        }
        
        if let postArr = postArr {
            self.postArr.append(contentsOf:postArr)
        }
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        let reload_distance:CGFloat = 10.0
        if y > (h + reload_distance) {
//            guard let uid = userInfo.uid else { return }
//            db.refetchReviews(uid: uid, lastSnapshot: self.lastSnapshot)
        }
    }
}
