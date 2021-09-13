//
//  ChatViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-10.
//

/*
 Abstract:
 Real time chat between two users.
 There are two ways to arrive on this view controller:
    1) ListDetailVC: A previous chat might not exists, in which case a new chat is created using getDocId(), a unique identifer for each chat channel
    2) ChatListVC: The chat already exists. ChatListVC passes post (PostCoreModel), which sets the document ID, which in turn, fetches the chat data using the document ID
 */

import UIKit
import CryptoKit
import FirebaseFirestore

class ChatViewController: UIViewController, FileUploadable {
    var userInfo: UserInfo!
    var post: PostCoreModel! {
        didSet {
            self.docId = post.documentId
        }
    }
    final var docId: String! {
        didSet {
//            if post == nil {
                fetchData(docId: docId)
//            }
        }
    }
    private var messages = [Message]()
    private var toolBarView: ToolBarView!
    private var heightConstraint: NSLayoutConstraint!
    var alert: Alerts!
    private var tableView: UITableView!
    private var userId: String!
    private var photoURL: String! {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.photoURL)
    }
    private var displayName: String!
    private var lastCell: CGRect!
    private var imageName: String!
    private let refreshControl = UIRefreshControl()
    private var lastSnapshot: QueryDocumentSnapshot!
    private var firstListener: ListenerRegistration!
    private var nextListener: ListenerRegistration!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        
        getProfileInfo()
        configureUI()
        setConstraints()
        // if coming from ListVC, no post so no need to fetch
        // post != nil means we're coming from ChatListVC, which already has docId
        if post == nil {
            getDocId()
        } else {
//            fetchData(docId: post.docId)
        }
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
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver()
    }
}

extension ChatViewController {
    private func getProfileInfo() {
        if let uid = UserDefaults.standard.string(forKey: UserDefaultKeys.userId),
           let displayName = UserDefaults.standard.string(forKey: UserDefaultKeys.displayName) {
            self.userId = uid
            self.displayName = displayName
        } else {
            self.alert.showDetail("Sorry", with: "Unable to retrieve your profile. Please try again.", for: self) {
                self.navigationController?.popViewController(animated: true)
            } completion: {}
        }
    }
    
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
        //        toolBarView.frame = CGRect(origin: CGPoint(x: 0, y: view.bounds.size.height - 60), size: CGSize(width: view.bounds.size.width, height: toolBarView.bounds.size.height + 60))
        view.addSubview(toolBarView)
        
        let refreshTitle = NSAttributedString(string: "Text Message", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        refreshControl.attributedTitle = refreshTitle
        refreshControl.addTarget(self, action: #selector(didRefreshTableView), for: .valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
    }
    
    private func setConstraints() {
        heightConstraint = toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBarView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            heightConstraint
        ])
    }
    
    @objc func didRefreshTableView() {
        print("refreshed")
    }
}

extension ChatViewController {
    // To create the unique ID for each chat channel.
    // Should only run when the chat is run for the first time. i.e., from ListDetailVC.
    private func getDocId() {
        let sellerUid = userInfo.uid!
        
        guard let buyerUid = userId else {
            self.alert.showDetail("Sorry", with: "You're currently not logged in. Please log in and try again.", for: self) {
                self.navigationController?.popViewController(animated: true)
            } completion: {}
            return
        }
        
        let combinedString = sellerUid + buyerUid
        let inputData = Data(combinedString.utf8)
        let hashedId = SHA256.hash(data: inputData)
        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()
        self.docId = hashString
    }
    
    private func fetchData(docId: String) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .limit(to: 3)
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
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
    
