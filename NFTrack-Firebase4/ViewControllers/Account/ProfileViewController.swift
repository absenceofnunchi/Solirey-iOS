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

class ProfileViewController: ParentProfileViewController, ModalConfigurable {
    var closeButton: UIButton!
    var deleteImageButton: UIButton!
    var emailTitleLabel: UILabel!
    var emailTextField: UITextField!
    var addressTitleLabel: UILabel!
    var addressTextField: UITextField!
    var profileImageName: String!
    var updateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCloseButton()
        setButtonConstraints()
        configureNavigationBar(vc: self)
    }
}

extension ProfileViewController {
//    func fetchUserInfo() {
//        let user = Auth.auth().currentUser
//        if let user = user {
//            self.userInfo = UserInfo(
//                email: user.email,
//                displayName: user.displayName ?? "N/A",
//                photoURL: (user.photoURL != nil) ? "\(user.photoURL!)" : "NA",
//                uid: user.uid,
//                memberSince: nil
//            )
//        }
//    }
    func fetchUserInfo() {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) else { return }
        FirebaseService.shared.db
            .collection("user")
            .document(userId)
            .getDocument { [weak self] (document, error) in
                guard error == nil else {
                    self?.alert.showDetail("Error", with: "Unable to retrieve the account info.", for: self)
                    return
                }
                
                guard let document = document,
                      document.exists,
                      let data = document.data() else {
                    return
                }
                
                var displayName: String!
                var uid: String!
                var photoURL: String!
                var address: String!
                data.forEach { (item) in
                    switch item.key {
                        case "displayName":
                            displayName = item.value as? String
                        case "uid":
                            uid = item.value as? String
                        case "photoURL":
                            photoURL = item.value as? String
                        case "address":
                            address = item.value as? String
                        default:
                            break
                    }
                }
                
                self?.userInfo = UserInfo(
                    email: nil,
                    displayName: displayName,
                    photoURL: photoURL,
                    uid: uid,
                    memberSince: nil,
                    address: address
                )
            }
    }
    
    override func configureUI() {
        super.configureUI()
        fetchUserInfo()

        self.hideKeyboardWhenTappedAround()
        
        emailTitleLabel = createTitleLabel(text: "Email")
        scrollView.addSubview(emailTitleLabel)

        emailTextField = createTextField(content: userInfo.email ?? "", delegate: self)
        scrollView.addSubview(emailTextField)
        
        addressTitleLabel = createTitleLabel(text: "Delivery Address")
        scrollView.addSubview(addressTitleLabel)
        
        addressTextField = createTextField(content: userInfo.address ?? "No Address", delegate: self)
        addressTextField.isUserInteractionEnabled = false
        scrollView.addSubview(addressTextField)
        
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
            
            addressTextField.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 10),
            addressTextField.heightAnchor.constraint(equalToConstant: 50),
            addressTextField.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            addressTextField.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            updateButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 50),
            updateButton.heightAnchor.constraint(equalToConstant: 50),
            updateButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            updateButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
        ])
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
                updateProfile()
            case 3:
                // delete image
                deleteProfileImage()
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
    // MARK: - updateProfile
    func updateProfile() {
        guard let email = self.emailTextField.text,
              !email.isEmpty,
              let displayName = self.displayNameTextField.text,
              !displayName.isEmpty else {
            self.alert.showDetail("Incomplete", with: "All fields must be filled.", for: self)
            return
        }
        
        showSpinner {
            if self.profileImageName != nil {
                self.uploadFile(fileName: self.profileImageName, userId: self.userInfo.uid!) { (url) in
                    //                            UserDefaults.standard.set(url, forKey: UserDefaultKeys.photoURL)
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = displayName
                    changeRequest?.photoURL = url
                    changeRequest?.commitChanges { [weak self] (error) in
                        if let error = error {
                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
                                self?.deleteFile(fileName: self!.profileImageName)
                                self?.dismiss(animated: true, completion: nil)
                            } completion: {}
                        }
                        
                        if self?.userInfo.email != email {
                            Auth.auth().currentUser?.updateEmail(to: email) { (error) in
                                if let error = error {
                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
                                        self?.deleteFile(fileName: self!.profileImageName)
                                        self?.dismiss(animated: true, completion: nil)
                                    } completion: {}
                                } else {
                                    self?.updateUser(displayName: displayName, photoURL: "\(url)", completion: { (error) in
                                        if let error = error {
                                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
                                                self?.deleteFile(fileName: self!.profileImageName)
                                                self?.dismiss(animated: true, completion: nil)
                                            } completion: {}
                                        } else {
                                            self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
                                                self?.deleteFile(fileName: self!.profileImageName)
                                                self?.dismiss(animated: true, completion: nil)
                                            } completion: {}
                                        }
                                    })
                                }
                            }
                        } else {
                            self?.updateUser(displayName: displayName, photoURL: "\(url)", completion: { (error) in
                                if let error = error {
                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self) {
                                        self?.deleteFile(fileName: self!.profileImageName)
                                        self?.dismiss(animated: true, completion: nil)
                                    } completion: {}
                                } else {
                                    self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
                                        self?.deleteFile(fileName: self!.profileImageName)
                                        self?.dismiss(animated: true, completion: nil)
                                    } completion: {}
                                }
                            })
                        }
                    }
                }
            } else {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = displayName
                changeRequest?.photoURL = nil
                changeRequest?.commitChanges { [weak self] (error) in
                    if let error = error {
                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                    }
                    
                    if self?.userInfo.email != email {
                        Auth.auth().currentUser?.updateEmail(to: email) { (error) in
                            if let error = error {
                                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                            }
                            
                            self?.updateUser(displayName: displayName, photoURL: nil, completion: { (error) in
                                if let error = error {
                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                                } else {
                                    self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
                                        self?.dismiss(animated: true, completion: nil)
                                    } completion: {}
                                }
                            })
                        }
                    } else {
                        self?.updateUser(displayName: displayName, photoURL: nil, completion: { (error) in
                            if let error = error {
                                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                            } else {
                                self?.alert.showDetail("Success!", with: "Your profile has been successfully updated", for: self) {
                                    self?.dismiss(animated: true, completion: nil)
                                } completion: {}
                            }
                        })
                    }
                }
            }
        }
    }
 
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
    func updateUser(displayName: String, photoURL: String?, completion: @escaping (Error?) -> Void) {
        guard let uid = self.userInfo.uid else { return }
        FirebaseService.shared.db.collection("user").document(uid).updateData([
            "photoURL": photoURL ?? "NA",
            "displayName": displayName,
            "uid": self.userInfo.uid!
        ], completion: { (error) in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        })
    }
}

