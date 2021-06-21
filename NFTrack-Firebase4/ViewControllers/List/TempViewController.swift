//////
////  ChatViewController.swift
////  NFTrack-Firebase4
////
////  Created by J C on 2021-06-10.
////
//
//import UIKit
//
//struct Message {
//    let id: String
//    let content: String
//    let displayName: String
//}
//
//class ChatViewController: UIViewController {
//    var userInfo: UserInfo!
//    var messages = [Message]()
//    var toolBarView: ToolBarView!
//    //    var messageTextField: UITextView!
//    var toolBarHeight: CGFloat = 50
//    var adjustedKeyboardHeight: CGFloat = 0 {
//        didSet {
//            if let tabBarHeight = self.tabBarController?.tabBar.frame.size.height {
//                print("tabBarHeight", tabBarHeight)
//                print("adjustedKeyboardHeight", self.adjustedKeyboardHeight)
//                let h = self.toolBarView.intrinsicContentSize.height
//                print("h", h)
//                let y = self.view.bounds.size.height - CGFloat(tabBarHeight + h + self.adjustedKeyboardHeight)
//                print("y", y)
//                self.toolBarView.frame = CGRect(x: 0, y: y, width: self.view.bounds.size.width, height: h)
//            }
//        }
//    }
//    var constraints = [NSLayoutConstraint]()
//    //    lazy var noKeyboard: [NSLayoutConstraint] = [
//    //        toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2)
//    //    ]
//    //
//    //    lazy var withKeyboard: [NSLayoutConstraint] = [
//    //        toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2)
//    //    ]
//    //
//    
//    let alert = Alerts()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        configureUI()
//        setConstraints()
//        //        applyConstraints(bottomDistance: 0)
//        adjustedKeyboardHeight = 0
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        addKeyboardObserver()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        removeKeyboardObserver()
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        DispatchQueue.main.async {
//            if let tabBarHeight = self.tabBarController?.tabBar.frame.size.height {
//                print("tabBarHeight", tabBarHeight)
//                print("adjustedKeyboardHeight", self.adjustedKeyboardHeight)
//                let h = self.toolBarView.intrinsicContentSize.height
//                print("h", h)
//                let y = self.view.bounds.size.height - CGFloat(tabBarHeight + h + self.adjustedKeyboardHeight)
//                print("y", y)
//                self.toolBarView.frame = CGRect(x: 0, y: y, width: self.view.bounds.size.width, height: h)
//            }
//        }
//    }
//}
//
//extension ChatViewController {
//    func configureUI() {
//        self.hideKeyboardWhenTappedAround()
//        view.backgroundColor = .white
//        
//        toolBarView = ToolBarView()
//        //        toolBarView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(toolBarView)
//        
//    }
//    
//    func setConstraints() {
//        //        NSLayoutConstraint.activate([
//        //            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//        //            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//        //        ])
//    }
//}
//
//extension ChatViewController {
//    func fetchData(docId: String) {
//        FirebaseService.sharedInstance.db.collection("chatroom").document(docId).collection("messages")
//            .order(by: "sentAt", descending: false).addSnapshotListener { [weak self] (snapShot, error) in
//                if let error = error {
//                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//                }
//                
//                guard let documents = snapShot?.documents else {
//                    print("no document")
//                    return
//                }
//                
//                self?.messages = documents.map { docSnapshot -> Message in
//                    let data = docSnapshot.data()
//                    let docId = docSnapshot.documentID
//                    let content = data["content"] as? String ?? ""
//                    let displayName = data["displayName"] as? String ?? ""
//                    return Message(id: docId, content: content, displayName: displayName)
//                }
//            }
//    }
//    
//    func sendMessage(messageContent: String, docId: String) {
//        FirebaseService.sharedInstance.db.collection("chatrooms").document(docId).collection("messages").addDocument(data: [
//            "sentAt": Date(),
//            "displayName": userInfo.email ?? "NA",
//            "content": messageContent,
//            "sender": userInfo.uid ?? "NA"
//        ])
//    }
//}
//
//extension ChatViewController {
//    // MARK: - addKeyboardObserver
//    func addKeyboardObserver() {
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
//                                               name: UIResponder.keyboardWillChangeFrameNotification,
//                                               object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
//                                               name: UIResponder.keyboardWillHideNotification,
//                                               object: nil)
//    }
//    
//    // MARK: - removeKeyboardObserver
//    func removeKeyboardObserver(){
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
//        
//        //        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
//    }
//    
//    // MARK: - keyboardNotifications
//    // This method will notify when keyboard appears/ dissapears
//    @objc func keyboardNotifications(notification: NSNotification) {
//        if let userInfo = notification.userInfo {
//            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
//            let keyboardViewEndFrame = view.convert(keyBoardFrame!, from: view.window)
//            let keyboardHeight = keyboardViewEndFrame.height
//            //            let keyBoardFrameY = keyBoardFrame!.origin.y
//            
//            //            //Check keyboards Y position and according to that move view up and down
//            //            if keyBoardFrameY >= UIScreen.main.bounds.size.height {
//            //                print("no keyboard")
//            //                applyConstraints(bottomDistance: 0)
//            //            } else {
//            //                print("yes keyboard")
//            //                print("keyBoardFrameY", keyBoardFrameY)
//            //                applyConstraints(bottomDistance: -keyboardHeight)
//            //            }
//            
//            if notification.name == UIResponder.keyboardWillHideNotification {
//                print("no keyboard")
//                //                applyConstraints(bottomDistance: 0)
//                adjustedKeyboardHeight = keyboardHeight
//                
//            } else {
//                print("yes keyboard")
//                adjustedKeyboardHeight = keyboardHeight
//                //                applyConstraints(isHidden: false, bottomDistance: -keyboardHeight)
//            }
//        }
//    }
//    
//    func applyConstraints(isHidden: Bool = true, bottomDistance: CGFloat) {
//        print("constraints", constraints)
//        NSLayoutConstraint.deactivate(constraints)
//        constraints.removeAll()
//        
//        if isHidden {
//            constraints.append(contentsOf: [
//                toolBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: bottomDistance)
//            ])
//        } else {
//            constraints.append(contentsOf: [
//                toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomDistance)
//            ])
//        }
//        
//        NSLayoutConstraint.activate(constraints)
//        UIView.animate(withDuration: 0.5) {
//            self.toolBarView.layoutIfNeeded()
//        }
//    }
//}
//
//
//class ToolBarView : UIView {
//    var textView: UITextView!
//    //    var textViewHeight: CGFloat = 50
//    var sendButton: UIButton!
//    var buttonAction: (()->Void)?
//    
//    var internalHeight : CGFloat = 200 {
//        didSet {
//            self.invalidateIntrinsicContentSize()
//        }
//    }
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width:300, height:self.internalHeight)
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        configure()
//        setConstraints()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//extension ToolBarView {
//    func configure() {
//        textView = UITextView(frame: CGRect(x: 4, y: 4, width: 0, height: 0))
//        let fixedWidth = textView.frame.size.width
//        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
//        //        textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
//        textView.frame.size = CGSize(width: fixedWidth, height: newSize.height)
//        internalHeight = newSize.height
//        textView.layer.borderWidth = 0.7
//        textView.layer.cornerRadius = 10
//        textView.layer.borderColor = UIColor.lightGray.cgColor
//        textView.isScrollEnabled = false
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        self.addSubview(textView)
//        
//        var sendImage: UIImage!
//        if #available(iOS 14.0, *) {
//            sendImage = UIImage(systemName: "paperplane.circle.fill")
//        } else {
//            sendImage = UIImage(systemName: "arrow.up.circle.fill")
//        }
//        
//        sendButton = UIButton.systemButton(with: sendImage, target: self, action: #selector(sent))
//        sendButton.tag = 1
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        self.addSubview(sendButton)
//    }
//    
//    func setConstraints() {
//        NSLayoutConstraint.activate([
//            sendButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.2),
//            sendButton.heightAnchor.constraint(equalTo: self.heightAnchor),
//            sendButton.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
//            
//            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -2),
//            textView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.7),
//            textView.heightAnchor.constraint(equalTo: self.heightAnchor),
//        ])
//    }
//    
//    func adjustTextViewHeight() {
//        let fixedWidth = addtextview.frame.size.width
//        let newSize = addtextview.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
//        self.textHeightConstraint.constant = newSize.height
//        self.view.layoutIfNeeded()
//    }
//    
//    @objc func sent(_ sender: UIButton!) {
//        print("send pressed")
//        if let buttonAction = self.buttonAction {
//            buttonAction()
//        }
//    }
//}
//
