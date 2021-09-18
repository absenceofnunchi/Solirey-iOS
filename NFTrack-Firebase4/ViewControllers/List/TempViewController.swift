////
////  ChatViewController.swift
////  NFTrack-Firebase4
////
////  Created by J C on 2021-06-10.
////
//
///*
// Abstract:
// Real time chat between two users.
// 
// Important:
// UserInfo always pertains to the recipient regardless of whether it is the buyer or the seller. Therefore, UserInfo cannot be used to determine whether a user is a buyer or a seller.
// 
// There are two ways to arrive on this view controller:
// 1) ListDetailVC: A previous chat might not exists, in which case a new chat is created using getDocId(), a unique identifer for each chat channel
// 2) ChatListVC: The chat already exists. ChatListVC passes post (PostCoreModel), which sets the document ID, which in turn, fetches the chat data using the document ID
// 
// Only the potential buyer can initiate the conversation and the seller cannot. When the buyer terminates the conversation, they can reinitate the conversation whereas the seller cannot. The seller can terminate the conversation as well, but the buyer can reinitate.
// 1) Buyer
// A. Terminates the conversation by removing their user ID from the channel's Members.
// B. Prevent the seller from contacting the buyer.
// C. When the buyer re-initiates the conversation, the chat is initiated from ListDetail, not ChatList.  The buyer's user ID is inserted to Members
// 2) Seller
// A. Terminates the conversation by removing their user ID from the channel's Members.
// B. The seller can still be contacted by the buyer even if their user ID has been removed
// */
//
//import UIKit
//import FirebaseFirestore
//import Combine
//
//class ChatViewController: UIViewController, FileUploadable, SingleDocumentFetchDelegate {
//    var userInfo: UserInfo!
//    var docId: String! {
//        didSet {
//            if docId != nil {
//                fetchMessages(docId)
//            } else {
//                alert.showDetail("Error", with: "Unable to generate the chat ID.", for: self)
//            }
//        }
//    }
//    var postingId: String!
//    private var messages = [Message]()
//    private var toolBarView: ToolBarView!
//    private var toolBarBottomConstraint: NSLayoutConstraint!
//    var alert: Alerts!
//    private var tableView: UITableView!
//    private var userId: String! {
//        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId)
//    }
//    private var lastCell: CGRect!
//    private var imageName: String!
//    private var lastSnapshot: QueryDocumentSnapshot!
//    private var firstListener: ListenerRegistration!
//    private var nextListener: ListenerRegistration!
//    private var chatInfoListener: ListenerRegistration!
//    // If chatListModel is set, it means the channel info already exists, therefore the chat is not new
//    var chatListModel: ChatListModel! {
//        didSet {
//            chatIsNew = false
//            postingId = chatListModel.postingId
//            docId = chatListModel.documentId
//        }
//    }
//    // Toggled on and off by fetchChanelInfo() depending on whether the channel info exists or not
//    // If new, create the channel info along with the very first message.
//    private var chatIsNew: Bool! = true
//    private var spinner: UIActivityIndicatorView!
//    private let PAGINATION_LIMIT: Int = 40
//    private var optionsBarItem: UIBarButtonItem!
//    private var postBarButton: UIBarButtonItem!
//    private var reportBarButton: UIBarButtonItem!
//    final var storage: Set<AnyCancellable>!
//    final var cache: NSCache<NSString, Post>!
//    
//    final override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        configureUI()
//        configureNavigationBar()
//        setConstraints()
//    }
//    
//    final override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        addKeyboardObserver()
//        self.tabBarController?.tabBar.isHidden = true
//    }
//    
//    final override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.tabBarController?.tabBar.isHidden = false
//        
//        if firstListener != nil {
//            firstListener.remove()
//        }
//        
//        if nextListener != nil {
//            nextListener.remove()
//        }
//        
//        if chatInfoListener != nil {
//            chatInfoListener.remove()
//        }
//        
//        if isMovingFromParent {
//            cache.removeObject(forKey: "CachedPost")
//        }
//    }
//    
//    final override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        removeKeyboardObserver()
//    }
//}
//
//extension ChatViewController: PostParseDelegate {
//    //    private func getProfileInfo() {
//    //        if let uid = UserDefaults.standard.string(forKey: UserDefaultKeys.userId),
//    //           let displayName = UserDefaults.standard.string(forKey: UserDefaultKeys.displayName) {
//    //            self.userId = uid
//    //            self.displayName = displayName
//    //        } else {
//    //            self.alert.showDetail("Sorry", with: "Unable to retrieve your profile. Please try again.", for: self) {
//    //                self.navigationController?.popViewController(animated: true)
//    //            } completion: {}
//    //        }
//    //    }
//    
//    private func configureNavigationBar() {
//        self.navigationItem.largeTitleDisplayMode = .never
//        
//        let button =  UIButton()
//        //        button.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        button.setTitle(userInfo.displayName, for: .normal)
//        button.setTitleColor(.gray, for: .normal)
//        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//        button.tag = 0
//        navigationItem.titleView = button
//        
//        guard let postBarImage = UIImage(systemName: "list.bullet.below.rectangle"),
//              let reportImage = UIImage(systemName: "flag") else {
//            return
//        }
//        
//        // Chat should only be able to navigate to the posting if the view controller was pushed from ChatListVC because if it was pushed from ListDetailVC, it's entirely redundant
//        if #available(iOS 14.0, *) {
//            var buttonArr: [UIAction] = [UIAction(title: NSLocalizedString("Report", comment: ""), image: reportImage, handler: menuHandler)]
//            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
//                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
//                if let _ = viewController as? ChatListViewController {
//                    buttonArr.append(UIAction(title: NSLocalizedString("Posting", comment: ""), image: postBarImage, handler: menuHandler))
//                }
//            }
//            let barButtonMenu = UIMenu(title: "", children: buttonArr)
//            
//            let image = UIImage(systemName: "line.horizontal.3.decrease")?.withRenderingMode(.alwaysOriginal)
//            optionsBarItem = UIBarButtonItem(title: nil, image: image, primaryAction: nil, menu: barButtonMenu)
//            navigationItem.rightBarButtonItem = optionsBarItem
//        } else {
//            var buttonArr = [UIBarButtonItem]()
//            reportBarButton = UIBarButtonItem(image: reportImage.withTintColor(.gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
//            reportBarButton.tag = 1
//            buttonArr.append(reportBarButton)
//            
//            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
//                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
//                if let _ = viewController as? ChatListViewController {
//                    postBarButton = UIBarButtonItem(image: postBarImage.withTintColor(.gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
//                    postBarButton.tag = 2
//                    buttonArr.append(postBarButton)
//                }
//            }
//            
//            self.navigationItem.rightBarButtonItems = buttonArr
//        }
//    }
//    
//    private func configureUI() {
//        view.backgroundColor = .white
//        alert = Alerts()
//        cache = NSCache<NSString, Post>()
//        storage = Set<AnyCancellable>()
//        
//        tableView = UITableView()
//        tableView.allowsSelection = false
//        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.separatorStyle = .none
//        tableView.keyboardDismissMode = .onDrag
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
//        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
//        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
//        view.addSubview(tableView)
//        
//        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
//        tap.cancelsTouchesInView = false
//        tableView.addGestureRecognizer(tap)
//        
//        toolBarView = ToolBarView()
//        toolBarView.buttonAction = { [weak self] tag in
//            switch tag {
//                case 1:
//                    let imagePickerController = UIImagePickerController()
//                    imagePickerController.allowsEditing = false
//                    imagePickerController.sourceType = .photoLibrary
//                    imagePickerController.delegate = self
//                    imagePickerController.modalPresentationStyle = .fullScreen
//                    self?.present(imagePickerController, animated: true, completion: nil)
//                case 2:
//                    self?.sendMessage()
//                default:
//                    break
//            }
//        }
//        toolBarView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(toolBarView)
//        
//        spinner = UIActivityIndicatorView()
//        spinner.stopAnimating()
//        spinner.hidesWhenStopped = true
//        spinner.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60)
//        tableView.tableFooterView = spinner
//    }
//    
//    private func setConstraints() {
//        toolBarBottomConstraint = toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        NSLayoutConstraint.activate([
//            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            toolBarView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
//            toolBarBottomConstraint
//        ])
//    }
//    
//    @objc func buttonPressed(_ sender: UIButton) {
//        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//        feedbackGenerator.impactOccurred()
//        
//        switch sender.tag {
//            case 0:
//                let profileDetailVC = ProfileDetailViewController()
//                profileDetailVC.userInfo = userInfo
//                self.navigationController?.pushViewController(profileDetailVC, animated: true)
//                break
//            case 1:
//                getPost(with: postingId) { [weak self] (fetchedPost) in
//                    let reportVC = ReportViewController()
//                    reportVC.post = fetchedPost
//                    reportVC.userId = self?.userId
//                    self?.navigationController?.pushViewController(reportVC, animated: true)
//                }
//                break
//            case 2:
//                getPost(with: postingId) { [weak self] (fetchedPost) in
//                    let listDetailVC = ListDetailViewController()
//                    listDetailVC.post = fetchedPost
//                    self?.navigationController?.pushViewController(listDetailVC, animated: true)
//                }
//            default:
//                break
//        }
//    }
//    
//    @objc func menuHandler(action: UIAction) {
//        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//        feedbackGenerator.impactOccurred()
//        
//        guard let postingId = postingId else { return }
//        switch action.title {
//            case "Posting":
//                getPost(with: postingId) { [weak self] (fetchedPost) in
//                    let listDetailVC = ListDetailViewController()
//                    listDetailVC.post = fetchedPost
//                    self?.navigationController?.pushViewController(listDetailVC, animated: true)
//                }
//                break
//            case "Report":
//                getPost(with: postingId) { [weak self] (fetchedPost) in
//                    let reportVC = ReportViewController()
//                    reportVC.post = fetchedPost
//                    reportVC.userId = self?.userId
//                    self?.navigationController?.pushViewController(reportVC, animated: true)
//                }
//                break
//            default:
//                break
//        }
//    }
//}
//
//extension ChatViewController {
//    private func fetchMessages(_ docId: String) {
//        firstListener = FirebaseService.shared.db
//            .collection("chatrooms")
//            .document(docId)
//            .collection("messages")
//            .limit(to: 5)
//            .order(by: "sentAt", descending: true)
//            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
//                if let _ = error {
//                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
//                }
//                
//                defer {
//                    DispatchQueue.main.async {
//                        self?.tableView.reloadData()
//                        self?.tableView.scrollToTop()
//                    }
//                }
//                
//                guard let querySnapshot = querySnapshot else {
//                    return
//                }
//                
//                guard let lastSnapshot = querySnapshot.documents.last else {
//                    // The collection is empty.
//                    return
//                }
//                
//                self?.lastSnapshot = lastSnapshot
//                
//                if let messages = self?.parseMessage(querySnapshot.documents) {
//                    self?.messages = messages
//                }
//            }
//    }
//    
//    private func refetchMessages(_ lastSnapshot: QueryDocumentSnapshot, docId: String) {
//        nextListener = FirebaseService.shared.db
//            .collection("chatrooms")
//            .document(docId)
//            .collection("messages")
//            .order(by: "sentAt", descending: true)
//            .limit(to: 5)
//            .start(afterDocument: lastSnapshot)
//            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
//                if let _ = error {
//                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
//                }
//                
//                defer {
//                    DispatchQueue.main.async {
//                        self?.tableView.reloadData()
//                        self?.tableView.scrollToBottom()
//                        DispatchQueue.main.async {
//                            self?.spinner.stopAnimating()
//                        }
//                    }
//                }
//                
//                guard let querySnapshot = querySnapshot else {
//                    return
//                }
//                
//                guard let lastSnapshot = querySnapshot.documents.last else {
//                    // The collection is empty.
//                    return
//                }
//                
//                self?.lastSnapshot = lastSnapshot
//                
//                if let messages = self?.parseMessage(querySnapshot.documents) {
//                    self?.messages.append(contentsOf: messages)
//                }
//            }
//    }
//    
//    private func parseMessage(_ documents: [QueryDocumentSnapshot]) -> [Message] {
//        return documents.map { docSnapshot -> Message in
//            let data = docSnapshot.data()
//            let senderId = data["sender"] as? String ?? ""
//            let content = data["content"] as? String ?? ""
//            let displayName = data["displayName"] as? String ?? ""
//            let sentAt = data["sentAt"] as? Date ?? Date()
//            let imageURL = data["imageURL"] as? String
//            
//            let formatter = DateFormatter()
//            formatter.dateFormat = "HH:mm"
//            let formattedDate = formatter.string(from: sentAt)
//            
//            return Message(
//                id: senderId,
//                content: content,
//                displayName: displayName,
//                sentAt: formattedDate,
//                imageURL: imageURL
//            )
//        }
//    }
//    
//    private func sendMessage() {
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
//        let chatInitializer = ChatInitializer(
//            chatIsNew: chatIsNew,
//            ref: ref,
//            userInfo: userInfo,
//            messageContent: messageContent,
//            chatListModel: chatListModel,
//            docId: docId,
//            postingId: postingId
//        )
//        
//        chatInitializer.createChatInfo()
//            .sink { [weak self] (completion) in
//                switch completion {
//                    case .failure(.generalError(reason: let err)):
//                        self?.alert.showDetail("Error", with: err, for: self)
//                    case .failure(.chatDisabled):
//                        guard let displayName = self?.userInfo.displayName else { return }
//                        self?.alert.showDetail("Undelivered Message", with: "The message couldn't be delivered because \(displayName) has left the chat.", for: self)
//                    case .finished:
//                        break
//                    default:
//                        break
//                }
//            } receiveValue: { [weak self] (ref) in
//                // send text message
//                guard let recipient = self?.userInfo.uid else { return }
//                
//                ref.collection("messages").addDocument(data: [
//                    "sentAt": Date(),
//                    "content": messageContent,
//                    "sender": userId,
//                    "recipient": recipient,
//                ]) { (error) in
//                    if let _ = error {
//                        self?.alert.showDetail("Sorry", with: "Unable to send the message at the moment.", for: self)
//                    } else {
//                        self?.toolBarView.textView.text.removeAll()
//                    }
//                }
//            }
//            .store(in: &storage)
//    }
//}
//
//extension ChatViewController {
//    // MARK: - addKeyboardObserver
//    private func addKeyboardObserver() {
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//        
//    }
//    
//    // MARK: - removeKeyboardObserver
//    private func removeKeyboardObserver(){
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
//    
//    @objc private func keyboardWillShow(notification: NSNotification) {
//        if let userInfo = notification.userInfo {
//            guard let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
//            let keyboardViewEndFrame = view.convert(keyBoardFrame, from: view.window)
//            let keyboardHeight = keyboardViewEndFrame.height
//            
//            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
//            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
//            
//            self.tableView.frame = CGRect(
//                origin: .zero,
//                size: CGSize(
//                    width: self.view.bounds.size.width,
//                    height: self.view.bounds.size.height - keyboardHeight
//                )
//            )
//            
//            // - toolBarView.bounds.size.height
//            //            let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
//            //            self.tableView.contentInset = insets
//            //            self.tableView.scrollIndicatorInsets = insets
//            
//            self.toolBarBottomConstraint.constant = -keyboardHeight
//            self.view.setNeedsLayout()
//            let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
//            UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
//                self.view.layoutIfNeeded()
//            })
//            tableView.scrollToTop()
//        }
//    }
//    
//    @objc private func keyboardWillHide(notification: NSNotification) {
//        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
//        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
//        
//        let insets: UIEdgeInsets = .zero
//        tableView.contentInset = insets
//        tableView.scrollIndicatorInsets = insets
//        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
//        
//        //        self.tableView.frame.origin.y = .zero
//        self.toolBarBottomConstraint.constant = 0
//        view.setNeedsLayout()
//        let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
//        UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
//            //                    self.toolBarView.frame = CGRect(origin: CGPoint(x: 0, y: self.view.frame.size.height - self.toolBarView.bounds.size.height - keyboardHeight), size: CGSize(width: self.view.bounds.size.width, height: 60))
//            self.view.layoutIfNeeded()
//        })
//    }
//}
//
//extension ChatViewController: TableViewConfigurable, UITableViewDataSource, UIContextMenuInteractionDelegate, SharableDelegate {
//    final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return messages.count
//    }
//    
//    final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as? MessageCell else {
//            fatalError("Unable to dequeue the custom table cell")
//        }
//        
//        cell.selectionStyle = .none
//        let message = messages[indexPath.row]
//        cell.set(with: message, myId: userId)
//        
//        let interaction = UIContextMenuInteraction(delegate: self)
//        cell.contentLabel.isUserInteractionEnabled = true
//        cell.contentLabel.addInteraction(interaction)
//        
//        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
//        return cell
//    }
//    
//    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
//            guard let contentLabel = interaction.view as? UILabel,
//                  let message = contentLabel.text else { return nil }
//            
//            return self.createMenu(message: message)
//        }
//    }
//    
//    func createMenu(message: String) -> UIMenu {
//        // Create a UIAction for sharing
//        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] action in
//            let objectsToShare: [AnyObject] = [message as AnyObject]
//            self?.share(objectsToShare)
//        }
//        
//        // Create an action for renaming
//        let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
//            let pasteboard = UIPasteboard.general
//            pasteboard.string = message
//        }
//        
//        // Create and return a UIMenu with all of the actions as children
//        return UIMenu(title: "", children: [share, copy])
//    }
//}
//
//// MARK: - Image picker
//extension ChatViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        picker.dismiss(animated: true)
//        
//        guard let url = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
//            print("No image found")
//            return
//        }
//        
//        alert.showDetail(
//            "Picture Message",
//            with: "Would you like to send the image?",
//            for: self,
//            alertStyle: .withCancelButton,
//            buttonAction: { [weak self] in
//                guard let userId = self?.userId else { return }
//                Future<URL?, PostingError> { promise in
//                    self?.uploadImage(url: url, userId: userId, promise: promise)
//                }
//                .sink { [weak self] (completion) in
//                    switch completion {
//                        case .failure(.generalError(reason: let err)):
//                            self?.alert.showDetail("Error", with: err, for: self)
//                        case .finished:
//                            break
//                        default:
//                            break
//                    }
//                } receiveValue: { [weak self] (url) in
//                    guard let url = url else { return }
//                    self?.sendImage(url: url)
//                }
//                .store(in: &self!.storage)
//            }
//        )
//    }
//    
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
//    
//    private func sendImage(url: URL) {
//        guard let userId = userId else {
//            return
//        }
//        
//        let ref = FirebaseService.shared.db
//            .collection("chatrooms")
//            .document(docId)
//        
//        let chatInitializer = ChatInitializer(
//            chatIsNew: chatIsNew,
//            ref: ref,
//            userInfo: userInfo,
//            messageContent: "Image",
//            chatListModel: chatListModel,
//            docId: docId,
//            postingId: postingId
//        )
//        
//        chatInitializer.createChatInfo()
//            .sink { [weak self] (completion) in
//                switch completion {
//                    case .failure(.generalError(reason: let err)):
//                        self?.alert.showDetail("Error", with: err, for: self)
//                    case .failure(.chatDisabled):
//                        guard let displayName = self?.userInfo.displayName else { return }
//                        self?.alert.showDetail("Undelivered Message", with: "The message couldn't be delivered because \(displayName) has left the chat.", for: self)
//                    case .finished:
//                        break
//                    default:
//                        break
//                }
//            } receiveValue: { [weak self] (ref) in
//                print("ref", ref)
//                // send text message
//                guard let recipient = self?.userInfo.uid else { return }
//                print("recipient", recipient)
//                ref.collection("messages").addDocument(data: [
//                    "sentAt": Date(),
//                    "imageURL": url.absoluteString,
//                    "sender": userId,
//                    "recipient": recipient,
//                ]) { (error) in
//                    if let _ = error {
//                        self?.alert.showDetail("Sorry", with: "Unable to send the image at the moment.", for: self)
//                    } else {
//                        //                        self?.toolBarView.textView.text.removeAll()
//                    }
//                }
//            }
//            .store(in: &storage)
//    }
//}
//
//extension ChatViewController: UITableViewDelegate {
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        let offset = scrollView.contentOffset
//        let bounds = scrollView.bounds
//        let size = scrollView.contentSize
//        let inset = scrollView.contentInset
//        let y = offset.y + bounds.size.height - inset.bottom
//        let h = size.height
//        let reload_distance:CGFloat = 10.0
//        if y > (h + reload_distance) {
//            spinner.startAnimating()
//            delay(0.5) { [weak self] in
//                guard let lastSnapshot = self?.lastSnapshot,
//                      let docId = self?.docId else { return }
//                self?.refetchMessages(lastSnapshot, docId: docId)
//            }
//        }
//    }
//}
//
////    private func sendMessage1() {
////        guard
////            let messageContent = toolBarView.textView.text,
////            !messageContent.isEmpty,
////            let userId = userId else {
////            return
////        }
////
////        let ref = FirebaseService.shared.db
////            .collection("chatrooms")
////            .document(docId)
////
////        if self.messages.count == 0 {
////            /// docId is the hashed Id that corresponds to the unique ID of the chat room
////            guard let sellerUserId = userInfo.uid else {
////                self.alert.showDetail(
////                    "Sorry",
////                    with: "Unable to retrieve the seller's info. Please try again",
////                    for: self,
////                    buttonAction: {
////                        self.navigationController?.popViewController(animated: true)
////                    }, completion:  {
////
////                    }
////                )
////                return
////            }
////
////            // only the buyer can initiate the conversation
////            // so the initial setting of the following data is true
////            ref.setData([
////                "members": [sellerUserId, userId],
////                "sellerUserId": sellerUserId,
////                "sellerDisplayName": userInfo.displayName,
////                "sellerPhotoURL": userInfo.photoURL ?? "NA",
////                "buyerUserId": userId,
////                "buyerDisplayName": displayName!,
////                "buyerPhotoURL": photoURL ?? "NA",
////                "docId": docId!,
////                "latestMessage": messageContent,
////                "sentAt": Date()
////            ]) { [weak self] (error) in
////                if let error = error {
////                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
////                } else {
//////                    if let tabBarVCs = self?.tabBarController?.viewControllers {
//////                        for case let vc as UINavigationController in tabBarVCs where vc.title == "Inbox" {
//////                            for case let chatListVC as ChatListViewController in vc.children {
//////                                chatListVC.fetchChatList()
//////                            }
//////                        }
//////                    }
////                }
////            }
////        } else {
////            ref.updateData([
////                "latestMessage": messageContent,
////                "sentAt": Date()
////            ]) { [weak self] (error) in
////                if let error = error {
////                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
////                }
////            }
////        }
////
////        ref.collection("messages").addDocument(data: [
////            "sentAt": Date(),
////            "content": messageContent,
////            "sender": userId,
////            "recipient": "recipientUid",
////        ]) { [weak self] (error) in
////            if let error = error {
////                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
////            } else {
////                self?.toolBarView.textView.text.removeAll()
////            }
////        }
////    }
////
////    private func sendImage(url: URL) {
////        let ref = FirebaseService.shared.db
////            .collection("chatrooms")
////            .document(docId)
////
////        if self.messages.count == 0 {
////            /// docId is the hashedId that corresponds to the unique ID of the chat room
////            guard let sellerUserId = userInfo.uid else {
////                self.alert.showDetail("Sorry", with: "Unable to retrieve the seller's info. Please try again", for: self) {
////                    self.navigationController?.popViewController(animated: true)
////                } completion: {}
////                return
////            }
////
////            defer {
////                deleteFile(fileName: imageName)
////            }
////
////            ref.setData([
////                "members": [sellerUserId, userId],
////                "sellerUserId": sellerUserId,
////                "sellerDisplayName": userInfo.displayName,
////                "sellerPhotoURL": userInfo.photoURL ?? "NA",
////                "buyerUserId": userId!,
////                "buyerDisplayName": displayName!,
////                "buyerPhotoURL": photoURL ?? "NA",
////                "docId": docId!,
////                "latestMessage": "",
////                "sentAt": Date(),
////            ])
////        } else {
////            ref.updateData([
////                "latestMessage": "",
////                "sentAt": Date()
////            ])
////        }
////
////        let data: [String: Any] = [
////            "sentAt": Date(),
////            "imageURL": "\(url)",
////            "sender": userId!
////        ]
////        ref.collection("messages").addDocument(data: data) { [weak self] (error) in
////            if let error = error {
////                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
////                    if let imageName = self?.imageName {
////                        self?.deleteFile(fileName: imageName)
////                    }
////                } completion: {}
////            }
////        }
////    }
//


