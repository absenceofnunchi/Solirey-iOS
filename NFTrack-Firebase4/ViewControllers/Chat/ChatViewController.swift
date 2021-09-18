//
//  ChatViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-10.
//

/*
 Abstract:
 Real time chat between two users.
 
 Important:
 UserInfo always pertains to the recipient regardless of whether it is the buyer or the seller. Therefore, UserInfo cannot be used to determine whether a user is a buyer or a seller.
 
 There are two ways to arrive on this view controller:
    1) ListDetailVC: A previous chat might not exists, in which case a new chat is created using getDocId(), a unique identifer for each chat channel
    2) ChatListVC: The chat already exists. ChatListVC passes post (PostCoreModel), which sets the document ID, which in turn, fetches the chat data using the document ID
 
 Only the potential buyer can initiate the conversation and the seller cannot. When the buyer terminates the conversation, they can reinitate the conversation whereas the seller cannot. The seller can terminate the conversation as well, but the buyer can reinitate.
    1) Buyer
        A. Terminates the conversation by removing their user ID from the channel's Members.
        B. Prevent the seller from contacting the buyer.
        C. When the buyer re-initiates the conversation, the chat is initiated from ListDetail, not ChatList.  The buyer's user ID is inserted to Members
    2) Seller
        A. Terminates the conversation by removing their user ID from the channel's Members.
        B. The seller can still be contacted by the buyer even if their user ID has been removed
 */

import UIKit
import FirebaseFirestore
import Combine

class ChatViewController: ParentListViewController<Message>, FileUploadable, SingleDocumentFetchDelegate {
    final var userInfo: UserInfo!
    final var docId: String! {
        didSet {
            if docId != nil {
                fetchMessages(docId)
            } else {
                alert.showDetail("Error", with: "Unable to generate the chat ID.", for: self)
            }
        }
    }
    final var postingId: String!
    final var toolBarView: ToolBarView!
    private var toolBarBottomConstraint: NSLayoutConstraint!
    private var lastCell: CGRect!
    private var imageName: String!
    // If chatListModel is set, it means the channel info already exists, therefore the chat is not new
    final var chatListModel: ChatListModel! {
        didSet {
            chatIsNew = false
            postingId = chatListModel.postingId
            docId = chatListModel.documentId
        }
    }
    // Toggled on and off by fetchChanelInfo() depending on whether the channel info exists or not
    // If new, create the channel info along with the very first message.
    final var chatIsNew: Bool! = true
    private var spinner: UIActivityIndicatorView!
    final override var PAGINATION_LIMIT: Int {
        get {
            return 40
        }
        set {}
    }
    private var optionsBarItem: UIBarButtonItem!
    private var postBarButton: UIBarButtonItem!
    private var reportBarButton: UIBarButtonItem!
    final var storage: Set<AnyCancellable>!
    final var postCache: NSCache<NSString, Post>!
    private var lastContentOffset: CGFloat = 0
    
    final override func setDataStore(postArr: [Message]) {
        dataStore = MessageImageDataStore(posts: postArr)
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureNavigationBar()
        setConstraints()
    }
    
    final override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        if firstListener != nil {
            firstListener.remove()
        }
        
        if nextListener != nil {
            nextListener.remove()
        }
   
