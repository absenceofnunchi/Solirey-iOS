//
//  ProfilePostingsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-22.
//

import UIKit
import FirebaseFirestore

class ProfilePostingsViewController: ProfileListViewController<Post>, PostParseDelegate {
    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    final override func configureUI() {
        super.configureUI()
        tableView = configureTableView(
            delegate: self,
            dataSource: self,
            height: CELL_HEIGHT,
            cellType: ProfilePostCell.self,
            identifier: ProfilePostCell.identifier
        )
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
 
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfilePostCell.identifier) as? ProfilePostCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        listDetailVC.tableViewRefreshDelegate = self
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
    
    final override func fetchData() {
        guard let uid = userInfo.uid else { return }
        db?.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .getDocuments { [weak self] (querySnapshot, err) in
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
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
                
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the user's posts.", for: self)
                } else {
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr = data
                    }
                }
            }
    }
    
    final override func refetchData(lastSnapshot: QueryDocumentSnapshot) {
        guard let uid = userInfo.uid else { return }
        db?.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .getDocuments { [weak self] (querySnapshot, err) in
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
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
                
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the user's posts.", for: self)
                } else {
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.append(contentsOf: data)
                    }
                }
            }
    }
}
