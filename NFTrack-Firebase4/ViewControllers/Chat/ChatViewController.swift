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
    var itemId: String!
    var messages = [Message]()
//    var messages = [
//        Message(id: "dkfjl", content: "First", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "dkfjl", content: "alsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfalsalsdjflasjflajsdljfals;fjldjsflaksdjfl;adjsfldjslfjsdlfkajsdf", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "dkfjl", content: "First", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "dkfjl", content: "First", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "AWHlYSzRCQcYz3zZvVvkXMRrZa72", content: "asdfja;ljsfladjsflkajslfjasdiouaosdfjsdjl", displayName: "Hello", sentAt: "10/2"),
//        Message(id: "AWHlYSzRCQcYz3zZvVvkXMRrZa72", content: "First", displayName: "Hello", sentAt: "10/2"),
//    ]
    var toolBarView: ToolBarView!
    var constraints = [NSLayoutConstraint]()
    let alert = Alerts()
    var docId: String! {
        didSet {
            fetchData(docId: docId)
        }
    }
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        
        getDocId()
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
    func configureUI() {
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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        swipe.direction = .down
        tableView.addGestureRecognizer(swipe)
        view.addSubview(tableView)
    }
    
    func setConstraints() {
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
    func getDocId() {
        let sellerUid = userInfo.uid!

        guard let buyerUid = UserDefaults.standard.string(forKey: "userId") else {
            self.alert.showDetail("Sorry", with: "You're currently not logged in. Please log in and try again.", for: self) {
                self.navigationController?.popViewController(animated: true)
            }
            return
        }

        let combinedString = sellerUid + buyerUid + itemId
        let hashedId = MD5(string: combinedString)
        self.docId = hashedId
    }
    
    func fetchData(docId: String) {
        FirebaseService.sharedInstance.db.collection("chatrooms").document(docId).collection("messages")
            .order(by: "sentAt", descending: false).addSnapshotListener { [weak self] (snapShot, error) in
                if let error = error {
                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
                }
                
                guard let documents = snapShot?.documents else {
                    print("no document")
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
    
    func sendMessage() {
        guard let messageContent = toolBarView.textView.text, !messageContent.isEmpty else {
            return
        }
  
        let ref = FirebaseService.sharedInstance.db.collection("chatrooms").document(docId)
        
        if self.messages.count == 0 {
            print("run")
            ref.setData(["new": "new"])
        }
        
        ref.collection("messages").addDocument(data: [
            "sentAt": Date(),
            "displayName": userInfo.email ?? "NA",
            "content": messageContent,
            "sender": userInfo.uid ?? "NA"
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
    
    func MD5(string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        
        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}

extension ChatViewController {
    // MARK: - addKeyboardObserver
    func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)

//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: - keyboardNotifications
    @objc func keyboardNotifications(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyboardViewEndFrame = view.convert(keyBoardFrame!, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height

//            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
//            let curve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
            
            if notification.name == UIResponder.keyboardWillHideNotification {
//                applyConstraints(bottomDistance: 0, duration: duration, curve: curve!)
                self.view.frame.origin.y = 0
                tableView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            } else {
//                applyConstraints(isHidden: false, bottomDistance: -keyboardHeight, duration: duration, curve: curve!)
                self.view.frame.origin.y = -keyboardHeight
                
                tableView.scrollToBottom()
                tableView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width + 600)

            }
        }
    }
    
    func applyConstraints(isHidden: Bool = true, bottomDistance: CGFloat, duration: TimeInterval = 0, curve: UInt = 0) {
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as! MessageCell
        cell.selectionStyle = .none
        let message = messages[indexPath.row]
        cell.set(with: message, senderId: userInfo.uid!)
        return cell
    }
}
