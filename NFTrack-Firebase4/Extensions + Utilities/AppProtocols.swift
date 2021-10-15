//
//  AppProtocols.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import MapKit
import CoreSpotlight
import MobileCoreServices
import Combine
import CryptoKit

// WalletViewController
protocol WalletDelegate: AnyObject {
    func didProcessWallet()
}

// MARK: - PreviewDelegate
/// PostViewController
protocol DeletePreviewDelegate: AnyObject {
    func didDeleteFileFromPreview(filePath: URL)
}

// MARK: - PreviewDelegate1
// To show the preview images 
protocol PreviewDelegate: DeletePreviewDelegate {
    var SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT: CGFloat! { get set }
    var IMAGE_PREVIEW_HEIGHT: CGFloat! { get }
    var SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW: CGFloat! { get set }
    var imagePreviewConstraintHeight: NSLayoutConstraint! { get set }
    var imagePreviewVC: ImagePreviewViewController! { get set }
    var previewDataArr: [PreviewData]! { get set }
    func configureImagePreview(postType: PostType, superView: UIView, closeButtonEnabled: Bool)
    func didDeleteFileFromPreview(filePath: URL)
}

extension PreviewDelegate where Self: UIViewController {
    // MARK: - configureImagePreview
    func configureImagePreview(postType: PostType, superView: UIView, closeButtonEnabled: Bool = true) {
        imagePreviewVC = ImagePreviewViewController(postType: postType)
        imagePreviewVC.data = previewDataArr
        imagePreviewVC.delegate = self
        imagePreviewVC.closeButtonEnabled = closeButtonEnabled
        imagePreviewVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(imagePreviewVC)
        imagePreviewVC.view.frame = view.bounds
        superView.addSubview(imagePreviewVC.view)
        imagePreviewVC.didMove(toParent: self)
    }
    
    // MARK: - didDeleteImage
    func didDeleteFileFromPreview(filePath: URL) {
        previewDataArr = previewDataArr.filter { $0.filePath != filePath }
    }
}

protocol ResaleDelegate: PreviewDelegate {
    // To pass the files to display
    var post: Post? { get set }
    // The height of the button panel gets reduced down to 0
    var buttonPanelHeight: NSLayoutConstraint! { get set }
    var BUTTON_PANEL_HEIGHT: CGFloat { get set }
    // To disable the close button feature for the image previews
    var closeButtonEnabled: Bool! { get set }
    func resaleConfig()
}

// MARK: - MessageDelegate
/// PostViewController
protocol SocketMessageDelegate: AnyObject {
    func didReceiveMessage(topics: [String])
}

// MARK: - TableViewRefreshDelegate
protocol TableViewRefreshDelegate: AnyObject {
    func didRefreshTableView(index: Int)
}

// MARK: - TableViewConfigurable
protocol TableViewConfigurable {
    func configureTableView(delegate: UITableViewDelegate?, dataSource: UITableViewDataSource, height: CGFloat?, estimatedRowHeight: CGFloat?, cellType: UITableViewCell.Type, identifier: String) -> UITableView
}

extension TableViewConfigurable where Self: UITableViewDataSource {
    func configureTableView(delegate: UITableViewDelegate?, dataSource: UITableViewDataSource, height: CGFloat?, estimatedRowHeight: CGFloat? = nil, cellType: UITableViewCell.Type, identifier: String) -> UITableView {
        let tableView = UITableView()
        tableView.register(cellType, forCellReuseIdentifier: identifier)
        
        if let height = height {
            tableView.estimatedRowHeight = height
            tableView.rowHeight = height
        } else if let estimatedRowHeight = estimatedRowHeight {
            tableView.estimatedRowHeight = estimatedRowHeight
            tableView.rowHeight = UITableView.automaticDimension
        }
        
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
}

// MARK: - ModalConfigurable
protocol ModalConfigurable where Self: UIViewController {
    var closeButton: UIButton! { get set }
    func configureCloseButton(tintColor: UIColor)
    func setButtonConstraints()
    func closeButtonPressed()
}

extension ModalConfigurable {
    func configureCloseButton(tintColor: UIColor = .black) {
        // close button
        guard let closeButtonImage = UIImage(systemName: "multiply") else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        closeButton = UIButton(type: .custom)
        closeButton.addAction { [weak self] in
            self?.closeButtonPressed()
        }
        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.tag = 10
        closeButton.tintColor = tintColor
        closeButton.alpha = 0
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        UIView.animate(withDuration: 1) { [weak self] in
            self?.closeButton.alpha = 1
        }
    }
    
    
    func setButtonConstraints() {
        NSLayoutConstraint.activate([
            // close button
            closeButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    func closeButtonPressed() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
}

typealias Closure = () -> ()

///
class ClosureSleeve {
    let closure: Closure
    init(_ closure: @escaping Closure) {
        self.closure = closure
    }
    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping Closure) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

/// test
protocol FileUploadable1 {
    func uploadSomething(completion: (() -> Void)?)
}

extension FileUploadable1 {
    func uploadSomething(completion: (() -> Void)? = nil) {
        completion?()
    }
}

// MARK: - FileUploadable
protocol FileUploadable where Self:UIViewController {
    var alert: Alerts! { get set }
    func uploadFile(fileURL: URL, userId: String, completion: @escaping (URL) -> Void)
    func uploadFile(fileName: String, userId: String, completion: @escaping (URL) -> Void)
    func uploadFileWithPromise(fileURL: URL, userId: String, promise: @escaping (Result<String?, PostingError>) -> Void)
    func uploadFileWithPromise(fileName: String, userId: String, promise: @escaping (Result<URL?, PostingError>) -> Void)
    func uploadImage(url: URL, userId: String, promise: @escaping (Result<URL?, PostingError>) -> Void)
    func uploadImage(image: UIImage, imageName: String, userId: String, promise: @escaping (Result<URL?, PostingError>) -> Void)
    func deleteFile(fileName: String)
    func saveImage(imageName: String, image: UIImage) -> URL?
    func saveFile(fileName: String, data: Data)
    func saveImage(imageName: String, image: UIImage, promise: @escaping (Result<URL, PostingError>) -> Void)
}

extension FileUploadable {
    func uploadFile(fileURL: URL, userId: String, completion: @escaping (URL) -> Void) {
        FirebaseService.shared.uploadFile(fileURL: fileURL, userId: userId) { [weak self](uploadTask, fileUploadError) in
            if let error = fileUploadError {
                switch error {
                    case .fileManagerError(let msg):
                        self?.alert.showDetail("Error", with: msg, for: self)
                    case .fileNotAvailable:
                        self?.alert.showDetail("Error", with: "Image file not found.", for: self)
                    case .userNotLoggedIn:
                        self?.alert.showDetail("Error", with: "You need to be logged in!", for: self)
                }
            }
            
            if let uploadTask = uploadTask {
                // Listen for state changes, errors, and completion of the upload.
                uploadTask.observe(.resume) { snapshot in
                    // Upload resumed, also fires when the upload starts
                }
                
                uploadTask.observe(.pause) { snapshot in
                    // Upload paused
                    self?.alert.showDetail("Image Upload", with: "The image uploading process has been paused.", for: self)
                }
                
                uploadTask.observe(.progress) { snapshot in
                    // Upload reported progress
                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                        / Double(snapshot.progress!.totalUnitCount)
                    print("percent Complete", percentComplete)
                }
                
                uploadTask.observe(.success) { snapshot in
                    // Upload completed successfully
                    snapshot.reference.downloadURL {(url, error) in
                        if let error = error {
                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                        }
                        
                        if let url = url {
                            completion(url)
                        }
                    }
                }
                
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error as NSError? {
                        switch (StorageErrorCode(rawValue: error.code)!) {
                            case .objectNotFound:
                                // File doesn't exist
                                print("object not found")
                                break
                            case .unauthorized:
                                // User doesn't have permission to access file
                                print("unauthorized")
                                break
                            case .cancelled:
                                // User canceled the upload
                                print("cancelled")
                                break
                                
                            /* ... */
                            
                            case .unknown:
                                // Unknown error occurred, inspect the server response
                                print("unknown")
                                break
                            default:
                                // A separate error occurred. This is a good place to retry the upload.
                                print("reload?")
                                break
                        }
                    }
                }
            }
        }
    }
    
    func uploadFileWithPromise(fileURL: URL, userId: String, promise: @escaping (Result<String?, PostingError>) -> Void) {
        FirebaseService.shared.uploadFile(fileURL: fileURL, userId: userId) { (uploadTask, fileUploadError) in
            if let error = fileUploadError {
                switch error {
                    case .fileNotAvailable:
                        promise(.failure(PostingError.fileUploadError(.fileNotAvailable)))
                    break
                    default:
                        promise(.failure(.generalError(reason: "Image Uploading Error.")))
                }
            }
            
            if let uploadTask = uploadTask {
                uploadTask.observe(.progress) { snapshot in
                    // Upload reported progress
                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                        / Double(snapshot.progress!.totalUnitCount)
                    print("percent Complete", percentComplete)
                }
                
                uploadTask.observe(.success) { snapshot in
                    // Upload completed successfully
                    snapshot.reference.downloadURL {(url, error) in
                        if let error = error {
                            promise(.failure(.generalError(reason: error.localizedDescription)))
                        }
                        
                        if let url = url {
                            promise(.success("\(url)"))
                        }
                    }
                }
                
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error as NSError? {
                        switch (StorageErrorCode(rawValue: error.code)!) {
                            case .objectNotFound:
                                // File doesn't exist
                                print("object not found")
                                break
                            case .unauthorized:
                                // User doesn't have permission to access file
                                print("unauthorized")
                                break
                            case .cancelled:
                                // User canceled the upload
                                print("cancelled")
                                break
                                
                            /* ... */
                            
                            case .unknown:
                                // Unknown error occurred, inspect the server response
                                print("unknown")
                                break
                            default:
                                // A separate error occurred. This is a good place to retry the upload.
                                print("reload?")
                                break
                        }
                    }
                }
            }
        }
    }
    
    func uploadFile(fileName: String, userId: String, completion: @escaping (URL) -> Void) {
        FirebaseService.shared.uploadFile(fileName: fileName, userId: userId) { [weak self](uploadTask, fileUploadError) in
            if let error = fileUploadError {
                switch error {
                    case .fileManagerError(let msg):
                        self?.alert.showDetail("Error", with: msg, for: self)
                    case .fileNotAvailable:
                        self?.alert.showDetail("Error", with: "Image file not found.", for: self)
                    case .userNotLoggedIn:
                        self?.alert.showDetail("Error", with: "You need to be logged in!", for: self)
                }
            }
            
            if let uploadTask = uploadTask {
                // Listen for state changes, errors, and completion of the upload.
                uploadTask.observe(.resume) { snapshot in
                    // Upload resumed, also fires when the upload starts
                }
                
                uploadTask.observe(.pause) { snapshot in
                    // Upload paused
                    self?.alert.showDetail("Image Upload", with: "The image uploading process has been paused.", for: self)
                }
                
                uploadTask.observe(.progress) { snapshot in
                    // Upload reported progress
                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                        / Double(snapshot.progress!.totalUnitCount)
                    print("percent Complete", percentComplete)
                }
                
                uploadTask.observe(.success) { snapshot in
                    // Upload completed successfully
                    print("success")
                    self?.deleteFile(fileName: fileName)
                    snapshot.reference.downloadURL { (url, error) in
                        if let error = error {
                            print("downloadURL error", error)
                        }
                        
                        if let url = url {
                            completion(url)
                        }
                    }
                }
                
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error as NSError? {
                        switch (StorageErrorCode(rawValue: error.code)!) {
                            case .objectNotFound:
                                // File doesn't exist
                                print("object not found")
                                break
                            case .unauthorized:
                                // User doesn't have permission to access file
                                print("unauthorized")
                                break
                            case .cancelled:
                                // User canceled the upload
                                print("cancelled")
                                break
                                
                            /* ... */
                            
                            case .unknown:
                                // Unknown error occurred, inspect the server response
                                print("unknown")
                                break
                            default:
                                // A separate error occurred. This is a good place to retry the upload.
                                print("reload?")
                                break
                        }
                    }
                }
            }
        }
    }
    
