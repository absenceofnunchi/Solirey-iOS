//
//  ReviewPostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-21.
//
/*
 Where you create the review and submit it
 */

import UIKit
import Firebase

class ReviewPostViewController: ParentProfileViewController {
    var post: Post!
    private var reviewTitleLabel: UILabel!
    private var reviewTextView: UITextView!
    private var ratingTitleLabel: UILabel!
    private var stackView: UIStackView!
    private var submitButton: UIButton!
    private let starTintColor: UIColor = .orange
    private var revieweeUserId: String? {
        /// reviewee is the ID that's not the current user's
        if let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) {
           return userId == post.sellerUserId ? post.buyerUserId : post.sellerUserId
        } else {
            return nil
        }
    }
    private var reviewerInfo: UserInfo? = {
        let userDefaults = UserDefaults.standard
        if let userId = userDefaults.string(forKey: UserDefaultKeys.userId),
           let displayName = userDefaults.string(forKey: UserDefaultKeys.displayName) {
            let photoURL = userDefaults.string(forKey: UserDefaultKeys.photoURL)
            return UserInfo(email: nil, displayName: displayName, photoURL: photoURL, uid: userId)
        } else {
            return nil
        }
    }()
    private var numOfStars: Int! {
        didSet {
            numOfStars += 1
        }
    }
    weak var delegate: TableViewRefreshDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver()
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver()
    }
}

