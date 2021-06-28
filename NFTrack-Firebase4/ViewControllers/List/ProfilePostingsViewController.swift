//
//  ProfilePostingsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-22.
//

import UIKit

class ProfilePostingsViewController: ProfileListViewController<Post>, PaginateFetchDelegate {
    typealias FetchResult = Post
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        // for PaginateFetchDelegate
        // returns the fetched arr, last snapshot, or error
        db.profilePostDelegate = self
    }
    
    final override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: ProfilePostCell.self, identifier: ProfilePostCell.identifier)
        tableView.prefetchDataSource = self
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        listDetailVC.tableViewRefreshDelegate = self
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
    
    final func didFetchPaginate(postArr: [Post]?,  error: Error?) {
        if let error = error {
            self.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
        }
        
        if let postArr = postArr {
            self.postArr.append(contentsOf:postArr)
        }
    }
}