    func uploadFileWithPromise(fileName: String, userId: String, promise: @escaping (Result<URL?, PostingError>) -> Void) {
        FirebaseService.shared.uploadFile(fileName: fileName, userId: userId) { [weak self](uploadTask, fileUploadError) in
            self?.processPostUpload(uploadTask: uploadTask, fileUploadError: fileUploadError, promise: promise)
        }
    }
    
    // Upload image with an URL
    func uploadImage(url: URL, userId: String, promise: @escaping (Result<URL?, PostingError>) -> Void) {
        FirebaseService.shared.uploadImage(fileURL: url, userId: userId) { [weak self] (uploadTask, fileUploadError) in
            self?.processPostUpload(uploadTask: uploadTask, fileUploadError: fileUploadError, promise: promise)
        }
    }

    // Upload image with an URL
    func uploadImage(image: UIImage, imageName: String, userId: String, promise: @escaping (Result<URL?, PostingError>) -> Void) {
        FirebaseService.shared.uploadImage(image: image, imageName: imageName, userId: userId) { [weak self] (uploadTask, fileUploadError) in
            self?.processPostUpload(uploadTask: uploadTask, fileUploadError: fileUploadError, promise: promise)
        }
    }
    
    private func processPostUpload(uploadTask: StorageUploadTask?, fileUploadError: FileUploadError?, promise: @escaping (Result<URL?, PostingError>) -> Void) {
        if let error = fileUploadError {
            switch error {
                case .fileManagerError(let msg):
                    promise(.failure(.generalError(reason: msg)))
                case .fileNotAvailable:
                    promise(.failure(.generalError(reason: "Image file not found.")))
                case .userNotLoggedIn:
                    promise(.failure(.generalError(reason: "You need to be logged in!")))
            }
        }
        
        if let uploadTask = uploadTask {
            // Listen for state changes, errors, and completion of the upload.
            uploadTask.observe(.success) { snapshot in
                // Upload completed successfully
                snapshot.reference.downloadURL { (url, error) in
                    if let _ = error {
                        promise(.failure(.generalError(reason: "Unable to upload.")))
                    }
                    
                    promise(.success(url))
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error as NSError? {
                    switch (StorageErrorCode(rawValue: error.code)!) {
                        case .objectNotFound:
                            // File doesn't exist
                            promise(.failure(.generalError(reason: "Object not found")))
                            break
                        case .unauthorized:
                            // User doesn't have permission to access file
                            promise(.failure(.generalError(reason: "Upload unauthorized")))
                            break
                        case .cancelled:
                            // User canceled the upload
                            promise(.failure(.generalError(reason: "Upload cancelled")))
                            break
                            
                        /* ... */
                        
                        case .unknown:
                            // Unknown error occurred, inspect the server response
                            promise(.failure(.generalError(reason: "Unknown Error")))
                            break
                        default:
                            // A separate error occurred. This is a good place to retry the upload.
                            promise(.failure(.generalError(reason: "Unknown error. Please try again.")))
                            break
                    }
                }
            }
        }
    }
    
    // MARK: - deleteFile
    func deleteFile(fileName: String) {
        // delete images from the system
        let fileManager = FileManager.default
        let documentsDirectory =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentsPath = documentsDirectory.path
        do {
            
            let filePathName = "\(documentsPath)/\(fileName)"
            try fileManager.removeItem(atPath: filePathName)
            
            let files = try fileManager.contentsOfDirectory(atPath: "\(documentsPath)")
            print("all files in cache after deleting images: \(files)")
            
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    func saveImage(imageName: String, image: UIImage) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch let error {
            print("error saving file with error", error)
            return nil
        }
    }
    
    func saveFile(fileName: String, data: Data) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try data.write(to: fileURL)
        } catch let error {
            print("error saving file with error", error)
        }
    }

    func saveImage(imageName: String, image: UIImage, promise: @escaping (Result<URL, PostingError>) -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            promise(.failure(.generalError(reason: "Could not create a URL to save the image.")))
            return
        }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            promise(.failure(.generalError(reason: "Could not process the downloaded image data.")))
            return
        }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch {
                promise(.failure(.generalError(reason: "Couldn't remove file at path.")))
            }
        }
        
        do {
            try data.write(to: fileURL)
            promise(.success(fileURL))
        } catch {
            promise(.failure(.generalError(reason: "Error saving file with error")))
        }
    }
    
    func saveFile(fileName: String, data: Data, promise: @escaping (Result<URL, PostingError>) -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            promise(.failure(.generalError(reason: "Could not create a URL to save the image.")))
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch {
                promise(.failure(.generalError(reason: "Couldn't remove file at path.")))
            }
        }
        
        do {
            try data.write(to: fileURL)
            promise(.success(fileURL))
        } catch {
            promise(.failure(.generalError(reason: "Error saving file with error")))
        }
    }
}

// MARK: - RefetchDataDelegate
protocol RefetchDataDelegate: AnyObject {
    func didFetchData()
}

// MARK: - SegmentConfigurable
protocol SegmentConfigurable {
    var segmentedControl: UISegmentedControl! { get set }
    func configureSwitch()
    func segmentedControlSelectionDidChange(_ sender: UISegmentedControl)
}

