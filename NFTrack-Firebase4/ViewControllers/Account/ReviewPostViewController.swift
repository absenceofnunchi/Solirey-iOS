//
//  ReviewPostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-21.
//
/*
 Create the review and submit it.
 Only available to the buyer after the sale has been finalized.
 The pending review is valid for 30 days.
 */

import UIKit
import Firebase
import FirebaseFirestore
import QuickLook

class ReviewPostViewController: ParentProfileViewController {
    var post: Post!
    private var reviewTitleLabel: UILabel!
    private var reviewTextView: UITextView!
    private var ratingTitleLabel: UILabel!
    private var submitButton: UIButton!
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
            return UserInfo(
                email: nil,
                displayName: displayName,
                photoURL: photoURL,
                uid: userId,
                memberSince: nil
            )
        } else {
            return nil
        }
    }()
    private var numOfStars: Int! {
        didSet {
            /// corrected since num starts from 0
            numOfStars += 1
        }
    }
    weak var delegate: TableViewRefreshDelegate?
    private var imagePreviewConstraintHeight: NSLayoutConstraint!
    var previewDataArr = [PreviewData]() {
        didSet {
            if previewDataArr.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.imagePreviewVC.view.isHidden = false
                    self?.imagePreviewConstraintHeight.constant = 180
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.imagePreviewVC.view.isHidden = true
                    self?.imagePreviewConstraintHeight.constant = 0
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    }
                }
            }
        }
    }
    private var imagePreviewVC: ImagePreviewViewController!
    private var url: URL!
    internal var buttonPanel: UIStackView!
    private var documentPicker: DocumentPicker!
    private var documentID: String!
    private let db = FirebaseService.shared.db!
    private var starRatingView: StarRatingView!
    internal var constraints: [NSLayoutConstraint]!
    private var pickerImageName: String! {
        var imageName: String!
        if #available(iOS 14.0, *) {
            imageName = "rectangle.fill.on.rectangle.fill.circle"
        } else {
            imageName = "tv.circle"
        }
        return imageName
    }
    let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .medium)
    lazy var panelButtons: [PanelButton] = [
        PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
        PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
        PanelButton(imageName: "doc.circle", imageConfig: configuration, tintColor: UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), tag: 10)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver()
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// whenever the image picker is dismissed, the collection view has to be updated
        if imagePreviewVC != nil {
            imagePreviewVC.data = previewDataArr
        }
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

