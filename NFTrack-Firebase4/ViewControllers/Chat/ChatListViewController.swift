//
//  ChatListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit
import FirebaseFirestore
import Combine

class ChatListViewController: ParentListViewController<ChatListModel>, PostParseDelegate, SingleDocumentFetchDelegate {
    var storage: Set<AnyCancellable>!
    var cache: NSCache<NSString, Post>!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar(vc: self)
        cache = NSCache<NSString, Post>()
        storage = Set<AnyCancellable>()
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchChatList()
        cache.removeObject(forKey: "CachedPost")
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

        // The recipient's user info
        let userInfo = createUserInfo(post)

        let chatVC = ChatViewController()
        chatVC.userInfo = userInfo
        chatVC.chatListModel = post
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    private func createUserInfo(_ post: ChatListModel) -> UserInfo {
        var userInfo: UserInfo!
        
        if post.buyerUserId == userId {
            userInfo = UserInfo(
                email: nil,
                displayName: post.sellerDisplayName,
                photoURL: post.sellerPhotoURL,
                uid: post.sellerUserId,
                memberSince: post.sellerMemberSince
            )
        } else {
            userInfo = UserInfo(
                email: nil,
                displayName: post.buyerDisplayName,
                photoURL: post.buyerPhotoURL,
                uid: post.buyerUserId,
                memberSince: post.buyerMemberSince
            )
        }
        
        return userInfo
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
                if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
                    self?.postArr.append(contentsOf: chatListModels)
                }
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
                
                if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
                    self?.postArr.append(contentsOf: chatListModels)
                }
            }
    }
    
    final override func executeAfterDragging() {
        refetchChatList(lastSnapshot: lastSnapshot)
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
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            self?.deleteChat(indexPath: indexPath)
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    final override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let postingAction = postingContextualAction(forRowAt: indexPath)
        let profileAction = profileContextualAction(forRowAt: indexPath)
        
        postingAction.backgroundColor = UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1)
        profileAction.backgroundColor = UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1)
        let configuration = UISwipeActionsConfiguration(actions: [postingAction, profileAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    final override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let post = postArr[indexPath.row]

        let posting = UIAction(title: "Posting", image: UIImage(systemName: "info.circle")) { [weak self] action in
            guard let postingId = self?.postArr[indexPath.row].postingId else { return }
            self?.navToPosting(with: postingId)
        }
        
        let profile = UIAction(title: "Profile", image: UIImage(systemName: "person.crop.circle")) { [weak self] action in
            guard let post = self?.postArr[indexPath.row] else { return }
            self?.navToProfile(using: post)
        }
        
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash.circle"), attributes: .destructive) { [weak self] action in
            self?.deleteChat(indexPath: indexPath)
        }
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSString, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: [posting, profile, delete])
        }
    }

    final override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        
        animator.addAnimations {
            self.show(destinationViewController, sender: self)
        }
    }
}

extension ChatListViewController {
    private func postingContextualAction(forRowAt indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Item") { [weak self] (action, swipeButtonView, completion) in
            guard let postingId = self?.postArr[indexPath.row].postingId else { return }
            self?.navToPosting(with: postingId)
            
            completion(true)
        }
    }
    
    private func profileContextualAction(forRowAt indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Profile") { [weak self] (action, swipeButtonView, completion) in
            guard let post = self?.postArr[indexPath.row] else { return }
            self?.navToProfile(using: post)
            completion(true)
        }
    }
    
    private func navToPosting(with postingId: String) {
        self.getPost(with: postingId) { (fetchedPost) in
            let listDetailVC = ListDetailViewController()
            listDetailVC.post = fetchedPost
            self.navigationController?.pushViewController(listDetailVC, animated: true)
        }
    }
    
    private func navToProfile(using post: ChatListModel) {
        let userInfo = self.createUserInfo(post)
        let profileDetailVC = ProfileDetailViewController()
        profileDetailVC.userInfo = userInfo
        self.navigationController?.pushViewController(profileDetailVC, animated: true)
    }
    
    private func getPreviewVC(post: ChatListModel) -> UIViewController {
        // The recipient's user info
        let userInfo = createUserInfo(post)
        
        let chatVC = ChatViewController()
        chatVC.userInfo = userInfo
        chatVC.chatListModel = post
        
        return chatVC
    }
    
    private func deleteChat(indexPath: IndexPath) {
        guard let userId = self.userId else { return }
        let chatroom = self.postArr[indexPath.row]
        
        let buyerMsg = "The seller will not be able to message you anymore. Proceed?"
        let sellerMsg = "Are you sure you want to clear this conversation?"
        
        self.alert.showDetail(
            "Delete Chat",
            with: userId == chatroom.buyerUserId ? buyerMsg : sellerMsg,
            for: self,
            alertStyle: .withCancelButton,
            buttonAction: {
                FirebaseService.shared.db
                    .collection("chatrooms")
                    .document(chatroom.documentId)
                    .updateData([
                        "members": FieldValue.arrayRemove([userId])
                    ]) { [weak self] (error) in
                        if let _ = error {
                            self?.alert.showDetail("Error", with: "There was an error deleting the chat.", for: self)
                        } else {
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    }
            })
    }
}
