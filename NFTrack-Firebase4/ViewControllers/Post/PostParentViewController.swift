//
//  PostParentViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-01.
//

import UIKit

import UIKit
import FirebaseFirestore
import FirebaseStorage
import Firebase
import web3swift

class PostParentViewController: UIViewController {
    var scrollView: UIScrollView!
    var titleLabel: UILabel!
    var titleTextField: UITextField!
    var priceLabel: UILabel!
    var priceTextField: UITextField!
    var descLabel: UILabel!
    var descTextView: UITextView!
    var idTitleLabel: UILabel!
    var idTextField: UITextField!
    var pickerTitleLabel: UILabel!
    var pickerLabel: UILabelPadding!
    var tagContainerView: UIView!
    var tagTitleLabel: UILabel!
    var tagTextField: UISearchTextField!
    var addTagButton: UIButton!
    var buttonPanel: UIView!
    var cameraButton: UIButton!
    var imagePickerButton: UIButton!
    var imageNameArr = [String]()
    var imagePreviewVC: ImagePreviewViewController!
    var postButton: UIButton!
    let transactionService = TransactionService()
    let alert = Alerts()
    var imageAddresses = [String]()
    let userDefaults = UserDefaults.standard
    var observation: NSKeyValueObservation?
    var userId: String!
    var documentId: String!
    var socketDelegate: SocketDelegate!

    let pvc = MyPickerVC()
    let mdbvc = MyDoneButtonVC()
    var showKeyboard = false
    
    deinit {
        if observation != nil {
            observation?.invalidate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar(vc: self)
        configureUI()
        configureImagePreview()
        setConstraints()
    }
    
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addKeyboardObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        imagePreviewVC.data = imageNameArr
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeKeyboardObserver()
    }
}

extension PostParentViewController {
    
    @objc func configureUI() {
        title = "Post"
        self.hideKeyboardWhenTappedAround()
        
        scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 1200)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.fill()
        
        titleLabel = createTitleLabel(text: "Title")
        scrollView.addSubview(titleLabel)
        
        titleTextField = createTextField(delegate: self)
        titleTextField.autocorrectionType = .no
        scrollView.addSubview(titleTextField)
        
        priceLabel = createTitleLabel(text: "Price")
        scrollView.addSubview(priceLabel)
        
        priceTextField = createTextField(delegate: self)
        priceTextField.keyboardType = .decimalPad
        priceTextField.placeholder = "In ETH"
        scrollView.addSubview(priceTextField)
        
        descLabel = createTitleLabel(text: "Description")
        scrollView.addSubview(descLabel)
        
