////
////  ProfielViewController.swift
////  NFTrack-Firebase4
////
////  Created by J C on 2021-06-07.
////
//
//import UIKit
//import Firebase
//
//class ProfileViewController: ParentModalViewController, UITextFieldDelegate {
//    var userInfo: UserInfo!
//    var profileImageButton: UIButton!
//    var deleteImageButton: UIButton!
//    var emailTitleLabel: UILabel!
//    var emailTextField: UITextField!
//    var displayNameTitleLabel: UILabel!
//    var displayNameTextField: UITextField!
//    var profileImageName: String!
//    var updateButton: UIButton!
//    let alert = Alerts()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        fetchUserInfo()
//        configureNavigationBar(vc: self)
//        configureUI()
//        setConstraints()
//    }
//}
//
//extension ProfileViewController {
//    func fetchUserInfo() {
//        let user = Auth.auth().currentUser
//        if let user = user {
//            self.userInfo = UserInfo(email: user.email, displayName: user.displayName ?? "N/A", photoURL: (user.photoURL != nil) ? "\(user.photoURL!)" : nil, uid: user.uid)
//        }
//    }
//
//    func configureUI() {
//        self.hideKeyboardWhenTappedAround()
//
//        profileImageButton = UIButton(type: .custom)
//        if let url = userInfo.photoURL {
//            showSpinner {
//                FirebaseService.sharedInstance.downloadImage(urlString: "\(url)") { [weak self] (image, error) in
//                    guard let strongSelf = self else { return }
//                    if let error = error {
//                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: strongSelf)
//                    }
//
//                    if let image = image {
//                        strongSelf.hideSpinner {
//                            strongSelf.profileImageButton.setImage(image, for: .normal)
//                            strongSelf.profileImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: strongSelf.profileImageButton.bounds.width - strongSelf.profileImageButton.bounds.height)
//                            strongSelf.profileImageButton.imageView?.layer.cornerRadius = strongSelf.profileImageButton.bounds.height/2.0
//                            strongSelf.profileImageButton.imageView?.contentMode = .scaleToFill
//
//                            guard let deleteImage = UIImage(systemName: "minus.circle.fill") else {
//                                strongSelf.dismiss(animated: true, completion: nil)
//                                return
//                            }
//                            strongSelf.deleteImageButton = UIButton.systemButton(with: deleteImage.withTintColor(.red, renderingMode: .alwaysOriginal), target: strongSelf, action: #selector(strongSelf.buttonPressed(_:)))
//                            strongSelf.deleteImageButton.tag = 3
//                            strongSelf.deleteImageButton.translatesAutoresizingMaskIntoConstraints = false
//                            strongSelf.view.addSubview(strongSelf.deleteImageButton)
//
//                            NSLayoutConstraint.activate([
//                                strongSelf.deleteImageButton.topAnchor.constraint(equalTo: strongSelf.profileImageButton.topAnchor, constant: -8),
//                                strongSelf.deleteImageButton.trailingAnchor.constraint(equalTo: strongSelf.profileImageButton.trailingAnchor, constant: 8)
//                            ])
//                        }
//                    }
//                }
//            }
//        } else {
//            guard let image = UIImage(systemName: "person.crop.circle.fill") else {
//                self.dismiss(animated: true, completion: nil)
//                return
//            }
//            let configuration = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .large)
//            let configuredImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal).withConfiguration(configuration)
//            profileImageButton.setImage(configuredImage, for: .normal)
//        }
//        profileImageButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//        profileImageButton.tag = 1
//        profileImageButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(profileImageButton)
//
//        emailTitleLabel = createTitleLabel(text: "Email")
//        view.addSubview(emailTitleLabel)
//
//        emailTextField = createTextField(content: userInfo.email, delegate: self)
//        view.addSubview(emailTextField)
//
//        displayNameTitleLabel = createTitleLabel(text: "Display Name")
//        view.addSubview(displayNameTitleLabel)
//
//        displayNameTextField = createTextField(content: userInfo.displayName, delegate: self)
//        view.addSubview(displayNameTextField)
//
//        updateButton = UIButton()
//        updateButton.backgroundColor = .black
//        updateButton.tag = 2
//        updateButton.layer.cornerRadius = 5
//        updateButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//        updateButton.setTitle("Update", for: .normal)
//        updateButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(updateButton)
//    }
//
//    func setConstraints() {
//        NSLayoutConstraint.activate([
//            profileImageButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
//            profileImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            profileImageButton.heightAnchor.constraint(equalToConstant: 100),
//            profileImageButton.widthAnchor.constraint(equalToConstant: 100),
//
//            emailTitleLabel.topAnchor.constraint(equalTo: profileImageButton.bottomAnchor, constant: 40),
//            emailTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
//            emailTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
//
//            emailTextField.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 10),
//            emailTextField.heightAnchor.constraint(equalToConstant: 50),
//            emailTextField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
//            emailTextField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
//
//            displayNameTitleLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 50),
//            displayNameTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
//            displayNameTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
//
//            displayNameTextField.topAnchor.constraint(equalTo: displayNameTitleLabel.bottomAnchor, constant: 10),
//            displayNameTextField.heightAnchor.constraint(equalToConstant: 50),
//            displayNameTextField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
//            displayNameTextField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
//
//            updateButton.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 50),
//            updateButton.heightAnchor.constraint(equalToConstant: 50),
//            updateButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
//            updateButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
//        ])
//    }
//
//    // MARK: - buttonPressed
//    @objc func buttonPressed(_ sender: UIButton!) {
//        switch sender.tag {
//            case 1:
//                let imagePickerController = UIImagePickerController()
//                imagePickerController.allowsEditing = false
//                imagePickerController.sourceType = .photoLibrary
//                imagePickerController.delegate = self
//                imagePickerController.modalPresentationStyle = .fullScreen
//                present(imagePickerController, animated: true, completion: nil)
//            case 2:
//                updateProfile()
//            case 3:
//                // delete image
//                deleteProfileImage()
//            default:
//                break
//        }
//    }
//}
//
//// MARK: - Image picker
//extension ProfileViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        picker.dismiss(animated: true)
//
//        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//            print("No image found")
//            return
//        }
//
//        profileImageButton.setImage(image, for: .normal)
//        profileImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: profileImageButton.bounds.width - profileImageButton.bounds.height)
//        profileImageButton.imageView?.layer.cornerRadius = profileImageButton.bounds.height/2.0
//        profileImageButton.imageView?.contentMode = .scaleToFill
//
//        profileImageName = UUID().uuidString
//        saveImage(imageName: profileImageName, image: image)
//
//        if deleteImageButton == nil {
//            guard let deleteImage = UIImage(systemName: "minus.circle.fill") else {
//                dismiss(animated: true, completion: nil)
//                return
//            }
//
//            deleteImageButton = UIButton.systemButton(with: deleteImage.withTintColor(.red, renderingMode: .alwaysOriginal), target: target, action: #selector(buttonPressed(_:)))
//            deleteImageButton.tag = 3
//            deleteImageButton.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(deleteImageButton)
//
//            NSLayoutConstraint.activate([
//                deleteImageButton.topAnchor.constraint(equalTo: profileImageButton.topAnchor, constant: -8),
//                deleteImageButton.trailingAnchor.constraint(equalTo: profileImageButton.trailingAnchor, constant: 8)
//            ])
//        } else {
//            deleteImageButton.isHidden = false
//        }
//    }
//
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
//}
//
//extension ProfileViewController {
//    // MARK: - updateProfile
//    func updateProfile() {
//        guard let email = self.emailTextField.text,
//              !email.isEmpty,
//              let displayName = self.displayNameTextField.text,
//              !displayName.isEmpty else {
//            self.alert.showDetail("Incomplete", with: "All fields must be filled.", for: self)
//            return
//        }
//
//        showSpinner {
//            if self.profileImageName != nil {
//                self.uploadImages(image: self.profileImageName, userId: self.userInfo.uid!) { (url) in
//                    //                            UserDefaults.standard.set(url, forKey: UserDefaultKeys.photoURL)
//                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
//                    changeRequest?.displayName = displayName
//                    changeRequest?.photoURL = url
//                    changeRequest?.commitChanges { [weak self] (error) in
//                        if let error = error {
//                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                        }
//
//                        if self?.userInfo.email != email {
//                            Auth.auth().currentUser?.updateEmail(to: email) { (error) in
//                                if let error = error {
//                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                                } else {
//                                    self?.updateUser(displayName: displayName, photoURL: "\(url)", completion: { (error) in
//                                        if let error = error {
//                                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                                        } else {
//                                            self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self!) {
//                                                self?.dismiss(animated: true, completion: nil)
//                                            }
//                                        }
//                                    })
//                                }
//                            }
//                        } else {
//                            self?.updateUser(displayName: displayName, photoURL: "\(url)", completion: { (error) in
//                                if let error = error {
//                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                                } else {
//                                    self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self!) {
//                                        self?.dismiss(animated: true, completion: nil)
//                                    }
//                                }
//                            })
//                        }
//                    }
//                }
//            } else {
//                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
//                changeRequest?.displayName = displayName
//                changeRequest?.photoURL = nil
//                changeRequest?.commitChanges { [weak self] (error) in
//                    if let error = error {
//                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                    }
//
//                    if self?.userInfo.email != email {
//                        Auth.auth().currentUser?.updateEmail(to: email) { (error) in
//                            if let error = error {
//                                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                            }
//
//                            self?.updateUser(displayName: displayName, photoURL: nil, completion: { (error) in
//                                if let error = error {
//                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                                } else {
//                                    self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self!) {
//                                        self?.dismiss(animated: true, completion: nil)
//                                    }
//                                }
//                            })
//                        }
//                    } else {
//                        self?.updateUser(displayName: displayName, photoURL: nil, completion: { (error) in
//                            if let error = error {
//                                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                            } else {
//                                self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self!) {
//                                    self?.dismiss(animated: true, completion: nil)
//                                }
//                            }
//                        })
//                    }
//                }
//            }
//        }
//    }
//
//    // MARK: - uploadImages
//    func uploadImages(image: String, userId: String, completion: @escaping (URL) -> Void) {
//        FirebaseService.sharedInstance.uploadPhoto(fileName: image, userId: userId) { [weak self](uploadTask, fileUploadError) in
//            if let error = fileUploadError {
//                switch error {
//                    case .fileManagerError(let msg):
//                        self?.alert.showDetail("Error", with: msg, for: self!)
//                    case .fileNotAvailable:
//                        self?.alert.showDetail("Error", with: "Image file not found.", for: self!)
//                    case .userNotLoggedIn:
//                        self?.alert.showDetail("Error", with: "You need to be logged in!", for: self!)
//                }
//            }
//
//            if let uploadTask = uploadTask {
//                // Listen for state changes, errors, and completion of the upload.
//                uploadTask.observe(.resume) { snapshot in
//                    print("resumed")
//                }
//
//                uploadTask.observe(.pause) { snapshot in
//                    // Upload paused
//                    self?.alert.showDetail("Image Upload", with: "The image uploading process has been paused.", for: self!)
//                }
//
//                uploadTask.observe(.progress) { snapshot in
//                    // Upload reported progress
//                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
//                        / Double(snapshot.progress!.totalUnitCount)
//                    print("percent Complete", percentComplete)
//                }
//
//                uploadTask.observe(.success) { snapshot in
//                    // Upload completed successfully
//                    self?.deleteFile(fileName: image)
//                    snapshot.reference.downloadURL { (url, error) in
//                        if let error = error {
//                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
//                        }
//
//                        if let url = url {
//                            completion(url)
//                        }
//                    }
//                }
//
//                uploadTask.observe(.failure) { snapshot in
//                    if let error = snapshot.error as NSError? {
//                        switch (StorageErrorCode(rawValue: error.code)!) {
//                            case .objectNotFound:
//                                // File doesn't exist
//                                print("object not found")
//                                break
//                            case .unauthorized:
//                                // User doesn't have permission to access file
//                                print("unauthorized")
//                                break
//                            case .cancelled:
//                                // User canceled the upload
//                                print("cancelled")
//                                break
//
//                            /* ... */
//
//                            case .unknown:
//                                // Unknown error occurred, inspect the server response
//                                print("unknown")
//                                break
//                            default:
//                                // A separate error occurred. This is a good place to retry the upload.
//                                print("reload?")
//                                break
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    // MARK: - deleteFile
//    func deleteFile(fileName: String) {
//        // delete images from the system
//        let fileManager = FileManager.default
//        let documentsDirectory =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let documentsPath = documentsDirectory.path
//        do {
//
//            let filePathName = "\(documentsPath)/\(fileName)"
//            try fileManager.removeItem(atPath: filePathName)
//
//            let files = try fileManager.contentsOfDirectory(atPath: "\(documentsPath)")
//            print("all files in cache after deleting images: \(files)")
//
//        } catch {
//            print("Could not clear temp folder: \(error)")
//        }
//    }
//
//    // MARK: - saveImage
//    func saveImage(imageName: String, image: UIImage) {
//        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
//
//        let fileName = imageName
//        let fileURL = documentsDirectory.appendingPathComponent(fileName)
//        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
//
//        //Checks if file exists, removes it if so.
//        if FileManager.default.fileExists(atPath: fileURL.path) {
//            do {
//                try FileManager.default.removeItem(atPath: fileURL.path)
//            } catch let removeError {
//                print("couldn't remove file at path", removeError)
//            }
//        }
//
//        do {
//            try data.write(to: fileURL)
//        } catch let error {
//            print("error saving file with error", error)
//        }
//    }
//
//    func deleteProfileImage() {
//        self.alert.showDetail("Update", with: "Press update button to execute the change.", for: self) {
//            guard let image = UIImage(systemName: "person.crop.circle.fill") else {
//                self.dismiss(animated: true, completion: nil)
//                return
//            }
//
//            let configuration = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .large)
//            let configuredImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal).withConfiguration(configuration)
//            self.profileImageButton.setImage(configuredImage, for: .normal)
//            self.deleteImageButton.isHidden = true
//            self.profileImageName = nil
//        }
//    }
//
//    // MARK: - createDeleteImageButton
//    //    func createDeleteImageButton(deleteImageButton: UIButton, target: UIViewController) {
//    //        guard let deleteImage = UIImage(systemName: "minus.circle.fill") else {
//    //            dismiss(animated: true, completion: nil)
//    //            return
//    //        }
//    //
//    //        deleteImageButton = UIButton.systemButton(with: deleteImage.withTintColor(.red, renderingMode: .alwaysOriginal), target: target, action: #selector(buttonPressed(_:)))
//    //        deleteImageButton.tag = 3
//    //        deleteImageButton.translatesAutoresizingMaskIntoConstraints = false
//    //        view.addSubview(deleteImageButton)
//    //
//    //        NSLayoutConstraint.activate([
//    //            deleteImageButton.topAnchor.constraint(equalTo: profileImageButton.topAnchor, constant: -8),
//    //            deleteImageButton.trailingAnchor.constraint(equalTo: profileImageButton.trailingAnchor, constant: 8)
//    //        ])
//    //    }
//}
//
//extension ProfileViewController {
//    /// this is for when ListDetailVC downloads and displays the user info
//    /// you want it on a separate collection so that when a profile is updated, you only have to update a single document, not every post
//    func updateUser(displayName: String, photoURL: String?, completion: @escaping (Error?) -> Void) {
//        print("self.userInfo.uid!", self.userInfo.uid!)
//        FirebaseService.sharedInstance.db.collection("user").document(self.userInfo.uid!).setData([
//            "photoURL": photoURL ?? "NA",
//            "displayName": displayName,
//            "uid": self.userInfo.uid!
//        ], completion: { (error) in
//            if let error = error {
//                completion(error)
//            } else {
//                completion(nil)
//            }
//        })
//    }
//}
//