// fetches the username and the profile image to display on ParentDetailVC, ReviewDetailVC
protocol UsernameBannerConfigurable where Self: UIViewController {
    var userInfo: UserInfo! { get set }
    var usernameContainer: UIView! { get set }
    var dateLabel: UILabel! { get set }
    var displayNameLabel: UILabel! { get set }
    var underLineView: UnderlineView! { get set }
    var alert: Alerts! { get }
    var fetchedImage: UIImage! { get set }
    var profileImageView: UIImageView! { get set }
    var constraints: [NSLayoutConstraint]! { get set }
    func processProfileImage()
    func tapped(_ sender: UITapGestureRecognizer!)
    func configureNameDisplay<T: Post, U: UIView>(post: T, v: U, callback: (_ profileImageView: UIImageView, _ displayNameLabel: UILabel) -> Void)
    func fetchUserData(id: String)
}

extension UsernameBannerConfigurable {
    func fetchUserData(id: String) {
        let docRef = FirebaseService.shared.db
            .collection("user")
            .document(id)

        docRef.getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let data = document.data() {
                    let displayName = data[UserDefaultKeys.displayName] as? String
                    let photoURL = data[UserDefaultKeys.photoURL] as? String
                    let memberSince = data[UserDefaultKeys.memberSince] as? Timestamp
                    var shippingAddress: ShippingAddress!
                    if let sa = data["shippingAddress"] as? [String: Any],
                       let address = sa[UserDefaultKeys.address] as? String,
                       let longitude = sa["longitude"] as? Double,
                       let latitude = sa["latitude"] as? Double {
                        shippingAddress = ShippingAddress(address: address, longitude: longitude, latitude: latitude)
                    }

                    let userInfo = UserInfo(
                        email: nil,
                        displayName: displayName ?? "N/A",
                        photoURL: photoURL,
                        uid: id,
                        memberSince: memberSince?.dateValue(),
                        shippingAddress: shippingAddress
                    )
                    self?.userInfo = userInfo
                }
            } else {
                self?.hideSpinner {
                    return
                }
            }
        }
    }
    
    func processProfileImage() {
        displayNameLabel?.text = userInfo.displayName
        if let info = self.userInfo,
           info.photoURL != "NA",
           let photoURL = self.userInfo.photoURL {
            FirebaseService.shared.downloadImage(urlString: photoURL) { [weak self] (image, error) in
                guard let self = self else { return }
                if let _ = error {
                    // if there is a discrepency between the photoURL of the "user" collection
                    // and the data in Firebase Storage, this error will occur
                    self.profileImageView.isUserInteractionEnabled = true
                    self.displayNameLabel.isUserInteractionEnabled = true
                    return
                }
                
                if let image = image {
                    self.fetchedImage = image
                    self.profileImageView.image = image
                    self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.height/2.0
                    self.profileImageView.contentMode = .scaleToFill
                    self.profileImageView.clipsToBounds = true
                    
                    self.profileImageView.isUserInteractionEnabled = true
                    self.displayNameLabel.isUserInteractionEnabled = true
                }
            }
        } else {
            profileImageView.isUserInteractionEnabled = true
            displayNameLabel.isUserInteractionEnabled = true
        }
    }
    
    func configureNameDisplay<T: DateConfigurable, U: UIView>(post: T, v: U, callback: (_ profileImageView: UIImageView, _ displayNameLabel: UILabel) -> Void) {
        usernameContainer = UIView()
        usernameContainer.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(usernameContainer)
        
        dateLabel = UILabel()
        dateLabel.textAlignment = .right
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let formattedDate = formatter.string(from: post.date)
        dateLabel.text = formattedDate
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(dateLabel)
        
        guard let image = UIImage(systemName: "person.crop.circle.fill") else {
            return
        }
        profileImageView = UIImageView()
        let profileImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal)
        profileImageView.image = profileImage
        profileImageView.tag = 1
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(profileImageView)
        
        displayNameLabel = UILabel()
        displayNameLabel.tag = 1
        displayNameLabel.text = userInfo?.displayName
        displayNameLabel.lineBreakMode = .byTruncatingTail
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(displayNameLabel)
        
        underLineView = UnderlineView()
        underLineView.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(underLineView)
        
        callback(profileImageView, displayNameLabel)
    }
    
    func setNameDisplayConstraints(topView: UIView) {
        constraints.append(contentsOf: [
            usernameContainer.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 50),
            usernameContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            usernameContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            usernameContainer.heightAnchor.constraint(equalToConstant: 51),
            
            dateLabel.trailingAnchor.constraint(equalTo: usernameContainer.trailingAnchor),
            dateLabel.heightAnchor.constraint(equalTo: usernameContainer.heightAnchor),
            dateLabel.widthAnchor.constraint(equalTo: usernameContainer.widthAnchor, multiplier: 0.4),
            
            profileImageView.leadingAnchor.constraint(equalTo: usernameContainer.leadingAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: usernameContainer.centerYAnchor),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            
            displayNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            displayNameLabel.heightAnchor.constraint(equalTo: usernameContainer.heightAnchor),
            displayNameLabel.widthAnchor.constraint(lessThanOrEqualTo: usernameContainer.widthAnchor, multiplier: 0.6),
            
            underLineView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
            underLineView.leadingAnchor.constraint(equalTo: usernameContainer.leadingAnchor),
            underLineView.trailingAnchor.constraint(equalTo: usernameContainer.trailingAnchor),
            underLineView.heightAnchor.constraint(equalToConstant: 0.2)
        ])
    }
}

protocol FetchUserConfigurable {
    func fetchUserData(userId: String, promise: @escaping (Result<UserInfo, PostingError>) -> Void)
    func fetchAddress(userId: String, promise: @escaping (Result<ShippingAddress?, PostingError>) -> Void)
}

extension FetchUserConfigurable {
    func fetchUserData(userId: String, promise: @escaping (Result<UserInfo, PostingError>) -> Void) {
        let docRef = FirebaseService.shared.db
            .collection("user")
            .document(userId)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data() {
                    let displayName = data[UserDefaultKeys.displayName] as? String
                    let photoURL = data[UserDefaultKeys.photoURL] as? String
                    let memberSince = data[UserDefaultKeys.memberSince] as? Timestamp
                    var shippingAddress: ShippingAddress!
                    if let sa = data["shippingAddress"] as? [String: Any],
                       let address = sa[UserDefaultKeys.address] as? String,
                       let longitude = sa["longitude"] as? Double,
                       let latitude = sa["latitude"] as? Double {
                        shippingAddress = ShippingAddress(address: address, longitude: longitude, latitude: latitude)
                    }

                    let userInfo = UserInfo(
                        email: nil,
                        displayName: displayName ?? "N/A",
                        photoURL: photoURL,
                        uid: userId,
                        memberSince: memberSince?.dateValue(),
                        shippingAddress: shippingAddress
                    )
                    
                    promise(.success(userInfo))
                }
            } else {
                promise(.failure(.generalError(reason: "Unable to load the profile information.")))
            }
        }
    }
    
    func fetchAddress(
        userId: String,
        promise: @escaping (Result<ShippingAddress?, PostingError>) -> Void
    ) {
        FirebaseService.shared.db
            .collection("user")
            .document(userId)
            .getDocument { (document, error) in
                guard error == nil else {
                    promise(.failure(.generalError(reason: "Unable to retrieve the account info.")))
                    return
                }
                
                guard let document = document,
                      document.exists,
                      let data = document.data() else {
                    promise(.failure(.generalError(reason: "Unable to retrieve the account info.")))
                    return
                }
                
                if let shippingAddress = data["shippingAddress"] as? [String: Any],
                   let address = shippingAddress["address"] as? String,
                   let longitude = shippingAddress["longitude"] as? Double,
                   let latitude = shippingAddress["latitude"] as? Double {
                    let sa = ShippingAddress(address: address, longitude: longitude, latitude: latitude)
                    promise(.success(sa))
                } else {
                    promise(.success(nil))
                }
            }
    }
}

protocol PageDataType where Self: UIViewController {
    associatedtype Assoc where Assoc: Equatable
    var gallery: Assoc? { get set }
    var galleries: [Assoc]? { get set }
    init(gallery: Assoc?, galleries: [Assoc]?)
}

//protocol PageVCConfigurable {
//    associatedtype T where T: PageDataType
//    associatedtype U where U: Equatable
//    var pvc: PageViewController<T, U>! { get set }
//}
//
//extension PageVCConfigurable {
//    mutating func configureImageDisplay<T: PageDataType, U: Equatable>(post: Post, newPVC: PageViewController<T, U>, newSinglePageVC: ParentSinglePageViewController<String>.Type) {
//        guard let files = post.files, files.count > 0 else { return }
//        pvc = newPVC
//    }
//}

