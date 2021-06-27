//
//  AppProtocols.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

// WalletViewController
protocol WalletDelegate: AnyObject {
    func didProcessWallet()
}

// MARK: - PreviewDelegate
/// PostViewController
protocol PreviewDelegate: AnyObject {
    func didDeleteFileFromPreview(filePath: URL)
}

// MARK: - MessageDelegate
/// PostViewController
protocol MessageDelegate: AnyObject {
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
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
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
    func deleteFile(fileName: String)
    func saveImage(imageName: String, image: UIImage) -> URL?
    func saveFile(fileName: String, data: Data)
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
}

// MARK: - RefetchDataDelegate
protocol RefetchDataDelegate: AnyObject {
    func didFetchData()
}

// MARK: - SegmentConfigurable
protocol SegmentConfigurable {
    associatedtype Segment: RawRepresentable
    func configureSwitch()
    func segmentedControlSelectionDidChange(_ sender: UISegmentedControl)
}

protocol UsernameBannerConfigurable where Self: UIViewController {
    var userInfo: UserInfo! { get set }
    var scrollView: UIScrollView! { get set }
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
}

extension UsernameBannerConfigurable {
    func fetchUserData(id: String) {
        DispatchQueue.global(qos: .utility).async {
            let docRef = FirebaseService.shared.db.collection("user").document(id)
            docRef.getDocument { [weak self] (document, error) in
                if let document = document, document.exists {
                    if let data = document.data() {
                        let displayName = data[UserDefaultKeys.displayName] as? String
                        let photoURL = data[UserDefaultKeys.photoURL] as? String
                        let userInfo = UserInfo(email: nil, displayName: displayName!, photoURL: photoURL, uid: id)
                        self?.userInfo = userInfo
                    }
                } else {
                    self?.hideSpinner {
                        return
                    }
                }
            }
        }
    }
    
    func processProfileImage() {
        displayNameLabel.text = userInfo.displayName
        if let info = self.userInfo, info.photoURL != "NA" {
            FirebaseService.shared.downloadImage(urlString: self.userInfo.photoURL!) { [weak self] (image, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: strongSelf)
                }
                
                if let image = image {
                    strongSelf.fetchedImage = image
                    strongSelf.profileImageView.image = image
                    strongSelf.profileImageView.layer.cornerRadius = strongSelf.profileImageView.bounds.height/2.0
                    strongSelf.profileImageView.contentMode = .scaleToFill
                    strongSelf.profileImageView.clipsToBounds = true
                    
                    strongSelf.profileImageView.isUserInteractionEnabled = true
                    strongSelf.displayNameLabel.isUserInteractionEnabled = true
                }
            }
        } else {
            profileImageView.isUserInteractionEnabled = true
            displayNameLabel.isUserInteractionEnabled = true
        }
    }
    
    func configureNameDisplay(post: Post) {
        usernameContainer = UIView()
        usernameContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(usernameContainer)
        
        dateLabel = UILabel()
        dateLabel.textAlignment = .right
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let formattedDate = formatter.string(from: post.date)
        dateLabel.text = formattedDate
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(dateLabel)
        
        guard let image = UIImage(systemName: "person.crop.circle.fill") else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        profileImageView = UIImageView()
        let profileImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal)
        profileImageView.image = profileImage
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        profileImageView.addGestureRecognizer(tap)
        profileImageView.tag = 1
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(profileImageView)
        
        displayNameLabel = UILabel()
        displayNameLabel.addGestureRecognizer(tap)
        displayNameLabel.tag = 1
        displayNameLabel.text = userInfo?.displayName
        displayNameLabel.lineBreakMode = .byTruncatingTail
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(displayNameLabel)
        
        underLineView = UnderlineView()
        underLineView.translatesAutoresizingMaskIntoConstraints = false
        usernameContainer.addSubview(underLineView)
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

fileprivate extension UIViewController {
    @objc func tapped(_ sender: UITapGestureRecognizer!) {
    }
}

protocol PageVCConfigurable: UIPageViewControllerDataSource, UIPageViewControllerDelegate where Self: UIViewController {
    var pvc: UIPageViewController! { get set }
    var galleries: [String]! { get set }
    var constraints: [NSLayoutConstraint]! { get set }
    func configureImageDisplay<T: Post, U: UIView>(post: T, v: U)
    func setImageDisplayConstraints<T: UIView>(v: T)
}

extension PageVCConfigurable {
    func configureImageDisplay<T: Post, U: UIView>(post: T, v: U) {
        if let files = post.files, files.count > 0 {
            self.galleries.append(contentsOf: files)
            let singlePageVC = ImagePageViewController(gallery: galleries[0])
            pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
            pvc.dataSource = self
            pvc.delegate = self
            addChild(pvc)
            v.addSubview(pvc.view)
            pvc.view.translatesAutoresizingMaskIntoConstraints = false
            pvc.didMove(toParent: self)
            
            let pageControl = UIPageControl.appearance()
            pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
            pageControl.currentPageIndicatorTintColor = .gray
            pageControl.backgroundColor = .white
        }
    }
    
    func setImageDisplayConstraints<T: UIView>(v: T) {
        guard let pv = pvc.view else { return }
        constraints.append(contentsOf: [
            pv.topAnchor.constraint(equalTo: v.topAnchor, constant: 0),
            pv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pv.heightAnchor.constraint(equalToConstant: 250),
        ])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index -= 1
        if index < 0 {
            return nil
        }
        
        return ImagePageViewController(gallery: galleries[index])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index += 1
        if index >= galleries.count {
            return nil
        }
        
        return ImagePageViewController(gallery: galleries[index])
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.galleries.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let page = pageViewController.viewControllers![0] as! ImagePageViewController
        
        if let gallery = page.gallery {
            return self.galleries.firstIndex(of: gallery)!
        } else {
            return 0
        }
    }
}
