//
//  PurchasedViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-06.
//

import UIKit
import Firebase

class PurchasesViewController: ParentListViewController<Post>, PostParseDelegate {
    let CELL_HEIGHT: CGFloat = 450
    weak final var delegate: RefetchDataDelegate?
    override var postArr: [Post] {
        didSet {
            tableView.contentSize = CGSize(width: self.view.bounds.size.width, height: CGFloat(postArr.count) * CELL_HEIGHT + 80)
            tableView.reloadData()
        }
    }
    
    override func configureUI() {
        super.configureUI()
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
            .getDocuments() { [weak self] (querySnapshot, error) in
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
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.removeAll()
                        self?.postArr = data
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
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        let reload_distance:CGFloat = 10.0
        if y > (h + reload_distance) {
            if postArr.count > 0 {
                delegate?.didFetchData()
            }
        }
    }
}
