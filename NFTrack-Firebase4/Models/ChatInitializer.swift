//
//  ChatInitializer.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-15.
//

/*
 Abstract:
 The chat initializer should:
 1. Check if this chat is new, in which case, the chat info has to be created.
 2. Check if how many members are present in the chat room.
    A. If members field doesn't exists, it means this is a new chat. Create a new chat info when the first message is composed.
    B. Seller: if the Members' count is 1, do not send. It means the buyer has exited the chat.
    C. Buyer: if the Members' count is 0, insert both the buyer and the seller into Members. It means the chat exists, but both have exited the chat at one point.
    D. Buyer: if the Members' count is 1, include both (whether it's the buyer or the seller missing)
    E. Buyer: if the Members' count is 2, don't update the channel info.
 Chat Initializer is only for non-new chats
 */

import Foundation
import FirebaseFirestore
import Combine

class ChatInfoConfig {
    private var chatListModel: ChatListModel!
    private var messageContent: String!
    private var userId: String!
    private var promise: (Result<DocumentReference, PostingError>) -> Void
    
    init(
        chatListModel: ChatListModel,
        messageContent: String,
        userId: String,
        promise: @escaping (Result<DocumentReference, PostingError>) -> Void
    ) {
        self.chatListModel = chatListModel
        self.messageContent = messageContent
        self.userId = userId
        self.promise = promise
    }
    
    final func prepareChatInfo() -> [String: Any]? {
        guard let messageContent = messageContent else {
            return nil
        }
        
        var chatInfo: [String: Any] = [
            "latestMessage": messageContent,
            "sentAt": Date()
        ]
        
        if userId == chatListModel.sellerUserId {
            // the chat user is the seller
            if chatListModel.members.count != 2 {
                promise(.failure(.chatDisabled))
            }
        } else {
            // the chat user is the buyer
            switch chatListModel.members.count {
                case 2:
                    break
                case 1, 0:
                    // Whether there is only the seller or the buyer left, if a buyer starts the conversation, both have to be present.
                    guard let userId = userId,
                          let sellerUserId = chatListModel.sellerUserId else { return nil }
                    
                    chatInfo.updateValue([userId, sellerUserId], forKey: "members")
                //                    case 1:
                //                        guard let userId = userId,
                //                              let sellerUserId = chatListModel.sellerUserId else { return nil }
                //
                //                        if chatListModel.members.contains(userId) {
                //                            return ["members": FieldValue.arrayUnion([sellerUserId])]
                //                        } else if chatListModel.members.contains(sellerUserId) {
                //                            return ["members": FieldValue.arrayUnion([userId])]
                //                        } else {
                //                            return ["members": [userId, sellerUserId]]
                //                        }
                //                    case 0:
                //                        guard let userId = userId,
                //                              let sellerUserId = chatListModel.sellerUserId else { return nil }
                //                        return ["members": [userId, sellerUserId]]
                default:
                    break
            }
        }
        
        return chatInfo
    }
}

