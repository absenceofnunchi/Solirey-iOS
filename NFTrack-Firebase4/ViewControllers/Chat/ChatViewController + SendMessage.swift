//
//  ChatViewController + SendMessage.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-17.
//

import UIKit
import Combine

extension ChatViewController {
    final func sendMessage() {
        guard
            let messageContent = toolBarView.textView.text,
            !messageContent.isEmpty,
            let userId = userId else {
            return
        }
        
        let ref = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
        
        let chatInitializer = ChatInitializer(
            chatIsNew: chatIsNew,
            ref: ref,
            userInfo: userInfo,
            messageContent: messageContent,
            chatListModel: chatListModel,
            docId: docId,
            postingId: postingId
        )
        
        chatInitializer.createChatInfo()
            .flatMap({ [weak self] (ref) -> AnyPublisher<Bool, PostingError> in
                // send text message
                Future<Bool, PostingError> { promise in
                    guard let recipient = self?.userInfo.uid else {
                        promise(.failure(.generalError(reason: "Unable to identify the recipient.")))
                        return
                    }
                    
                    ref.collection("messages").addDocument(data: [
                        "sentAt": Date(),
                        "content": messageContent,
                        "sender": userId,
                        "recipient": recipient,
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
                guard let userId = self?.userId else { return }
                Future<URL?, PostingError> { promise in
                    self?.uploadImage(url: url, userId: userId, promise: promise)
                }
                .sink { [weak self] (completion) in
                    switch completion {
                        case .failure(.generalError(reason: let err)):
                            self?.alert.showDetail("Error", with: err, for: self)
                        case .finished:
                            break
                        default:
                            break
                    }
                } receiveValue: { [weak self] (url) in
                    guard let url = url else { return }
                    self?.sendImage(url: url)
                }
                .store(in: &self!.storage)
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
        
        let ref = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
        
        let chatInitializer = ChatInitializer(
            chatIsNew: chatIsNew,
            ref: ref,
            userInfo: userInfo,
            messageContent: "Image",
            chatListModel: chatListModel,
            docId: docId,
            postingId: postingId
        )
        
        chatInitializer.createChatInfo()
            .flatMap({ [weak self] (ref) -> Future<Bool, PostingError> in
                Future<Bool, PostingError> { promise in
                    // send text message
                    guard let recipient = self?.userInfo.uid else {
                        promise(.failure(.generalError(reason: "Unable to identify the recipient.")))
                        return
                    }
                    print("recipient", recipient)
                    ref.collection("messages").addDocument(data: [
                        "sentAt": Date(),
                        "imageURL": url.absoluteString,
                        "sender": userId,
                        "recipient": recipient,
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
                    case .failure(.chatDisabled):
                        guard let displayName = self?.userInfo.displayName else { return }
                        self?.alert.showDetail("Undelivered Message", with: "The message couldn't be delivered because \(displayName) has left the chat.", for: self)
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
