//
//  ChatViewController + SendMessage.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-17.
//

import UIKit
import Combine
import FirebaseStorage
import FirebaseFirestore

extension ChatViewController {
    final func initializeChat(
        message: String,
        promise: @escaping (Result<DocumentReference, PostingError>) -> Void
    ) {
        let ref = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
        
        let chatInitializer = ChatInitializer(
            chatIsNew: chatIsNew,
            ref: ref,
            userInfo: userInfo,
            messageContent: message,
            chatListModel: chatListModel,
            docId: docId,
            postingId: postingId,
            itemName: itemName
        )
        
        chatInitializer.createChatInfo(promise: promise)
    }
    
    final func sendMessage() {
        guard
            let messageContent = toolBarView.textView.text,
            !messageContent.isEmpty,
            let userId = userId else {
            return
        }

        Future<DocumentReference, PostingError> { [weak self] promise in
            self?.initializeChat(message: messageContent, promise: promise)
        }
        .eraseToAnyPublisher()
        .flatMap({ [weak self] (ref) -> AnyPublisher<Bool, PostingError> in
            // send text message
            Future<Bool, PostingError> { promise in
                guard let userInfo = self?.userInfo,
                      let recipient = userInfo.uid,
                      let senderDisplayName = self?.senderDisplayName else {
                    promise(.failure(.generalError(reason: "Unable to prepare the information to send the message.")))
                    return
                }
                
                ref.collection("messages").addDocument(data: [
                    "type": MessageType.text.rawValue,
                    "sentAt": Date(),
                    "content": messageContent,
                    "sender": userId,
                    "senderDisplayName": senderDisplayName,
                    "recipient": recipient,
                    "recipientDisplayName": userInfo.displayName,
                ]) { (error) in
                    if let _ = error {
                        promise(.failure(.generalError(reason: "Unable to send the message at the moment.")))
                    } else {
                        promise(.success(true))
                    }
                }
            }
            .eraseToAnyPublisher()
        })
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    self?.alert.showDetail("Error", with: err, for: self)
                case .failure(.chatDisabled):
                    guard let displayName = self?.userInfo.displayName else { return }
                    self?.alert.showDetail("Undelivered Message", with: "The message couldn't be delivered because \(displayName) has left the chat.", for: self)
                case .finished:
                    DispatchQueue.main.async {
                        self?.toolBarView.textView.text.removeAll()
                    }
                    break
                default:
                    break
            }
        } receiveValue: { (_) in
        }
        .store(in: &storage)
    }
}

// MARK: - Image picker
extension ChatViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    final func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let url = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            print("No image found")
            return
        }
        
        alert.showDetail(
            "Picture Message",
            with: "Would you like to send the image?",
            for: self,
            alertStyle: .withCancelButton,
            buttonAction: { [weak self] in
                self?.sendImage(url: url)
            }
        )
    }
    
    final func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    final func sendImage(url: URL) {
        guard let userId = userId else {
            return
        }
        
        var urlRetainer: URL!
        Future<URL?, PostingError> { [weak self] promise in
            self?.uploadImage(
                url: url,
                userId: userId,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
        .flatMap { (url) -> AnyPublisher<DocumentReference, PostingError> in
            urlRetainer = url
            return Future<DocumentReference, PostingError> { [weak self] promise in
                self?.initializeChat(message: "Image", promise: promise)
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ [weak self] (ref) -> Future<Bool, PostingError> in
            Future<Bool, PostingError> { promise in
                // send image message
                guard let userInfo = self?.userInfo,
                      let recipient = userInfo.uid,
                      let senderDisplayName = self?.senderDisplayName else {
                    promise(.failure(.generalError(reason: "Unable to prepare the information to send the message.")))
                    return
                }
                
                ref.collection("messages").addDocument(data: [
                    "type": MessageType.image.rawValue,
                    "sentAt": Date(),
                    "imageURL": urlRetainer.absoluteString,
                    "sender": userId,
                    "senderDisplayName": senderDisplayName,
                    "recipient": recipient,
                    "recipientDisplayName": userInfo.displayName,
                ]) { (error) in
                    if let _ = error {
                        promise(.failure(.generalError(reason: "Unable to send the image at the moment.")))
                    } else {
                        promise(.success(true))
                    }
                }
            }
        })
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    self?.alert.showDetail("Error", with: err, for: self)
                    break
                case .failure(.chatDisabled):
                    guard let displayName = self?.userInfo.displayName else { return }
                    self?.alert.showDetail("Undelivered Message", with: "The message couldn't be delivered because \(displayName) has left the chat.", for: self)
                    break
                case .failure(PostingError.fileUploadError(.fileManagerError(let msg))):
                    self?.alert.showDetail("Error", with: msg, for: self)
                    break
                case .failure(PostingError.fileUploadError(.fileNotAvailable)):
                    self?.alert.showDetail("Error", with: "Image file not found.", for: self)
                    break
                case .failure(PostingError.fileUploadError(.userNotLoggedIn)):
                    self?.alert.showDetail("Error", with: "You need to be logged in!", for: self)
                    break
                case .finished:
                    self?.toolBarView.textView.text.removeAll()
                    break
                default:
                    break
            }
        } receiveValue: { (_) in
            
        }
        .store(in: &storage)
    }
}

