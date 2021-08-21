//
//  ParentParentListEditViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-17.
//

import UIKit
import Firebase

class ParentListEditViewController: UIViewController, UITextFieldDelegate {
    var scrollView = UIScrollView()
    var post: Post!
    let TOP_MARGIN: CGFloat = 40
    var titleLabel: UILabel!
    var titleNameTextField: UITextField!
    var descTitleLabel: UILabel!
    var descTextView: UITextView!
    var db: Firestore! {
        return FirebaseService.shared.db
    }
    var alert: Alerts!
    // The callback to the previous VC (i.e. ListDetailVC) to reflect the updated data
    weak var delegate: UpdatePostDelegate?
    var stackView: UIStackView!
    let buttonData: [[String: Any]] = [
        [
            "title": "Update",
            "tag": 0,
            "bgColor": UIColor.black
        ],
        [
            "title": "Delete",
            "tag": 1,
            "bgColor": UIColor.red
        ]
    ]
    var SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addKeyboardObserver()
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObserver()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT = getDefaultHeight()
    }

    func configureUI() {
        alert = Alerts()
        self.hideKeyboardWhenTappedAround()
        title = "Edit Post"
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.fill()
                
        titleLabel = createTitleLabel(text: "Title")
        titleLabel.sizeToFit()
        scrollView.addSubview(titleLabel)
        
        titleNameTextField = createTextField(delegate: self)
        titleNameTextField.text = post.title
        scrollView.addSubview(titleNameTextField)
        
        descTitleLabel = createTitleLabel(text: "Description")
        scrollView.addSubview(descTitleLabel)
        
        descTextView = UITextView()
        descTextView.text = post.description
        descTextView.layer.borderWidth = 0.7
        descTextView.layer.cornerRadius = 5
        descTextView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        descTextView.clipsToBounds = true
        descTextView.isScrollEnabled = true
        descTextView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        descTextView.font = UIFont.preferredFont(forTextStyle: .body)
        descTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descTextView)
        
        stackView = createUpdateDeleteButtons(buttonData)
        scrollView.addSubview(stackView)
    }
    
    func setConstraints() {        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: TOP_MARGIN),
            titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            
            titleNameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            titleNameTextField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            titleNameTextField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            titleNameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            descTitleLabel.topAnchor.constraint(equalTo: titleNameTextField.bottomAnchor, constant: 40),
            descTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            descTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            descTextView.topAnchor.constraint(equalTo: descTitleLabel.bottomAnchor, constant: 10),
            descTextView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            descTextView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            descTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                guard let itemTitle = titleNameTextField.text,
                      let desc = descTextView.text else { return }
                
                let content = [
                    StandardAlertContent(
                        index: 0,
                        titleString: "Update Post",
                        body: ["": "Are you sure you want to update your post?"],
                        fieldViewHeight: 100,
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton
                    )
                ]
                
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    // responses to the main vc's button
                    mainVC.buttonAction = { _ in
                        guard let postId = self?.post.documentId else { return }
                        
                        self?.db.collection("post").document(postId).updateData([
                            "title": itemTitle,
                            "description": desc
                        ]) { [weak self] (error) in
                            if let error = error {
                                self?.alert.showDetail("Update Error", with: error.localizedDescription, height: 400, for: self)
                            }
                            
                            self?.alert.showDetail("Success!", with: "Your post has been successfully updated.", for: self, buttonAction: {
                                self?.dismiss(animated: true, completion: {
                                    self?.navigationController?.popViewController(animated: true)
                                })
                            }, completion:  {
                                self?.delegate?.didUpdatePost(titleString: itemTitle, desc: desc, files: nil)
                            })
                        }
                    }
                }
                self.present(alertVC, animated: true, completion: nil)
            case 1:
                let content = [
                    StandardAlertContent(
                        index: 0,
                        titleString: "Delete Post",
                        body: ["": "Are you sure you want to delete your post?"],
                        fieldViewHeight: 100,
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton
                    )
                ]
                
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    // responses to the main vc's button
                    mainVC.buttonAction = { _ in
                        guard let postId = self?.post.documentId else { return }
                        self?.db.collection("post").document(postId).delete(completion: { (error) in
                            if let error = error {
                                self?.alert.showDetail("Update Error", with: error.localizedDescription, height: 400, for: self)
                            }
                            
                            if let files = self?.post.files {
                                for file in files {
                                    // Create a reference to the file to delete
                                    let storage = Storage.storage()
                                    let storageRef = storage.reference()
                                    let mediaRef = storageRef.child(file)
                                    
                                    // Delete the file
                                    mediaRef.delete { error in
                                        if let error = error {
                                            // Uh-oh, an error occurred!
                                            print("storage delete error", error)
                                        } else {
                                            // File deleted successfully
                                            print("storage delete success")
                                        }
                                    }
                                }
                            }
                            
                            self?.alert.showDetail("Success!", with: "Your post has been successfully deleted.", for: self, buttonAction: {
                                self?.dismiss(animated: true, completion: {
                                    self?.navigationController?.popToRootViewController(animated: true)
                                })
                            }, completion:  {})
                        })
                    }
                }
                self.present(alertVC, animated: true, completion: nil)
            default:
                break
        }
    }
    
    func getDefaultHeight() -> CGFloat {
        return TOP_MARGIN +
            titleLabel.bounds.size.height +
            descTitleLabel.bounds.size.height +
            descTextView.bounds.size.height +
            stackView.bounds.size.height +
            300
    }
    
    func createUpdateDeleteButtons(_ buttonData: [[String: Any]]) -> UIStackView {
        let buttons = buttonData.map { createSingleButton(titleString: $0["title"] as! String, tag: $0["tag"] as! Int, bgColor: $0["bgColor"] as! UIColor)}
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    func createSingleButton(titleString: String, tag: Int, bgColor: UIColor) -> UIButton {
        let button = UIButton()
        button.backgroundColor = .black
        button.layer.cornerRadius = 5
        button.setTitle(titleString, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button.backgroundColor = bgColor
        button.tag = tag
        return button
    }
}

extension ParentListEditViewController {
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
        //Need to calculate keyboard exact size due to Apple suggestions
        
        guard let info = notification.userInfo,
              let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize.height
        if let activeField = self.descTextView {
            if (!aRect.contains(activeField.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        //Once keyboard disappears, restore original positions
        self.scrollView.contentInset = .zero
        self.scrollView.scrollIndicatorInsets = .zero
        self.view.endEditing(true)
    }
}
