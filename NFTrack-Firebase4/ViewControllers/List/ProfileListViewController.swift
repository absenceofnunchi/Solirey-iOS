//
//  ProfileReviewListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-22.
//
/*
 Abstract: ParentVC for ProfilePostingVC and ProfileReviewListVC, both of which are the tabs within ProfileDetailVC
 */

import UIKit
import FirebaseFirestore

class ProfileListViewController<T>: ParentListViewController<T> {
    let CELL_HEIGHT: CGFloat = 150
    let PAGINATION_LIMIT: Int = 8
    weak var delegate: RefetchDataDelegate?
    var constraints = [NSLayoutConstraint]()
    let db = FirebaseService.shared
    override var postArr: [T] {
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
}
