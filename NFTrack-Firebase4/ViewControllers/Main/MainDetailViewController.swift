//
//  MainDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import FirebaseFirestore

class MainDetailViewController: ParentListViewController {
    var category: String! {
        didSet {
            title = category!
            FirebaseService.sharedInstance.db.collection("post")
                .whereField("category", isEqualTo: category! as String)
                .whereField("status", isEqualTo: "ready")
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
    }
}

extension MainDetailViewController {
    // MARK: - didRefreshTableView
    override func didRefreshTableView() {
        
    }
}

