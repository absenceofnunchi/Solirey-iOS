//
//  ProfileReviewListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-27.
//

import UIKit

class ProfileReviewListViewController: ProfileListViewController<Review>, PaginateFetchDelegate {
    typealias FetchResult = Review
    final override func setDataStore(postArr: [Review]) {
        dataStore = ReviewImageDataStore(posts: postArr)
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        // for PaginateFetchDelegate
        // returns the fetched arr, last snapshot, or error
        db.profileReviewDelegate = self
    }
    
    final override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: ReviewCell.self, identifier: ReviewCell.identifier)
        tableView.prefetchDataSource = self
        tableView.isScrollEnabled = false
        view.addSubview(tableView)
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReviewCell.identifier) as? ReviewCell else {
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
        let reviewDetailVC = ReviewDetailViewController()
        reviewDetailVC.post = post
        
        self.navigationController?.pushViewController(reviewDetailVC, animated: true)
    }
    
    final func didFetchPaginate(data: [Review]?,  error: Error?) {
        if let error = error {
            self.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
        }
        
        if let data = data {
            self.postArr.append(contentsOf: data)
        }
    }
}