//// displays images and pdf documents
////protocol PageVCConfigurable: UIPageViewControllerDataSource, UIPageViewControllerDelegate where Self: UIViewController {
//protocol PageVCConfigurable where Self: UIViewController {
//    associatedtype T where T: PageDataType
//    associatedtype U where U: Equatable
//    var pvc: PageViewController<T, U>! { get set }
//    var singlePageVC: SmallSinglePageViewController! { get set }
//    var constraints: [NSLayoutConstraint]! { get set }
//    var imageHeightConstraint: NSLayoutConstraint! { get set }
//    func configureImageDisplay<T: MediaConfigurable, U: UIView>(post: T, v: U, margin: CGFloat)
////    func configureImageDisplay<T: UIView>(files: [String]?, v: T)
//    func setImageDisplayConstraints<T: UIView>(v: T, topConstant: CGFloat)
//}
//
//extension PageVCConfigurable {
//    func configureImageDisplay<T: PageDataType, U: Equatable>(post: Post, newPVC: PageViewController<T, U>, newSinglePageVC: ParentSinglePageViewController<String>.Type) {
//        guard let files = post.files, files.count > 0 else { return }
//        //        pvc = PageViewController<SmallSinglePageViewController<String>, String>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: files)
//        pvc = newPVC
////        singlePageVC = SmallSinglePageViewController(gallery: files[0])
//        singlePageVC = newSinglePageVC.init(gallery: files[0])
//        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
//        pvc.view.translatesAutoresizingMaskIntoConstraints = false
//        addChild(pvc)
//        view.addSubview(pvc.view)
//        pvc.didMove(toParent: self)
//        
//        let pageControl = UIPageControl.appearance()
//        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
//        pageControl.currentPageIndicatorTintColor = .gray
//        pageControl.backgroundColor = .clear
//    }
//
//    func configureImageDisplay<T: MediaConfigurable, U: UIView>(post: T, v: U, margin: CGFloat = 0) {
//        if let files = post.files, files.count > 0 {
//            pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: files)
//            singlePageVC = SmallSinglePageViewController(gallery: files.first, margin: margin)
//        } else {
//            pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: nil)
//            singlePageVC = SmallSinglePageViewController(gallery: nil)
//        }
//        configurePageVC(v: v)
//    }
//    
//    func configureImageDisplay1<T: UIView>(files: [String]?, v: T) {
//        if let files = files, files.count > 0 {
//            pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: files)
//            singlePageVC = SmallSinglePageViewController(gallery: files.first)
//        } else {
//            pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: nil)
//            singlePageVC = SmallSinglePageViewController(gallery: nil)
//        }
//        configurePageVC(v: v)
//    }
//    
//    private func configurePageVC<T: UIView>(v: T) {
//        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
//        addChild(pvc)
//        v.addSubview(pvc.view)
//        pvc.view.translatesAutoresizingMaskIntoConstraints = false
//        pvc.didMove(toParent: self)
//        
//        let pageControl = UIPageControl.appearance()
//        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
//        pageControl.currentPageIndicatorTintColor = .gray
//        pageControl.backgroundColor = .clear
//    }
//    
//    func setImageDisplayConstraints<T: UIView>(v: T, topConstant: CGFloat = 20) {
//        guard let pv = pvc.view else { return }
//        constraints.append(contentsOf: [
//            imageHeightConstraint,
//            pv.topAnchor.constraint(equalTo: v.topAnchor, constant: topConstant),
//            pv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
//            pv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
//        ])
//    }
//}

protocol MediaConfigurable {
    var files: [String]? { get set }
}

protocol DateConfigurable {
    var date: Date! { get set }
}


//protocol PaginateFetchDelegate: AnyObject {
//    func didFetchPaginate<T>(reviewArr: [T]?, error: Error?)
//    func didGetLastSnapshot(_ lastSnapshot: QueryDocumentSnapshot)
//}
//
//extension PaginateFetchDelegate {
//    func didFetchPaginate<T>(reviewArr: [T]?, error: Error?) {
//        print("fetch")
//    }
//
//    func didGetLastSnapshot(_ lastSnapshot: QueryDocumentSnapshot) {
//
//    }
//}

protocol PaginateFetchDelegate {
    associatedtype FetchResult
    func didFetchPaginate(data: [FetchResult]?, error: Error?)
    func didGetLastSnapshot(_ lastSnapshot: QueryDocumentSnapshot)
}

extension PaginateFetchDelegate {
    func didFetchPaginate(data: [FetchResult]?, error: Error?) {
       
    }

    func didGetLastSnapshot(_ lastSnapshot: QueryDocumentSnapshot) {

    }
}

protocol PostParseDelegate {
    func parseDocuments(querySnapshot: QuerySnapshot?) -> [Post]?
    func parseDocument(document: DocumentSnapshot) -> Post?
    func parseChatListModels(_ documents: [QueryDocumentSnapshot]) -> [ChatListModel]
}

extension PostParseDelegate {
    // Parse multiple query results
    func parseDocuments(querySnapshot: QuerySnapshot?) -> [Post]? {
        var postArr = [Post]()
        guard let querySnapshot = querySnapshot else { return nil }
        for document in querySnapshot.documents {
            let data = document.data()
            var buyerHash, sellerUserId, buyerUserId, sellerHash, title, description, price, mintHash, escrowHash, auctionHash, id, transferHash, status, confirmPurchaseHash, confirmReceivedHash, type, deliveryMethod, paymentMethod, saleFormat, address: String!
            var date, confirmPurchaseDate, transferDate, confirmReceivedDate, bidDate, auctionEndDate, auctionTransferredDate: Date!
            var files, savedBy: [String]?
            var shippingInfo: ShippingInfo!
            var saleType: SaleType!
            var tokenId: String?
            
            data.forEach { (item) in
                switch item.key {
                    case "sellerUserId":
                        sellerUserId = item.value as? String
                    case "senderAddress":
                        sellerHash = item.value as? String
                    case "title":
                        title = item.value as? String
                    case "description":
                        description = item.value as? String
                    case "date":
                        let timeStamp = item.value as? Timestamp
                        date = timeStamp?.dateValue()
                    case "files":
                        files = item.value as? [String]
                    case "price":
                        price = item.value as? String
                    case "mintHash":
                        mintHash = item.value as? String
                    case "escrowHash":
                        escrowHash = item.value as? String
                    case "auctionHash":
                        auctionHash = item.value as? String
                    case "itemIdentifier":
                        id = item.value as? String
                    case "transferHash":
                        transferHash = item.value as? String
                    case "status":
                        status = item.value as? String
                    case "confirmPurchaseHash":
                        confirmPurchaseHash = item.value as? String
                    case "confirmReceivedHash":
                        confirmReceivedHash = item.value as? String
                    case "confirmPurchaseDate":
                        let timeStamp = item.value as? Timestamp
                        confirmPurchaseDate = timeStamp?.dateValue()
                    case "transferDate":
                        let timeStamp = item.value as? Timestamp
                        transferDate = timeStamp?.dateValue()
                    case "confirmReceivedDate":
                        let timeStamp = item.value as? Timestamp
                        confirmReceivedDate = timeStamp?.dateValue()
                    case "buyerHash":
                        buyerHash = item.value as? String
                    case "savedBy":
                        savedBy = item.value as? [String]
                    case "buyerUserId":
                        buyerUserId = item.value as? String
                    case "type":
                        type = item.value as? String
                    case "deliveryMethod":
                        deliveryMethod = item.value as? String
                    case "paymentMethod":
                        paymentMethod = item.value as? String
                    case "saleFormat":
                        saleFormat = item.value as? String
                    case "bidDate":
                        let timeStamp = item.value as? Timestamp
                        bidDate = timeStamp?.dateValue()
                    case "auctionEndDate":
                        let timeStamp = item.value as? Timestamp
                        auctionEndDate = timeStamp?.dateValue()
                    case "auctionTransferredDate":
                        let timeStamp = item.value as? Timestamp
                        auctionTransferredDate = timeStamp?.dateValue()
                    case "address":
                        address = item.value as? String
                    case "shippingInfo":
                        if let si = item.value as? [String: Any] {
                            guard let shippingRestriction = si["scope"] as? String,
                                  let scope = ShippingRestriction(rawValue: shippingRestriction),
                                  let addresses = si["addresses"] as? [String],
                                  let radius = si["radius"] as? Double,
                                  let longitude = si["longitude"] as? Double,
                                  let latitude = si["latitude"] as? Double else { return }

                            shippingInfo = ShippingInfo(
                                scope: scope,
                                addresses: addresses,
                                radius: radius,
                                longitude: longitude,
                                latitude: latitude
                            )
                        }
                        break
                    case "saleType":
                        // For the resale items, some adjustments need to be made, such as diabling the tappable mintHash on HistoryDetailVC
                        guard let saleTypeString = item.value as? String else { return }
                        saleType = SaleType(rawValue: saleTypeString)
                    case "tokenId":
                        // The existing Token ID is needed for the resale since a new token is not being minted
                        tokenId = item.value as? String
                    default:
                        break
                }
            }
            
            let post = Post(
                documentId: document.documentID,
                title: title,
                description: description,
                date: date,
                files: files,
                price: price,
                mintHash: mintHash,
                escrowHash: escrowHash,
                auctionHash: auctionHash,
                id: id,
                status: status,
                sellerUserId: sellerUserId,
                buyerUserId: buyerUserId,
                sellerHash: sellerHash,
                buyerHash: buyerHash,
                confirmPurchaseHash: confirmPurchaseHash,
                confirmPurchaseDate: confirmPurchaseDate,
                transferHash: transferHash,
                transferDate: transferDate,
                confirmReceivedHash: confirmReceivedHash,
                confirmReceivedDate: confirmReceivedDate,
                savedBy: savedBy,
                type: type,
                deliveryMethod: deliveryMethod,
                paymentMethod: paymentMethod,
                saleFormat: saleFormat,
                bidDate: bidDate,
                auctionEndDate: auctionEndDate,
                auctionTransferredDate: auctionTransferredDate,
                address: address,
                shippingInfo: shippingInfo,
                saleType: saleType,
                tokenId: tokenId
            )
            
            postArr.append(post)
        }
        return postArr
    }
    
