//
//  ProfielViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-07.
//

/*
 Abstract:
 The profile page from AccountVC only for the user themselves, not for the public viewing
 Able to edit the profile photo, username, and the email.
 */

import UIKit
import Firebase
import FirebaseAuth
import MapKit
import Combine

class ProfileViewController: ParentProfileViewController, ModalConfigurable {
    var closeButton: UIButton!
    var deleteImageButton: UIButton!
    var emailTitleLabel: UILabel!
    var emailTextField: UITextField!
    var addressTitleLabel: UILabel!
    var addressLabel: UILabel!
    var profileImageName: String!
    var updateButton: UIButton!
    var storage = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserInfo()
        configureCloseButton()
        setButtonConstraints()
        configureNavigationBar(vc: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension ProfileViewController {
    override func configureUI() {
        super.configureUI()
        self.hideKeyboardWhenTappedAround()
        
        emailTitleLabel = createTitleLabel(text: "Email")
        scrollView.addSubview(emailTitleLabel)
        
        emailTextField = createTextField(content: nil, delegate: self)
        scrollView.addSubview(emailTextField)
        
        addressTitleLabel = createTitleLabel(text: "Shipping Address")
        scrollView.addSubview(addressTitleLabel)
        
        addressLabel = UILabelPadding()
        addressLabel.layer.borderWidth = 0.7
        addressLabel.layer.cornerRadius = 5
        addressLabel.layer.borderColor = UIColor.lightGray.cgColor
        addressLabel.isUserInteractionEnabled = true
        addressLabel.tag = 4
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addressLabel.addGestureRecognizer(tap)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(addressLabel)
        
        updateButton = UIButton()
        updateButton.backgroundColor = .black
        updateButton.tag = 2
        updateButton.layer.cornerRadius = 5
        updateButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        updateButton.setTitle("Update", for: .normal)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(updateButton)
        
        NSLayoutConstraint.activate([
            emailTitleLabel.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 40),
            emailTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            emailTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            emailTextField.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 10),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            emailTextField.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            addressTitleLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 40),
            addressTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            addressTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            addressLabel.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 10),
            addressLabel.heightAnchor.constraint(equalToConstant: 50),
            addressLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            addressLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            updateButton.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 50),
            updateButton.heightAnchor.constraint(equalToConstant: 50),
            updateButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            updateButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
        ])
    }
    
    // fetch the email, display name and the photo url with Auth.auth().currentUser
    // and fetch the address from Firestore
    func fetchUserInfo() {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) else { return }

        Future<UserInfo, PostingError> { promise in
            let user = Auth.auth().currentUser
            if let user = user {
                let userInfo = UserInfo(
                    email: user.email,
                    displayName: user.displayName ?? "N/A",
                    photoURL: (user.photoURL != nil) ? "\(user.photoURL!)" : "NA",
                    uid: user.uid,
                    memberSince: nil
                )
                promise(.success(userInfo))
            } else {
                promise(.failure(.generalError(reason: "Unable to fetch user data.")))
            }
        }
        .eraseToAnyPublisher()
        .flatMap { [weak self] (userInfo) -> AnyPublisher<UserInfo, PostingError> in
            Future<UserInfo, PostingError> { promise in
                self?.fetchAddress(userInfo: userInfo, userId: userId, promise: promise)
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
                    self?.alert.showDetail("Error", with: "Unable to retrieve the profile info.", for: self)
            }
        } receiveValue: { [weak self] (userInfo) in
            self?.userInfo = userInfo
            self?.emailTextField?.text = userInfo.email
            self?.addressLabel?.text = userInfo.address
        }
        .store(in: &storage)
    }
    
    func fetchAddress(
        userInfo: UserInfo,
        userId: String,
        promise: @escaping (Result<UserInfo, PostingError>) -> Void
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

                if let address = data["address"] as? String {
                    var ui = userInfo
                    ui.address = address
                    promise(.success(ui))
                } else {
                    promise(.success(userInfo))
                }
            }
    }
    
    // MARK: - buttonPressed
    @objc override func buttonPressed(_ sender: UIButton!) {
        super.buttonPressed(sender)
        switch sender.tag {
            case 1:
                let imagePickerController = UIImagePickerController()
                imagePickerController.allowsEditing = false
                imagePickerController.sourceType = .photoLibrary
                imagePickerController.delegate = self
                imagePickerController.modalPresentationStyle = .fullScreen
                present(imagePickerController, animated: true, completion: nil)
            case 2:
                showSpinner { [weak self] in
                    self?.updateProfile()
                }
            case 3:
                // delete image
                deleteProfileImage()
            default:
                break
        }
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        guard let v = sender.view else { return }
        switch v.tag {
            case 4:
                let mapVC = MapViewController()
                mapVC.fetchPlacemarkDelegate = self
                self.navigationController?.pushViewController(mapVC, animated: true)
            default:
                break
        }
    }
}

