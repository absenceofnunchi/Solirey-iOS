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
}

extension FirebaseService {
    func uploadPhoto(fileName: String, userId: String, completion: @escaping (StorageUploadTask?, FileUploadError?) -> Void) {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let localFile = documentDirectory.appendingPathComponent(fileName).appendingPathExtension("")
            if FileManager.default.fileExists(atPath: localFile.path) {
                let metadata = StorageMetadata()
                metadata.contentType = "image/*"
                
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
}

enum FileUploadError: Error {
    case fileNotAvailable
    case userNotLoggedIn
    case fileManagerError(String)
}
