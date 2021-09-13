//
//  TestViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-13.
//

import UIKit
import FirebaseFirestore

class TestViewController: ParentTestViewController<ChatListModel>  {
    let refreshControl = UIRefreshControl()
    var alert: Alerts!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchChatList()
    }
    
    // MARK: - configureUI
    func configureUI() {
        view.backgroundColor = .white
        alert = Alerts()
        
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
}

// MARK: - Trailing action
extension TestViewController {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            print("delete action")
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [
            makeDeleteContextualAction(forRowAt: indexPath)
        ])
    }
    
    private func makeDeleteContextualAction(forRowAt indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .destructive, title: "Delete") { (action, swipeButtonView, completion) in
            print("DELETE HERE")
            
            completion(true)
        }
    }
}