        if isMovingFromParent {
            postCache.removeObject(forKey: "CachedPost")
        }
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver()
    }
    
    final override func configureUI() {
        super.configureUI()
        view.backgroundColor = .white
        alert = Alerts()
        postCache = NSCache<NSString, Post>()
        storage = Set<AnyCancellable>()
        
        tableView = UITableView()
        tableView.allowsSelection = false
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: ImageMessageCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.prefetchDataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(tableView)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        toolBarView = ToolBarView()
        toolBarView.buttonAction = { [weak self] tag in
            switch tag {
                case 1:
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.allowsEditing = false
                    imagePickerController.sourceType = .photoLibrary
                    imagePickerController.delegate = self
                    imagePickerController.modalPresentationStyle = .fullScreen
                    self?.present(imagePickerController, animated: true, completion: nil)
                case 2:
                    self?.sendMessage()
                default:
                    break
            }
        }
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBarView)
        
        spinner = UIActivityIndicatorView()
        spinner.stopAnimating()
        spinner.hidesWhenStopped = true
        spinner.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60)
        tableView.tableFooterView = spinner
    }
    
    private func setConstraints() {
        toolBarBottomConstraint = toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBarView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            toolBarBottomConstraint
        ])
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        let post = postArr[indexPath.row]
        
        if let _ = post.imageURL {
            guard let imageCell = tableView.dequeueReusableCell(withIdentifier: ImageMessageCell.identifier, for: indexPath) as? ImageMessageCell else {
                fatalError("Unable to dequeue the custom table cell")
            }
            
            imageCell.myUserId = userId
            imageCell.selectionStyle = .none
            let post = postArr[indexPath.row]
            imageCell.configure(post)
            //        imageCell.updateAppearanceFor(.pending(post))
            
            let interaction = UIContextMenuInteraction(delegate: self)
            imageCell.thumbImageView.isUserInteractionEnabled = true
            imageCell.thumbImageView.addInteraction(interaction)
            
            cell = imageCell
        } else {
            guard let messageCell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as? MessageCell else {
                fatalError("Unable to dequeue the custom table cell")
            }
            
            messageCell.myUserId = userId
            messageCell.selectionStyle = .none
            let post = postArr[indexPath.row]
            messageCell.configure(post)
            //        messageCell.updateAppearanceFor(.pending(post))
            
            let interaction = UIContextMenuInteraction(delegate: self)
            messageCell.messageLabel.isUserInteractionEnabled = true
            messageCell.messageLabel.addInteraction(interaction)
            cell = messageCell
        }

        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            if let contentLabel = interaction.view as? UILabel,
               let message = contentLabel.text {
                return self.createMessageMenu(message: message)
            } else if let imageView = interaction.view as? UIImageView {
                guard let image = imageView.image else { return nil }
                return self.createImageMenu(image: image)
            } else {
                return nil
            }
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        let reload_distance:CGFloat = 10.0
        
        // Only refresh if pulled down
        if lastContentOffset > scrollView.contentOffset.y && lastContentOffset < scrollView.contentSize.height - scrollView.frame.height {
            // 
        } else if lastContentOffset < scrollView.contentOffset.y && scrollView.contentOffset.y > 0 {
            // update the new position acquired
            lastContentOffset = scrollView.contentOffset.y
            if y > (h + reload_distance) {
                guard self.postArr.count > 0 else { return }
                executeAfterDragging()
            }
        }
    }

    final override func executeAfterDragging() {
        spinner.startAnimating()
        delay(0.5) { [weak self] in
            guard let lastSnapshot = self?.lastSnapshot,
                  let docId = self?.docId else { return }
            self?.refetchMessages(lastSnapshot, docId: docId)
        }
    }
}

extension ChatViewController: PostParseDelegate {
    private func configureNavigationBar() {
        self.navigationItem.largeTitleDisplayMode = .never

        let button =  UIButton()
        //        button.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        button.setTitle(userInfo.displayName, for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button.tag = 0
        navigationItem.titleView = button

        guard let postBarImage = UIImage(systemName: "list.bullet.below.rectangle"),
              let reportImage = UIImage(systemName: "flag") else {
            return
        }
        
        // Chat should only be able to navigate to the posting if the view controller was pushed from ChatListVC because if it was pushed from ListDetailVC, it's entirely redundant
        if #available(iOS 14.0, *) {
            var buttonArr: [UIAction] = [UIAction(title: NSLocalizedString("Report", comment: ""), image: reportImage, handler: menuHandler)]
            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
                if let _ = viewController as? ChatListViewController {
                    buttonArr.append(UIAction(title: NSLocalizedString("Posting", comment: ""), image: postBarImage, handler: menuHandler))
                }
            }
            let barButtonMenu = UIMenu(title: "", children: buttonArr)
            
