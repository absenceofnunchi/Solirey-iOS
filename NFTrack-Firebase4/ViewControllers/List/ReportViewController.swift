//
//  ReportViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-24.
//

import UIKit

class ReportViewController: UIViewController {
    var post: Post!
    var scrollView: UIScrollView!
    var reportView: GradientBackgroundView!
    var titleContainer: UIView!
    var titleLabel: UILabel!
    var itemTitleLabel: UILabel!
    var usernameLabel: UILabel!
    var commentTitleLabel: UILabel!
    var textView: UITextView!
    var submitButton: UIButton!
    var userId: String!
    var alert: Alerts!
    let TEXTVIEW_HEIGHT: CGFloat = 250

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        setConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentSizeHeight: CGFloat = reportView.bounds.size.height + submitButton.bounds.size.height + textView.bounds.size.height + 200
        scrollView.contentSize = CGSize(width: view.bounds.size.width, height: contentSizeHeight)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addKeyboardObserver()
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObserver()
    }
}

extension ReportViewController {
    func configure() {
        title = "Report"
        self.hideKeyboardWhenTappedAround()
        view.backgroundColor = .white
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.fill()
        
        alert = Alerts()
        
        reportView = GradientBackgroundView()
        reportView.layer.cornerRadius = 10
        reportView.clipsToBounds = true
        reportView.layer.masksToBounds = true
        reportView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 15, leading: 30, bottom: 15, trailing: 20)
        reportView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(reportView)
        
        titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        reportView.addSubview(titleContainer)
        
//        titleLabel = createTitleLabel(text: "Item Title")
//        titleLabel.textColor = .white
//        titleContainer.addSubview(titleLabel)
        
        itemTitleLabel = UILabel()
        itemTitleLabel.text = post.title
        itemTitleLabel.textColor = .white
        itemTitleLabel.lineBreakMode = .byTruncatingTail
        itemTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(itemTitleLabel)
        
        commentTitleLabel = createTitleLabel(text: "Comment")
        commentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(commentTitleLabel)
        
        textView = UITextView()
        textView.layer.borderWidth = 0.7
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 5
        textView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(textView)
        
        submitButton = UIButton()
        submitButton.setTitle("Submit", for: .normal)
        submitButton.backgroundColor = UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1)
        submitButton.layer.cornerRadius = 5
        submitButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(submitButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            reportView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
            reportView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            reportView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            reportView.heightAnchor.constraint(equalToConstant: 150),
            
            titleContainer.centerYAnchor.constraint(equalTo: reportView.centerYAnchor),
            titleContainer.centerXAnchor.constraint(equalTo: reportView.centerXAnchor),
            titleContainer.heightAnchor.constraint(equalToConstant: 100),
            titleContainer.widthAnchor.constraint(equalTo: reportView.widthAnchor, multiplier: 0.8),
            
//            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
//            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
//            titleLabel.widthAnchor.constraint(equalTo: titleContainer.widthAnchor),
//            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            
//            itemTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
//            itemTitleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            itemTitleLabel.widthAnchor.constraint(equalTo: titleContainer.widthAnchor),
            itemTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            itemTitleLabel.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor),
            
            commentTitleLabel.topAnchor.constraint(equalTo: reportView.bottomAnchor, constant: 40),
            commentTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commentTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: commentTitleLabel.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: TEXTVIEW_HEIGHT),
            
            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 50),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        view.layoutIfNeeded()
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        guard let userId = userId else {
            self.alert.showDetail("User ID Error", with: "Please make sure you're logged in.", for: self)
            return
        }
        
        let whitespaceCharacterSet = CharacterSet.whitespaces
        guard let comment = textView.text else {
            self.alert.showDetail("Empty Comment", with: "The comment cannot be empty. Please make sure to fill it out before submitting the report.", for: self)
            return
        }
        
        let strippedString = comment.trimmingCharacters(in: whitespaceCharacterSet)
        guard !strippedString.isEmpty else {
            self.alert.showDetail("Empty Comment", with: "The comment cannot be empty. Please make sure to fill it out before submitting the report.", for: self)
            return
        }
                
        let ref = FirebaseService.shared.db
            .collection("report")
            .document(post.documentId)
        
        ref.getDocument { [weak self] (snapshot, error) in
            if let _ = error {
                self?.alert.showDetail("Error", with: "There was an error submitting your report.", for: self)
                return
            }
            
            if let documentExists = snapshot?.exists,
               documentExists == false,
               let docId = self?.post.documentId {
                ref.setData([
                    "documentId": docId
                ])
            }
        }
        
        ref.collection("detail")
        .addDocument(data: [
            "reporter": userId,
            "comment": comment,
            "date": Date(),
            "sellerId": post.sellerUserId ?? "",
            "identifier": post.id ?? ""
        ]) { [weak self] (error) in
            if let _ = error {
                self?.alert.showDetail("Error", with: "Unable to submit the report.", for: self)
            }

            self?.alert.showDetail(
                "Success",
                with: "Your report has been successfully submitted.",
                for: self,
                buttonAction: {
                    self?.dismiss(animated: true, completion: {
                        self?.navigationController?.popViewController(animated: true)
                    })
                }
            )
        }
    }
}

extension ReportViewController {
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
        if let activeField = self.textView {
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