extension ReviewPostViewController: ButtonPanelConfigurable {
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
                    let userInfo = UserInfo(
                        email: nil,
                        displayName: displayName!,
                        photoURL: photoURL,
                        uid: revieweeUserId,
                        memberSince: nil
                        )
                    self?.userInfo = userInfo
                    completion?()
                }
            } else {
                self?.alert.showDetail("Sorry", with: "User data could not be fetched", for: self) {
                    self?.navigationController?.popViewController(animated: true)
                } completion: {}
            }
        }
    }
    
    func fetchUserInfo() {
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
                    let userInfo = UserInfo(
                        email: nil,
                        displayName: displayName!,
                        photoURL: photoURL,
                        uid: revieweeUserId,
                        memberSince: nil
                    )
                    self?.userInfo = userInfo
                }
            } else {
                self?.alert.showDetail("Sorry", with: "User data could not be fetched", for: self) {
                    self?.navigationController?.popViewController(animated: true)
                } completion: {}
            }
        }
    }
    
    override func configureUI() {
        super.configureUI()

        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()

        guard let docImage = UIImage(systemName: "doc.plaintext") else { return }
        let rightBarButton = UIBarButtonItem(image: docImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
        rightBarButton.tag = 7
        self.navigationItem.rightBarButtonItem = rightBarButton

        self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height + 500)
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
        
        self.starRatingView = StarRatingView()
        self.starRatingView.isEnabled = true
        self.starRatingView.starHeight = 40
        self.starRatingView.numOfStars = { [weak self] num in
            self?.numOfStars = num
        }
        self.starRatingView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(self.starRatingView)
        
        self.createButtonPanel(panelButtons: self.panelButtons, superView: self.scrollView) { (buttonsArr) in
            buttonsArr.forEach { (button) in
                button.addTarget(self, action: #selector(self.buttonPressed(_:)), for: .touchUpInside)
            }
        }
        
        self.configureImagePreview(postType: .tangible)
        
        self.submitButton = UIButton()
        self.submitButton.setTitle("Submit", for: .normal)
        self.submitButton.addTarget(self, action: #selector(self.buttonPressed(_:)), for: .touchUpInside)
        self.submitButton.tag = 6
        self.submitButton.layer.cornerRadius = 8
        self.submitButton.backgroundColor = .black
        self.submitButton.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(self.submitButton)
        
        self.imagePreviewConstraintHeight = self.imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 0)
        constraints = [NSLayoutConstraint]()
        self.constraints.append(contentsOf: [
            self.ratingTitleLabel.topAnchor.constraint(equalTo: self.displayNameTextField.bottomAnchor, constant: 40),
            self.ratingTitleLabel.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            self.ratingTitleLabel.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            self.ratingTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            self.starRatingView.topAnchor.constraint(equalTo: self.ratingTitleLabel.bottomAnchor, constant: 0),
            self.starRatingView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, multiplier: 0.8),
            self.starRatingView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor),
            self.starRatingView.heightAnchor.constraint(equalToConstant: 40),
            
            self.reviewTitleLabel.topAnchor.constraint(equalTo: self.starRatingView.bottomAnchor, constant: 40),
            self.reviewTitleLabel.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            self.reviewTitleLabel.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            self.reviewTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            self.reviewTextView.topAnchor.constraint(equalTo: self.reviewTitleLabel.bottomAnchor, constant: 0),
            self.reviewTextView.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            self.reviewTextView.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            self.reviewTextView.heightAnchor.constraint(equalToConstant: 150),
        ])
        
        self.setButtonPanelConstraints(topView: self.reviewTextView)
        
        self.constraints.append(contentsOf: [
            self.imagePreviewVC.view.topAnchor.constraint(equalTo: self.buttonPanel.bottomAnchor, constant: 20),
            self.imagePreviewVC.view.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9),
            self.imagePreviewVC.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.imagePreviewConstraintHeight,
            
            self.submitButton.topAnchor.constraint(equalTo: self.imagePreviewVC.view.bottomAnchor, constant: 40),
            self.submitButton.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            self.submitButton.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            self.submitButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate(self.constraints)
    }
    
    // MARK: - configureImagePreview
    func configureImagePreview(postType: PostType) {
        imagePreviewVC = ImagePreviewViewController(postType: postType)
        imagePreviewVC.data = previewDataArr
        imagePreviewVC.delegate = self
        imagePreviewVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(imagePreviewVC)
        imagePreviewVC.view.frame = view.bounds
        scrollView.addSubview(imagePreviewVC.view)
        imagePreviewVC.didMove(toParent: self)
    }

    @objc override func buttonPressed(_ sender: UIButton!) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        if previewDataArr.count < 3 {
            switch sender.tag {
                case 6:
                    didSubmit()
                case 7:
                    let historyDetailVC = HistoryDetailViewController()
                    historyDetailVC.post = post
                    historyDetailVC.userInfo = userInfo
                    self.navigationController?.pushViewController(historyDetailVC, animated: true)
                case 8:
                    let vc = UIImagePickerController()
                    vc.sourceType = .camera
                    vc.allowsEditing = true
                    vc.delegate = self
                    present(vc, animated: true)
                case 9:
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.allowsEditing = false
                    imagePickerController.sourceType = .photoLibrary
                    imagePickerController.delegate = self
                    imagePickerController.modalPresentationStyle = .fullScreen
                    present(imagePickerController, animated: true, completion: nil)
                case 10:
                    documentPicker = DocumentPicker(presentationController: self, delegate: self)
                    documentPicker.displayPicker()
                default:
                    break
            }
        } else {
            self.alert.showDetail(
                "Upload Limit",
                with: "There is a limit of 3 files per review.",
                for: self) {
                print("something")
            } completion:  {}
        }
    }
    
    func batchUpdate(reviewText: String, numOfStars: Int, revieweeUserId: String, reviewerUserId: String, reviewerDisplayName: String) {
//        guard let db = FirebaseService.shared.db else {
//            self.alert.showDetail("Sorry", with: "There was an error submitting your review.", for: self)
//            return
//        }
        
        let batch = db.batch()
        // isReviewd in post
        let postRef = db.collection("post").document(self.post.documentId)
        batch.updateData(["isReviewed": true], forDocument: postRef)
        
        // first create review
        let reviewRef = db.collection("review").document(revieweeUserId)
        batch.setData([
            "revieweeUserId": revieweeUserId,
        ], forDocument: reviewRef)
        
        let reviewDetailRef = reviewRef.collection("details").document()
        self.documentID = reviewDetailRef.documentID
        
        guard
            let rInfo = self.reviewerInfo,
            let photoURL = rInfo.photoURL,
            let confirmReceivedHash = self.post.confirmReceivedHash
            else { return }
        
        batch.setData([
            "revieweeUserId": revieweeUserId,
            "reviewerUserId": reviewerUserId,
            "reviewerDisplayName": reviewerDisplayName,
            "reviewerPhotoURL": photoURL,
            "starRating": numOfStars,
            "review": reviewText,
            "confirmReceivedHash": confirmReceivedHash,
            /// finalized date
            "date": (self.post.confirmReceivedDate ?? Date()) as Date,
        ], forDocument: reviewDetailRef)
        
        batch.commit() { err in
            if let err = err {
                self.alert.showDetail("Sorry", with: err.localizedDescription, for: self)
                return
            }
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
        
        self.alert.showDetail(
            "Are you sure you want to submit this review?",
            with: "Your review cannot be modified or deleted once submitted.",
            for: self,
            alertStyle: .withCancelButton
        ) { [weak self] in
            self?.dismiss(animated: true, completion: {
                /// batch commit
                /// 1. update the post's isReviewed field to true
                /// 2. create a new review post
                
                self?.showSpinner {
                    self?.batchUpdate(reviewText: textView.text, numOfStars: numOfStars, revieweeUserId: revieweeUserId, reviewerUserId: reviewerUserId, reviewerDisplayName: reviewerDisplayName)
                    if let pdr = self?.previewDataArr, pdr.count > 0 {
                        self?.uploadFiles()
                    } else {
                        self?.alert.showDetail(
                            "Success!",
                            with: "Thank you for providing your review.",
                            for: self) {
                            DispatchQueue.main.async { [weak self] in
                                self?.imagePreviewVC.collectionView.reloadData()
                                self?.navigationController?.popViewController(animated: true)
                                self?.delegate?.didRefreshTableView(index: self?.reviewerInfo?.uid == self?.post.sellerUserId ? 1 : 0)
                            }
                        } completion: {}
                    }
                }
            })
        } completion:  {}
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
                return
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

// MARK: - Image picker
extension ReviewPostViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let _ = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
              let filePath = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            print("No image found")
            return
        }
        
        let previewData = PreviewData(header: .image, filePath: filePath)
        previewDataArr.append(previewData)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ReviewPostViewController: DocumentDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        //        return self.url as QLPreviewItem
        let  docTitle = UUID().uuidString
        let previewItem = CustomPreviewItem(url: url, title: docTitle)
        return previewItem as QLPreviewItem
    }
    
    // MARK: - didPickDocument
    func didPickDocument(document: Document?) {
        if let pickedDoc = document {
            let fileURL = pickedDoc.fileURL
            guard fileURL.pathExtension == "pdf" else {
                self.alert.showDetail("Sorry", with: "The document has to be a PDF file", for: self)
                return
            }
            url = fileURL
            let previewData = PreviewData(header: .document, filePath: fileURL)
            previewDataArr.append(previewData)
            
            let preview = PreviewPDFViewController()
            preview.delegate = self
            preview.dataSource = self
            present(preview, animated: true, completion: nil)
        }
    }
}

