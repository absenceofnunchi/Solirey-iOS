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
 
 When deleting the profile photo, the "Update" button doesn't have to be pressed. The delete button will update the Firebase Auth profile as well as Firestore.
 When updating the photo to another photo, or go from no photo to a photo, the Update button has to be pressed. 
 */

import UIKit
import FirebaseAuth
import MapKit
import Combine

class ProfileViewController: ParentProfileViewController, ModalConfigurable {
    final var closeButton: UIButton!
    private var deleteImageButton: UIButton!
    private var emailTitleLabel: UILabel!
    private var emailTextField: UITextField!
    private var addressTitleLabel: UILabel!
    private var addressDeleteButton: UIButton!
    private var addressLabel: UILabel!
    private var profileImageURL: URL!
    private var updateButton: UIButton!
    private var storage = Set<AnyCancellable>()
    private var coordinates: CLLocationCoordinate2D!
    private var deleteImage: UIImage? {
        guard let deleteImage = UIImage(systemName: "minus.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal) else {
            return nil
        }
        return deleteImage
    }
    weak var delegate: RefetchDataDelegate?
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserInfo()
        configureCloseButton()
        setButtonConstraints()
        configureNavigationBar(vc: self)
    }
    
    final override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingAnimation()
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func loadingAnimation() {
        let totalCount = 4
        let duration = 1.0 / Double(totalCount)
        
        let animation = UIViewPropertyAnimator(duration: 0.7, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.displayNameTitleLabel.alpha = 1
                    self?.displayNameTitleLabel.transform = .identity
                    
                    self?.displayNameTextField.alpha = 1
                    self?.displayNameTextField.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.emailTitleLabel.alpha = 1
                    self?.emailTitleLabel.transform = .identity
                    
                    self?.emailTextField.alpha = 1
                    self?.emailTextField.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 3 / Double(totalCount), relativeDuration: duration) {
                    self?.addressTitleLabel.alpha = 1
                    self?.addressTitleLabel.transform = .identity
                    
                    self?.addressLabel.alpha = 1
                    self?.addressLabel.transform = .identity
                    
                    if self?.addressLabel != nil, self?.addressDeleteButton != nil {
                        if (self?.addressLabel.text == "" || self?.addressLabel.text == nil) {
                            self?.addressDeleteButton.alpha = 0
                        } else {
                            self?.addressDeleteButton.alpha = 1
                        }
                    }
                    
                    self?.addressDeleteButton.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 4 / Double(totalCount), relativeDuration: duration) {
                    self?.updateButton.alpha = 1
                    self?.updateButton.transform = .identity
                }
            })
        }
        
        animation.startAnimation()
    }
}

extension ProfileViewController {
    final override func configureUI() {
        super.configureUI()
        self.hideKeyboardWhenTappedAround()
        
        displayNameTitleLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        displayNameTitleLabel.alpha = 0
        displayNameTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        displayNameTextField.alpha = 0
        
        emailTitleLabel = createTitleLabel(text: "Email")
        emailTitleLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        emailTitleLabel.alpha = 0
        scrollView.addSubview(emailTitleLabel)
        
        emailTextField = createTextField(content: nil, delegate: self)
        emailTextField.alpha = 0
        emailTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        scrollView.addSubview(emailTextField)
        
        addressTitleLabel = createTitleLabel(text: "Shipping Address")
        addressTitleLabel.alpha = 0
        addressTitleLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        addressTitleLabel.sizeToFit()
        scrollView.addSubview(addressTitleLabel)
        
        guard let deleteImage = deleteImage else { return }
        addressDeleteButton = UIButton.systemButton(with: deleteImage, target: self, action: #selector(buttonPressed(_:)))
        addressDeleteButton.tag = 4
        addressDeleteButton.transform = CGAffineTransform(translationX: 0, y: 40)
        addressDeleteButton.alpha = 0
        addressDeleteButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(addressDeleteButton)
        
        addressLabel = UILabelPadding()
        addressLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        addressLabel.alpha = 0
        addressLabel.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        addressLabel.layer.cornerRadius = 10
        addressLabel.isUserInteractionEnabled = true
        addressLabel.clipsToBounds = true
        addressLabel.tag = 5
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addressLabel.addGestureRecognizer(tap)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(addressLabel)
        
        updateButton = UIButton()
        updateButton.transform = CGAffineTransform(translationX: 0, y: 40)
        updateButton.alpha = 0
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
            
            addressDeleteButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 40),
            addressDeleteButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
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
    private func fetchUserInfo() {
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
            self?.addressLabel?.text = userInfo.shippingAddress?.address
            
            // Even though the coordinates are not displayed, they still need to be stored in a variable
            // because when the profile is updated, even the ones that haven't been changed will be updated
            // which means if no new address is updated, the coordinates will be set to 0
            if let latitude = self?.userInfo.shippingAddress?.latitude,
               let longitude = self?.userInfo.shippingAddress?.longitude {
                self?.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            
        }
        .store(in: &storage)
    }
    
    private func fetchAddress(
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

                if let shippingAddress = data["shippingAddress"] as? [String: Any],
                   let address = shippingAddress["address"] as? String,
                   let latitude = shippingAddress["latitude"] as? Double,
                   let longitude = shippingAddress["longitude"] as? Double {
                    
                    var ui = userInfo
                    ui.shippingAddress = ShippingAddress(address: address, longitude: longitude, latitude: latitude)
                    promise(.success(ui))
                } else {
                    promise(.success(userInfo))
                }
            }
    }
    
