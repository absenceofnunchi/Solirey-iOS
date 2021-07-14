//
//  SavedViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-13.
//

import UIKit
import FirebaseFirestore

class SavedViewController: ParentListViewController<Post>, RefetchDataDelegate, PostParseDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Items"
        fetchData()
    }
    
    func fetchData() {
        FirebaseService.shared.db.collection("post")
            .whereField("savedBy", arrayContainsAny: [userId!])
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
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    // MARK: - didRefreshTableView
    override func didRefreshTableView(index: Int = 0) {
        
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
        listDetailVC.delegate = self
        listDetailVC.tableViewRefreshDelegate = self
        self.navigationController?.pushViewController(listDetailVC, animated: true)
        
    }
    
    /// when the save button is toggled
    func didFetchData() {
        fetchData()
    }
}
