//
//  ProfielViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-07.
//

import UIKit
import Firebase
import FirebaseAuth

class ProfileViewController: ParentProfileViewController, ModalConfigurable {
    var closeButton: UIButton!
    var deleteImageButton: UIButton!
    var emailTitleLabel: UILabel!
    var emailTextField: UITextField!
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
    func fetchUserInfo() {
        let user = Auth.auth().currentUser
        if let user = user {
            self.userInfo = UserInfo(email: user.email, displayName: user.displayName ?? "N/A", photoURL: (user.photoURL != nil) ? "\(user.photoURL!)" : "NA", uid: user.uid)
        }
    }
    
    override func configureUI() {
        fetchUserInfo()

        super.configureUI()
        self.hideKeyboardWhenTappedAround()
        
        emailTitleLabel = createTitleLabel(text: "Email")
        scrollView.addSubview(emailTitleLabel)

        emailTextField = createTextField(content: userInfo.email, delegate: self)
        scrollView.addSubview(emailTextField)
        
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
            
            updateButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 50),
            updateButton.heightAnchor.constraint(equalToConstant: 50),
            updateButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            updateButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
        ])
    }
    
//    override func setConstraints() {
//        super.setConstraints()
//
//        NSLayoutConstraint.activate([
//            emailTitleLabel.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 40),
//            emailTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
//            emailTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
//
//            emailTextField.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 10),
//            emailTextField.heightAnchor.constraint(equalToConstant: 50),
//            emailTextField.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
//            emailTextField.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
//
//            updateButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 50),
//            updateButton.heightAnchor.constraint(equalToConstant: 50),
//            updateButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
//            updateButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
//        ])
//    }
    
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
        self.alert.showDetail("Update", with: "Press update button to execute the change.", for: self) {
            guard let image = UIImage(systemName: "person.crop.circle.fill") else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            let configuration = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .large)
            let configuredImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal).withConfiguration(configuration)
            self.profileImageButton.setImage(configuredImage, for: .normal)
            self.deleteImageButton.isHidden = true
            self.profileImageName = nil
        } completion: {}
    }
}

extension ProfileViewController {
    /// this is for when ListDetailVC downloads and displays the user info
    /// you want it on a separate collection so that when a profile is updated, you only have to update a single document, not every post
    func updateUser(displayName: String, photoURL: String?, completion: @escaping (Error?) -> Void) {
        FirebaseService.shared.db.collection("user").document(self.userInfo.uid!).setData([
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