extension ReviewPostViewController {
    func fetchUserInfo(_ completion: (() -> Void)? = nil) {
        guard let revieweeUserId = revieweeUserId else {
            self.alert.showDetail("Sorry", with: "Unable to get the user ID.", for: self)
            return
        }
        
        let docRef = FirebaseService.shared.db.collection("user").document(revieweeUserId)
        docRef.getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let data = document.data() {
                    let displayName = data[UserDefaultKeys.displayName] as? String
                    let photoURL = data[UserDefaultKeys.photoURL] as? String
                    let userInfo = UserInfo(email: nil, displayName: displayName!, photoURL: photoURL, uid: revieweeUserId)
                    self?.userInfo = userInfo
                    completion?()
                }
            } else {
                self?.alert.showDetail("Sorry", with: "User data could not be fetched", for: self) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    override func configureUI() {
        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
        
        guard let docImage = UIImage(systemName: "doc.plaintext") else { return }
        let rightBarButton = UIBarButtonItem(image: docImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
        rightBarButton.tag = 7
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        fetchUserInfo {
            super.configureUI()
            self.displayNameTextField.isUserInteractionEnabled = false
            
            self.reviewTitleLabel = self.createTitleLabel(text: "Review")
            self.reviewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.addSubview(self.reviewTitleLabel)
            
            self.reviewTextView = UITextView()
            self.reviewTextView.layer.borderWidth = 0.7
            self.reviewTextView.layer.borderColor = UIColor.lightGray.cgColor
            self.reviewTextView.layer.cornerRadius = 5
            self.reviewTextView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
            self.reviewTextView.clipsToBounds = true
            self.reviewTextView.isScrollEnabled = true
            self.reviewTextView.font = UIFont.systemFont(ofSize: 15)
            self.reviewTextView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
            self.reviewTextView.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.addSubview(self.reviewTextView)
            
            self.ratingTitleLabel = self.createTitleLabel(text: "Rating")
            self.ratingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.addSubview(self.ratingTitleLabel)
            
            var starArr = [UIButton]()
            for i in 0..<5 {
                guard let image = UIImage(systemName: "star") else { return }
                let button = UIButton.systemButton(with: image.withTintColor(self.starTintColor, renderingMode: .alwaysOriginal), target: self, action: #selector(self.buttonPressed(_:)))
                button.tag = i
                starArr.append(button)
            }
            self.stackView = UIStackView(arrangedSubviews: starArr)
            self.stackView.axis = .horizontal
            self.stackView.distribution = .fillEqually
            self.stackView.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.addSubview(self.stackView)
            
            self.submitButton = UIButton()
            self.submitButton.setTitle("Submit", for: .normal)
            self.submitButton.addTarget(self, action: #selector(self.buttonPressed(_:)), for: .touchUpInside)
            self.submitButton.tag = 6
            self.submitButton.layer.cornerRadius = 8
            self.submitButton.backgroundColor = .black
            self.submitButton.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.addSubview(self.submitButton)
            
            NSLayoutConstraint.activate([
                self.reviewTitleLabel.topAnchor.constraint(equalTo: self.displayNameTextField.bottomAnchor, constant: 40),
                self.reviewTitleLabel.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
                self.reviewTitleLabel.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
                self.reviewTitleLabel.heightAnchor.constraint(equalToConstant: 50),
                
                self.reviewTextView.topAnchor.constraint(equalTo: self.reviewTitleLabel.bottomAnchor, constant: 0),
                self.reviewTextView.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
                self.reviewTextView.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
                self.reviewTextView.heightAnchor.constraint(equalToConstant: 150),
                
                self.ratingTitleLabel.topAnchor.constraint(equalTo: self.reviewTextView.bottomAnchor, constant: 40),
                self.ratingTitleLabel.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
                self.ratingTitleLabel.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
                self.ratingTitleLabel.heightAnchor.constraint(equalToConstant: 50),
                
                self.stackView.topAnchor.constraint(equalTo: self.ratingTitleLabel.bottomAnchor, constant: 0),
                self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
                self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
                self.stackView.heightAnchor.constraint(equalToConstant: 50),
                
                self.submitButton.topAnchor.constraint(equalTo: self.stackView.bottomAnchor, constant: 40),
                self.submitButton.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
                self.submitButton.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
                self.submitButton.heightAnchor.constraint(equalToConstant: 50),
            ])
        }
    }
    
    @objc override func buttonPressed(_ sender: UIButton!) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0..<5:
                numOfStars = sender.tag
                for case let av as UIButton in stackView.arrangedSubviews {
                    if av.tag <= sender.tag {
                        guard let image = UIImage(systemName: "star.fill") else { return }
                        av.setImage(image.withTintColor(starTintColor, renderingMode: .alwaysOriginal), for: .normal)
                    } else {
                        guard let image = UIImage(systemName: "star") else { return }
                        av.setImage(image.withTintColor(starTintColor, renderingMode: .alwaysOriginal), for: .normal)
                    }
                }
            case 6:
                didSubmit()
            case 7:
                let historyDetailVC = HistoryDetailViewController()
                historyDetailVC.post = post
                historyDetailVC.userInfo = userInfo
                self.navigationController?.pushViewController(historyDetailVC, animated: true)
            default:
                break
        }
    }
    
    func didSubmit() {
        guard let textView = reviewTextView, !textView.text.isEmpty, let numOfStars = numOfStars, numOfStars > 0 else {
            self.alert.showDetail("Sorry", with: "All fields must be filled out including the rating.", for: self)
            return
        }
        
        guard let revieweeUserId = revieweeUserId,
              let reviewerUserId = reviewerInfo?.uid,
              let reviewerDisplayName = reviewerInfo?.displayName else {
            self.alert.showDetail("Sorry", with: "Unable to retrieve user ID.", for: self)
            return
        }
        guard let db = FirebaseService.shared.db else {
            self.alert.showDetail("Sorry", with: "There was an error submitting your review.", for: self)
            return
        }
        
        let detailVC = DetailViewController(titleAlignment: .left, messageTextAlignment: .left, detailVCStyle: .withCancelButton)
        detailVC.titleString = "Are you sure you want to submit this review?"
        detailVC.message = "Your review cannot be modified or deleted once submitted."
        detailVC.buttonAction = { [weak self] _ in
            self?.dismiss(animated: true, completion: {
                /// batch commit
                /// 1. update the post's isReviewed field to true
                /// 2. create a new review post
                                
                self?.showSpinner {
                    let batch = db.batch()
                    // isReviewd in post
                    let postRef = db.collection("post").document(self!.post.documentId)
                    batch.updateData(["isReviewed": true], forDocument: postRef)
                    
                    // first create review
                    let reviewRef = db.collection("review").document(revieweeUserId)
                    batch.setData([
                        "revieweeUserId": revieweeUserId,
                    ], forDocument: reviewRef)
                    
                    for i in 0..<25 {
                        let reviewDetailRef = reviewRef.collection("details").document()
                        batch.setData([
                            "revieweeUserId": revieweeUserId,
                            "reviewerUserId": reviewerUserId,
                            "reviewerDisplayName": reviewerDisplayName,
                            "reviewerPhotoURL": self!.reviewerInfo!.photoURL!,
                            "starRating": numOfStars,
//                            "review": textView.text!,
                            "review": "\(i)",
                            "confirmReceivedHash": self!.post.confirmReceivedHash! as String,
                            "finalizedDate": (self?.post.confirmReceivedDate! ?? Date()) as Date,
                        ], forDocument: reviewDetailRef)
                    }
                    
                    batch.commit() { err in
                        if let err = err {
                            self?.alert.showDetail("Sorry", with: err.localizedDescription, for: self)
                        } else {
                            self?.alert.showDetail("Success!", with: "Thank you for the review.", for: self) {
                                self?.navigationController?.popViewController(animated: true)
                                self?.delegate?.didRefreshTableView(index: self?.reviewerInfo?.uid == self?.post.sellerUserId ? 1 : 0)
                            }
                        }
                    }
                }
            })
        }
        present(detailVC, animated: true, completion: nil)
    }
    
    override func configureCustomProfileImage(from url: String) {
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        profileImageButton.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: profileImageButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: profileImageButton.centerYAnchor)
        ])
        loadingIndicator.startAnimating()
        
        FirebaseService.shared.downloadImage(urlString: url) { [weak self] (image, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: strongSelf)
            }
            
            if let image = image {
                loadingIndicator.stopAnimating()
                strongSelf.profileImageButton = strongSelf.createProfileImageButton(strongSelf.profileImageButton, image: image)
            }
        }
        
    }
}

private extension ReviewPostViewController {
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
            
            let insets = UIEdgeInsets(top: -keyboardHeight + 20, left: 0, bottom: 0, right: 0)
            scrollView.contentInset = insets
            scrollView.scrollIndicatorInsets = insets
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
}
