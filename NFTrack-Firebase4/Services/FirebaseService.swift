//
//  FirebaseService.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-14.
//

import Foundation
import FirebaseStorage
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
    var cancellable = Set<AnyCancellable>()
}

extension FirebaseService: PostParseDelegate {
    final func uploadFile(fileName: String, userId: String, completion: @escaping (StorageUploadTask?, FileUploadError?) -> Void) {
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
        
    final func uploadFile(fileURL: URL, userId: String, completion: @escaping (StorageUploadTask?, FileUploadError?) -> Void) {
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
    
    final func uploadImage(fileURL: URL, userId: String, completion: @escaping (StorageUploadTask?, FileUploadError?) -> Void) {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/*"
            
            imageRef = storageRef.child(userId).child(fileURL.lastPathComponent)
            // Upload file and metadata to the object 'images/mountains.jpg'
            let uploadTask = imageRef.putFile(from: fileURL, metadata: metadata)
            
            completion(uploadTask, nil)
        } else {
            completion(nil, .fileNotAvailable)
        }
    }
    
    final func downloadURL(urlString: String, promise: @escaping (Result<Data, PostingError>) -> Void) {
        // Create a reference to the file you want to download
        let httpsReference = storage.reference(forURL: urlString)
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        httpsReference.getData(maxSize: 15000000) { data, error in
            if let _ = error {
                promise(.failure(.generalError(reason: "Unable to retrieve the files")))
            }
            
            // Data for "images/island.jpg" is returned
            if let data = data {
                promise(.success(data))
            }
        }
    }
    
    final func downloadImage(urlString: String, completion: @escaping (UIImage?, Error?) -> Void) {
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
}

extension FirebaseService {
    final func sendToTopics(
        title: String,
        content: String,
        topic: String,
        docId: String
    ) -> AnyPublisher<Data, PostingError> {
        guard let url = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/sendToTopics-sendToTopics") else {
            return Fail(error: PostingError.generalError(reason: "There was an error broadcasting your post to the subscribers."))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // the topic will results in a "Malformed topic name" error if it has any white space or special characters
        let convertedTopic = topic.trimmingAllSpaces(using: .whitespacesAndNewlines).lowercased()
        
        let parameters: [String: Any] = [
            "title": title,
            "content": content,
            "topic": convertedTopic,
            "docId": docId
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
    
    final func sendToTopicsVoid(
        title: String,
        content: String,
        topic: String,
        docId: String
    ){
        guard let url = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/sendToTopics-sendToTopics") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // the topic will results in a "Malformed topic name" error if it has any white space or special characters
        let convertedTopic = topic.trimmingAllSpaces(using: .whitespacesAndNewlines).lowercased()
        
        let parameters: [String: Any] = [
            "title": title,
            "content": content,
            "topic": convertedTopic,
            "docId": docId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            return
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                print(error)
            }
            
            if let response = response as? HTTPURLResponse,
               let httpStatusCode = APIError.HTTPStatusCode(rawValue: response.statusCode) {
                if !(200...299).contains(response.statusCode) {
                    print("httpStatusCode.description", httpStatusCode.description)
                }
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    guard let convertedJson = json as? NSNumber else {
                        print("decoding error")
                        return
                    }
                    print("convertedJson.intValue", convertedJson.intValue)
                } catch {
                    print("decoding")
                }
            }
        })

        task.resume()
    }
    
    final func unsubscribeToTopic(
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
    /// uploads the receipt to the Firebase final function to get the token number, which will update the Firestore
    final func getTokenId1(topics: [String], documentId: String, promise: @escaping (Result<Int, PostingError>) -> Void) {
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
    
    final func unsubscribeToTopic1(topic: String) -> AnyPublisher<Data, APIError> {
        //        let url = URL(string: "https://us-central1-nftrack-69488.cloudfinal functions.net/unsubscribeToTopic-unsubscribeToTopic")!
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
    
    /// sender, recipient: firebase userId
    /// content: the message to be show on the push notification
    /// docID: the ID that'll be used to fetch the firebase entry once the recipient taps on the message
    /// Post is not sent along with the message because 1) it's a class and 2) FCM only allows strings in the properties
    final func sendNotification(
        sender: String,
        recipient: String,
        content: String,
        docID: String,
        completion: @escaping (Error?) -> Void
    ) {
        // build request URL
        guard let requestURL = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/sendStatusNotification-sendStatusNotification") else {
            return
        }
        //        guard let requestURL = URL(string: "http://localhost:5001/nftrack-69488/us-central1/sendStatusNotification-sendStatusNotification") else {
        //            return
        //        }
        
        // prepare request
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        print("sender", sender)
        print("recipient", recipient)
        print("content", content)
        print("docID", docID)
        let parameter: [String: Any] = [
            "sender": sender,
            "recipient": recipient,
            "content": content,
            "docID": docID
        ]
        
        let paramData = try? JSONSerialization.data(withJSONObject: parameter, options: [])
        request.httpBody = paramData
        
        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (_, response, error) -> Void in
            if let error = error {
                completion(error)
            }
            
            if let response = response as? HTTPURLResponse {
                print("response", response)
                
                let httpStatusCode = APIError.HTTPStatusCode(rawValue: response.statusCode)
                completion(httpStatusCode)
                
                //                if !(200...299).contains(response.statusCode) {
                //                    print("start1")
                //                    // handle HTTP server-side error
                //                }
            }
        })
        
        task.resume()
    }
}