    // MARK: - buttonPressed
    @objc final override func buttonPressed(_ sender: UIButton!) {
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
                showSpinner { [weak self] in
                    self?.deleteProfileImage()
                }
            case 4:
                // delete the address text field
                addressLabel.text = ""
                addressDeleteButton.alpha = 0
            default:
                break
        }
    }
    
    @objc final func tapped(_ sender: UITapGestureRecognizer) {
        guard let v = sender.view else { return }
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch v.tag {
            case 5:
                let mapVC = MapViewController()
                mapVC.title = "Shipping Address"
                mapVC.fetchPlacemarkDelegate = self
                self.navigationController?.pushViewController(mapVC, animated: true)
            default:
                break
        }
    }
}

extension ProfileViewController {
    final override func configureCustomProfileImage(from url: String) {
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
                guard let deleteImage = self?.deleteImage else { return }
                strongSelf.deleteImageButton = UIButton.systemButton(with: deleteImage, target: strongSelf, action: #selector(strongSelf.buttonPressed(_:)))
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
    final func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
              let url = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            print("No image found")
            return
        }
        
        profileImageButton.setImage(image, for: .normal)
        profileImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: profileImageButton.bounds.width - profileImageButton.bounds.height)
        profileImageButton.imageView?.layer.cornerRadius = profileImageButton.bounds.height/2.0
        profileImageButton.imageView?.contentMode = .scaleToFill
        
        profileImageURL = url
        