        descTextView = UITextView()
        descTextView.delegate = self
        descTextView.layer.borderWidth = 0.7
        descTextView.layer.borderColor = UIColor.lightGray.cgColor
        descTextView.layer.cornerRadius = 5
        descTextView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        descTextView.clipsToBounds = true
        descTextView.isScrollEnabled = true
        descTextView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        descTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descTextView)
        
        idTitleLabel = createTitleLabel(text: "Unique Identifier")
        scrollView.addSubview(idTitleLabel)
        
        idTextField = createTextField(delegate: self)
        idTextField.autocapitalizationType = .none
        idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
        scrollView.addSubview(idTextField)
        
        pickerTitleLabel = createTitleLabel(text: "Category")
        scrollView.addSubview(pickerTitleLabel)
        
        pickerLabel = UILabelPadding()
        pickerLabel.isUserInteractionEnabled = true
        pickerLabel.layer.borderWidth = 0.7
        pickerLabel.layer.cornerRadius = 5
        pickerLabel.layer.borderColor = UIColor.lightGray.cgColor
        pickerLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pickerLabel)
        
        self.mdbvc.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
        pickerLabel.addGestureRecognizer(tap)
        
        tagContainerView = UIView()
        tagContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tagContainerView)
        
        tagTitleLabel = createTitleLabel(text: "Tags")
        scrollView.addSubview(tagTitleLabel)
        
        tagTextField = UISearchTextField()
        tagTextField.placeholder = "Up to 5 tags"
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: tagTextField.frame.size.height))
        tagTextField.leftView = paddingView
        tagTextField.leftViewMode = .always
        tagTextField.delegate = self
        tagTextField.layer.borderWidth = 0.7
        tagTextField.layer.cornerRadius = 5
        tagTextField.layer.borderColor = UIColor.lightGray.cgColor
        tagTextField.backgroundColor = .white
        tagTextField.translatesAutoresizingMaskIntoConstraints = false
        tagContainerView.addSubview(tagTextField)
        
        guard let addTagImage = UIImage(systemName: "plus") else { return }
        addTagButton = UIButton.systemButton(with: addTagImage.withTintColor(.black, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonPressed))
        addTagButton.layer.cornerRadius = 5
        addTagButton.layer.borderWidth = 0.7
        addTagButton.layer.borderColor = UIColor.lightGray.cgColor
        addTagButton.tag = 4
        addTagButton.translatesAutoresizingMaskIntoConstraints = false
        tagContainerView.addSubview(addTagButton)
        
        buttonPanel = UIView()
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonPanel)
        
        let cameraImage = UIImage(systemName: "camera")!.withTintColor(.white, renderingMode: .alwaysOriginal)
        cameraButton = UIButton.systemButton(with: cameraImage, target: self, action: #selector(buttonPressed))
        cameraButton.tag = 1
        cameraButton.layer.cornerRadius = 5
        cameraButton.backgroundColor = .black
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(cameraButton)
        
        let pickerImage = UIImage(systemName: "photo")!.withTintColor(.white, renderingMode: .alwaysOriginal)
        imagePickerButton = UIButton.systemButton(with: pickerImage, target: self, action: #selector(buttonPressed(_:)))
        imagePickerButton.tag = 2
        imagePickerButton.layer.cornerRadius = 5
        imagePickerButton.backgroundColor = .black
        imagePickerButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(imagePickerButton)
        
        postButton = UIButton()
        postButton.setTitle("Post", for: .normal)
        postButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        postButton.layer.cornerRadius = 5
        postButton.backgroundColor = .black
        postButton.tag = 3
        postButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(postButton)
    }
    
    // MARK: - setConstraints
    @objc func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            
            titleTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),
            titleTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            
            priceLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            priceLabel.heightAnchor.constraint(equalToConstant: 50),
            priceLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            
            priceTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            priceTextField.heightAnchor.constraint(equalToConstant: 50),
            priceTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            priceTextField.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 0),
            
            descLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            descLabel.heightAnchor.constraint(equalToConstant: 50),
            descLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: 20),
            
            descTextView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            descTextView.heightAnchor.constraint(equalToConstant: 100),
            descTextView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            descTextView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 0),
            
            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            idTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTitleLabel.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 20),
            
            idTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            idTextField.heightAnchor.constraint(equalToConstant: 50),
            idTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTextField.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
            
            pickerTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            pickerTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            pickerTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pickerTitleLabel.topAnchor.constraint(equalTo: idTextField.bottomAnchor, constant: 20),
            
            pickerLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            pickerLabel.heightAnchor.constraint(equalToConstant: 50),
            pickerLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pickerLabel.topAnchor.constraint(equalTo: pickerTitleLabel.bottomAnchor, constant: 0),
            
            tagTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            tagTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            tagTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            tagTitleLabel.topAnchor.constraint(equalTo: pickerLabel.bottomAnchor, constant: 20),
            
            tagContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            tagContainerView.heightAnchor.constraint(equalToConstant: 50),
            tagContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            tagContainerView.topAnchor.constraint(equalTo: tagTitleLabel.bottomAnchor, constant: 0),
            
            tagTextField.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.7),
            tagTextField.heightAnchor.constraint(equalToConstant: 50),
            tagTextField.leadingAnchor.constraint(equalTo: tagContainerView.leadingAnchor),
            tagTextField.topAnchor.constraint(equalTo: tagContainerView.topAnchor),
            
            addTagButton.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.2),
            addTagButton.heightAnchor.constraint(equalToConstant: 50),
            addTagButton.trailingAnchor.constraint(equalTo: tagContainerView.trailingAnchor),
            addTagButton.topAnchor.constraint(equalTo: tagContainerView.topAnchor),
            
            buttonPanel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            buttonPanel.heightAnchor.constraint(equalToConstant: 50),
            buttonPanel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            buttonPanel.topAnchor.constraint(equalTo: tagContainerView.bottomAnchor, constant: 40),
            
            cameraButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
            cameraButton.heightAnchor.constraint(equalToConstant: 80),
            cameraButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
            
            imagePickerButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
            imagePickerButton.heightAnchor.constraint(equalToConstant: 80),
            imagePickerButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
            
            postButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            postButton.heightAnchor.constraint(equalToConstant: 50),
            postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            postButton.topAnchor.constraint(equalTo: imagePickerButton.bottomAnchor, constant: 20),
            
            imagePreviewVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 170),
            imagePreviewVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imagePreviewVC.view.topAnchor.constraint(equalTo: postButton.bottomAnchor, constant: 20),
        ])
    }
    

    
    // MARK: - buttonPressed
    @objc func buttonPressed(_ sender: UIButton) {
        if imageNameArr.count < 7 {
            switch sender.tag {
                case 1:
                    let vc = UIImagePickerController()
                    vc.sourceType = .camera
                    vc.allowsEditing = true
                    vc.delegate = self
                    present(vc, animated: true)
                case 2:
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.allowsEditing = false
                    imagePickerController.sourceType = .photoLibrary
                    imagePickerController.delegate = self
                    imagePickerController.modalPresentationStyle = .fullScreen
                    present(imagePickerController, animated: true, completion: nil)
                case 3:
                    mint()
                case 4:
                    if let text = tagTextField.text, !text.isEmpty {
                        tagTextField.text?.removeAll()
                        let token = createSearchToken(text: text, index: tagTextField.tokens.count)
                        tagTextField.insertToken(token, at: tagTextField.tokens.count > 0 ? tagTextField.tokens.count : 0)
                    }
                default:
                    break
            }
        } else {
            let detailVC = DetailViewController(height: 250)
            detailVC.titleString = "Image Upload Limit"
            detailVC.message = "There is a limit of 6 images per post."
            detailVC.buttonAction = { [weak self]vc in
                self?.dismiss(animated: true, completion: nil)
            }
            present(detailVC, animated: true, completion: nil)
        }
    }
    
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

