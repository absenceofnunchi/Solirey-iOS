//
//  CollectFundsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-15.
//

import UIKit
import FirebaseFirestore

class CollectFundsViewController: PurchasesViewController {
    final override func viewDidLoad() {
        super.viewDidLoad()
        title = "Collect Funds"
        configureNavigationBar()
    }
    
    func configureNavigationBar() {
        guard let infoImage = UIImage(systemName: "info.circle") else { return }
        let infoButtonItem = UIBarButtonItem(image: infoImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
        infoButtonItem.tag = 0
        self.navigationItem.rightBarButtonItem = infoButtonItem
    }
    
    final override func fetchData() {
        guard let userId = userId else { return }
        FirebaseService.shared.db.collection("post")
            .whereField(PositionStatus.sellerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: [PostStatus.complete.rawValue])
            .whereField("isWithdrawn", isEqualTo: false)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .getDocuments() { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    print("error.localizedDescription", error.localizedDescription)
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
                    
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr = data
                    }
                }
            }
    }
    
    final override  func refetchData(lastSnapshot: QueryDocumentSnapshot) {
        guard let userId = userId else { return }
        FirebaseService.shared.db.collection("post")
            .whereField(PositionStatus.buyerUserId.rawValue, isEqualTo: userId)
            .whereField("status", in: [PostStatus.complete.rawValue])
            .whereField("isWithdrawn", isEqualTo: false)
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .getDocuments() { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
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
                    
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.append(contentsOf: data)
                    }
                }
            }
    }
    
    final override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let post = postArr[indexPath.row]
        var actionArray = [UIAction]()
        
        let profile = UIAction(title: "Profile", image: UIImage(systemName: "person.crop.circle")) { [weak self] action in
            self?.navToProfile(post)
        }
        actionArray.append(profile)
        
        if let files = post.files, files.count > 0 {
            let profile = UIAction(title: "Images", image: UIImage(systemName: "photo")) { [weak self] action in
                self?.imagePreivew(post)
            }
            actionArray.append(profile)
        }
        
        let history = UIAction(title: "Tx Detail", image: UIImage(systemName: "rectangle.stack")) { [weak self] action in
            self?.navToHistory(post)
        }
        actionArray.append(history)
        
        let reviews = UIAction(title: "Reviews", image: UIImage(systemName: "square.and.pencil")) { [weak self] action in
            self?.navToReviews(post)
        }
        actionArray.append(reviews)
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: actionArray)
        }
    }
    
    final override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let post = postArr[indexPath.row]
        let profileAction = navToProfileContextualAction(post)
        let imageAction = imagePreviewContextualAction(post)
        let historyAction = navToHistoryContextualAction(post)
        let reviewAction = navToReviewsContextualAction(post)
        
        profileAction.backgroundColor = UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1)
        imageAction.backgroundColor = UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1)
        historyAction.backgroundColor = UIColor(red: 112/255, green: 176/255, blue: 161/255, alpha: 1)
        reviewAction.backgroundColor = UIColor(red: 110/255, green: 126/255, blue: 175/255, alpha: 1)
        
        let configuration = UISwipeActionsConfiguration(actions: [profileAction, imageAction, historyAction, reviewAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

extension CollectFundsViewController {
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Funds To Collect", detail: InfoText.fundsToCollect)])
                self.present(infoVC, animated: true, completion: nil)
            default:
                break
        }
    }
}
