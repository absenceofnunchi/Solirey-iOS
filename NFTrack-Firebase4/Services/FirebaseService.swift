//
//  FirebaseService.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-14.
//

import Foundation
import FirebaseStorage
import Firebase
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    var db: Firestore! {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        let db = Firestore.firestore()
        return db
    }
    
    let storage = Storage.storage()
    lazy var storageRef = storage.reference()
    var imageRef: StorageReference!
    weak var profileReviewDelegate: ProfileReviewListViewController?
    weak var profilePostDelegate: ProfilePostingsViewController?
    weak var lastSnapshotDelegate: ProfileDetailViewController?
}

extension FirebaseService: PostParseDelegate {
    func uploadFile(fileName: String, userId: String, completion: @escaping (StorageUploadTask?, FileUploadError?) -> Void) {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let localFile = documentDirectory.appendingPathComponent(fileName).appendingPathExtension("")
            if FileManager.default.fileExists(atPath: localFile.path) {
                let metadata = StorageMetadata()
//                metadata.contentType = "image/*"
                
                imageRef = storageRef.child(userId).child(fileName)
                // Upload file and metadata to the object 'images/mountains.jpg'
                let uploadTask = imageRef.putFile(from: localFile, metadata: metadata)
                
                completion(uploadTask, nil)
            } else {
                completion(nil, .fileNotAvailable)
            }
        } catch {
            completion(nil, .fileManagerError(error.localizedDescription))
        }
    }
    
    func uploadFile(fileURL: URL, userId: String, completion: @escaping (StorageUploadTask?, FileUploadError?) -> Void) {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let metadata = StorageMetadata()
            //                metadata.contentType = "image/*"
            
            imageRef = storageRef.child(userId).child(fileURL.lastPathComponent)
            // Upload file and metadata to the object 'images/mountains.jpg'
            let uploadTask = imageRef.putFile(from: fileURL, metadata: metadata)
            
            completion(uploadTask, nil)
        } else {
            completion(nil, .fileNotAvailable)
        }
    }
    
    func downloadURL() {
        imageRef.downloadURL { (url, error) in
            if let error = error {
                print("downloadURL error", error)
            }
            
            guard let downloadURL = url else {
                print("Uh-oh, an error occurred!")
                
                return
            }
            
            print("downloadURL", downloadURL)
        }
    }
    
    func downloadImage(urlString: String, completion: @escaping (UIImage?, Error?) -> Void) {
        // Create a reference to the file you want to download
        let httpsReference = storage.reference(forURL: urlString)
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        httpsReference.getData(maxSize: 15000000) { data, error in
            if let error = error {
                completion(nil, error)
            } else {
                // Data for "images/island.jpg" is returned
                let image = UIImage(data: data!)
                completion(image, nil)
            }
        }
    }
    
    func getReviews(uid: String) {
        let first = db?.collection("review").document(uid).collection("details")
            .order(by: "date", descending: true)
            .limit(to: 8)
        
        first?.getDocuments(completion: { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            self?.profileReviewDelegate?.didFetchPaginate(reviewArr: nil, error: error)
            
            guard let snapshot = snapshot else {
                print("snapshot error")
                return
            }
            
            let documents = snapshot.documents
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
                        
            if let lastSnapshot = snapshot.documents.last {
                self?.lastSnapshotDelegate?.didGetLastSnapshot(lastSnapshot)
                self?.profileReviewDelegate?.didFetchPaginate(reviewArr: reviewArr, error: nil)
            }
        })
    }
    
    func refetchReviews(uid: String, lastSnapshot: QueryDocumentSnapshot) {
        let next = db?.collection("review").document(uid).collection("details")
            .order(by: "date", descending: true)
            .limit(to: 8)
            .start(afterDocument: lastSnapshot)
        
        next?.getDocuments(completion: { [weak self] (snapshot, error) in
            self?.profileReviewDelegate?.didFetchPaginate(reviewArr: nil, error: error)

            guard let snapshot = snapshot else {
                print("snapshot error")
                return
            }
            
            let documents = snapshot.documents
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

            if let lastSnapshot = snapshot.documents.last {
                self?.lastSnapshotDelegate?.didGetLastSnapshot(lastSnapshot)
                self?.profileReviewDelegate?.didFetchPaginate(reviewArr: reviewArr, error: nil)
            }
        })
    }
    
    func getCurrentPosts(uid: String) {
        let first = db?.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .order(by: "date", descending: true)
            .limit(to: 8)
            
        first?.getDocuments { [weak self] (querySnapshot, err) in
                if let err = err {
                    print("err", err)
                    self?.profilePostDelegate?.didFetchPaginate(postArr: nil, error: err)
                } else {
                    if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.profilePostDelegate?.didFetchPaginate(postArr: postArr, error: nil)
                    }
                }
            }
    }
    
    func refetchPosts(uid: String, lastSnapshot: QueryDocumentSnapshot) {
        let next = db?.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .order(by: "date", descending: true)
            .limit(to: 8)
            .start(afterDocument: lastSnapshot)
        
        next?.getDocuments { [weak self] (querySnapshot, err) in
            if let err = err {
                self?.profilePostDelegate?.didFetchPaginate(postArr: nil, error: err)
            } else {
                if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                    self?.profilePostDelegate?.didFetchPaginate(postArr: postArr, error: nil)
                }
            }
        }
    }
}