//
//  MessageCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

//import UIKit
//
//class MessageCell: UITableViewCell {
//    static let identifier = "MessageCell"
//    
//    final var stackView: UIStackView!
//    final var contentLabel: UILabelPadding!
//    final var dateLabel: UILabelPadding!
//    final var constraint = [NSLayoutConstraint]()
//    final let thumbImageView = UIImageView()
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
//        
//        configure()
//        setConstraints()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("not implemented")
//    }
//    
//}
//
//extension MessageCell {
//    func configure() {
//        contentLabel = UILabelPadding()
//        contentLabel.numberOfLines = 0
//        contentLabel.font = UIFont.systemFont(ofSize: 15)
//        contentLabel.layer.cornerRadius = 11
//        contentLabel.clipsToBounds = true
//        contentLabel.adjustsFontForContentSizeCategory = true
//        
//        dateLabel = UILabelPadding()
//        dateLabel.top = 0
//        dateLabel.textAlignment = .right
//        dateLabel.textColor = .lightGray
//        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
//        dateLabel.adjustsFontForContentSizeCategory = true
//        
//        stackView = UIStackView(arrangedSubviews: [thumbImageView, contentLabel, dateLabel])
//        stackView.spacing = 3
//        stackView.axis = .vertical
//        stackView.distribution = .fillProportionally
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(stackView)
//    }
//    
//    func setConstraints() {
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
//            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//        ])
//    }
//    
//    func set(with message: Message, myId: String) {
//        contentLabel.text = message.content
//        dateLabel.text = message.sentAt
//        
//        NSLayoutConstraint.deactivate(constraint)
//        constraint.removeAll()
//        // message.id means the UID of the sender
//        if message.id == myId {
//            if let imageURL = message.imageURL {
//                //                let loadingIndicator = UIActivityIndicatorView()
//                thumbImageView.image = UIImage(named: "placeholder")
//                guard let url = URL(string: imageURL) else { return }
//                downloadImageFrom(url) { [weak self] (image) in
//                    DispatchQueue.main.async {
//                        //                        self?.thumbImageView.bounds = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
//                        self?.thumbImageView.image = image
//                    }
//                }
//                thumbImageView.layer.cornerRadius = 8
//                thumbImageView.translatesAutoresizingMaskIntoConstraints = false
//                constraint.append(thumbImageView.heightAnchor.constraint(equalToConstant: 200))
//                
//            } else {
//                contentLabel?.backgroundColor = UIColor(red: 102/255, green: 140/255, blue: 255/255, alpha: 1)
//                contentLabel?.textColor = .white
//                stackView.alignment = .trailing
//            }
//            
//            constraint.append(contentsOf: [
//                stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
//            ])
//        } else {
//            contentLabel?.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
//            contentLabel?.textColor = .black
//            stackView.alignment = .leading
//            
//            constraint.append(contentsOf: [
//                stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
//            ])
//        }
//        NSLayoutConstraint.activate(constraint)
//        stackView.setNeedsLayout()
//    }
//    
//    override func prepareForReuse() {
//        thumbImageView.image = nil
//    }
//}