extension ProfileViewController {
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
            if let _ = error {
                loadingIndicator.stopAnimating()
                guard let image = UIImage(systemName: "person.crop.circle.fill") else {
                    strongSelf.dismiss(animated: true, completion: nil)
                    return
                }
                let configuration = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .large)
                let configuredImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal).withConfiguration(configuration)
                strongSelf.profileImageButton.setImage(configuredImage, for: .normal)
            }
            
            if let image = image {
                loadingIndicator.stopAnimating()
                strongSelf.profileImageButton = strongSelf.createProfileImageButton(strongSelf.profileImageButton, image: image)
                
                guard let deleteImage = UIImage(systemName: "minus.circle.fill") else {
                    strongSelf.dismiss(animated: true, completion: nil)
                    return
                }
                strongSelf.deleteImageButton = UIButton.systemButton(with: deleteImage.withTintColor(.red, renderingMode: .alwaysOriginal), target: strongSelf, action: #selector(strongSelf.buttonPressed(_:)))
                strongSelf.deleteImageButton.tag = 3
                strongSelf.deleteImageButton.translatesAutoresizingMaskIntoConstraints = false
                strongSelf.view.addSubview(strongSelf.deleteImageButton)
                
                NSLayoutConstraint.activate([
                    strongSelf.deleteImageButton.topAnchor.constraint(equalTo: strongSelf.profileImageButton.topAnchor, constant: -8),
                    strongSelf.deleteImageButton.trailingAnchor.constraint(equalTo: strongSelf.profileImageButton.trailingAnchor, constant: 8)
                ])
            }
        }
    }
}