extension ChatViewController {
    final func sendLocation(
        image: UIImage,
        imageName: String,
        userId: String,
        address: ShippingAddress
    ) {
        var urlRetainer: URL!
        Future<URL?, PostingError> { [weak self] promise in
            self?.uploadImage(
                image: image,
                imageName: imageName,
                userId: userId,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
        .flatMap { (url) -> AnyPublisher<DocumentReference, PostingError> in
            urlRetainer = url
            return Future<DocumentReference, PostingError> { [weak self] promise in
                self?.initializeChat(message: "Image", promise: promise)
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ [weak self] (ref) -> Future<Bool, PostingError> in
            Future<Bool, PostingError> { promise in
                // send location message
                guard let userInfo = self?.userInfo,
                      let recipient = userInfo.uid,
                      let senderDisplayName = self?.senderDisplayName else {
                    promise(.failure(.generalError(reason: "Unable to prepare the information to send the message.")))
                    return
                }
                
                let addressDict: [String: Any] = [
                    "address": address.address,
                    "latitude": address.latitude ?? 0,
                    "longitude": address.longitude ?? 0
                ]
                
                let messageDict: [String: Any] = [
                    "type": MessageType.location.rawValue,
                    "sentAt": Date(),
                    "imageURL": urlRetainer.absoluteString,
                    "location": addressDict,
                    "sender": userId,
                    "senderDisplayName": senderDisplayName,
                    "recipient": recipient,
                    "recipientDisplayName": userInfo.displayName,
                ]
                
                ref.collection("messages").addDocument(data: messageDict) { (error) in
                    if let _ = error {
                        promise(.failure(.generalError(reason: "Unable to send the image at the moment.")))
                    } else {
                        promise(.success(true))
                    }
                }
            }
        })
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    self?.alert.showDetail("Error", with: err, for: self)
                case .failure(.chatDisabled):
                    guard let displayName = self?.userInfo.displayName else { return }
                    self?.alert.showDetail("Undelivered Message", with: "The message couldn't be delivered because \(displayName) has left the chat.", for: self)
                case .failure(PostingError.fileUploadError(.fileManagerError(let msg))):
                    self?.alert.showDetail("Error", with: msg, for: self)
                case .failure(PostingError.fileUploadError(.fileNotAvailable)):
                    self?.alert.showDetail("Error", with: "Image file not found.", for: self)
                case .failure(PostingError.fileUploadError(.userNotLoggedIn)):
                    self?.alert.showDetail("Error", with: "You need to be logged in!", for: self)
                case .finished:
                    print("location sent")
                    self?.toolBarView.textView.text.removeAll()
                    break
                default:
                    break
            }
        } receiveValue: { (_) in
            
        }
        .store(in: &storage)
    }
}
