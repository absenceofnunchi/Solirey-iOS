//
//  PurchasedViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-06.
//

/*
 Abstract:
 Fetches the purchased items from Firestore and displays it.
 The purchased items are anything with their status as "complete".
 This implies all items including tangible items (escrow, direct), digital (online direct, open auction).
 The items will be displayed here until the user decides to resell, at which point, the item will show on ListVC.
 */

import UIKit
import FirebaseFirestore

class PurchasesViewController: ParentListViewController<Post>, PostParseDelegate {
    let CELL_HEIGHT: CGFloat = 450

    override var postArr: [Post] {
        didSet {
            tableView.contentSize = CGSize(width: self.view.bounds.size.width, height: CGFloat(postArr.count) * CELL_HEIGHT + 80)
            tableView.reloadData()
        }
    }
    
    override func configureUI() {
        super.configureUI()
        title = "Purchases"
        tableView = configureTableView(delegate: self, dataSource: self, height: 450, cellType: ProgressCell.self, identifier: ProgressCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }
    
    func fetchData() {
        guard let userId = userId else { return }
        FirebaseService.shared.db.collection("post")
            .whereField(PositionStatus.buyerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: [PostStatus.complete.rawValue])
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .getDocuments() { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    self?.alert.showDetail("Error in Fetching Data", with: error.localizedDescription, for: self)
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
                    
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.removeAll()
                        self?.postArr = data
                    }
                }
            }
    }
    
    func refetchData(lastSnapshot: QueryDocumentSnapshot) {
        guard let userId = userId else { return }
        FirebaseService.shared.db.collection("post")
            .whereField(PositionStatus.buyerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: [PostStatus.complete.rawValue])
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .getDocuments() { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    self?.alert.showDetail("Error in Fetching Data", with: error.localizedDescription, for: self)
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
                    
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.append(contentsOf: data)
                    }
                }
            }
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
    
    override func executeAfterDragging() {
        refetchData(lastSnapshot: lastSnapshot)
    }
}