    private func refetchData(_ lastSnapshot: QueryDocumentSnapshot, docId: String) {
        nextListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .limit(to: 3)
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
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
            
            return Message(id: senderId, content: content, displayName: displayName, sentAt: formattedDate, imageURL: imageURL)
        }
    }
    
    private func sendMessage() {
        guard let messageContent = toolBarView.textView.text, !messageContent.isEmpty, let userId = userId else {
            return
        }

        let ref = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
        
        if self.messages.count == 0 {
            /// docId is the hashedId that corresponds to the unique ID of the chat room
            guard let sellerUserId = userInfo.uid else {
                self.alert.showDetail("Sorry", with: "Unable to retrieve the seller's info. Please try again", for: self, completion:  {
                    self.navigationController?.popViewController(animated: true)
                })
                return
            }

            // only the buyer can initiate the conversation
            // so the initial setting of the following data is true
            ref.setData([
                "members": [sellerUserId, userId],
                "sellerUserId": sellerUserId,
                "sellerDisplayName": userInfo.displayName,
                "sellerPhotoURL": userInfo.photoURL ?? "NA",
                "buyerUserId": userId,
                "buyerDisplayName": displayName!,
                "buyerPhotoURL": photoURL ?? "NA",
                "docId": docId!,
                "latestMessage": messageContent,
                "sentAt": Date()
            ]) { [weak self] (error) in
                if let error = error {
                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                } else {
//                    if let tabBarVCs = self?.tabBarController?.viewControllers {
//                        for case let vc as UINavigationController in tabBarVCs where vc.title == "Inbox" {
//                            for case let chatListVC as ChatListViewController in vc.children {
//                                chatListVC.fetchChatList()
//                            }
//                        }
//                    }
                }
            }
        } else {
            ref.updateData([
                "latestMessage": messageContent,
                "sentAt": Date()
            ]) { [weak self] (error) in
                if let error = error {
                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                }
            }
        }

        ref.collection("messages").addDocument(data: [
            "sentAt": Date(),
            "content": messageContent,
            "sender": userId,
            "recipient": userId == post.sellerUserId ? post.buyerUserId! as String : post.sellerUserId as String,
        ]) { [weak self] (error) in
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
            } else {
                self?.toolBarView.textView.text.removeAll()
            }
        }
    }
    
    private func sendImage(url: URL) {
        let ref = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
        
        if self.messages.count == 0 {
            /// docId is the hashedId that corresponds to the unique ID of the chat room
            guard let sellerUserId = userInfo.uid else {
                self.alert.showDetail("Sorry", with: "Unable to retrieve the seller's info. Please try again", for: self) {
                    self.navigationController?.popViewController(animated: true)
                } completion: {}
                return
            }
            
            defer {
                deleteFile(fileName: imageName)
            }
            
            ref.setData([
                "members": [sellerUserId, userId],
                "sellerUserId": sellerUserId,
                "sellerDisplayName": userInfo.displayName,
                "sellerPhotoURL": userInfo.photoURL ?? "NA",
                "buyerUserId": userId!,
                "buyerDisplayName": displayName!,
                "buyerPhotoURL": photoURL ?? "NA",
                "docId": docId!,
                "latestMessage": "",
                "sentAt": Date(),
            ])
        } else {
            ref.updateData([
                "latestMessage": "",
                "sentAt": Date()
            ])
        }
        
        let data: [String: Any] = [
            "sentAt": Date(),
            "imageURL": "\(url)",
            "sender": userId!
        ]
        ref.collection("messages").addDocument(data: data) { [weak self] (error) in
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
                    if let imageName = self?.imageName {
                        self?.deleteFile(fileName: imageName)
                    }
                } completion: {}
            }
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
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyboardViewEndFrame = view.convert(keyBoardFrame!, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height

            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt

            self.tableView.frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height - keyboardHeight - toolBarView.bounds.size
                                                                        .height))
//            let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
//            self.tableView.contentInset = insets
//            self.tableView.scrollIndicatorInsets = insets

            self.heightConstraint.constant = -keyboardHeight
            self.view.setNeedsLayout()
            let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
            UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
                self.view.layoutIfNeeded()
            })
            tableView.scrollToBottom()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        print("hide")
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt

        let insets: UIEdgeInsets = .zero
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
        
//        self.tableView.frame.origin.y = .zero
        self.heightConstraint.constant = 0
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
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as! MessageCell
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
