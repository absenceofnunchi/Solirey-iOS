//
//  ChatViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-10.
//

import UIKit
import CryptoKit

class ChatViewController: UIViewController, ImageUploadable {
    var userInfo: UserInfo!
    final var itemId: String!
    final var messages = [Message]()
    final var toolBarView: ToolBarView!
    final var heightConstraint: NSLayoutConstraint!
    var alert: Alerts!
    final var docId: String! {
        didSet {
            fetchData(docId: docId)
        }
    }
    final var tableView: UITableView!
    final var userId: String!
    final var photoURL: String! {
        return UserDefaults.standard.string(forKey: "photoURL")
    }
    final var displayName: String!
    final var lastCell: CGRect!
    final var imageName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        
        getProfileInfo()
        if docId == nil {
            getDocId()
        }
        configureUI()
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver()
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
}

extension ChatViewController {
    private func getProfileInfo() {
        if let uid = UserDefaults.standard.string(forKey: "userId"),
           let displayName = UserDefaults.standard.string(forKey: "displayName") {
            self.userId = uid
            self.displayName = displayName
        } else {
            self.alert.showDetail("Sorry", with: "Unable to retrieve your profile. Please try again.", for: self) {
                self.navigationController?.popViewController(animated: true)
            }
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
        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
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
    }
    
    private func setConstraints() {
        heightConstraint = toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBarView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            heightConstraint
            
//            tableView.topAnchor.constraint(equalTo: view.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension ChatViewController {
    private func getDocId() {
        let sellerUid = userInfo.uid!

        guard let buyerUid = userId else {
            self.alert.showDetail("Sorry", with: "You're currently not logged in. Please log in and try again.", for: self) {
                self.navigationController?.popViewController(animated: true)
            }
            return
        }

        let combinedString = sellerUid + buyerUid
        let inputData = Data(combinedString.utf8)
        let hashedId = SHA256.hash(data: inputData)
        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()
        self.docId = hashString
    }
    
    private func fetchData(docId: String) {
        DispatchQueue.global(qos: .background).async {
            FirebaseService.shared.db.collection("chatrooms").document(docId).collection("messages")
                .order(by: "sentAt", descending: false).addSnapshotListener { [weak self] (snapShot, error) in
                    if let error = error {
                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
                    }
                    
                    guard let documents = snapShot?.documents else {
                        return
                    }
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                            self?.tableView.scrollToBottom()
                        }
                    }
                    
                    self?.messages = documents.map { docSnapshot -> Message in
                        let data = docSnapshot.data()
                        let docId = data["sender"] as? String ?? ""
                        let content = data["content"] as? String ?? ""
                        let displayName = data["displayName"] as? String ?? ""
                        let sentAt = data["sentAt"] as? Date ?? Date()
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        let formattedDate = formatter.string(from: sentAt)
                        
                        return Message(id: docId, content: content, displayName: displayName, sentAt: formattedDate)
                    }
                }
        }
    }
    
    private func sendMessage() {
        guard let messageContent = toolBarView.textView.text, !messageContent.isEmpty else {
            return
        }
          
        let ref = FirebaseService.shared.db.collection("chatrooms").document(docId)
        if self.messages.count == 0 {
            /// docId is the hashedId that corresponds to the unique ID of the chat room
            guard let sellerId = userInfo.uid else {
                self.alert.showDetail("Sorry", with: "Unable to retrieve the seller's info. Please try again", for: self) {
                    self.navigationController?.popViewController(animated: true)
                }
                return
            }
            
            ref.setData([
                "members": [sellerId, userId],
                "sellerId": sellerId,
                "sellerDisplayName": userInfo.displayName,
                "sellerPhotoURL": userInfo.photoURL ?? "NA",
                "buyerId": userId!,
                "buyerDisplayName": displayName!,
                "buyerPhotoURL": photoURL ?? "NA",
                "docId": docId!,
                "latestMessage": messageContent,
                "sentAt": Date()
            ])
        } else {
            ref.updateData([
                "latestMessage": messageContent,
                "sentAt": Date()
            ])
        }
        
        ref.collection("messages").addDocument(data: [
            "sentAt": Date(),
            "content": messageContent,
            "sender": userId!
        ])
        toolBarView.textView.text.removeAll()
    }
    
    private func sendImage(url: URL) {
        let ref = FirebaseService.shared.db.collection("chatrooms").document(docId)
        if self.messages.count == 0 {
            /// docId is the hashedId that corresponds to the unique ID of the chat room
            guard let sellerId = userInfo.uid else {
                self.alert.showDetail("Sorry", with: "Unable to retrieve the seller's info. Please try again", for: self) {
                    self.navigationController?.popViewController(animated: true)
                }
                return
            }
            
            defer {
                deleteFile(fileName: imageName)
            }
            
            ref.setData([
                "members": [sellerId, userId],
                "sellerId": sellerId,
                "sellerDisplayName": userInfo.displayName,
                "sellerPhotoURL": userInfo.photoURL ?? "NA",
                "buyerId": userId!,
                "buyerDisplayName": displayName!,
                "buyerPhotoURL": photoURL ?? "NA",
                "docId": docId!,
                "latestMessage": "",
                "sentAt": Date()
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
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!) {
                    if let imageName = self?.imageName {
                        self?.deleteFile(fileName: imageName)
                    }
                }
            }
        }
    }
}

extension ChatViewController {
    // MARK: - addKeyboardObserver
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    private func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - keyboardNotifications
    @objc private func keyboardNotifications(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyboardViewEndFrame = view.convert(keyBoardFrame!, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height

            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
            
            if notification.name == UIResponder.keyboardWillHideNotification {
                self.tableView.frame.origin.y = .zero
//                toolBarView.frame = CGRect(origin: CGPoint(x: 0, y: view.bounds.size.height - 60), size: CGSize(width: view.bounds.size.width, height: 60))
                
                self.heightConstraint.constant = 0
                view.setNeedsLayout()
                let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
                UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
                    //                    self.toolBarView.frame = CGRect(origin: CGPoint(x: 0, y: self.view.frame.size.height - self.toolBarView.bounds.size.height - keyboardHeight), size: CGSize(width: self.view.bounds.size.width, height: 60))
                    self.view.layoutIfNeeded()
                })
            } else {
                self.heightConstraint.constant = -keyboardHeight
                view.setNeedsLayout()
                let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
                UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
//                    self.toolBarView.frame = CGRect(origin: CGPoint(x: 0, y: self.view.frame.size.height - self.toolBarView.bounds.size.height - keyboardHeight), size: CGSize(width: self.view.bounds.size.width, height: 60))
                    self.view.layoutIfNeeded()
                })
                
                if let lastCell = view.viewWithTag(100) {
                    let lastCellFrame = lastCell.convert(lastCell.frame, to: view.superview)
                    if lastCellFrame.origin.y + lastCellFrame.size.height > keyboardViewEndFrame.origin.y {
                        let overlap = lastCellFrame.origin.y + lastCellFrame.size.height - keyboardViewEndFrame.origin.y + toolBarView.bounds.size.height + 10
                        self.tableView.frame.origin.y = -overlap
                    }
                }
            }
        }
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
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        imageName = UUID().uuidString
        saveImage(imageName: imageName, image: image)
        uploadImages(image: imageName, userId: userId) { [weak self] (url) in
            self?.sendImage(url: url)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
