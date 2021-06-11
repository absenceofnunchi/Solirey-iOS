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
}

class ChatViewController: UIViewController {
    var userInfo: UserInfo!
    var messages = [Message]()
    var toolBarView: ToolBarView!
    var constraints = [NSLayoutConstraint]()
    let alert = Alerts()
    var docId: String! {
        didSet {
            fetchData(docId: docId)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDocId()
        configureUI()
        setConstraints()
        applyConstraints(bottomDistance: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addKeyboardObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObserver()
    }
}

extension ChatViewController {
    func configureUI() {
        self.hideKeyboardWhenTappedAround()
        view.backgroundColor = .white
        title = userInfo.displayName

        toolBarView = ToolBarView()
        toolBarView.buttonAction = {
            self.sendMessage()
        }
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBarView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
        
        let combinedString = sellerUid + buyerUid
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
                    return Message(id: docId, content: content, displayName: displayName)
                }
            }
    }
    
    func sendMessage() {
        guard let messageContent = toolBarView.textView.text, !messageContent.isEmpty else {
            return
        }
        
        FirebaseService.sharedInstance.db.collection("chatrooms").document(docId).collection("messages").addDocument(data: [
            "sentAt": Date(),
            "displayName": userInfo.email ?? "NA",
            "content": messageContent,
            "sender": userInfo.uid ?? "NA"
        ])
        
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

            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
            let curve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
            
            if notification.name == UIResponder.keyboardWillHideNotification {
                applyConstraints(bottomDistance: 0, duration: duration, curve: curve!)
            } else {
                applyConstraints(isHidden: false, bottomDistance: -keyboardHeight, duration: duration, curve: curve!)
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

        NSLayoutConstraint.activate(constraints)
        let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
        UIView.animate(withDuration: duration * 3, delay: 0, options: curveAnimationOptions, animations: {
            self.toolBarView.layoutIfNeeded()
        }, completion: { (isCompleted) in
            return
        })
    }
}