// MARK: - Image picker
extension PostParentViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        let imageName = UUID().uuidString
        imageNameArr.append(imageName)
        saveImage(imageName: imageName, image: image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension PostParentViewController {
    // MARK: - addKeyboardObserver
    func addKeyboardObserver() {
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
//                                               name: UIResponder.keyboardWillChangeFrameNotification,
//                                               object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    func removeKeyboardObserver(){
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: - keyboardNotifications
    // This method will notify when keyboard appears/ dissapears
    @objc func keyboardNotifications(notification: NSNotification) {
        
        var txtFieldY : CGFloat = 0.0  //Using this we will calculate the selected textFields Y Position
        let spaceBetweenTxtFieldAndKeyboard : CGFloat = 5.0 //Specify the space between textfield and keyboard
        
        
        var frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        if let activeTextField = UIResponder.currentFirst() as? UITextField ?? UIResponder.currentFirst() as? UITextView {
            // Here we will get accurate frame of textField which is selected if there are multiple textfields
            frame = self.view.convert(activeTextField.frame, from:activeTextField.superview!.superview)
            txtFieldY = frame.origin.y + frame.size.height
        }
        
        if let userInfo = notification.userInfo {
            // here we will get frame of keyBoard (i.e. x, y, width, height)
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyBoardFrameY = keyBoardFrame!.origin.y
            let keyBoardFrameHeight = keyBoardFrame!.size.height
//            print("keyBoardFrameHeight", keyBoardFrameHeight)
            var viewOriginY: CGFloat = 0.0
            //Check keyboards Y position and according to that move view up and down
            if keyBoardFrameY >= UIScreen.main.bounds.size.height {
//                print("keyBoardFrameY", keyBoardFrameY)
//                print("UIScreen.main.bounds.size.height", UIScreen.main.bounds.size.height)
                viewOriginY = 0.0
            } else {
                // if textfields y is greater than keyboards y then only move View to up
                if txtFieldY >= keyBoardFrameY {
                    
                    print("txtFieldY", txtFieldY)
                    print("keyBoardFrameY", keyBoardFrameY)
//                    print("spaceBetweenTxtFieldAndKeyboard", spaceBetweenTxtFieldAndKeyboard)
                    viewOriginY = (txtFieldY - keyBoardFrameY) + spaceBetweenTxtFieldAndKeyboard
//                    print("viewOriginY before", viewOriginY)
                    // This condition is just to check viewOriginY should not be greator than keyboard height
                    // if its more than keyboard height then there will be black space on the top of keyboard.
                    if viewOriginY > keyBoardFrameHeight { viewOriginY = keyBoardFrameHeight }
                }
            }
            print("viewOriginY", viewOriginY)
            //set the Y position of view
            self.view.frame.origin.y = -viewOriginY
        }
    }
}

extension PostParentViewController {
    // MARK: - saveImage
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

extension PostParentViewController: PreviewDelegate {
    // MARK: - configureImagePreview
    func configureImagePreview() {
        imagePreviewVC = ImagePreviewViewController()
        imagePreviewVC.data = imageNameArr
        imagePreviewVC.delegate = self
        imagePreviewVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(imagePreviewVC)
        imagePreviewVC.view.frame = view.bounds
        view.addSubview(imagePreviewVC.view)
        imagePreviewVC.didMove(toParent: self)
    }
    
    // MARK: - didDeleteImage
    func didDeleteImage(imageName: String) {
        imageNameArr = imageNameArr.filter { $0 != imageName }
    }
}

extension PostParentViewController {
    // MARK: - checkExistingId
    func checkExistingId(id: String, completion: @escaping (Bool) -> Void) {
        FirebaseService.sharedInstance.db.collection("post")
            .whereField("id", isEqualTo: id)
            .getDocuments() { (querySnapshot, err) in
                if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
    
    @objc func mint() {

    }
    
    // MARK: - uploadImages
    func uploadImages(image: String, userId: String, id: String) {
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
                            FirebaseService.sharedInstance.db.collection("post").document(id).updateData([
                                "images": FieldValue.arrayUnion(["\(url)"])
                            ], completion: { (error) in
                                if let error = error {
                                    self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                                }
                            })
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
}

extension PostParentViewController: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        showKeyboard = false
        mdbvc.view.alpha = 0
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        showKeyboard = false
        mdbvc.view.alpha = 0
    }
}

extension PostParentViewController {
    //    let eventABI = [
    //        {
    //            "indexed": true,
    //            "internalType": "address",
    //            "name": "from",
    //            "type": "address"
    //        },
    //        {
    //            "indexed": true,
    //            "internalType": "address",
    //            "name": "to",
    //            "type": "address"
    //        },
    //        {
    //            "indexed": true,
    //            "internalType": "uint256",
    //            "name": "tokenId",
    //            "type": "uint256"
    //        }
    //    ]
    
    func mint(_ hash: Data) {
        
        
        //        let from = ABI.Element.InOut(name: "from", type: .address)
        //        let to = ABI.Element.InOut(name: "to", type: .address)
        //        let tokenId = ABI.Element.InOut(name: "tokenId", type: .uint(bits: 256))
        //        let abiElement = ABI.Element.Function(name: "Transfer", inputs: [from, to, tokenId], outputs: [], constant: false, payable: false)
        //        print("abiElement", abiElement)
        
        
                let from = ABI.Element.Event.Input(name: "from", type: .address, indexed: true)
                let to = ABI.Element.Event.Input(name: "to", type: .address, indexed: true)
                let tokenId = ABI.Element.Event.Input(name: "tokenId", type: .uint(bits: 256), indexed: true)
                let abiEvent = ABI.Element.Event(name: "Transfer", inputs: [from, to, tokenId], anonymous: false)
                print("abiEvent", abiEvent)
        
                let eventLogData = Data(base64Encoded: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef")
                let eventLogTopics = [
                    Data(base64Encoded: "0x0000000000000000000000000000000000000000000000000000000000000000")!,
                    Data(base64Encoded: "0x0000000000000000000000006879f0a123056b5bb56c7e787cf64a67f3a16a71")!,
                    Data(base64Encoded: "0x0000000000000000000000000000000000000000000000000000000000000030")!
                ]
        
                let decodedLog = ABIDecoder.decodeLog(event: abiEvent, eventLogTopics: eventLogTopics, eventLogData: eventLogData!)
                print("decodedLog", decodedLog as Any)
    }
}

extension PostParentViewController: MessageDelegate {
    // MARK: - didReceiveMessage
    @objc func didReceiveMessage(topics: [String]) {
        // get the token ID to be uploaded to Firestore
        getTokenId(topics: topics) { [weak self](tokenId, error) in
            if let error = error {
                self?.alert.showDetail("Token ID Fetch Error", with: error.localizedDescription, for: self!)
            }
            
            if let tokenId = tokenId {
                FirebaseService.sharedInstance.db.collection("post").document(self!.documentId).updateData([
                    "tokenId": tokenId
                ]) { (error) in
                    if let error = error {
                        self?.alert.showDetail("Error Loading TokenID", with: error.localizedDescription, for: self!)
                    } else {
                        self?.alert.showDetail("Success", with: "You have successfully minted a token", for: self!) {
                            // disconnect socket
                            self?.socketDelegate.disconnectSocket()
                            
                            var imageCount: Int = 0
                            // upload images and delete them afterwards
                            if self!.imageNameArr.count > 0, let imageNameArr = self?.imageNameArr {
                                for image in imageNameArr {
                                    self?.uploadImages(image: image, userId: self!.userId, id: self!.documentId)
                                    imageCount += 1
                                    if imageCount == imageNameArr.count, let ipvc = self?.imagePreviewVC {
                                        self?.imageNameArr.removeAll()
                                        ipvc.data.removeAll()
                                        ipvc.collectionView.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - getTokenId
    func getTokenId(topics: [String], completion: @escaping (String?, Error?) -> Void) {
        // build request URL
        guard let requestURL = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/decodeLog") else {
            return
        }
        
        // prepare request
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let parameter: [String: Any] = [
            "hexString": topics[0],
            "topics": [
                topics[1],
                topics[2],
                topics[3]
            ]
        ]
        
        let paramData = try? JSONSerialization.data(withJSONObject: parameter, options: [])
        request.httpBody = paramData
        
        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                completion(nil, error)
            }
            
            
            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                // handle HTTP server-side error
                completion(nil, error)
            }
            
            if let data = data {
                do {
                    if let responseObj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0)) as? [String:Any],
                       let tokenId = responseObj["tokenId"] as? String {
                        completion(tokenId, nil)
                    }
                } catch {
                    completion(nil, error)
                }
            }
        })
        
        observation = task.progress.observe(\.fractionCompleted) { (progress, _) in
            print("progress", progress)
            DispatchQueue.main.async {
                //                self?.progressView.progress = Float(progress.fractionCompleted)
                //                self?.progressLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
            }
        }
        
        task.resume()
    }
}
