//
//  ProfileReviewListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-22.
//

import UIKit
import FirebaseFirestore

class ProfileReviewListViewController: ParentListViewController<Review> {
    let CELL_HEIGHT: CGFloat = 150
    let PAGINATION_LIMIT: Int = 8
    weak var delegate: RefetchDataDelegate?
    var constraints = [NSLayoutConstraint]()
    private let db = FirebaseService.shared
    override var postArr: [Review] {
        didSet {
            let tableViewHeight = CGFloat(postArr.count) * CELL_HEIGHT
            NSLayoutConstraint.deactivate(constraints)
            constraints.removeAll()
            constraints.append(tableView.heightAnchor.constraint(equalToConstant: tableViewHeight))
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ]+constraints)

            var indexPathArr = [IndexPath]()
            let from = max(postArr.count - PAGINATION_LIMIT, 0)
            let to = max(postArr.count, 0)
            for i in stride(from: from, to: to, by: 1) {
                indexPathArr.append(IndexPath(item: i, section: 0))
            }
            tableView.insertRows(at: indexPathArr, with: .none)
            
            preferredContentSize = CGSize(width: view.bounds.size.width, height: tableViewHeight + 700)
        }
    }
    override func setDataStore(postArr: [Review]) {
        dataStore = ReviewImageDataStore(posts: postArr)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(barButton))
        self.parent!.navigationItem.rightBarButtonItem = rightBarButton
        
        // for PaginateFetchDelegate
        // returns the fetched arr, last snapshot, or error
        db.delegate = self
    }
    
    @objc func barButton() {
        tableView.reloadRows(at: [IndexPath(item: 0, section: 0)], with: .top)
    }
    
    override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: ReviewCell.self, identifier: ReviewCell.identifier)
        tableView.prefetchDataSource = self
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        let reviewDetailVC = ReviewDetailViewController()
        reviewDetailVC.post = post
        self.navigationController?.pushViewController(reviewDetailVC, animated: true)
    }
}

extension ProfileReviewListViewController: PaginateFetchDelegate {
    func didFetchPaginate(reviewArr: [Review]?,  error: Error?) {
        if let error = error {
            self.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
        }
        
        if let reviewArr = reviewArr{
            print("new arr", reviewArr)
            self.postArr.append(contentsOf: reviewArr)
        }
    }
}