            let image = UIImage(systemName: "line.horizontal.3.decrease")?.withRenderingMode(.alwaysOriginal)
            optionsBarItem = UIBarButtonItem(title: nil, image: image, primaryAction: nil, menu: barButtonMenu)
            navigationItem.rightBarButtonItem = optionsBarItem
        } else {
            var buttonArr = [UIBarButtonItem]()
            reportBarButton = UIBarButtonItem(image: reportImage.withTintColor(.gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
            reportBarButton.tag = 1
            buttonArr.append(reportBarButton)

            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
                if let _ = viewController as? ChatListViewController {
                    postBarButton = UIBarButtonItem(image: postBarImage.withTintColor(.gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
                    postBarButton.tag = 2
                    buttonArr.append(postBarButton)
                }
            }

            self.navigationItem.rightBarButtonItems = buttonArr
        }
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                let profileDetailVC = ProfileDetailViewController()
                profileDetailVC.userInfo = userInfo
                self.navigationController?.pushViewController(profileDetailVC, animated: true)
                break
            case 1:
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let reportVC = ReportViewController()
                    reportVC.post = fetchedPost
                    reportVC.userId = self?.userId
                    self?.navigationController?.pushViewController(reportVC, animated: true)
                }
                break
            case 2:
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let listDetailVC = ListDetailViewController()
                    listDetailVC.post = fetchedPost
                    self?.navigationController?.pushViewController(listDetailVC, animated: true)
                }
            default:
                break
        }
    }
    
    @objc private func menuHandler(action: UIAction) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        guard let postingId = postingId else { return }
        switch action.title {
            case "Posting":
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let listDetailVC = ListDetailViewController()
                    listDetailVC.post = fetchedPost
                    self?.navigationController?.pushViewController(listDetailVC, animated: true)
                }
                break
            case "Report":
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let reportVC = ReportViewController()
                    reportVC.post = fetchedPost
                    reportVC.userId = self?.userId
                    self?.navigationController?.pushViewController(reportVC, animated: true)
                }
                break
            default:
                break
        }
    }
}

extension ChatViewController {
    private func fetchMessages(_ docId: String) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .limit(to: 5)
            .order(by: "sentAt", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
                }
                
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.tableView.scrollToTop()
                    }
                }
                
                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    // The collection is empty.
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                if let messages = self?.parseMessage(querySnapshot.documents) {
                    self?.postArr = messages
                }
            }
    }
    
    private func refetchMessages(_ lastSnapshot: QueryDocumentSnapshot, docId: String) {
        nextListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .order(by: "sentAt", descending: true)
            .limit(to: 5)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
                }
                
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.tableView.scrollToBottom()
                        DispatchQueue.main.async {
                            self?.spinner.stopAnimating()
                        }
                    }
                }
                
                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    // The collection is empty.
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                if let messages = self?.parseMessage(querySnapshot.documents) {
                    self?.postArr.append(contentsOf: messages)
                }
            }
    }
    
    private func parseMessage(_ documents: [QueryDocumentSnapshot]) -> [Message] {
        return documents.map { docSnapshot -> Message in
            let data = docSnapshot.data()
            let senderId = data["sender"] as? String ?? ""
            let content = data["content"] as? String ?? ""
            let displayName = data["displayName"] as? String ?? ""
            let sentAt = data["sentAt"] as? Date ?? Date()
            let imageURL = data["imageURL"] as? String
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let formattedDate = formatter.string(from: sentAt)
            
            return Message(
                id: senderId,
                content: content,
                displayName: displayName,
                sentAt: formattedDate,
                imageURL: imageURL
            )
        }
    }
}

extension ChatViewController {
    // MARK: - addKeyboardObserver
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    // MARK: - removeKeyboardObserver
    private func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            guard let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
            let keyboardViewEndFrame = view.convert(keyBoardFrame, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height

            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt

            self.tableView.frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: self.view.bounds.size.width,
                    height: self.view.bounds.size.height - keyboardHeight
                )
            )

            self.toolBarBottomConstraint.constant = -keyboardHeight
            self.view.setNeedsLayout()
            let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
            UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
                self.view.layoutIfNeeded()
            })
            tableView.scrollToTop()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt

        let insets: UIEdgeInsets = .zero
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
        
//        self.tableView.frame.origin.y = .zero
        self.toolBarBottomConstraint.constant = 0
        view.setNeedsLayout()
        let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
        UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
            //                    self.toolBarView.frame = CGRect(origin: CGPoint(x: 0, y: self.view.frame.size.height - self.toolBarView.bounds.size.height - keyboardHeight), size: CGSize(width: self.view.bounds.size.width, height: 60))
            self.view.layoutIfNeeded()
        })
    }
}

extension ChatViewController: SharableDelegate {
    final func createMessageMenu(message: String) -> UIMenu {
        // Create a UIAction for sharing
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] action in
            let objectsToShare: [AnyObject] = [message as AnyObject]
            self?.share(objectsToShare)
        }
        
        // Create an action for renaming
        let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
            let pasteboard = UIPasteboard.general
            pasteboard.string = message
        }
        
        // Create and return a UIMenu with all of the actions as children
        return UIMenu(title: "", children: [share, copy])
    }
    
    final func createImageMenu(image: UIImage) -> UIMenu {
        // Create a UIAction for sharing
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] action in
            let objectsToShare: [AnyObject] = [image as AnyObject]
            self?.share(objectsToShare)
        }
        
        // Create an action for renaming
        let copy = UIAction(title: "Open", image: UIImage(systemName: "doc.on.doc")) { [weak self] action in
            let vc = BigPreviewViewController()
            vc.imageView.image = image
            self?.present(vc, animated: true, completion: nil)
        }
        
        // Create and return a UIMenu with all of the actions as children
        return UIMenu(title: "", children: [share, copy])
    }
}

