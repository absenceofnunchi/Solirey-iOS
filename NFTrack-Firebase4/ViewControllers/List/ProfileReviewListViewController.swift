//
//  ProfileReviewListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-27.
//

import UIKit
import FirebaseFirestore

class ProfileReviewListViewController: ProfileListViewController<Review> {
    final override func setDataStore(postArr: [Review]) {
        dataStore = ReviewImageDataStore(posts: postArr)
    }

    final override func configureUI() {
        super.configureUI()
        tableView = configureTableView(
            delegate: self,
            dataSource: self,
            height: CELL_HEIGHT,
            cellType: ReviewCell.self,
            identifier: ReviewCell.identifier
        )
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    final override func fetchData() {
        guard let uid = userInfo.uid else { return }
        
        dataStore = nil
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
        postArr.removeAll()
        tableView.reloadData()
        
        db?.collection("review")
            .document(uid)
            .collection("details")
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .getDocuments(completion: { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
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
                
                let documents = querySnapshot.documents
                var reviewArr = [Review]()
                documents.forEach { (querySnapshot) in
                    let data = querySnapshot.data()
                    var revieweeUserId, reviewerDisplayName, reviewerPhotoURL, reviewerUserId, review, confirmReceivedHash, itemDocId, uniqueIdentifier: String!
                    /// finalized date, confirmRecievedDate
                    var date: Date!
                    var starRating: Int!
                    var files: [String]?
                    data.forEach({ (item) in
                        switch item.key {
                            case "revieweeUserId":
                                revieweeUserId = item.value as? String
                            case "reviewerDisplayName":
                                reviewerDisplayName = item.value as? String
                            case "reviewerPhotoURL":
                                reviewerPhotoURL = item.value as? String
                            case "reviewerUserId":
                                reviewerUserId = item.value as? String
                            case "starRating":
                                starRating = item.value as? Int
                            case "review":
                                review = item.value as? String
                            case "files":
                                files = item.value as? [String]
                            case "confirmReceivedHash":
                                confirmReceivedHash = item.value as? String
                            case "date":
                                let timeStamp = item.value as? Timestamp
                                date = timeStamp?.dateValue()
                            case "itemDocId":
                                itemDocId = item.value as? String
                            case "uniqueIdentifier":
                                uniqueIdentifier = item.value as? String
                            default:
                                break
                        }
                    })
                    let reviewModel = Review(
                        revieweeUserId: revieweeUserId,
                        reviewerDisplayName: reviewerDisplayName,
                        reviewerPhotoURL: reviewerPhotoURL,
                        reviewerUserId: reviewerUserId,
                        starRating: starRating,
                        review: review,
                        files: files,
                        confirmReceivedHash: confirmReceivedHash,
                        date: date,
                        itemDocId: itemDocId,
                        uniqueIdentifier: uniqueIdentifier
                    )
                    
                    reviewArr.append(reviewModel)
                }
                
                self?.postArr = reviewArr
            })
    }
    
    final override func refetchData(lastSnapshot: QueryDocumentSnapshot) {
        guard let uid = userInfo.uid else { return }

        let next = db?.collection("review")
            .document(uid)
            .collection("details")
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
        
        next?.getDocuments(completion: { [weak self] (querySnapshot, error) in
            defer {
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
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
            let documents = querySnapshot.documents
            var reviewArr = [Review]()
            documents.forEach { (querySnapshot) in
                let data = querySnapshot.data()
                var revieweeUserId, reviewerDisplayName, reviewerPhotoURL, reviewerUserId, review, confirmReceivedHash, itemDocId, uniqueIdentifier: String!
                var date: Date!
                var starRating: Int!
                var files: [String]?
                data.forEach({ (item) in
                    switch item.key {
                        case "revieweeUserId":
                            revieweeUserId = item.value as? String
                        case "reviewerDisplayName":
                            reviewerDisplayName = item.value as? String
                        case "reviewerPhotoURL":
                            reviewerPhotoURL = item.value as? String
                        case "reviewerUserId":
                            reviewerUserId = item.value as? String
                        case "starRating":
                            starRating = item.value as? Int
                        case "review":
                            review = item.value as? String
                        case "files":
                            files = item.value as? [String]
                        case "confirmReceivedHash":
                            confirmReceivedHash = item.value as? String
                        case "date":
                            let timeStamp = item.value as? Timestamp
                            date = timeStamp?.dateValue()
                        case "itemDocId":
                            itemDocId = item.value as? String
                        case "uniqueIdentifier":
                            uniqueIdentifier = item.value as? String
                        default:
                            break
                    }
                })
                
                let reviewModel = Review(
                    revieweeUserId: revieweeUserId,
                    reviewerDisplayName: reviewerDisplayName,
                    reviewerPhotoURL: reviewerPhotoURL,
                    reviewerUserId: reviewerUserId,
                    starRating: starRating,
                    review: review,
                    files: files,
                    confirmReceivedHash: confirmReceivedHash,
                    date: date,
                    itemDocId: itemDocId,
                    uniqueIdentifier: uniqueIdentifier
                )
                reviewArr.append(reviewModel)
            }
            
            self?.postArr.append(contentsOf: reviewArr)
        })
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
}

extension ProfileReviewListViewController {
    final override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        animator.addAnimations { [weak self] in
            self?.show(destinationViewController, sender: self)
        }
    }
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    final override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let post = postArr[indexPath.row]
        var actionArray = [UIAction]()
        
        if let files = post.files, files.count > 0 {
            let profile = UIAction(title: "Images", image: UIImage(systemName: "photo")) { [weak self] action in
                guard let galleries = post.files else { return }
                self?.imagePreivew(galleries)
            }
            actionArray.append(profile)
        }
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: actionArray)
        }
    }
    
    final override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    final override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [])
    }
    
    final override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let files = postArr[indexPath.row].files else { return nil }
        let imageAction = imagePreviewContextualAction(files)
        imageAction.backgroundColor = UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1)
        
        let configuration = UISwipeActionsConfiguration(actions: [imageAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    private func getPreviewVC(post: Review) -> ReviewDetailViewController {
        let reviewDetailVC = ReviewDetailViewController()
        reviewDetailVC.post = post
        return reviewDetailVC
    }
    
    private func imagePreviewContextualAction(_ files: [String]) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Images") { [weak self] (action, swipeButtonView, completion) in
            self?.imagePreivew(files)
            completion(true)
        }
    }
    
    private func imagePreivew(_ galleries: [String]) {
        guard galleries.count > 0 else { return }
        let pvc = PageViewController<BigSinglePageViewController<String>>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: galleries)
        let singlePageVC = BigSinglePageViewController(gallery: galleries.first, galleries: galleries)
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        pvc.modalPresentationStyle = .fullScreen
        pvc.modalTransitionStyle = .crossDissolve
        present(pvc, animated: true, completion: nil)
    }
}

