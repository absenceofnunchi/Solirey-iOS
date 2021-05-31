//
//  PostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit
import FirebaseFirestore
import Firebase
import web3swift

class PostViewController: UIViewController {
    var scrollView: UIScrollView!
    var titleLabel: UILabel!
    var titleTextField: UITextField!
    var priceLabel: UILabel!
    var priceTextField: UITextField!
    var descLabel: UILabel!
    var descTextView: UITextView!
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
    
    let pvc = MyPickerVC()
    let mdbvc = MyDoneButtonVC()
    var showKeyboard = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
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

extension PostViewController {
    // MARK: - configureNavigationBar
    func configureNavigationBar() {
        // navigation controller
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .white
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            
        } else {
            self.navigationController?.navigationBar.barTintColor = .white
            self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    func configureUI() {
        title = "Post"
        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
        
        scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 1000)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.fill()
        
        titleLabel = createLabel(text: "Title")
        scrollView.addSubview(titleLabel)
        
        titleTextField = createTextField()
        scrollView.addSubview(titleTextField)
        
        priceLabel = createLabel(text: "Price")
        scrollView.addSubview(priceLabel)
        
        priceTextField = createTextField()
        scrollView.addSubview(priceTextField)
        
        descLabel = createLabel(text: "Description")
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
        
        pickerTitleLabel = createLabel(text: "Category")
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
        
        tagTitleLabel = createLabel(text: "Tags")
        scrollView.addSubview(tagTitleLabel)
        
        tagTextField = UISearchTextField()
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
    func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 100),
            
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

            pickerTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.8),
            pickerTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            pickerTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pickerTitleLabel.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 20),
            
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

    func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .rounded(ofSize: label.font.pointSize, weight: .bold)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func createTextField(placeHolder: String? = nil) -> UITextField {
        let textField = UITextField()
        textField.setLeftPaddingPoints(10)
        textField.delegate = self
        textField.placeholder = placeHolder ?? ""
        textField.layer.borderWidth = 0.7
        textField.layer.cornerRadius = 5
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
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
                    if let userId = userDefaults.string(forKey: "userId") {
                        self.mint(userId: userId)
                    } else {
                        self.alert.showDetail("Authorization", with: "You need to be logged in!", for: self)
                    }
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
extension PostViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
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

extension PostViewController {
    // MARK: - addKeyboardObserver
    func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // This method will notify when keyboard appears/ dissapears
    @objc func keyboardNotifications(notification: NSNotification) {
        
        var txtFieldY : CGFloat = 0.0  //Using this we will calculate the selected textFields Y Position
        let spaceBetweenTxtFieldAndKeyboard : CGFloat = 5.0 //Specify the space between textfield and keyboard
        
        
        var frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        if let activeTextField = UIResponder.currentFirst() as? UITextField ?? UIResponder.currentFirst() as? UITextView {
            // Here we will get accurate frame of textField which is selected if there are multiple textfields
            frame = self.view.convert(activeTextField.frame, from:activeTextField.superview)
            txtFieldY = frame.origin.y + frame.size.height
        }
        
        if let userInfo = notification.userInfo {
            // here we will get frame of keyBoard (i.e. x, y, width, height)
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyBoardFrameY = keyBoardFrame!.origin.y
            let keyBoardFrameHeight = keyBoardFrame!.size.height
            
            var viewOriginY: CGFloat = 0.0
            //Check keyboards Y position and according to that move view up and down
            if keyBoardFrameY >= UIScreen.main.bounds.size.height {
                viewOriginY = 0.0
            } else {
                // if textfields y is greater than keyboards y then only move View to up
                if txtFieldY >= keyBoardFrameY {
                    
                    viewOriginY = (txtFieldY - keyBoardFrameY) + spaceBetweenTxtFieldAndKeyboard
                    
                    //This condition is just to check viewOriginY should not be greator than keyboard height
                    // if its more than keyboard height then there will be black space on the top of keyboard.
                    if viewOriginY > keyBoardFrameHeight { viewOriginY = keyBoardFrameHeight }
                }
            }
            
            //set the Y position of view
            self.view.frame.origin.y = -viewOriginY
        }
    }
}

extension PostViewController {
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

extension PostViewController: PreviewDelegate {
    // MARK: - configureImagePreview
    func configureImagePreview() {
        imagePreviewVC = ImagePreviewViewController()
        imagePreviewVC.data = imageNameArr
        imagePreviewVC.delegate = self
        imagePreviewVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(imagePreviewVC)
        view.addSubview(imagePreviewVC.view)
        imagePreviewVC.view.frame = view.bounds
        imagePreviewVC.didMove(toParent: self)
    }
    
    // MARK: - didDeleteImage
    func didDeleteImage(imageName: String) {
        imageNameArr = imageNameArr.filter { $0 != imageName }
    }
}

extension PostViewController {
    func mint2(userId: String) {
        
//        let usersRef = self.db.collection("users")
//        usersRef.document(userId).collection("post").addDocument(data: [
//            "key": "value"
//        ]) { (error) in
//            print("error", error?.localizedDescription as Any)
//        }
        
        FirebaseService.sharedInstance.db.collection(userId).document("post").collection("mint").addDocument(data: [
            "key": "value"
        ]) { (error) in
            if let error = error {
                print("error", error.localizedDescription)
            }
        }
    }
    
    // MARK: - mint
    func mint(userId: String) {
        //MARK: - create purchase contract
        guard let price = priceTextField.text,
              !price.isEmpty,
              let title = titleTextField.text,
              !title.isEmpty,
              let desc = descTextView.text,
              !desc.isEmpty,
              let category = pickerLabel.text,
              !category.isEmpty,
              tagTextField.tokens.count > 0 else {
            self.alert.showDetail("Incomplete", with: "All fields must be filled.", for: self)
            return
        }
        
        var tokensArr = [String]()
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = title.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
        let searchItems = strippedString.components(separatedBy: " ") as [String]
        tokensArr.append(contentsOf: searchItems)
        
        for token in tagTextField.tokens {
            if let retrievedToken = token.representedObject as? String {
                tokensArr.append(retrievedToken.lowercased())
            }
        }
        
        transactionService.prepareTransactionForNewContract(value: String(price), completion: { [weak self](transaction, error) in
            if let error = error {
                switch error {
                    case .contractLoadingError:
                        self?.alert.showDetail("Error", with: "Contract Loading Error", for: self!)
                    case .createTransactionIssue:
                        self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self!)
                    default:
                        self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self!)
                }
            }
            
            if let transaction = transaction {
                let detailVC = DetailViewController(height: 250, isTextField: true)
                detailVC.titleString = "Enter your password"
                detailVC.buttonAction = { vc in
                    if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                        self?.dismiss(animated: true, completion: {
                            DispatchQueue.global().async {
                                do {
                                    // create new contract
                                    let result = try transaction.send(password: password, transactionOptions: nil)
                                    // minting
                                    self?.transactionService.prepareTransactionForMinting { [self] (mintTransaction, mintError) in
                                        if let error = mintError {
                                            switch error {
                                                case .contractLoadingError:
                                                    self?.alert.showDetail("Error", with: "Contract Loading Error", for: self!)
                                                case .createTransactionIssue:
                                                    self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self!)
                                                default:
                                                    self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self!)
                                            }
                                        }

                                        if let mintTransaction = mintTransaction {
                                            do {
                                                let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)

                                                // firebase
                                                let senderAddress = result.transaction.sender!.address
                                                
                                                let postId = UUID().uuidString
                                                let ref = FirebaseService.sharedInstance.db.collection("mint")
                                                let id = ref.document().documentID
                                                
                                                FirebaseService.sharedInstance.db.collection("post").document(id).setData([
                                                    "postId": postId,
                                                    "userId": userId,
                                                    "senderAddress": senderAddress,
                                                    "escrowHash": result.hash,
                                                    "mintHash": mintResult.hash,
                                                    "mintNonce": String(mintResult.transaction.nonce.description),
                                                    "escrowNonce": String(result.transaction.nonce.description),
                                                    "date": Date(),
                                                    "title": title,
                                                    "description": desc,
                                                    "price": price,
                                                    "category": category,
                                                    "status": PostStatus.ready.rawValue,
                                                    "tags": tokensArr
                                                ]) { (error) in
                                                    if let error = error {
                                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self!) {
                                                            for image in self!.imageNameArr {
                                                                self?.deleteFile(fileName: image)
                                                            }
                                                        }
                                                    } else {
                                                        self?.alert.showDetail("Success", with: "You have successfully minted a token", for: self!) {
                                                            if self!.imageNameArr.count > 0, let imageNameArr = self?.imageNameArr {
                                                                for image in imageNameArr {
                                                                    self?.uploadImages(image: image, userId: userId, id: id)
                                                                }
                                                            }
                                                        }
                                                        
//                                                        let detailVC = DetailViewController(height: 250)
//                                                        detailVC.titleString = "Success"
//                                                        detailVC.message = "You have successfully minted a token"
//                                                        detailVC.buttonAction = { vc in
//                                                            self?.dismiss(animated: true, completion: nil)
//                                                        }
//                                                        self?.present(detailVC, animated: true, completion: {
//                                                            if self!.imageNameArr.count > 0, let imageNameArr = self?.imageNameArr {
//                                                                for image in imageNameArr {
//                                                                    self?.uploadImages(image: image, userId: userId, id: id)
//                                                                }
//                                                            }
//                                                        })
                                                    }
                                                }
                                            } catch Web3Error.nodeError(let desc) {
                                                if let index = desc.firstIndex(of: ":") {
                                                    let newIndex = desc.index(after: index)
                                                    let newStr = desc[newIndex...]
                                                    self?.alert.showDetail("Alert", with: String(newStr), for: self!)
                                                }
                                            } catch {
                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self!) {
                                                    for image in self!.imageNameArr {
                                                        self?.deleteFile(fileName: image)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } catch Web3Error.nodeError(let desc) {
                                    if let index = desc.firstIndex(of: ":") {
                                        let newIndex = desc.index(after: index)
                                        let newStr = desc[newIndex...]
                                        DispatchQueue.main.async {
                                            self?.alert.showDetail("Alert", with: String(newStr), for: self!)
                                        }
                                    }
                                } catch {
                                    self?.alert.showDetail("Error", with: error.localizedDescription, for: self!) {
                                        for image in self!.imageNameArr {
                                            self?.deleteFile(fileName: image)
                                        }
                                    }
                                }
                            }
                        })
                    }
                }
                self?.present(detailVC, animated: true, completion: {
                    self?.titleTextField.text?.removeAll()
                    self?.priceTextField.text?.removeAll()
                    self?.descTextView.text?.removeAll()
                    self?.pickerLabel.text?.removeAll()
                    self?.tagTextField.tokens.removeAll()
                })
            }
        })
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

extension PostViewController: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        showKeyboard = false
        mdbvc.view.alpha = 0
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        showKeyboard = false
        mdbvc.view.alpha = 0
    }
}