    // Parse single document query
    func parseDocument(document: DocumentSnapshot) -> Post? {
        guard let data = document.data() else { return nil }
        var buyerHash, sellerUserId, buyerUserId, sellerHash, title, description, price, mintHash, escrowHash, auctionHash, id, transferHash, status, confirmPurchaseHash, confirmReceivedHash, type, deliveryMethod, paymentMethod, saleFormat, address: String!
        var tokenId: String?
        var date, confirmPurchaseDate, transferDate, confirmReceivedDate, bidDate, auctionEndDate, auctionTransferredDate: Date!
        var files, savedBy: [String]?
        var shippingInfo: ShippingInfo!
        var saleType: SaleType!
        data.forEach { (item) in
            switch item.key {
                case "sellerUserId":
                    sellerUserId = item.value as? String
                case "senderAddress":
                    sellerHash = item.value as? String
                case "title":
                    title = item.value as? String
                case "description":
                    description = item.value as? String
                case "date":
                    let timeStamp = item.value as? Timestamp
                    date = timeStamp?.dateValue()
                case "files":
                    files = item.value as? [String]
                case "price":
                    price = item.value as? String
                case "mintHash":
                    mintHash = item.value as? String
                case "escrowHash":
                    escrowHash = item.value as? String
                case "auctionHash":
                    auctionHash = item.value as? String
                case "itemIdentifier":
                    id = item.value as? String
                case "transferHash":
                    transferHash = item.value as? String
                case "status":
                    status = item.value as? String
                case "confirmPurchaseHash":
                    confirmPurchaseHash = item.value as? String
                case "confirmReceivedHash":
                    confirmReceivedHash = item.value as? String
                case "confirmPurchaseDate":
                    let timeStamp = item.value as? Timestamp
                    confirmPurchaseDate = timeStamp?.dateValue()
                case "transferDate":
                    let timeStamp = item.value as? Timestamp
                    transferDate = timeStamp?.dateValue()
                case "confirmReceivedDate":
                    let timeStamp = item.value as? Timestamp
                    confirmReceivedDate = timeStamp?.dateValue()
                case "buyerHash":
                    buyerHash = item.value as? String
                case "savedBy":
                    savedBy = item.value as? [String]
                case "buyerUserId":
                    buyerUserId = item.value as? String
                case "type":
                    type = item.value as? String
                case "deliveryMethod":
                    deliveryMethod = item.value as? String
                case "paymentMethod":
                    paymentMethod = item.value as? String
                case "saleFormat":
                    saleFormat = item.value as? String
                case "bidDate":
                    let timeStamp = item.value as? Timestamp
                    bidDate = timeStamp?.dateValue()
                case "auctionEndDate":
                    let timeStamp = item.value as? Timestamp
                    auctionEndDate = timeStamp?.dateValue()
                case "auctionTransferredDate":
                    let timeStamp = item.value as? Timestamp
                    auctionTransferredDate = timeStamp?.dateValue()
                case "address":
                    // the shipping address of the buyer
                    address = item.value as? String
                case "shippingInfo":
                    if let si = item.value as? [String: Any] {
                        guard let shippingRestriction = si["scope"] as? String,
                              let scope = ShippingRestriction(rawValue: shippingRestriction),
                              let addresses = si["addresses"] as? [String],
                              let radius = si["radius"] as? Double,
                              let longitude = si["longitude"] as? Double,
                              let latitude = si["latitude"] as? Double else { return }
                        
                        shippingInfo = ShippingInfo(
                            scope: scope,
                            addresses: addresses,
                            radius: radius,
                            longitude: longitude,
                            latitude: latitude
                        )
                    }
                    break
                case "saleType":
                    // For the resale items, some adjustments need to be made, such as diabling the tappable mintHash on HistoryDetailVC
                    guard let saleTypeString = item.value as? String else { return }
                    saleType = SaleType(rawValue: saleTypeString)
                case "tokenId":
                    // The existing Token ID is needed for the resale since a new token is not being minted
                    tokenId = item.value as? String
                default:
                    break
            }
        }
        
        let post = Post(
            documentId: document.documentID,
            title: title,
            description: description,
            date: date,
            files: files,
            price: price,
            mintHash: mintHash,
            escrowHash: escrowHash,
            auctionHash: auctionHash,
            id: id,
            status: status,
            sellerUserId: sellerUserId,
            buyerUserId: buyerUserId,
            sellerHash: sellerHash,
            buyerHash: buyerHash,
            confirmPurchaseHash: confirmPurchaseHash,
            confirmPurchaseDate: confirmPurchaseDate,
            transferHash: transferHash,
            transferDate: transferDate,
            confirmReceivedHash: confirmReceivedHash,
            confirmReceivedDate: confirmReceivedDate,
            savedBy: savedBy,
            type: type,
            deliveryMethod: deliveryMethod,
            paymentMethod: paymentMethod,
            saleFormat: saleFormat,
            bidDate: bidDate,
            auctionEndDate: auctionEndDate,
            auctionTransferredDate: auctionTransferredDate,
            address: address,
            shippingInfo: shippingInfo,
            saleType: saleType,
            tokenId: tokenId
        )
        return post
    }
    
    // Parse ChatListModel
    func parseChatListModels(_ documents: [QueryDocumentSnapshot]) -> [ChatListModel] {
        var results = [ChatListModel]()
        for doc in documents {
            let data = doc.data()
            var buyerDisplayName, sellerDisplayName, latestMessage, buyerPhotoURL, sellerPhotoURL, sellerUserId, buyerUserId, postingId, itemName: String!
            var date, sellerMemberSince, buyerMemberSince: Date!
            var members: [String]!
            
            data.forEach { (item) in
                switch item.key {
                    case "buyerDisplayName":
                        buyerDisplayName = item.value as? String
                    case "buyerPhotoURL":
                        buyerPhotoURL = item.value as? String
                    case "buyerUserId":
                        buyerUserId = item.value as? String
                    case "latestMessage":
                        latestMessage = item.value as? String
                    case "sellerDisplayName":
                        sellerDisplayName = item.value as? String
                    case "sellerPhotoURL":
                        sellerPhotoURL = item.value as? String
                    case "sentAt":
                        let timeStamp = item.value as? Timestamp
                        date = timeStamp?.dateValue()
                    case "sellerUserId":
                        sellerUserId = item.value as? String
                    case "members":
                        members = item.value as? [String]
                    case "postingId":
                        postingId = item.value as? String
                    case "sellerMemberSince":
                        let timeStamp = item.value as? Timestamp
                        sellerMemberSince = timeStamp?.dateValue()
                    case "buyerMemberSince":
                        let timeStamp = item.value as? Timestamp
                        buyerMemberSince = timeStamp?.dateValue()
                    case "itemName":
                        itemName = item.value as? String
                    default:
                        break
                }
            }
            
            let chatListModel = ChatListModel(
                documentId: doc.documentID,
                latestMessage: latestMessage,
                date: date,
                buyerDisplayName: buyerDisplayName,
                buyerPhotoURL: buyerPhotoURL,
                buyerUserId: buyerUserId,
                sellerDisplayName: sellerDisplayName,
                sellerPhotoURL: sellerPhotoURL,
                sellerUserId: sellerUserId,
                members: members,
                postingId: postingId,
                sellerMemberSince: sellerMemberSince,
                buyerMemberSince: buyerMemberSince,
                itemName: itemName
            )
            
            results.append(chatListModel)
        }
        
        return results
    }
}

