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
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar(vc: self)
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchChatList()
    }
    
    final override func setDataStore(postArr: [ChatListModel]) {
        dataStore = ChatImageDataStore(posts: postArr, userId: userId)
    }
    
    final override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: 110, cellType: ChatListCell.self, identifier: ChatListCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatListCell.identifier) as? ChatListCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        cell.userId = userId
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }

    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    private func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
//            postArr.remove(at: indexPath.row)
//            tableView.deleteSections([indexPath.row], with: .fade)
            let chatRoom = postArr[indexPath.row]
            
            FirebaseService.shared.db
                .collection("chatrooms")
                .document(chatRoom.documentId)
                .delete(completion: { (error) in
                    if let error = error {
                        print(error)
                    } else {
                        print("delete success")
                    }
                })
        }
    }

    private func fetchChatList() {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .limit(to: PAGINATION_LIMIT)
            .order(by: "sentAt", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to fetch your chat.", for: self)
                    return
                }

                defer {
                    self?.tableView.reloadData()
                }

                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                guard !querySnapshot.documents.isEmpty else {
                    return
                }
                
                self?.postArr.removeAll()
                self?.parseDocuments(querySnapshot.documents)
            }
    }
    
    private func refetchChatList(lastSnapshot: QueryDocumentSnapshot) {
        nextListener = FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .order(by: "sentAt", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to fetch your chat.", for: self)
                    return
                }
                
                defer {
                    self?.tableView.reloadData()
                }
                
                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                guard !querySnapshot.documents.isEmpty else {
                    return
                }
                
                self?.parseDocuments(querySnapshot.documents)
            }
    }
    
    private func parseDocuments(_ documents: [QueryDocumentSnapshot]) {
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
            let chatListModel = ChatListModel(
                documentId: doc.documentID,
                latestMessage: latestMessage,
                date: date,
                buyerDisplayName: buyerDisplayName,
                buyerPhotoURL: buyerPhotoURL,
                buyerUserId: buyerUserId,
                sellerDisplayName: sellerDisplayName,
                sellerPhotoURL: sellerPhotoURL,
                sellerUserId: sellerUserId
            )
            
            self.postArr.append(chatListModel)
        }
    }
    
    final override func executeAfterDragging() {
        refetchChatList(lastSnapshot: lastSnapshot)
    }
}