// password 111111
// 0x0b6fcFEc0133E77DcE6021Ff79BeFAd4b3af7564

//transactionService.prepareTransactionForNewContract(value: String(price), completion: { [weak self](transaction, error) in
//    if let error = error {
//        switch error {
//            case .contractLoadingError:
//                self?.alert.showDetail("Error", with: "Contract Loading Error", for: self!)
//            case .createTransactionIssue:
//                self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self!)
//            default:
//                self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self!)
//        }
//    }
//
//    if let transaction = transaction {
//        let detailVC = DetailViewController(height: 250, isTextField: true)
//        detailVC.titleString = "Enter your password"
//        detailVC.buttonAction = { vc in
//            if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
//                self?.dismiss(animated: true, completion: {
//                    DispatchQueue.global().async {
//                        do {
//                            let result = try transaction.send(password: password, transactionOptions: nil)
//                            // minting
//                            self?.transactionService.prepareTransactionForMinting { [self] (mintTransaction, mintError) in
//                                if let error = mintError {
//                                    switch error {
//                                        case .contractLoadingError:
//                                            self?.alert.showDetail("Error", with: "Contract Loading Error", for: self!)
//                                        case .createTransactionIssue:
//                                            self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self!)
//                                        default:
//                                            self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self!)
//                                    }
//                                }
//
//                                if let mintTransaction = mintTransaction {
//                                    do {
//                                        let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
//                                        print("mintResult", mintResult)
//
//                                        // firebase
//                                        let senderAddress = result.transaction.sender!.address
//
//                                        let postId = UUID().uuidString
//
//                                        FirebaseService.sharedInstance.db.collection("escrow").addDocument(data: [
//                                            "postId": postId,
//                                            "userId": userId,
//                                            "senderAddress": senderAddress,
//                                            "transactionHash": result.hash,
//                                            "nonce": String(result.transaction.nonce.description),
//                                            "date": Date(),
//                                            "title": title,
//                                            "description": desc,
//                                            "price": price,
//                                            "category": category,
//                                        ], completion: { (error) in
//                                            if let error = error {
//                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self!) {
//                                                    for image in self!.imageNameArr {
//                                                        self?.deleteFile(fileName: image)
//                                                    }
//                                                }
//                                            } else {
//
//                                                let ref = FirebaseService.sharedInstance.db.collection("mint")
//                                                let id = ref.document().documentID
//
//                                                FirebaseService.sharedInstance.db.collection("mint").document(id).setData([
//                                                    "postId": postId,
//                                                    "type": "mint",
//                                                    "userId": userId,
//                                                    "senderAddress": senderAddress,
//                                                    "transactionHash": mintResult.hash,
//                                                    "nonce": String(mintResult.transaction.nonce.description),
//                                                    "date": Date(),
//                                                    "title": title,
//                                                    "description": desc,
//                                                    "price": price,
//                                                    "category": category
//                                                ]) { (error) in
//                                                    if let error = error {
//                                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self!) {
//                                                            for image in self!.imageNameArr {
//                                                                self?.deleteFile(fileName: image)
//                                                            }
//                                                        }
//                                                    } else {
//                                                        let detailVC = DetailViewController(height: 250)
//                                                        detailVC.titleString = "Success"
//                                                        detailVC.message = "You have successfully minted a token"
//                                                        detailVC.buttonAction = { vc in
//                                                            self?.dismiss(animated: true, completion: nil)
//                                                        }
//                                                        self?.present(detailVC, animated: true, completion: {
//                                                            if self!.imageNameArr.count > 0, let imageNameArr = self?.imageNameArr {
//                                                                for image in imageNameArr {
//                                                                    self?.uploadImages(image: image, userId: userId, id: id)
//                                                                }
//                                                            }
//                                                        })
//                                                    }
//                                                }
//                                            }
//                                        })
//                                    } catch {
//                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self!) {
//                                            for image in self!.imageNameArr {
//                                                self?.deleteFile(fileName: image)
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        } catch {
//                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self!) {
//                                for image in self!.imageNameArr {
//                                    self?.deleteFile(fileName: image)
//                                }
//                            }
//                        }
//                    }
//                })
//            }
//        }
//        self?.present(detailVC, animated: true, completion: nil)
//    }
//})