// Panel of buttons i. e. Camera, Image, Document buttons for posting items
protocol ButtonPanelConfigurable where Self: UIViewController {
    var buttonPanel: UIStackView! { get set }
    var constraints: [NSLayoutConstraint]! { get set }
    func createButtonPanel(panelButtons: [PanelButton], superView: UIView, completion: (_ buttonsArr: [UIButton]) -> Void)
    func setButtonPanelConstraints(topView: UIView, heightConstant: CGFloat?)
}

extension ButtonPanelConfigurable {
    func createButtonPanel(panelButtons: [PanelButton], superView: UIView, completion: (_ buttonsArr: [UIButton]) -> Void) {
        buttonPanel = UIStackView()
        buttonPanel.axis = .horizontal
        buttonPanel.distribution = .fillEqually
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        superView.addSubview(buttonPanel)
        
        var buttonsArr = [UIButton]()
        for i in 0..<panelButtons.count {
            let button = createPanelButton(panelButton: panelButtons[i])
            buttonPanel.addArrangedSubview(button)
            buttonsArr.append(button)
        }
        
        completion(buttonsArr)
    }

    func createPanelButton(panelButton: PanelButton) -> UIButton {
        let image = UIImage(systemName: panelButton.imageName)!
            .withTintColor(panelButton.tintColor, renderingMode: .alwaysOriginal)
            .withConfiguration(panelButton.imageConfig)
        let button = UIButton.systemButton(with: image, target: self, action: nil)
        button.tag = panelButton.tag
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    func setButtonPanelConstraints(topView: UIView, heightConstant: CGFloat? = nil) {
        constraints.append(contentsOf: [
            buttonPanel.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 40),
            buttonPanel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            buttonPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonPanel.heightAnchor.constraint(equalToConstant: heightConstant ?? 80)
        ])
    }
}

protocol SharableDelegate where Self: UIViewController  {
    func share(_ objectsToShare: [AnyObject], completion: (() -> Void)?)
}

extension SharableDelegate {
    func share(_ objectsToShare: [AnyObject], completion: (() -> Void)? = nil) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        let shareSheetVC = CustomActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        present(shareSheetVC, animated: true, completion: completion)

        if let pop = shareSheetVC.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.height, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
    }
}

class CustomActivityViewController: UIActivityViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .gray
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .gray
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        UIButton.appearance().tintColor = .gray
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        applyBarTintColorToTheNavigationBar()
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .white
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .white
        UIButton.appearance().tintColor = .white
    }
}

protocol HandleMapSearch: AnyObject {
    func dropPinZoomIn(placemark: MKPlacemark,
                       addressString: String?,
                       scope: ShippingRestriction?)
    func getPlacemark( addressString : String,
                       completionHandler: @escaping(MKPlacemark?, NSError?) -> Void )
    func resetSearchResults()
    func getScreenshot(image: UIImage, address: ShippingAddress)
}

extension HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark,
                       addressString: String? = nil,
                       scope: ShippingRestriction? = .cities) {
        
    }
    
    func getPlacemark( addressString : String,
                       completionHandler: @escaping(MKPlacemark?, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    let pm = MKPlacemark(coordinate: location.coordinate)
                    completionHandler(pm, nil)
                    return
                }
            }
            
            completionHandler(nil, error as NSError?)
        }
    }
    
    func resetSearchResults() {
        
    }
    
    func getScreenshot(image: UIImage, address: ShippingAddress) {
        
    }
}

protocol ParseAddressDelegate {
    func parseAddress<T: MKPlacemark>(selectedItem: T) -> String
    func parseAddress<T: MKPlacemark>(selectedItem: T, scope: ShippingRestriction) -> String
}

extension ParseAddressDelegate {
    func parseAddress<T: MKPlacemark>(selectedItem: T) -> String {
        let firstSpace = (selectedItem.thoroughfare != nil && selectedItem.subThoroughfare != nil) ? " ": ""
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", ": ""
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " ": ""
        let addressLine = String(
            format: "%@%@%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state or province
            selectedItem.administrativeArea ?? "",
            " ",
            // postal code
            selectedItem.postalCode ?? ""
        )
        return addressLine
    }
    
    func parseAddress<T: MKPlacemark>(selectedItem: T, scope: ShippingRestriction) -> String {
        let firstSpace = (selectedItem.thoroughfare != nil && selectedItem.subThoroughfare != nil) ? " ": ""
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", ": ""
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " ": ""
        var addressLine: String!
                
        switch scope {
            case .cities:
                addressLine = String(
                    format: "%@%@%@%@%@",
                    // city
                    selectedItem.locality ?? "",
                    secondSpace,
                    // state or province
                    selectedItem.administrativeArea ?? "",
                    " ",
                    // country
                    selectedItem.country ?? ""
                )
            case .state:
                addressLine = String(
                    format: "%@%@%@",
                    // state or province
                    selectedItem.administrativeArea ?? "",
                    " ",
                    // country
                    selectedItem.country ?? ""
                )
                break
            case .country:
                addressLine = selectedItem.country ?? ""
                break
            case .distance:
                addressLine = String(
                    format: "%@%@%@%@%@%@%@%@%@",
                    // street number
                    selectedItem.subThoroughfare ?? "",
                    firstSpace,
                    // street name
                    selectedItem.thoroughfare ?? "",
                    comma,
                    // city
                    selectedItem.locality ?? "",
                    secondSpace,
                    // state or province
                    selectedItem.administrativeArea ?? "",
                    " ",
                    // postal code
                    selectedItem.postalCode ?? ""
                )
                break
        }

        return addressLine
    }
}

protocol TokenConfigurable {
    func createSearchToken(text: String, index: Int) -> UISearchToken
    func suggestedColor(fromIndex: Int) -> UIColor
}

extension TokenConfigurable {
    func createSearchToken(text: String, index: Int) -> UISearchToken {
        let tokenColor = suggestedColor(fromIndex: index)
        let image = UIImage(systemName: "circle.fill")?.withTintColor(tokenColor, renderingMode: .alwaysOriginal)
        let searchToken = UISearchToken(icon: image, text: text)
        searchToken.representedObject = text
        return searchToken
    }
    
    // colors for the tokens
    func suggestedColor(fromIndex: Int) -> UIColor {
        var suggestedColor: UIColor!
        switch fromIndex {
            case 0:
                suggestedColor = UIColor.red
            case 1:
                suggestedColor = UIColor.orange
            case 2:
                suggestedColor = UIColor.yellow
            case 3:
                suggestedColor = UIColor.green
            case 4:
                suggestedColor = UIColor.blue
            case 5:
                suggestedColor = UIColor.purple
            case 6:
                suggestedColor = UIColor.brown
            case 7:
                suggestedColor = UIColor(red: 93/255, green: 109/255, blue: 126/255, alpha: 1)
            case 8:
                suggestedColor = UIColor(red: 245/255, green: 176/255, blue: 65/255, alpha: 1)
            default:
                suggestedColor = UIColor.cyan
        }
        
        return suggestedColor
    }
}

protocol PostEditDelegate: AnyObject {
    func didUpdatePost(title: String, desc: String, imagesString: [String]?)
}

// Index and deindex from Core Spotlight when posting a new item, deleting the item from Edit, or aborting the smart contract
protocol CoreSpotlightDelegate {
    func indexSpotlight(
        itemTitle: String,
        desc: String,
        tokensArr: Set<String>,
        convertedId: String
    )
    func deindexSpotlight(identifier: String)
}

extension CoreSpotlightDelegate {
    func indexSpotlight(
        itemTitle: String,
        desc: String,
        tokensArr: Set<String>,
        convertedId: String
    ) {
        // Core Spotlight indexing
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = itemTitle
        attributeSet.contentCreationDate = Date()
        attributeSet.contentDescription = desc
        attributeSet.keywords = Array(tokensArr)
        
        let item = CSSearchableItem(uniqueIdentifier: convertedId, domainIdentifier: "com.ovis.NFTrack10", attributeSet: attributeSet)
        item.expirationDate = Date.distantFuture
        CSSearchableIndex.default().indexSearchableItems([item]) { (error) in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Search item for Goal successfully indexed")
            }
        }
    }
    
    func deindexSpotlight(identifier: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { (error) in
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Goal successfully deindexed")
            }
        }
    }
}

protocol SingleDocumentFetchDelegate where Self: UIViewController & PostParseDelegate {
    var postCache: NSCache<NSString, Post>! { get set }
    var storage: Set<AnyCancellable>! { get set }
    var alert: Alerts! { get set }
    func getPost(with postingId: String, completionHandler: @escaping (Post) -> Void)
}

extension SingleDocumentFetchDelegate {
    func getPostFromFirestore(
        with postingId: String,
        promise: @escaping (Result<Post, PostingError>) -> Void
    ) {
        FirebaseService.shared.db
            .collection("post")
            .document(postingId)
            .getDocument { [weak self] (querySnapshot, error) in
                if let _ = error {
                    promise(.failure(.generalError(reason: "Unable to get the item data to initialize the chat.")))
                }
                
                guard let document = querySnapshot,
                      let post = self?.parseDocument(document: document) else {
                    promise(.failure(.generalError(reason: "Unable to get the item data to initialize the chat.")))
                    return
                }
                
                //guard let p = post as? Self.T else { return }
                //CacheManager.shared["CachedPost"] = p
                
                promise(.success(post))
            }
    }
    
