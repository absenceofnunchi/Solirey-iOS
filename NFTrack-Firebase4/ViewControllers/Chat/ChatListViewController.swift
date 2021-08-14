//
//  ChatListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit
import Firebase
import FirebaseFirestore

class ChatListViewController: ParentListViewController<ChatListModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar(vc: self)
        fetchChatList()
    }
    
    override func setDataStore(postArr: [ChatListModel]) {
        dataStore = ChatImageDataStore(posts: postArr, userId: userId)
    }
    
    override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: 110, cellType: ChatListCell.self, identifier: ChatListCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatListCell.identifier) as? ChatListCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        cell.userId = userId
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        
        var displayName: String!
        if post.sellerUserId != userId {
            displayName = post.sellerDisplayName
        } else {
            displayName = post.buyerDisplayName
        }
        
        let userInfo = UserInfo(
            email: nil,
            displayName: displayName,
            photoURL: nil,
            uid: userId,
            memberSince: nil
        )
        
        let chatVC = ChatViewController()
        chatVC.post = post
        chatVC.userInfo = userInfo
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension ChatListViewController {
    func fetchChatList() {
        FirebaseService.shared.db.collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    if let error = error {
                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                    }
                    return
                }
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }
                
                for doc in documents {
                    let data = doc.data()
                    var buyerDisplayName, sellerDisplayName, latestMessage, buyerPhotoURL, sellerPhotoURL, sellerUserId, buyerUserId: String!
                    var date: Date!
                    data.forEach { (item) in
                        switch item.key {
                            case "buyerDisplayName":
                                buyerDisplayName = item.value as? String
                            case "buyerPhotoURL":
                                buyerPhotoURL = item.value as? String
                            case "buyerUserId":
                                buyerUserId = item.value as? String
                            case "latestMessage":
                                latestMessage = item.value as? String
                            case "sellerDisplayName":
                                sellerDisplayName = item.value as? String
                            case "sellerPhotoURL":
                                sellerPhotoURL = item.value as? String
                            case "sentAt":
                                let timeStamp = item.value as? Timestamp
                                date = timeStamp?.dateValue()
                            case "sellerUserId":
                                sellerUserId = item.value as? String
                            default:
                                break
                        }
                    }
                    let chatListModel = ChatListModel(documentId: doc.documentID, latestMessage: latestMessage, date: date, buyerDisplayName: buyerDisplayName, buyerPhotoURL: buyerPhotoURL, buyerUserId: buyerUserId, sellerDisplayName: sellerDisplayName, sellerPhotoURL: sellerPhotoURL, sellerUserId: sellerUserId)
                    self?.postArr.removeAll()
                    self?.postArr.append(chatListModel)
                }
            }
//        docRef.getDocuments { [weak self] (document, error) in
//            if let error = error {
//                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//            }
//
//            if let document = document,
//               !document.isEmpty {
//
//                defer {
//                    DispatchQueue.main.async {
//                        self?.tableView.reloadData()
//                    }
//                }
//
//                for doc in document.documents {
//                    let data = doc.data()
//                    var buyerDisplayName, sellerDisplayName, latestMessage, buyerPhotoURL, sellerPhotoURL, sellerUserId, buyerUserId: String!
//                    var date: Date!
//                    data.forEach { (item) in
//                        switch item.key {
//                            case "buyerDisplayName":
//                                buyerDisplayName = item.value as? String
//                            case "buyerPhotoURL":
//                                buyerPhotoURL = item.value as? String
//                            case "buyerUserId":
//                                buyerUserId = item.value as? String
//                            case "latestMessage":
//                                latestMessage = item.value as? String
//                            case "sellerDisplayName":
//                                sellerDisplayName = item.value as? String
//                            case "sellerPhotoURL":
//                                sellerPhotoURL = item.value as? String
//                            case "sentAt":
//                                let timeStamp = item.value as? Timestamp
//                                date = timeStamp?.dateValue()
//                            case "sellerUserId":
//                                sellerUserId = item.value as? String
//                            default:
//                                break
//                        }
//                    }
//                    let chatListModel = ChatListModel(documentId: doc.documentID, latestMessage: latestMessage, date: date, buyerDisplayName: buyerDisplayName, buyerPhotoURL: buyerPhotoURL, buyerUserId: buyerUserId, sellerDisplayName: sellerDisplayName, sellerPhotoURL: sellerPhotoURL, sellerUserId: sellerUserId)
//                    self?.postArr.append(chatListModel)
//                }
//            } else {
//                print("no data")
//            }
//        }
    }
}
