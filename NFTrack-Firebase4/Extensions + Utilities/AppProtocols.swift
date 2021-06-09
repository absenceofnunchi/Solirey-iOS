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
    func didDeleteImage(imageName: String)
}

// MARK: - MessageDelegate
/// PostViewController
protocol MessageDelegate: AnyObject {
    func didReceiveMessage(topics: [String])
}

// MARK: - TableViewRefreshDelegate
protocol TableViewRefreshDelegate: AnyObject {
    func didRefreshTableView()
}

// MARK: - TableViewConfigurable
protocol TableViewConfigurable {
    func configureTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource, height: CGFloat, cellType: UITableViewCell.Type, identifier: String) -> UITableView
}

extension TableViewConfigurable where Self: UITableViewDataSource {
    func configureTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource, height: CGFloat, cellType: UITableViewCell.Type, identifier: String) -> UITableView {
        let tableView = UITableView()
        tableView.register(cellType, forCellReuseIdentifier: identifier)
        tableView.estimatedRowHeight = height
        tableView.rowHeight = height
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
}

// MARK: - ModalConfigurable
protocol ModalConfigurable where Self: UIViewController {
    var closeButton: UIButton! { get set }
    func configureCloseButton()
    func setButtonConstraints()
    func closeButtonPressed()
}

extension ModalConfigurable {
    func configureCloseButton() {
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
        closeButton.tintColor = .black
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


protocol FileUploadable1 {
    func uploadSomething(completion: (() -> Void)?)
}

extension FileUploadable1 {
    func uploadSomething(completion: (() -> Void)? = nil) {
        print("hello")
        completion?()
    }
}

// MARK: - FileUploadable
protocol FileUploadable where Self:UIViewController {
    var alert: Alerts! { get set }
    func uploadImages(image: String, userId: String, completion: @escaping (URL) -> Void)
    func deleteFile(fileName: String)
    func saveImage(imageName: String, image: UIImage)
}

extension FileUploadable {
    func uploadImages(image: String, userId: String, completion: @escaping (URL) -> Void) {
        FirebaseService.sharedInstance.uploadPhoto(fileName: image, userId: userId) { [weak self](uploadTask, fileUploadError) in
            if let error = fileUploadError {
                switch error {
                    case .fileManagerError(let msg):
                        self?.alert.showDetail("Error", with: msg, for: self!)
                    case .fileNotAvailable:
                        self?.alert.showDetail("Error", with: "Image file not found.", for: self!)
                    case .userNotLoggedIn:
                        self?.alert.showDetail("Error", with: "You need to be logged in!", for: self!)
                }
            }
            
            if let uploadTask = uploadTask {
                // Listen for state changes, errors, and completion of the upload.
                uploadTask.observe(.resume) { snapshot in
                    // Upload resumed, also fires when the upload starts
                }
                
                uploadTask.observe(.pause) { snapshot in
                    // Upload paused
                    self?.alert.showDetail("Image Upload", with: "The image uploading process has been paused.", for: self!)
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
                    self?.deleteFile(fileName: image)
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
        let documentsDirectory =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
    
    func saveImage(imageName: String, image: UIImage) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
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