    func getPost(with postingId: String, completionHandler: @escaping (Post) -> Void) {
        return Future<Post, PostingError> { [weak self] promise in
            if let cachedVersion = self?.postCache.object(forKey: "CachedPost") {
                print("cached", cachedVersion)
                // use the cached version
                promise(.success(cachedVersion))
            } else {
                print("not cached")
                self?.getPostFromFirestore(with: postingId, promise: promise)
            }
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    self?.alert.showDetail("Error", with: err, for: self)
                case .finished:
                    break
                default:
                    break
            }
        } receiveValue: { (fetchedPost) in
            DispatchQueue.main.async {
                completionHandler(fetchedPost)
            }
        }
        .store(in: &storage)
    }
}

protocol ChatDelegate {
    func setSeenIndicator(isOnline: Bool, seenTime: Date?, sentTime: Date?) -> Bool
}

extension ChatDelegate {
    func setSeenIndicator(isOnline: Bool, seenTime: Date?, sentTime: Date?) -> Bool {
        // If the recipient is currently online, all the messages have been seen.
        // If not, check the last seen time:
        //      1. If the last seen time doesn't exist, then the messages have not been seen.
        //      2. The last seen time exists:
        //          A. If the last seen time is greater (later) then the sent time of the messages, they have been read.
        //          B. If the sent time of the messages is greater (later) then the last seen time of the recipient, then the messages have not been read.
        if isOnline {
            return true
        } else {
            if seenTime != nil {
                if let sentTime = sentTime, let seenTime = seenTime {
                    if seenTime > sentTime {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
}

protocol CustomNavBarConfigurable where Self: UIViewController  {
    associatedtype T where T: SpectrumView
    var customNavView: T! { get set }
    func configureCustomNavBar(v: UIView)
}

extension CustomNavBarConfigurable {
    func configureCustomNavBar(v: UIView) {
        customNavView = T()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(customNavView)
        
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: v.topAnchor, constant: -65),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

protocol GeneralPurposeDelegate: AnyObject {
    func doSomething()
}

protocol ProgressPanel where Self: CardCell {
    var containerView: UIView! { get set }
    var strokeColor: UIColor! { get set }
    var lineWidth: CGFloat! { get set }
    var selectedColor: UIColor! { get }
    // contains the entire meter: the circle, line, node title, date
    var meterContainer: UIView! { get set }
    // contains the node title and the date
    var nodeStackView: UIStackView! { get set }
    var nodeCount: CGFloat! { get set }
    var progressMeterNodeArr: [ProgressMeterNode]! { get set }
    func configureMeterContainer(post: Post, topView: UIView)
    //    func configureProgressMeter(nodeArray: [ProgressMeterNode], offset: CGFloat)
    //    func createStatusLabel(text: String) -> UILabel
    //    func processDate(date: Date?) -> String?
    func configurePrepareForeReuse()
}

extension ProgressPanel {
    func configureMeterContainer(post: Post, topView: UIView) {
//        meterContainer = UIView()
        meterContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(meterContainer)
        
        nodeStackView = UIStackView()
        nodeStackView.axis = .horizontal
        nodeStackView.distribution = .fillEqually
        nodeStackView.translatesAutoresizingMaskIntoConstraints = false
        meterContainer.addSubview(nodeStackView)

        NSLayoutConstraint.activate([
            meterContainer.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 10),
            meterContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            meterContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            meterContainer.heightAnchor.constraint(equalToConstant: 100),
            
            nodeStackView.leadingAnchor.constraint(equalTo: meterContainer.leadingAnchor),
            nodeStackView.trailingAnchor.constraint(equalTo: meterContainer.trailingAnchor),
            nodeStackView.heightAnchor.constraint(equalTo: meterContainer.heightAnchor, multiplier: 0.5),
            nodeStackView.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor)
        ])
        meterContainer.layoutIfNeeded()
        
        progressMeterNodeArr = [ProgressMeterNode]()
        // parse Post so that the node title like "Bid" or "Purchase" is paired up with its own dates accordingly
        
        switch post.paymentMethod {
            case PaymentMethod.auctionBeneficiary.rawValue:
                // auction
                
                // auction first node
                let bidNode = ProgressMeterNode(statusLabelText: AuctionStatus.bid.toDisplay, dateLabelText: processDate(date: post.bidDate))
                progressMeterNodeArr.append(bidNode)
                
                // auction second node
                let endedNode = ProgressMeterNode(statusLabelText: AuctionStatus.ended.toDisplay, dateLabelText: processDate(date: post.auctionEndDate))
                progressMeterNodeArr.append(endedNode)
                
                // auction third node
                let auctionTransferNode = ProgressMeterNode(statusLabelText: AuctionStatus.transferred.toDisplay, dateLabelText: processDate(date: post.auctionTransferredDate))
                progressMeterNodeArr.append(auctionTransferNode)
            case PaymentMethod.escrow.rawValue:
                // tangible and digital escrow
                
                // first node
                let purchaseDateNode = ProgressMeterNode(statusLabelText: "Purchased", dateLabelText: processDate(date: post.confirmPurchaseDate))
                progressMeterNodeArr.append(purchaseDateNode)
                
                // second node
                let transferNode = ProgressMeterNode(statusLabelText: "Transferred", dateLabelText: processDate(date: post.transferDate))
                progressMeterNodeArr.append(transferNode)
                
                // third node
                let receivedNode = ProgressMeterNode(statusLabelText: "Received", dateLabelText: processDate(date: post.confirmReceivedDate))
                progressMeterNodeArr.append(receivedNode)
            case PaymentMethod.directTransfer.rawValue:
                // first node
                let purchaseDateNode = ProgressMeterNode(statusLabelText: SimplePaymentStatus.purchased.toDisplay, dateLabelText: processDate(date: post.confirmPurchaseDate))
                progressMeterNodeArr.append(purchaseDateNode)
                
                // second node
                let transferNode = ProgressMeterNode(statusLabelText: SimplePaymentStatus.transferred.toDisplay, dateLabelText: processDate(date: post.transferDate))
                progressMeterNodeArr.append(transferNode)
                
                // third node. confirmReceivedDate is a misnomer since it's a date that the seller withdraws the funds. But, it is being repurposed from escrow to fit the direct transfer.
                let receivedNode = ProgressMeterNode(statusLabelText: SimplePaymentStatus.complete.toDisplay, dateLabelText: processDate(date: post.confirmReceivedDate))
                progressMeterNodeArr.append(receivedNode)
                break
            default:
                break
        }
        
        configureProgressMeter(nodeArray: progressMeterNodeArr)
    }
    
    // 2 points
    // (1 / 2) * (1 / 2) = 1 / 4
    // 1 / 4, 3 / 4
    
    // 3 points
    // (1 / 3) * (1 / 2) = 1 / 6
    // 1 / 6, 5 / 5
    
    // 4 points
    // (1 / 4) * (1 / 2) = 1 / 8
    // 1 / 8, 7 / 8
    
    private func configureProgressMeter(
        nodeArray: [ProgressMeterNode],
        offset: CGFloat = -20
    ) {
        // multiplied by 2 because we're finding the middle point between the nodes
        // as specified in the above example calculations, the midpoint is always 1/2 of any number of nodes
        nodeCount = CGFloat(nodeArray.count) * 2
        
        // the horizontal line throught the circular nodes
        let path = UIBezierPath()
        path.move(to: CGPoint(x: meterContainer.bounds.width / (nodeCount), y: meterContainer.bounds.midY + offset))
        path.addLine(to: CGPoint(x: (meterContainer.bounds.width / (nodeCount)) * (nodeCount - 1), y: meterContainer.bounds.midY + offset))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = strokeColor.cgColor
        meterContainer.layer.addSublayer(shapeLayer)
        
        // the circular nodes + node containers (status label + date label)
        for (i, element) in stride(from: 1, to: Int(nodeCount), by: 2).enumerated() {
            let circlePath = UIBezierPath(
                arcCenter: CGPoint(x: (meterContainer.bounds.width / (nodeCount)) * CGFloat(element),
                                   y: meterContainer.bounds.midY + offset),
                radius: 8, startAngle: CGFloat(0),
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )
            circlePath.lineWidth = lineWidth
            
            let circleShapeLayer = CAShapeLayer()
            circleShapeLayer.strokeColor = strokeColor.cgColor
            circleShapeLayer.fillColor = UIColor.white.cgColor
            circleShapeLayer.lineWidth = lineWidth
            circleShapeLayer.path = circlePath.cgPath
            circleShapeLayer.lineWidth = lineWidth
            circleShapeLayer.name = "circle"
            meterContainer.layer.addSublayer(circleShapeLayer)
            
            let nodeContainer = UIView()
            nodeContainer.translatesAutoresizingMaskIntoConstraints = false
            nodeStackView.addArrangedSubview(nodeContainer)
            
            let progressMeterNode = nodeArray[i]
            
            let statusLabel = createStatusLabel(text: progressMeterNode.statusLabelText)
            statusLabel.textAlignment = .center
            statusLabel.tag = 500 + i
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            nodeContainer.addSubview(statusLabel)
            
            let dateLabel = createStatusLabel(text: progressMeterNode.dateLabelText ?? "")
            dateLabel.textAlignment = .center
            dateLabel.tag = 600 + i
            dateLabel.translatesAutoresizingMaskIntoConstraints = false
            nodeContainer.addSubview(dateLabel)
            
            // if the date isn't null, it means the execution happened on those dates, therefore change the color of the node accordingly
            if progressMeterNode.dateLabelText != nil {
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel.textColor = selectedColor
                dateLabel.textColor = selectedColor
            }
            
            NSLayoutConstraint.activate([
                statusLabel.topAnchor.constraint(equalTo: nodeContainer.topAnchor),
                statusLabel.widthAnchor.constraint(equalTo: nodeContainer.widthAnchor),
                statusLabel.heightAnchor.constraint(equalTo: nodeContainer.heightAnchor, multiplier: 0.50),
                
                dateLabel.bottomAnchor.constraint(equalTo: nodeContainer.bottomAnchor),
                dateLabel.widthAnchor.constraint(equalTo: nodeContainer.widthAnchor),
                dateLabel.heightAnchor.constraint(equalTo: nodeContainer.heightAnchor, multiplier: 0.50)
            ])
        }
    }
    
    private func createStatusLabel(text: String) -> UILabel {
        let statusLabel = UILabel()
        statusLabel.text = text
        statusLabel.textColor = .lightGray
        statusLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        statusLabel.sizeToFit()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }
    
    private func processDate(date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
    
    func configurePrepareForeReuse() {
        let circleShapeLayerArr = meterContainer.layer.sublayers?.filter { $0.name == "circle" } as? [CAShapeLayer]
        circleShapeLayerArr?.forEach {
            $0.fillColor = UIColor.gray.cgColor;
            $0.strokeColor = UIColor.gray.cgColor
        }
        
        for i in 0..<Int(nodeCount) {
            if let statusLabel = viewWithTag(500 + i) as? UILabel {
                statusLabel.textColor = .gray
                statusLabel.text?.removeAll()
            }
            
            if let dateLabel = viewWithTag(600 + i) as? UILabel {
                dateLabel.textColor = .gray
                dateLabel.text?.removeAll()
            }
        }
    }
}

protocol ContextAction: FetchUserConfigurable where Self: UIViewController {
    var storage: Set<AnyCancellable>! { get set }
    var alert: Alerts! { get set }
}

extension ContextAction {
    func navToProfile(_ post: Post) {
        showSpinner { [weak self] in
            Future<UserInfo, PostingError> { promise in
                self?.fetchUserData(userId: post.sellerUserId, promise: promise)
            }
            .sink { (completion) in
                switch completion {
                    case .failure(.generalError(reason: let err)):
                        self?.alert.showDetail("Error", with: err, for: self)
                        break
                    case .finished:
                        break
                    default:
                        break
                }
            } receiveValue: { (userInfo) in
                self?.hideSpinner({
                    DispatchQueue.main.async {
                        let profileDetailVC = ProfileDetailViewController()
                        profileDetailVC.userInfo = userInfo
                        self?.navigationController?.pushViewController(profileDetailVC, animated: true)
                    }
                })
            }
            .store(in: &self!.storage)
        }
    }
    
    func imagePreivew(_ post: Post) {
        guard let galleries = post.files, galleries.count > 0 else { return }
        let pvc = PageViewController<BigSinglePageViewController<String>>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: galleries)
        let singlePageVC = BigSinglePageViewController(gallery: galleries.first, galleries: galleries)
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        pvc.modalPresentationStyle = .fullScreen
        pvc.modalTransitionStyle = .crossDissolve
        present(pvc, animated: true, completion: nil)
    }
    
    func imagePreivew(_ galleries: [String]) {
        guard galleries.count > 0 else { return }
        let pvc = PageViewController<BigSinglePageViewController<String>>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: galleries)
        let singlePageVC = BigSinglePageViewController(gallery: galleries.first, galleries: galleries)
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        pvc.modalPresentationStyle = .fullScreen
        pvc.modalTransitionStyle = .crossDissolve
        present(pvc, animated: true, completion: nil)
    }
    
    func navToHistory(_ post: Post) {
        let historyDetailVC = HistoryDetailViewController()
        historyDetailVC.post = post
        self.navigationController?.pushViewController(historyDetailVC, animated: true)
    }
    
    func navToReviews(_ post: Post) {
        let userInfo = UserInfo(email: nil, displayName: "NA", photoURL: nil, uid: post.sellerUserId, memberSince: nil)
        let userDetailVC = UserDetailViewController()
        userDetailVC.userInfo = userInfo
        navigationController?.pushViewController(userDetailVC, animated: true)
    }
    
    func navToChatVC(userId: String?, post: Post) {
        var userInfoRetainer: UserInfo!
        Future<UserInfo, PostingError> { [weak self] promise in
            self?.fetchUserData(userId: post.sellerUserId, promise: promise)
        }
        .eraseToAnyPublisher()
        .flatMap { (userInfo) -> AnyPublisher<String, PostingError> in
            userInfoRetainer = userInfo
            return Future<String, PostingError> { [weak self] promise in
                self?.getDocId(
                    userId: userId,
                    userInfo: userInfo,
                    itemDocId: post.documentId,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    self?.alert.showDetail("Error", with: err, for: self)
                case .finished:
                    break
                default:
                    self?.alert.showDetail("Error", with: "There was an error generating a chat ID.", for: self)
            }
        } receiveValue: { [weak self] (docId) in
            let chatVC = ChatViewController()
            // the name of the item to be displayed on ChatListVC as well as be used as a search term.
            chatVC.itemName = post.title
            chatVC.userInfo = userInfoRetainer
            // docId is the chat's unique ID
            chatVC.docId = docId
            // The unique ID of the posting so that when ChatVC is pushed from ChatListVC, the ChatListVC can push ReportVC
            chatVC.postingId = post.documentId
            self?.navigationController?.pushViewController(chatVC, animated: true)
        }
        .store(in: &storage)
    }
    
    // Create the document ID for the chat
    private func getDocId(
        userId: String?,
        userInfo: UserInfo,
        itemDocId: String,
        promise: @escaping (Result<String, PostingError>) -> Void
    ) {
        guard let sellerUid = userInfo.uid,
              let buyerUid = userId else {
            promise(.failure(.generalError(reason: "You're currently not logged in. Please log in and try again.")))
            return
        }
        
        let combinedString = sellerUid + buyerUid + itemDocId
        let inputData = Data(combinedString.utf8)
        let hashedId = SHA256.hash(data: inputData)
        let hashString = hashedId.compactMap { String(format: "%02x", $0) }.joined()
        promise(.success(hashString))
    }
    
    func navToReport(userId: String, post: Post) {
        let reportVC = ReportViewController()
        reportVC.post = post
        reportVC.userId = userId
        self.navigationController?.pushViewController(reportVC, animated: true)
    }
    
    func resale(_ post: Post) {
        let resaleVC = ResaleViewController()
        resaleVC.post = post
        resaleVC.title = "Resale"
        navigationController?.pushViewController(resaleVC, animated: true)
    }
    
    func getPreviewVC(post: Post) -> ListDetailViewController {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        return listDetailVC
    }
    
    func navToProfileContextualAction(_ post: Post) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Profile") { [weak self] (action, swipeButtonView, completion) in
            self?.navToProfile(post)
            completion(true)
        }
    }
    
    func imagePreviewContextualAction(_ post: Post) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Images") { [weak self] (action, swipeButtonView, completion) in
            self?.imagePreivew(post)
            completion(true)
        }
    }
    
    func navToHistoryContextualAction(_ post: Post) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Tx Detail") { [weak self] (action, swipeButtonView, completion) in
            self?.navToHistory(post)
            completion(true)
        }
    }
    
    func navToReviewsContextualAction(_ post: Post) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Reviews") { [weak self] (action, swipeButtonView, completion) in
            self?.navToReviews(post)
            completion(true)
        }
    }
    
    func resaleContextualAction(_ post: Post) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Resale") { [weak self] (action, swipeButtonView, completion) in
            self?.resale(post)
            completion(true)
        }
    }
}