//func getReviews(uid: String) {
//    let first = db?.collection("review").document(uid).collection("details")
//        .order(by: "finalizedDate")
//        .limit(to: 2)
//
//    first?.addSnapshotListener({ [weak self] (snapshot, error) in
//        self?.delegate?.didFetchPaginate(reviewArr: nil, error: error)
//
//        guard let snapshot = snapshot else {
//            print("snapshot error")
//            return
//        }
//
//        let documents = snapshot.documents
//        var reviewArr = [Review]()
//        documents.forEach { (querySnapshot) in
//            let data = querySnapshot.data()
//            var revieweeUserId, reviewerDisplayName, reviewerPhotoURL, reviewerUserId, review, confirmReceivedHash: String!
//            var finalizedDate: Date!
//            var starRating: Int!
//            var images: [String]?
//            data.forEach({ (item) in
//                switch item.key {
//                    case "revieweeUserId":
//                        revieweeUserId = item.value as? String
//                    case "reviewerDisplayName":
//                        reviewerDisplayName = item.value as? String
//                    case "reviewerPhotoURL":
//                        reviewerPhotoURL = item.value as? String
//                    case "reviewerUserId":
//                        reviewerUserId = item.value as? String
//                    case "starRating":
//                        starRating = item.value as? Int
//                    case "review":
//                        review = item.value as? String
//                    case "images":
//                        images = item.value as? [String]
//                    case "confirmReceivedHash":
//                        confirmReceivedHash = item.value as? String
//                    case "finalizedDate":
//                        let timeStamp = item.value as? Timestamp
//                        finalizedDate = timeStamp?.dateValue()
//                    default:
//                        break
//                }
//            })
//            let reviewModel = Review(revieweeUserId: revieweeUserId, reviewerDisplayName: reviewerDisplayName, reviewerPhotoURL: reviewerPhotoURL, reviewerUserId: reviewerUserId, starRating: starRating, review: review, images: images, confirmReceivedHash: confirmReceivedHash, finalizedDate: finalizedDate)
//            reviewArr.append(reviewModel)
//        }
//
//        if let lastSnapshot = snapshot.documents.last {
//            self?.lastSnapshotDelegate?.didGetLastSnapshot(lastSnapshot)
//            self?.delegate?.didFetchPaginate(reviewArr: reviewArr, error: nil)
//        }
//    })
//}
////        guard let uid = userInfo.uid else { return }
////        FirebaseService.shared.db.collection("review")
////            .whereField("revieweeUserId", isEqualTo: uid)
////            .getDocuments { [weak self] (querySnapshot, err) in
////                if let err = err {
////                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self)
////                } else {
////                    var reviewArr = [Review]()
////                    for document in querySnapshot!.documents {
////                        let data = document.data()
////                        var revieweeUserId, reviewerDisplayName, reviewerPhotoURL, reviewerUserId, review, confirmReceivedHash: String!
////                        var finalizedDate: Date!
////                        var starRating: Int!
////                        var images: [String]?
////                        data.forEach({ (item) in
////                            switch item.key {
////                                case "revieweeUserId":
////                                    revieweeUserId = item.value as? String
////                                case "reviewerDisplayName":
////                                    reviewerDisplayName = item.value as? String
////                                case "reviewerPhotoURL":
////                                    reviewerPhotoURL = item.value as? String
////                                case "reviewerUserId":
////                                    reviewerUserId = item.value as? String
////                                case "starRating":
////                                    starRating = item.value as? Int
////                                case "review":
////                                    review = item.value as? String
////                                case "images":
////                                    images = item.value as? [String]
////                                case "confirmReceivedHash":
////                                    confirmReceivedHash = item.value as? String
////                                case "finalizedDate":
////                                    let timeStamp = item.value as? Timestamp
////                                    finalizedDate = timeStamp?.dateValue()
////                                default:
////                                    break
////                            }
////                        })
////                        let reviewModel = Review(revieweeUserId: revieweeUserId, reviewerDisplayName: reviewerDisplayName, reviewerPhotoURL: reviewerPhotoURL, reviewerUserId: reviewerUserId, starRating: starRating, review: review, images: images, confirmReceivedHash: confirmReceivedHash, finalizedDate: finalizedDate)
////                        reviewArr.append(reviewModel)
////                    }
////                    self?.profileReviewVC.postArr = reviewArr
////            }
////        }
//
//func refetchReviews(uid: String, lastSnapshot: QueryDocumentSnapshot) {
//    let next = db?.collection("review").document(uid).collection("details")
//        .order(by: "finalizedDate")
//        .limit(to: 8)
//        .start(afterDocument: lastSnapshot)
//
//    next?.addSnapshotListener({ [weak self] (snapshot, error) in
//        self?.delegate?.didFetchPaginate(reviewArr: nil, error: error)
//
//        guard let snapshot = snapshot else {
//            print("snapshot error")
//            return
//        }
//
//        var num: Int! = 0
//        let documents = snapshot.documents
//        var reviewArr = [Review]()
//        documents.forEach { (querySnapshot) in
//            let data = querySnapshot.data()
//            var revieweeUserId, reviewerDisplayName, reviewerPhotoURL, reviewerUserId, review, confirmReceivedHash: String!
//            var finalizedDate: Date!
//            var starRating: Int!
//            var images: [String]?
//            data.forEach({ (item) in
//                switch item.key {
//                    case "revieweeUserId":
//                        revieweeUserId = item.value as? String
//                    case "reviewerDisplayName":
//                        reviewerDisplayName = item.value as? String
//                    case "reviewerPhotoURL":
//                        reviewerPhotoURL = item.value as? String
//                    case "reviewerUserId":
//                        reviewerUserId = item.value as? String
//                    case "starRating":
//                        starRating = item.value as? Int
//                    case "review":
//                        //                            review = item.value as? String
//                        review = "\(String(describing: num))"
//                    case "images":
//                        images = item.value as? [String]
//                    case "confirmReceivedHash":
//                        confirmReceivedHash = item.value as? String
//                    case "finalizedDate":
//                        let timeStamp = item.value as? Timestamp
//                        finalizedDate = timeStamp?.dateValue()
//                    default:
//                        break
//                }
//                num += 1
//            })
//
//            let reviewModel = Review(revieweeUserId: revieweeUserId, reviewerDisplayName: reviewerDisplayName, reviewerPhotoURL: reviewerPhotoURL, reviewerUserId: reviewerUserId, starRating: starRating, review: review, images: images, confirmReceivedHash: confirmReceivedHash, finalizedDate: finalizedDate)
//            reviewArr.append(reviewModel)
//        }
//
//        if let lastSnapshot = snapshot.documents.last {
//            self?.lastSnapshotDelegate?.didGetLastSnapshot(lastSnapshot)
//            self?.delegate?.didFetchPaginate(reviewArr: reviewArr, error: nil)
//        }
//    })
//}

