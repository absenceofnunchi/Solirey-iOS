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
                    var revieweeUserId, reviewerDisplayName, reviewerPhotoURL, reviewerUserId, review, confirmReceivedHash: String!
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
                            default:
                                break
                        }
                    })
                    let reviewModel = Review(revieweeUserId: revieweeUserId, reviewerDisplayName: reviewerDisplayName, reviewerPhotoURL: reviewerPhotoURL, reviewerUserId: reviewerUserId, starRating: starRating, review: review, files: files, confirmReceivedHash: confirmReceivedHash, date: date)
                    reviewArr.append(reviewModel)
                }
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
                var revieweeUserId, reviewerDisplayName, reviewerPhotoURL, reviewerUserId, review, confirmReceivedHash: String!
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
                        default:
                            break
                    }
                })
                
                let reviewModel = Review(revieweeUserId: revieweeUserId, reviewerDisplayName: reviewerDisplayName, reviewerPhotoURL: reviewerPhotoURL, reviewerUserId: reviewerUserId, starRating: starRating, review: review, files: files, confirmReceivedHash: confirmReceivedHash, date: date)
                reviewArr.append(reviewModel)
            }
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
