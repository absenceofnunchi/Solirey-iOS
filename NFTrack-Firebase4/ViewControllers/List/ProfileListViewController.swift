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
    var db: Firestore! {
        return FirebaseService.shared.db
    }
    var userInfo: UserInfo!
    
    required init(userInfo: UserInfo) {
        super.init(nibName: nil, bundle: nil)
        self.userInfo = userInfo
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchData()
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        fetchData()
//    }
    
    func fetchData() {}
    func refetchData(lastSnapshot: QueryDocumentSnapshot) {}
    
    override func executeAfterDragging() {
        refetchData(lastSnapshot: lastSnapshot)
    }
}
