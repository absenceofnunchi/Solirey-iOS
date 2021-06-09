//
//  ListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import FirebaseFirestore

class ListViewController: ParentListViewController {
    private let userDefaults = UserDefaults.standard
    private var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar(vc: self)
        configureSwitch()
        configureDataFetch(isBuyer: true, status: [PostStatus.complete.rawValue])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension ListViewController {
    fileprivate enum Segment: Int, CaseIterable {
        case purchases, posts
        
        func asString() -> String {
            switch self {
                case .purchases:
                    return "Purchases"
                case .posts:
                    return "Posts"
            }
        }
        
        static func getSegmentText() -> [String] {
            let segmentArr = Segment.allCases
            var segmentTextArr = [String]()
            for segment in segmentArr {
                segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
            }
            return segmentTextArr
        }
    }
    
    // MARK: - configureSwitch
    func configureSwitch() {
        // Segmented control as the custom title view.
        let segmentTextContent = Segment.getSegmentText()
        segmentedControl = UISegmentedControl(items: segmentTextContent)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
    }
    
    // MARK: - segmentedControlSelectionDidChange
    @objc func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegmentIndex)
        else { fatalError("No item at \(sender.selectedSegmentIndex)) exists.") }
        
        switch segment {
            case .purchases:
                configureDataFetch(isBuyer: true, status: [PostStatus.complete.rawValue])
            case .posts:
                configureDataFetch(isBuyer: false, status: [PostStatus.ready.rawValue, PostStatus.pending.rawValue, PostStatus.transferred.rawValue])
        }
    }
    
    // MARK: - configureDataFetch
    func configureDataFetch(isBuyer: Bool, status: [String]) {
        if let userId = userDefaults.string(forKey: UserDefaultKeys.userId) {
            FirebaseService.sharedInstance.db.collection("post")
                .whereField(isBuyer ? PositionStatus.buyerUserId.rawValue: PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
                .whereField("status", in: status)
                .getDocuments() { [weak self] (querySnapshot, err) in
                    if let err = err {
                        self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self!)
                    } else {
                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.postArr.removeAll()
                            self?.postArr = data

                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                                self?.delay(1.0) {
                                    DispatchQueue.main.async {
                                        self?.refreshControl.endRefreshing()
                                    }
                                }
                            }
                        }
                    }
                }
        } else {
            self.alert.showDetail("Oops!", with: "You have to be logged in!", for: self)
        }
    }

}

extension ListViewController {
    // MARK: - didRefreshTableView
    override func didRefreshTableView() {
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.sendActions(for: UIControl.Event.valueChanged)
        configureDataFetch(isBuyer: true, status: [PostStatus.complete.rawValue])
    }
}