//    private func sendMessage1() {
//        guard
//            let messageContent = toolBarView.textView.text,
//            !messageContent.isEmpty,
//            let userId = userId else {
//            return
//        }
//
//        let ref = FirebaseService.shared.db
//            .collection("chatrooms")
//            .document(docId)
//
//        if self.messages.count == 0 {
//            /// docId is the hashed Id that corresponds to the unique ID of the chat room
//            guard let sellerUserId = userInfo.uid else {
//                self.alert.showDetail(
//                    "Sorry",
//                    with: "Unable to retrieve the seller's info. Please try again",
//                    for: self,
//                    buttonAction: {
//                        self.navigationController?.popViewController(animated: true)
//                    }, completion:  {
//
//                    }
//                )
//                return
//            }
//
//            // only the buyer can initiate the conversation
//            // so the initial setting of the following data is true
//            ref.setData([
//                "members": [sellerUserId, userId],
//                "sellerUserId": sellerUserId,
//                "sellerDisplayName": userInfo.displayName,
//                "sellerPhotoURL": userInfo.photoURL ?? "NA",
//                "buyerUserId": userId,
//                "buyerDisplayName": displayName!,
//                "buyerPhotoURL": photoURL ?? "NA",
//                "docId": docId!,
//                "latestMessage": messageContent,
//                "sentAt": Date()
//            ]) { [weak self] (error) in
//                if let error = error {
//                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//                } else {
////                    if let tabBarVCs = self?.tabBarController?.viewControllers {
////                        for case let vc as UINavigationController in tabBarVCs where vc.title == "Inbox" {
////                            for case let chatListVC as ChatListViewController in vc.children {
////                                chatListVC.fetchChatList()
////                            }
////                        }
////                    }
//                }
//            }
//        } else {
//            ref.updateData([
//                "latestMessage": messageContent,
//                "sentAt": Date()
//            ]) { [weak self] (error) in
//                if let error = error {
//                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//                }
//            }
//        }
//
//        ref.collection("messages").addDocument(data: [
//            "sentAt": Date(),
//            "content": messageContent,
//            "sender": userId,
//            "recipient": "recipientUid",
//        ]) { [weak self] (error) in
//            if let error = error {
//                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//            } else {
//                self?.toolBarView.textView.text.removeAll()
//            }
//        }
//    }
//
//    private func sendImage(url: URL) {
//        let ref = FirebaseService.shared.db
//            .collection("chatrooms")
//            .document(docId)
//
//        if self.messages.count == 0 {
//            /// docId is the hashedId that corresponds to the unique ID of the chat room
//            guard let sellerUserId = userInfo.uid else {
//                self.alert.showDetail("Sorry", with: "Unable to retrieve the seller's info. Please try again", for: self) {
//                    self.navigationController?.popViewController(animated: true)
//                } completion: {}
//                return
//            }
//
//            defer {
//                deleteFile(fileName: imageName)
//            }
//
//            ref.setData([
//                "members": [sellerUserId, userId],
//                "sellerUserId": sellerUserId,
//                "sellerDisplayName": userInfo.displayName,
//                "sellerPhotoURL": userInfo.photoURL ?? "NA",
//                "buyerUserId": userId!,
//                "buyerDisplayName": displayName!,
//                "buyerPhotoURL": photoURL ?? "NA",
//                "docId": docId!,
//                "latestMessage": "",
//                "sentAt": Date(),
//            ])
//        } else {
//            ref.updateData([
//                "latestMessage": "",
//                "sentAt": Date()
//            ])
//        }
//
//        let data: [String: Any] = [
//            "sentAt": Date(),
//            "imageURL": "\(url)",
//            "sender": userId!
//        ]
//        ref.collection("messages").addDocument(data: data) { [weak self] (error) in
//            if let error = error {
//                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
//                    if let imageName = self?.imageName {
//                        self?.deleteFile(fileName: imageName)
//                    }
//                } completion: {}
//            }
//        }
//    }
