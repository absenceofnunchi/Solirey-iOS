//
//  ChatListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit
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
    
    
    final override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ParentTableCell<ChatListCell> else { return }
        
        // How should the operation update the cell once the data has been loaded?
        let updateCellClosure: (UIImage?) -> () = { [weak self] (image) in
            print("updateCellClosure")
            cell.updateAppearanceFor(.fetched(image))
            guard let self = self else { return }
            self.loadingOperations.removeValue(forKey: indexPath)
        }
        
        // Try to find an existing data loader
        if let dataLoader = loadingOperations[indexPath] {
            // Has the data already been loaded?
            if let image = dataLoader.image {
                cell.updateAppearanceFor(.fetched(image))
                loadingOperations.removeValue(forKey: indexPath)
            } else {
                // No data loaded yet, so add the completion closure to update the cell once the data arrives
                dataLoader.loadingCompleteHandler = updateCellClosure
            }
        } else {
            // Need to create a data loaded for this index path
            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
                // Provide the completion closure, and kick off the loading operation
                dataLoader.loadingCompleteHandler = updateCellClosure
                loadingQueue.addOperation(dataLoader)
                loadingOperations[indexPath] = dataLoader
            }
        }
    }
    
    // 1. The entire data is loaded to the data store
    // 2. For every cell, prefetch the Operation that pertains to indexPath.row
    // 3. Add the operation to the loading queue (addOperation)
    // 4. Add the opertaion to the loadingOperation dictionary
    // 5. If the data has been loaded already, delete it form the loadingOperations queue
    final override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If there's a data loader for this index path we don't need it any more. Cancel and dispose
        if let dataLoader = loadingOperations[indexPath] {
            dataLoader.cancel()
            loadingOperations.removeValue(forKey: indexPath)
        }
    }
    
    // MARK:- TableView Prefetching DataSource
    final override func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let _ = loadingOperations[indexPath] { return }
            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
                loadingQueue.addOperation(dataLoader)
                loadingOperations[indexPath] = dataLoader
            }
        }
    }
    
    final override func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let dataLoader = loadingOperations[indexPath] {
                dataLoader.cancel()
                loadingOperations.removeValue(forKey: indexPath)
            }
        }
    }
}

// MARK: - Trailing action
extension ChatListViewController {
    final override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    final override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //
    }
    
    final override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            print("delete action")
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    final override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    final override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
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
        
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] action in
            print("delete")
        }
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSString, previewProvider: { [weak self] in self?.getPreviewVC(for: indexPath, post: post, userInfo: userInfo) }) { _ in
            UIMenu(title: "", children: [delete])
        }
    }
    
    private func getPreviewVC(for indexPath: IndexPath, post: ChatListModel, userInfo: UserInfo) -> UIViewController? {
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
        return chatVC
    }
    
    
}
