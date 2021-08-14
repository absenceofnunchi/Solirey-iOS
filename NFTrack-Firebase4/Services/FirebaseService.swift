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
import Combine

struct HttpResponse: Codable {
    let status: String
}

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
    var cancellable: AnyCancellable!
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
            self?.profileReviewDelegate?.didFetchPaginate(data: nil, error: error)
            
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
                self?.profileReviewDelegate?.didFetchPaginate(data: reviewArr, error: nil)
            }
        })
    }
    
    func refetchReviews(uid: String, lastSnapshot: QueryDocumentSnapshot) {
        let next = db?.collection("review").document(uid).collection("details")
            .order(by: "date", descending: true)
            .limit(to: 8)
            .start(afterDocument: lastSnapshot)
        
        next?.getDocuments(completion: { [weak self] (snapshot, error) in
            self?.profileReviewDelegate?.didFetchPaginate(data: nil, error: error)

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
                self?.profileReviewDelegate?.didFetchPaginate(data: reviewArr, error: nil)
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
            guard let querySnapshot = querySnapshot else {
                print("snapshot error")
                return
            }
            
            if let err = err {
                self?.profilePostDelegate?.didFetchPaginate(data: nil, error: err)
            } else {
                if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                    self?.profilePostDelegate?.didFetchPaginate(data: postArr, error: nil)
                }
            }
            
            if let lastSnapshot = querySnapshot.documents.last {
                self?.lastSnapshotDelegate?.didGetLastSnapshot(lastSnapshot)
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
            guard let querySnapshot = querySnapshot else {
                print("snapshot error")
                return
            }
            
            if let err = err {
                self?.profilePostDelegate?.didFetchPaginate(data: nil, error: err)
            } else {
                if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                    self?.profilePostDelegate?.didFetchPaginate(data: postArr, error: nil)
                }
            }
            
            if let lastSnapshot = querySnapshot.documents.last {
                self?.lastSnapshotDelegate?.didGetLastSnapshot(lastSnapshot)
            }
        }
    }
    
    func sendToTopics(
        title: String,
        topic: String,
        content: String
    ) -> AnyPublisher<Data, PostingError> {
        let url = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/sendToTopics-sendToTopics")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters: [String: Any] = [
            "title": title,
            "topic": topic,
            "content": content,
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            return Fail(error: PostingError.generalError(reason: "There was an error serializing parameters to the server."))
                .eraseToAnyPublisher()
        }
        
        let session = URLSession.shared
        return session.dataTaskPublisher(for: request)
            .tryMap() { element -> Data in
                if let httpResponse = element.response as? HTTPURLResponse,
                   let httpStatusCode = APIError.HTTPStatusCode(rawValue: httpResponse.statusCode) {
                    if !(200...299).contains(httpResponse.statusCode) {
                        throw PostingError.apiError(APIError.generalError(reason: httpStatusCode.description))
                    }
                }
                return element.data
            }
            .mapError { $0 as? PostingError ?? PostingError.generalError(reason: "Unknown Error") }
            .eraseToAnyPublisher()
    }
    
    func unsubscribeToTopic(
        topic: String
    ) -> AnyPublisher<Data, PostingError> {
//        let url = URL(string: "http://localhost:5001/nftrack-69488/us-central1/unsubscribeToTopic-unsubscribeToTopic")!
        let url = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/unsubscribeToTopic-unsubscribeToTopic")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters: [String: Any] = [
            "topic": topic,
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            return Fail(error: PostingError.generalError(reason: "There was an error serializing parameters to the server."))
                .eraseToAnyPublisher()
        }
        
        let session = URLSession.shared
        return session.dataTaskPublisher(for: request)
            .tryMap() { element -> Data in
                if let httpResponse = element.response as? HTTPURLResponse,
                   let httpStatusCode = APIError.HTTPStatusCode(rawValue: httpResponse.statusCode) {
                    if !(200...299).contains(httpResponse.statusCode) {
                        throw PostingError.apiError(APIError.generalError(reason: httpStatusCode.description))
                    }
                }
                return element.data
            }
            .mapError({ (error) -> PostingError in
                print("error in unsubscribeToTopic: ", error)
                return error as? PostingError ?? PostingError.generalError(reason: "Unknown Error")
            })
//            .mapError { $0 as? PostingError ?? PostingError.generalError(reason: "Unknown Error") }
            .eraseToAnyPublisher()
    }
    
    // MARK: - getTokenId
    /// uploads the receipt to the Firebase function to get the token number, which will update the Firestore
    func getTokenId1(topics: [String], documentId: String, promise: @escaping (Result<Int, PostingError>) -> Void) {
        // build request URL
        guard let requestURL = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/decodeLog-decodeLog") else {
            return
        }
        //        guard let requestURL = URL(string: "http://localhost:5001/nftrack-69488/us-central1/decodeLog") else {
        //            return
        //        }
        
        // prepare request
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let parameter: [String: Any] = [
            "hexString": topics[0],
            "topics": [
                topics[1],
                topics[2],
                topics[3]
            ],
            "documentID": documentId
        ]
        
        let paramData = try? JSONSerialization.data(withJSONObject: parameter, options: [])
        request.httpBody = paramData
        
        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                promise(.failure(.apiError(APIError.generalError(reason: error.localizedDescription))))
            }
            
            if let response = response as? HTTPURLResponse,
               let httpStatusCode = APIError.HTTPStatusCode(rawValue: response.statusCode) {
                if !(200...299).contains(response.statusCode) {
                    promise(.failure(.apiError(APIError.generalError(reason: httpStatusCode.description))))
                }
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    guard let convertedJson = json as? NSNumber else {
                        promise(.failure(.apiError(APIError.decodingError)))
                        return
                    }
                    print("convertedJson.intValue", convertedJson.intValue)
                    promise(.success(convertedJson.intValue))
                } catch {
                    promise(.failure(.apiError(APIError.decodingError)))
                }
            }
        })
        
        //            observation = task.progress.observe(\.fractionCompleted) { [weak self] (progress, _) in
        //                print("decode log progress", progress)
        //                DispatchQueue.main.async {
        //                    self?.progressModal.progressView.isHidden = false
        //                    self?.progressModal.progressLabel.isHidden = false
        //                    self?.progressModal.progressView.progress = Float(progress.fractionCompleted)
        //                    self?.progressModal.progressLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
        //                    self?.progressModal.progressView.isHidden = true
        //                    self?.progressModal.progressLabel.isHidden = true
        //                }
        //            }
        task.resume()
    }
    
    func unsubscribeToTopic1(topic: String) -> AnyPublisher<Data, APIError> {
//        let url = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/unsubscribeToTopic-unsubscribeToTopic")!
        let url = URL(string: "http://localhost:5001/nftrack-69488/us-central1/unsubscribeToTopic-unsubscribeToTopic")!
        let requestURL = url
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "topic": topic,
        ]
        
        let paramData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = paramData
        
        return URLSession.DataTaskPublisher(request: request, session: .shared)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                
                if httpResponse.statusCode > 300 {
                    if let httpStatusCode = APIError.HTTPStatusCode(rawValue: httpResponse.statusCode) {
                        throw APIError.generalError(reason: httpStatusCode.description)
                    }
                }
                
                return data
            }
            .mapError { error in
                if let error = error as? APIError {
                    return error
                }
                
                if let urlError = error as? URLError {
                    return APIError.networkError(from: urlError)
                }
                
                return APIError.unknown
            }
            .eraseToAnyPublisher()
    }
}