extension ReviewPostViewController: DeletePreviewDelegate {

    // MARK: - didDeleteImage
    func didDeleteFileFromPreview(filePath: URL) {
        previewDataArr = previewDataArr.filter { $0.filePath != filePath }
    }
}

extension ReviewPostViewController: FileUploadable {
    func uploadFiles() {
        if self.previewDataArr.count > 0 {
            var fileCount: Int = 0
            for previewData in previewDataArr {
                guard let uid = self.userInfo.uid else { return }
                self.uploadFile(fileURL: previewData.filePath, userId: uid) {[weak self](url) in
                    guard let strongSelf = self else { return }
                    strongSelf.db.collection("review").document(strongSelf.userInfo.uid!).collection("details").document(strongSelf.documentID).updateData([
                        "files": FieldValue.arrayUnion(["\(url)"])
                    ], completion: { (error) in
                        if let error = error {
                            strongSelf.alert.showDetail("Error", with: error.localizedDescription, for: self)
                            return
                        }
                    })
                }
                fileCount += 1
                if fileCount == previewDataArr.count {
                    self.previewDataArr.removeAll()
                    self.imagePreviewVC.data.removeAll()
                    self.alert.showDetail("Success!", with: "Thank you for providing your review.", for: self) {
                        DispatchQueue.main.async { [weak self] in
                            self?.imagePreviewVC.collectionView.reloadData()
                            self?.navigationController?.popViewController(animated: true)
                            self?.delegate?.didRefreshTableView(index: self?.reviewerInfo?.uid == self?.post.sellerUserId ? 1 : 0)
                        }
                    } completion: {
                        
                    }

                }
            }
        }
    }
}

//guard let strongSelf = self else { return }
//strongSelf.db.collection("post").document(strongSelf.documentId).updateData([
//    "files": FieldValue.arrayUnion(["\(url)"])
//], completion: { (error) in
//    defer {
//        /// this runs last. place the success alert here. use the same image counter to check if all the images have been fulfilled
//        /// there has to be a success alert for if you don't have images to upload
//        print("after update data")
//    }
//    if let error = error {
//        strongSelf.alert.showDetail("Error", with: error.localizedDescription, for: self)
//    }
//})
