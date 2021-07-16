//
//  MainDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import FirebaseFirestore

class MainDetailViewController: ParentListViewController<Post>, PostParseDelegate {
    var category: String! {
        didSet {
            title = category!
            FirebaseService.shared.db.collection("post")
                .whereField("category", isEqualTo: category! as String)
                .whereField("status", isEqualTo: "ready")
                .order(by: "date", descending: true)
                .getDocuments() { [weak self](querySnapshot, err) in
                    if let err = err {
                        self?.alert.showDetail("Error fetching data", with: err.localizedDescription, for: self)
                    } else {
                        defer {
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                        
                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.postArr = data
                            self?.dataStore = PostImageDataStore(posts: data)
                        }
                    }
                }
        }
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    // MARK: - didRefreshTableView
    override func didRefreshTableView(index: Int) {
        
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
        
        guard let saleFormat = SaleFormat(rawValue: post.saleFormat) else {
            self.alert.showDetail("Error", with: "There was an error accessing the item data.", for: self)
            return
        }
        
        switch saleFormat {
            case .onlineDirect:
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                // refreshes the MainDetailVC table when the user updates the status
                listDetailVC.tableViewRefreshDelegate = self
                self.navigationController?.pushViewController(listDetailVC, animated: true)
            case .openAuction:
                let auctionDetailVC = AuctionDetailViewController()
                auctionDetailVC.post = post
                self.navigationController?.pushViewController(auctionDetailVC, animated: true)
        }
    }
}