        if deleteImageButton == nil {
            guard let deleteImage = deleteImage else { return }
            deleteImageButton = UIButton.systemButton(with: deleteImage, target: target, action: #selector(buttonPressed(_:)))
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
    
    final func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ProfileViewController: FileUploadable {
//    final func uploadProfileImage(uid: String) -> AnyPublisher<URL?, PostingError> {
//        if self.profileImageName != nil {
//            return Future<URL?, PostingError> { promise in
//                self.uploadFileWithPromise(fileName: self.profileImageName, userId: uid, promise: promise)
//            }
//            .eraseToAnyPublisher()
//        } else {
//            return Result.Publisher(nil).eraseToAnyPublisher()
//        }
//    }
    
    final func uploadProfileImage(uid: String) -> AnyPublisher<URL?, PostingError> {
        if self.profileImageURL != nil {
            return Future<URL?, PostingError> { promise in
                self.uploadImage(url: self.profileImageURL, userId: uid, promise: promise)
            }
            .eraseToAnyPublisher()
        } else {
            return Result.Publisher(nil).eraseToAnyPublisher()
        }
    }
    
    final func updateProfile() {
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
                    changeRequest?.commitChanges { (error) in
                        if let _ = error {
                            promise(.failure(.generalError(reason: "Unable to update your profile.")))
                        }
                        
                        promise(.success(url))
                    }
                }
                .eraseToAnyPublisher()
            }
            .flatMap { (url) -> AnyPublisher<URL?, PostingError> in
                Future<URL?, PostingError> { promise in
                    Auth.auth().currentUser?.updateEmail(to: email) { (error) in
                        if let _ = error {
                            promise(.failure(.generalError(reason: "Unable to update the email.")))
                        }
                        
                        promise(.success(url))
                    }
                }
                .eraseToAnyPublisher()
            }
            .flatMap { [weak self] (url) -> AnyPublisher<Bool, PostingError> in
                return Future<Bool, PostingError> { promise in
                    self?.updateUser(
                        email: email,
                        displayName: displayName,
                        photoURL: url != nil ? url?.absoluteString : nil,
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
                        self?.delay(0.5, closure: {
                            self?.alert.showDetail("Success!", with: "You have successfully updated your profile.", for: self)
                            self?.delegate?.didFetchData()
                        })
                    default:
                        self?.alert.showDetail("Update Error", with: "There was an error updating your profile", for: self)
                        break
                }
            } receiveValue: { (_) in
            }
            .store(in: &storage)
    }
    
    final func deleteProfileImage() {
        guard let uid = self.userInfo.uid, let image = UIImage(systemName: "person.crop.circle.fill") else { return }
        
        Future<Bool, PostingError> { promise in
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.photoURL = nil
            changeRequest?.commitChanges { (error) in
                if let _ = error {
                    promise(.failure(.generalError(reason: "Unable to delete the profile image.")))
                }
                
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
        .flatMap { (isDone) -> Future<Bool, PostingError> in
            Future<Bool, PostingError> { promise in
                FirebaseService.shared.db
                    .collection("user")
                    .document(uid)
                    .updateData([
                        "photoURL": "NA"
                    ], completion: { (error) in
                        if let _ = error {
                            promise(.failure(.generalError(reason: "Unable to delete the profile image.")))
                        } else {
                            promise(.success(true))
                        }
                    })
            }
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    self?.alert.showDetail("Error", with: err, for: self)
                    break
                case .finished:
                    break
                default:
                    break
            }
        } receiveValue: { [weak self] (_) in
            self?.hideSpinner({
                UserDefaults.standard.set(nil, forKey: UserDefaultKeys.photoURL)
                
                let configuration = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .large)
                let configuredImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal).withConfiguration(configuration)
                
                DispatchQueue.main.async {
                    self?.profileImageButton.setImage(configuredImage, for: .normal)
                    self?.deleteImageButton.isHidden = true
                    self?.profileImageURL = nil
                }
            })
        }
        .store(in: &storage)
    }
}

extension ProfileViewController {
    /// this is for when ListDetailVC downloads and displays the user info
    /// you want it on a separate collection so that when a profile is updated, you only have to update a single document, not every post
    private func updateUser(
        email: String?,
        displayName: String,
        photoURL: String?,
        address: String?,
        completion: @escaping (Error?) -> Void
    ) {
        guard let uid = self.userInfo.uid else { return }
        let userDefaults = UserDefaults.standard
        var userData: [String: Any]!
        
        // if photo has not been updated, then leave it as it is.
        if let photoURL = photoURL {
            userData = [
                "email": email ?? "NA",
                "photoURL": photoURL,
                "displayName": displayName,
                "uid": uid,
                "shippingAddress": [
                    "address": address ?? "NA",
                    "longitude": coordinates?.longitude ?? 0,
                    "latitude": coordinates?.latitude ?? 0
                ]
            ]
            
            userDefaults.set(photoURL, forKey: UserDefaultKeys.photoURL)
        } else {
            userData = [
                "email": email ?? "NA",
                "displayName": displayName,
                "uid": uid,
                "shippingAddress": [
                    "address": address ?? "NA",
                    "longitude": coordinates?.longitude ?? 0,
                    "latitude": coordinates?.latitude ?? 0
                ]
            ]
        }
        
        FirebaseService.shared.db
            .collection("user")
            .document(uid)
            .updateData(userData, completion: { [weak self] (error: Error?) in
            if let error = error {
                completion(error)
            } else {
                userDefaults.set(displayName, forKey: UserDefaultKeys.displayName)
                userDefaults.set(address, forKey: UserDefaultKeys.address)
                userDefaults.set(self?.coordinates?.longitude, forKey: UserDefaultKeys.longitude)
                userDefaults.set(self?.coordinates?.latitude, forKey: UserDefaultKeys.latitude)
                
                completion(nil)
            }
        })
    }
}

extension ProfileViewController: HandleMapSearch, ParseAddressDelegate {
    // reusing dropPinZoomIn method here that was originally used within the map in LocationSearchVC
    final func dropPinZoomIn(placemark: MKPlacemark, addressString: String?, scope: ShippingRestriction?) {
        delay(0.5) { [weak self] in
            self?.alert.fading(text: "Press \"Update\" to execute the change.", controller: self, toBePasted: nil, width: 320)
        }
        
        addressLabel.text = parseAddress(selectedItem: placemark)
        coordinates = placemark.coordinate
    }
}