class ChatInitializer {
    private var chatIsNew: Bool!
    private var ref: DocumentReference!
    private let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId)
    private var userInfo: UserInfo!
    private var messageContent: String!
    private var chatListModel: ChatListModel!
    private var chatInfo: [String: Any]!
    private var docId: String!
    private var postingId: String
    private var itemName: String
    
    init(
        chatIsNew: Bool = true,
        ref: DocumentReference,
        userInfo: UserInfo,
        messageContent: String,
        chatListModel: ChatListModel?,
        docId: String,
        postingId: String,
        itemName: String
    ) {
        self.chatIsNew = chatIsNew
        self.ref = ref
        self.userInfo = userInfo
        self.messageContent = messageContent
        self.chatListModel = chatListModel
        self.docId = docId
        self.postingId = postingId
        self.itemName = itemName
    }
    
    final func createChatInfo(promise: @escaping (Result<DocumentReference, PostingError>) -> Void) {
        guard let chatIsNew = self.chatIsNew,
              let userId = self.userId,
              let userInfo = self.userInfo,
              let messageContent = self.messageContent else {
            promise(.failure(.generalError(reason: "Unable to initialize the chat.")))
            return
        }
        
        // Create or update the chat info
        if chatIsNew {
            // If the chat is new, create a new chat info
            // Only the buyer can initate the chat from ListDetailVC so no need to check whether the chat user is the buyer or the seller
            guard let docId = self.docId,
                  let sellerUserId = userInfo.uid,
                  let sellerMemberSince = userInfo.memberSince,
                  let buyerMemberSince = UserDefaults.standard.object(forKey: UserDefaultKeys.memberSince) as? Date else {
                promise(.failure(.generalError(reason: "Unable to retrieve the seller's info. Please try again.")))
                return
            }
            
            let displayName = UserDefaults.standard.string(forKey: UserDefaultKeys.displayName)
            let photoURL = UserDefaults.standard.string(forKey: UserDefaultKeys.photoURL)
            
            self.chatInfo = [
                "members": [sellerUserId, userId],
                "sellerUserId": sellerUserId,
                "sellerDisplayName": userInfo.displayName,
                "sellerPhotoURL": userInfo.photoURL ?? "NA",
                "buyerUserId": userId,
                "buyerDisplayName": displayName ?? "NA",
                "buyerPhotoURL": photoURL ?? "NA",
                "docId": docId,
                "latestMessage": messageContent,
                "sentAt": Date(),
                "sellerMemberSince": sellerMemberSince,
                "buyerMemberSince": buyerMemberSince,
                "postingId": postingId,
                "itemName": itemName
            ]
        } else {
            // If the chat is not new, determine whether the sender is a seller or the buyer and how many members are in the chat currently
            guard let chatListModel = self.chatListModel else {
                promise(.failure(.generalError(reason: "Unable to retrieve the seller's info. Please try again.")))
                return
            }
            
            let chatInitializer = ChatInfoConfig(
                chatListModel: chatListModel,
                messageContent: messageContent,
                userId: userId,
                promise: promise
            )
            
            self.chatInfo = chatInitializer.prepareChatInfo()
        }
        
        guard let chatInfo = self.chatInfo,
              let ref = self.ref else {
            promise(.failure(.generalError(reason: "Unable to initialize the chat.")))
            return
        }
        
        self.ref.setData(chatInfo, merge: true) { (error) in
            if let _ = error {
                promise(.failure(.generalError(reason: "Unable to initialize the chat.")))
                return
            } else {
                promise(.success(ref))
            }
        }
    }
    
    final func createChatInfo() -> AnyPublisher<DocumentReference, PostingError> {
        Future<DocumentReference, PostingError> { [weak self] promise in
            guard let chatIsNew = self?.chatIsNew,
                  let userId = self?.userId,
                  let userInfo = self?.userInfo,
                  let messageContent = self?.messageContent else {
                promise(.failure(.generalError(reason: "Unable to initialize the chat.")))
                return
            }
            
            // Create or update the chat info
            if chatIsNew {
                // If the chat is new, create a new chat info
                // Only the buyer can initate the chat from ListDetailVC so no need to check whether the chat user is the buyer or the seller
                guard let docId = self?.docId,
                      let sellerUserId = userInfo.uid,
                      let sellerMemberSince = userInfo.memberSince,
                      let buyerMemberSince = UserDefaults.standard.object(forKey: UserDefaultKeys.memberSince) as? Date,
                      let postingId = self?.postingId,
                      let itemName = self?.itemName else {
                    promise(.failure(.generalError(reason: "Unable to retrieve the seller's info. Please try again.")))
                    return
                }
                
                let displayName = UserDefaults.standard.string(forKey: UserDefaultKeys.displayName)
                let photoURL = UserDefaults.standard.string(forKey: UserDefaultKeys.photoURL)
                
                self?.chatInfo = [
                    "members": [sellerUserId, userId],
                    "sellerUserId": sellerUserId,
                    "sellerDisplayName": userInfo.displayName,
                    "sellerPhotoURL": userInfo.photoURL ?? "NA",
                    "buyerUserId": userId,
                    "buyerDisplayName": displayName ?? "NA",
                    "buyerPhotoURL": photoURL ?? "NA",
                    "docId": docId,
                    "latestMessage": messageContent,
                    "sentAt": Date(),
                    "sellerMemberSince": sellerMemberSince,
                    "buyerMemberSince": buyerMemberSince,
                    "postingId": postingId,
                    "itemName": itemName
                ]
                
            } else {
                // If the chat is not new, determine whether the sender is a seller or the buyer and how many members are in the chat currently
                guard let chatListModel = self?.chatListModel else {
                    promise(.failure(.generalError(reason: "Unable to retrieve the seller's info. Please try again.")))
                    return
                }
                
                let chatInitializer = ChatInfoConfig(
                    chatListModel: chatListModel,
                    messageContent: messageContent,
                    userId: userId,
                    promise: promise
                )
                
                self?.chatInfo = chatInitializer.prepareChatInfo()
            }
            
            guard let chatInfo = self?.chatInfo,
                  let ref = self?.ref else {
                promise(.failure(.generalError(reason: "Unable to initialize the chat.")))
                return
            }
            
            self?.ref.setData(chatInfo, merge: true) { (error) in
                if let _ = error {
                    promise(.failure(.generalError(reason: "Unable to initialize the chat.")))
                    return
                } else {
                    promise(.success(ref))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
