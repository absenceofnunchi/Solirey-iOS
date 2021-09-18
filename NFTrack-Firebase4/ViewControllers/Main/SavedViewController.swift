//
//  SavedViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-13.
//

import UIKit
import FirebaseFirestore

class SavedViewController: ParentListViewController<Post>, PostParseDelegate {
    var first: Query!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Items"
        fetchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isMovingToParent {
            if firstListener != nil {
                firstListener.remove()
            }
            
            if nextListener != nil {
                nextListener.remove()
            }
        }
    }

    func fetchData() {
        firstListener = FirebaseService.shared.db.collection("post")
            .whereField("savedBy", arrayContainsAny: [userId!])
            .limit(to: PAGINATION_LIMIT)
            .addSnapshotListener() { [weak self](querySnapshot: QuerySnapshot?, err: Error?) in
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the saved posts.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    self?.imageCache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr = data
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    override func configureUI() {
        super.configureUI()
        
        tableView = configureTableView(delegate: self, dataSource: self, height: 330, cellType: CardCell.self, identifier: CardCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
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
        let post = postArr[indexPath.row]
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }

    override func executeAfterDragging() {
        nextListener = FirebaseService.shared.db.collection("post")
            .whereField("savedBy", arrayContainsAny: [userId!])
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener() { [weak self](querySnapshot: QuerySnapshot?, err: Error?) in
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the saved posts.", for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    self?.imageCache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.append(contentsOf: data)
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
    }
}