// MARK: - Image picker
extension ProfileViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        profileImageButton.setImage(image, for: .normal)
        profileImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: profileImageButton.bounds.width - profileImageButton.bounds.height)
        profileImageButton.imageView?.layer.cornerRadius = profileImageButton.bounds.height/2.0
        profileImageButton.imageView?.contentMode = .scaleToFill
        
        profileImageName = UUID().uuidString
        let _ = saveImage(imageName: profileImageName, image: image)
        
        if deleteImageButton == nil {
            guard let deleteImage = UIImage(systemName: "minus.circle.fill") else {
                dismiss(animated: true, completion: nil)
                return
            }
            
            deleteImageButton = UIButton.systemButton(with: deleteImage.withTintColor(.red, renderingMode: .alwaysOriginal), target: target, action: #selector(buttonPressed(_:)))
            deleteImageButton.tag = 3
            deleteImageButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(deleteImageButton)
            
            NSLayoutConstraint.activate([
                deleteImageButton.topAnchor.constraint(equalTo: profileImageButton.topAnchor, constant: -8),
                deleteImageButton.trailingAnchor.constraint(equalTo: profileImageButton.trailingAnchor, constant: 8)
            ])
        } else {
            deleteImageButton.isHidden = false
        }
        
        delay(1) { [weak self] in
            self?.alert.fading(text: "Press update to finalize\nthe image change.", controller: self, toBePasted: nil, width: 250)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ProfileViewController: FileUploadable {
    func uploadProfileImage(uid: String) -> AnyPublisher<URL?, PostingError> {
        if self.profileImageName != nil {
            return Future<URL?, PostingError> { promise in
                self.uploadFileWithPromise(fileName: self.profileImageName, userId: uid, promise: promise)
            }
            .eraseToAnyPublisher()
        } else {
            return Result.Publisher(nil).eraseToAnyPublisher()
        }
    }
    
    func updateProfile() {
        guard let email = self.emailTextField.text,
              !email.isEmpty,
              let uid = self.userInfo.uid else {
            self.alert.showDetail("Incomplete", with: "The email field must be filled.", for: self)
            return
        }

        guard let displayName = self.displayNameTextField.text,
              !displayName.isEmpty else {
            self.alert.showDetail("Incomplete", with: "The display name field must be filled.", for: self)
            return
        }
        
        uploadProfileImage(uid: uid)
            .flatMap { (url) -> AnyPublisher<URL?, PostingError> in
                Future<URL?, PostingError> { promise in
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = displayName
                    changeRequest?.photoURL = url
                    changeRequest?.commitChanges { [weak self] (error) in
                        if let _ = error {
                            self?.deleteFile(fileName: self!.profileImageName)
                            promise(.failure(.generalError(reason: "Unable to update your profile.")))
                        }
                        
                        promise(.success(url))
                    }
                }
                .eraseToAnyPublisher()
            }
            .flatMap { [weak self] (url) -> AnyPublisher<URL?, PostingError> in
                Future<URL?, PostingError> { promise in
                    Auth.auth().currentUser?.updateEmail(to: email) { (error) in
                        if let _ = error {
                            self?.deleteFile(fileName: self!.profileImageName)
                            promise(.failure(.generalError(reason: "Unable to update the email.")))
                        }
                        
                        promise(.success(url))
                    }
                }
                .eraseToAnyPublisher()
            }
            .flatMap { [weak self] (url) -> AnyPublisher<Bool, PostingError> in
                Future<Bool, PostingError> { promise in
                    self?.updateUser(
                        email: email,
                        displayName: displayName,
                        photoURL: (url != nil) ? String(describing: url) : nil,
                        address: self?.addressLabel.text,
                        completion: { (error) in
                            if let _ = error {
                                promise(.failure(.generalError(reason: "Unable to update your profile.")))
                            } else {
                                promise(.success(true))
                            }
                        })
                }
                .eraseToAnyPublisher()
            }
            .sink { [weak self] (completion) in
                switch completion {
                    case .failure(.generalError(reason: let err)):
                        self?.alert.showDetail("Update Error", with: err, for: self)
                    case .finished:
                        self?.alert.showDetail("Success!", with: "You have successfully updated your profile.", for: self)
                    default:
                        self?.alert.showDetail("Update Error", with: "There was an error updating your profile", for: self)
                        break
                }
    
            } receiveValue: { [weak self] (url) in
                self?.hideSpinner({
                    guard let profileImageName = self?.profileImageName else { return }
                    self?.deleteFile(fileName: profileImageName)
                })
            }
            .store(in: &storage)
    }
    
//    // MARK: - updateProfile
//    func updateProfile1() {
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
//                self.uploadFile(fileName: self.profileImageName, userId: self.userInfo.uid!) { (url) in
//                    //                            UserDefaults.standard.set(url, forKey: UserDefaultKeys.photoURL)
//                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
//                    changeRequest?.displayName = displayName
//                    changeRequest?.photoURL = url
//                    changeRequest?.commitChanges { [weak self] (error) in
//                        if let error = error {
//                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
//                                self?.deleteFile(fileName: self!.profileImageName)
//                                self?.dismiss(animated: true, completion: nil)
//                            } completion: {}
//                        }
//
//                        if self?.userInfo.email != email {
//                            Auth.auth().currentUser?.updateEmail(to: email) { (error) in
//                                if let error = error {
//                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
//                                        self?.deleteFile(fileName: self!.profileImageName)
//                                        self?.dismiss(animated: true, completion: nil)
//                                    } completion: {}
//                                } else {
//                                    self?.updateUser(
//                                        email: email,
//                                        displayName: displayName,
//                                        photoURL: "\(url)",
//                                        address: self?.addressLabel.text,
//                                        completion: { (error) in
//                                        if let error = error {
//                                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
//                                                self?.deleteFile(fileName: self!.profileImageName)
//                                                self?.dismiss(animated: true, completion: nil)
//                                            } completion: {}
//                                        } else {
//                                            self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
//                                                self?.deleteFile(fileName: self!.profileImageName)
//                                                self?.dismiss(animated: true, completion: nil)
//                                            } completion: {}
//                                        }
//                                    })
//                                }
//                            }
//                        } else {
//                            self?.updateUser(
//                                email: email,
//                                displayName: displayName,
//                                photoURL: "\(url)",
//                                address: self?.addressLabel.text,
//                                completion: { (error) in
//                                if let error = error {
//                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
//                                        self?.deleteFile(fileName: self!.profileImageName)
//                                        self?.dismiss(animated: true, completion: nil)
//                                    } completion: {}
//                                } else {
//                                    self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
//                                        self?.deleteFile(fileName: self!.profileImageName)
//                                        self?.dismiss(animated: true, completion: nil)
//                                    } completion: {}
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
//                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//                    }
//
//                    if self?.userInfo.email != email {
//                        Auth.auth().currentUser?.updateEmail(to: email) { (error) in
//                            if let error = error {
//                                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//                            }
//
//                            self?.updateUser(
//                                email: email,
//                                displayName: displayName,
//                                photoURL: nil,
//                                address: self?.addressLabel.text,
//                                completion: { (error) in
//                                if let error = error {
//                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//                                } else {
//                                    self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
//                                        self?.dismiss(animated: true, completion: nil)
//                                    } completion: {}
//                                }
//                            })
//                        }
//                    } else {
//                        self?.updateUser(
//                            email: email,
//                            displayName: displayName,
//                            photoURL: nil,
//                            address: self?.addressLabel.text,
//                            completion: { (error) in
//                            if let error = error {
//                                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//                            } else {
//                                self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
//                                    self?.dismiss(animated: true, completion: nil)
//                                } completion: {}
//                            }
//                        })
//                    }
//                }
//            }
//        }
//    }
//
    func deleteProfileImage() {
        self.alert.fading(text: "Press \"Update\" to execute the change.", controller: self, toBePasted: nil, width: 350)
        guard let image = UIImage(systemName: "person.crop.circle.fill") else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        let configuration = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .large)
        let configuredImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal).withConfiguration(configuration)
        self.profileImageButton.setImage(configuredImage, for: .normal)
        self.deleteImageButton.isHidden = true
        self.profileImageName = nil
    }
}

extension ProfileViewController {
    /// this is for when ListDetailVC downloads and displays the user info
    /// you want it on a separate collection so that when a profile is updated, you only have to update a single document, not every post
    func updateUser(
        email: String?,
        displayName: String,
        photoURL: String?,
        address: String?,
        completion: @escaping (Error?) -> Void
    ) {
        guard let uid = self.userInfo.uid else { return }
        FirebaseService.shared.db.collection("user").document(uid).updateData([
            "email": email ?? "NA",
            "photoURL": photoURL ?? "NA",
            "displayName": displayName,
            "uid": uid,
            "address": address ?? "NA"
        ], completion: { (error) in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        })
    }
}

extension ProfileViewController: HandleMapSearch, ParseAddressDelegate {
    // reusing dropPinZoomIn method here that was originally used within the map in LocationSearchVC
    func dropPinZoomIn(placemark: MKPlacemark) {
        self.alert.fading(text: "Press \"Update\" to execute the change.", controller: self, toBePasted: nil, width: 320)
        addressLabel.text = parseAddress(selectedItem: placemark)
    }
}
