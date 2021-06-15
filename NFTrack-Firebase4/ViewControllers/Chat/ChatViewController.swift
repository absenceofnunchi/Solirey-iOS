//
//  ChatViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-10.
//

import UIKit
import CryptoKit

struct Message {
    let id: String
    let content: String
    let displayName: String
    let sentAt: String
}

class ChatViewController: UIViewController {
    var userInfo: UserInfo!
    final var itemId: String!
    final var messages = [Message]()
//    final var messages = [
//        Message(id: "dkfjl", content: "First", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "dkfjl", content: "alsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfals;fjldjsflaksdjfl;adjsfldjslfjsdlfkajsdf", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "dkfjl", content: "First", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "dkfjl", content: "First", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "AWHlYSzRCQcYz3zZvVvkXMRrZa72", content: "asdfja;ljsfladjsflkajslfjasdiouaosdfjsdjl", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "AWHlYSzRCQcYz3zZvVvkXMRrZa72", content: "First", displayName: "Hello", sentAt: "10/2"),
//    ]
    final var toolBarView: ToolBarView!
    final var constraints = [NSLayoutConstraint]()
    let alert = Alerts()
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
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        
        getProfileInfo()
        getDocId()
        configureUI()
        setConstraints()
        
//        tableView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver()
        tableView.scrollToBottom()
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
        
        toolBarView = ToolBarView()
        toolBarView.buttonAction = {
            self.sendMessage()
        }
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBarView)
        
        tableView = configureTableView(delegate: nil, dataSource: self, height: nil, cellType: MessageCell.self, identifier: MessageCell.identifier)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        swipe.direction = .down
        tableView.addGestureRecognizer(swipe)
        view.addSubview(tableView)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            toolBarView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: toolBarView.topAnchor),
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

        let combinedString = sellerUid + buyerUid + itemId
        let hashedId = MD5(string: combinedString)
        self.docId = hashedId
    }
    
    private func fetchData(docId: String) {
        FirebaseService.shared.db.collection("chatrooms").document(docId).collection("messages")
            .order(by: "sentAt", descending: false).addSnapshotListener { [weak self] (snapShot, error) in
                if let error = error {
                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
                }
                
                guard let documents = snapShot?.documents else {
                    return
                }
                
                self?.messages = documents.map { docSnapshot -> Message in
                    let data = docSnapshot.data()
                    let docId = docSnapshot.documentID
                    let content = data["content"] as? String ?? ""
                    let displayName = data["displayName"] as? String ?? ""
                    let sentAt = data["sentAt"] as? Date ?? Date()
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    let formattedDate = formatter.string(from: sentAt)
                    
                    return Message(id: docId, content: content, displayName: displayName, sentAt: formattedDate)
                }
                
                self?.tableView.reloadData()
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
        
        
        
//        FirebaseService.sharedInstance.db.collection("chatrooms").document(docId).collection("messages").addDocument(data: [
//            "sentAt": Date(),
//            "displayName": userInfo.email ?? "NA",
//            "content": messageContent,
//            "sender": userInfo.uid ?? "NA"
//        ])
        
//        FirebaseService.sharedInstance.db.collection("messages").document(docId).setData([
//            "sentAt": Date(),
//            "displayName": userInfo.email ?? "NA",
//            "content": messageContent,
//            "sender": userInfo.uid ?? "NA"
//        ])
        
        toolBarView.textView.text.removeAll()
    }
    
    private func MD5(string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        
        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
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
            
            if notification.name == UIResponder.keyboardWillHideNotification {
                self.view.frame.origin.y = 0
            } else {
                self.view.frame.origin.y = -keyboardHeight
//                tableView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width + 600)
            }
        }
    }
    
    private func applyConstraints(isHidden: Bool = true, bottomDistance: CGFloat, duration: TimeInterval = 0, curve: UInt = 0) {
        NSLayoutConstraint.deactivate(constraints)
        constraints.removeAll()
        
        if isHidden {
            constraints.append(contentsOf: [
                toolBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: bottomDistance)
            ])
        } else {
            constraints.append(contentsOf: [
                toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomDistance)
            ])
        }

        let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
        UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
            DispatchQueue.main.async {
                NSLayoutConstraint.activate(self.constraints)
                self.toolBarView.layoutIfNeeded()
            }
        }, completion: { (isCompleted) in
            return
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
        let message = messages[indexPath.row]
        cell.set(with: message, senderId: userInfo.uid!)
        
        let totalRows = tableView.numberOfRows(inSection: indexPath.section)
        //first get total rows in that section by current indexPath.
        if indexPath.row == totalRows - 1 {
            //this is the last row in section.

        }
        return cell
    }
}
