//
//  MainViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-21.
//

import UIKit
import FirebaseFirestore

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
        configureUI()
    }
}

extension MainViewController {
    func configureUI() {
        view.backgroundColor = .white
        
        
    }
    
    func fetchData() {
        FirebaseService.sharedInstance.db.collection("mint").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    print("snapshot", querySnapshot)
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                    }
                }
            }
    }
}
