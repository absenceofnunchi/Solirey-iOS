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

class ChatViewController: UIViewController, FileUploadable {
    var userInfo: UserInfo!
    var docId: String! {
        didSet {
            if docId != nil {
                fetchMessages(docId)
                fetchChanelInfo(docId)
            } else {
                alert.showDetail("Error", with: "Unable to generate the chat ID.", for: self)
            }
        }
    }
    private var messages = [Message]()
    private var toolBarView: ToolBarView!
    private var toolBarBottomConstraint: NSLayoutConstraint!
    var alert: Alerts!
    private var tableView: UITableView!
    private var userId: String! {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId)
    }
    private var lastCell: CGRect!
    private var imageName: String!
    private let refreshControl = UIRefreshControl()
    private var lastSnapshot: QueryDocumentSnapshot!
    private var firstListener: ListenerRegistration!
    private var nextListener: ListenerRegistration!
    private var chatInfoListener: ListenerRegistration!
    private var chatListModel: ChatListModel!
    // Toggled on and off by fetchChanelInfo() depending on whether the channel info exists or not
    // If new, create the channel info along with the very first message.
    private var chatIsNew: Bool! = true
    private var storage = Set<AnyCancellable>()
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        
//        getProfileInfo()
        configureUI()
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
        
        if chatInfoListener != nil {
            chatInfoListener.remove()
        }
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver()
    }
}

extension ChatViewController {
//    private func getProfileInfo() {
//        if let uid = UserDefaults.standard.string(forKey: UserDefaultKeys.userId),
//           let displayName = UserDefaults.standard.string(forKey: UserDefaultKeys.displayName) {
//            self.userId = uid
//            self.displayName = displayName
//        } else {
//            self.alert.showDetail("Sorry", with: "Unable to retrieve your profile. Please try again.", for: self) {
//                self.navigationController?.popViewController(animated: true)
//            } completion: {}
//        }
//    }
    
    private func configureUI() {
        view.backgroundColor = .white
        title = userInfo.displayName
        
        alert = Alerts()
        
        tableView = UITableView()
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
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
        
        let refreshTitle = NSAttributedString(string: "Text Message", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        refreshControl.attributedTitle = refreshTitle
        refreshControl.addTarget(self, action: #selector(didRefreshTableView), for: .valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
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
    
    @objc func didRefreshTableView() {
        print("refreshed")
    }
}

extension ChatViewController {
    private func fetchChanelInfo(_ docId: String) {
        FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                if let _ = error {
                    self?.alert.showDetail("Error", with: "There was an error getting the chat information.", for: self)
                    return
                }
 
                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard querySnapshot.exists else {
                    self?.chatIsNew = true
                    return
                }
                
                guard let data = querySnapshot.data() else {
                    return
                }
                
                guard !data.isEmpty else {
                    return
                }
                
                self?.chatIsNew = false
                self?.chatListModel = self?.parseChatListModel(querySnapshot)
            }
    }
    
    private func parseChatListModel(_ document: DocumentSnapshot) -> ChatListModel? {
        guard let data = document.data() else { return nil }
        var buyerDisplayName, sellerDisplayName, latestMessage, buyerPhotoURL, sellerPhotoURL, sellerUserId, buyerUserId: String!
        var date: Date!
        var members: [String]!
        
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
                case "members":
                    members = item.value as? [String]
                default:
                    break
            }
        }
        
        return ChatListModel(
            documentId: document.documentID,
            latestMessage: latestMessage,
            date: date,
            buyerDisplayName: buyerDisplayName,
            buyerPhotoURL: buyerPhotoURL,
            buyerUserId: buyerUserId,
            sellerDisplayName: sellerDisplayName,
            sellerPhotoURL: sellerPhotoURL,
            sellerUserId: sellerUserId,
            members: members
        )
    }
    
    private func fetchMessages(_ docId: String) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .limit(to: 20)
            .order(by: "sentAt", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
                }
                
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.tableView.scrollToBottom()
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
                    self?.messages = messages
                }
            }
    }
    
    private func refetchMessages(_ lastSnapshot: QueryDocumentSnapshot, docId: String) {
        nextListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .limit(to: 3)
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
                }
                
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.tableView.scrollToBottom()
                        self?.delay(1.0) {
                            DispatchQueue.main.async {
                                self?.refreshControl.endRefreshing()
                            }
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
                    self?.messages = messages
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
    
    private func sendMessage() {
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
            docId: docId
        )

        chatInitializer.createChatInfo()
            .sink { [weak self] (completion) in
                switch completion {
                    case .failure(.generalError(reason: let err)):
                        self?.alert.showDetail("Error", with: err, for: self)
                    case .failure(.chatDisabled):
                        guard let displayName = self?.userInfo.displayName else { return }
                        self?.alert.showDetail("Undelivered Message", with: "The message couldn't be delivered because \(displayName) has left the chat.", for: self)
                    case .finished:
                        break
                    default:
                        break
                }
            } receiveValue: { [weak self] (ref) in
                // send text message
                guard let recipient = self?.userInfo.uid else { return }
                
                ref.collection("messages").addDocument(data: [
                    "sentAt": Date(),
                    "content": messageContent,
                    "sender": userId,
                    "recipient": recipient,
                ]) { (error) in
                    if let _ = error {
                        self?.alert.showDetail("Sorry", with: "Unable to send the message at the moment.", for: self)
                    } else {
                        self?.toolBarView.textView.text.removeAll()
                    }
                }
            }
            .store(in: &storage)
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
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyboardViewEndFrame = view.convert(keyBoardFrame!, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height

            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt

            self.tableView.frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: self.view.bounds.size.width,
                    height: self.view.bounds.size.height - keyboardHeight - toolBarView.bounds.size.height
                )
            )
            
//            self.tableView.frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height - keyboardHeight - toolBarView.bounds.size
//                                                                        .height))
//            let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
//            self.tableView.contentInset = insets
//            self.tableView.scrollIndicatorInsets = insets

            self.toolBarBottomConstraint.constant = -keyboardHeight
            self.view.setNeedsLayout()
            let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
            UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
                self.view.layoutIfNeeded()
            })
//            tableView.scrollToBottom()
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

extension ChatViewController: TableViewConfigurable, UITableViewDataSource {
    final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as? MessageCell else {
            fatalError("Unable to dequeue the custom table cell")
        }
        
        cell.selectionStyle = .none
        cell.contentView.tag = 0
        let message = messages[indexPath.row]
        cell.set(with: message, myId: userId)
        
        let totalRows = tableView.numberOfRows(inSection: indexPath.section)
        //first get total rows in that section by current indexPath.
        if indexPath.row == totalRows - 1 {
            //this is the last row in section.
            cell.contentView.tag = 100
        }
        
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
}

// MARK: - Image picker
extension ChatViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
//        
//        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//            print("No image found")
//            return
//        }
//        
//        imageName = UUID().uuidString
//        saveImage(imageName: imageName, image: image)
//        uploadFile(fileName: imageName, userId: userId) { [weak self] (url) in
//            self?.sendImage(url: url)
//        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
