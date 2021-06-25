//
//  ParentPostViewController.swift
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
import QuickLook

class ParentPostViewController: UIViewController, DocumentDelegate, QLPreviewControllerDataSource {
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
    var buttonPanel: UIStackView!
    var cameraButton: UIButton!
    var imagePickerButton: UIButton!
    var documentPickerButton: UIButton!
    var imageNameArr = [String]() {
        didSet {
            if imageNameArr.count > 0 {
                imagePreviewVC.view.isHidden = false
                imagePreviewConstraintHeight.constant = 170
                UIView.animate(withDuration: 1) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            } else {
                imagePreviewVC.view.isHidden = true
                imagePreviewConstraintHeight.constant = 0
                UIView.animate(withDuration: 1) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
                
            }
        }
    }
    var imagePreviewVC: ImagePreviewViewController!
    var postButton: UIButton!
    let transactionService = TransactionService()
    var alert: Alerts!
    var imageAddresses = [String]()
    let userDefaults = UserDefaults.standard
    var observation: NSKeyValueObservation?
    var userId: String!
    var documentId: String!
    var socketDelegate: SocketDelegate!
    var documentPicker: DocumentPicker!
    var url: URL!
    var imagePreviewConstraintHeight: NSLayoutConstraint!
    var documentArr: [Document]!
    
    let pvc = MyPickerVC()
    /// MyDoneButtonVC
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
        deleteAllFiles()
    }
 
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        imagePreviewVC.data = imageNameArr
        
        if observation != nil {
            observation?.invalidate()
        }
    }
}

extension ParentPostViewController {
    
    @objc func configureUI() {
        title = "Post"
        self.hideKeyboardWhenTappedAround()
        alert = Alerts()
        
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
        
        buttonPanel = UIStackView()
        buttonPanel.axis = .horizontal
        buttonPanel.distribution = .fillEqually
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonPanel)
        
        let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .medium)
        let cameraImage = UIImage(systemName: "camera.circle")!
            .withTintColor(UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), renderingMode: .alwaysOriginal)
            .withConfiguration(configuration)
        cameraButton = UIButton.systemButton(with: cameraImage, target: self, action: #selector(buttonPressed))
        cameraButton.tag = 1
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addArrangedSubview(cameraButton)
        
        var imageName: String!
        if #available(iOS 14.0, *) {
            imageName = "rectangle.fill.on.rectangle.fill.circle"
        } else {
            imageName = "person.crop.circle.fill.badge.plus"
        }
        
        let pickerImage = UIImage(systemName: imageName)!
            .withTintColor(UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), renderingMode: .alwaysOriginal)
            .withConfiguration(configuration)
        imagePickerButton = UIButton.systemButton(with: pickerImage, target: self, action: #selector(buttonPressed(_:)))
        imagePickerButton.tag = 2
        imagePickerButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addArrangedSubview(imagePickerButton)
        
        let documentPickerImage = UIImage(systemName: "doc.circle")!
            .withTintColor(UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), renderingMode: .alwaysOriginal)
            .withConfiguration(configuration)
        documentPickerButton = UIButton.systemButton(with: documentPickerImage, target: self, action: #selector(buttonPressed(_:)))
        documentPickerButton.tag = 6
        documentPickerButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addArrangedSubview(documentPickerButton)
        
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
        imagePreviewConstraintHeight = imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            
            titleTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),
            titleTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            
            priceLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            priceLabel.heightAnchor.constraint(equalToConstant: 50),
            priceLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            
            priceTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            priceTextField.heightAnchor.constraint(equalToConstant: 50),
            priceTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            priceTextField.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 0),
            
            descLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            descLabel.heightAnchor.constraint(equalToConstant: 50),
            descLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: 20),
            
            descTextView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            descTextView.heightAnchor.constraint(equalToConstant: 100),
            descTextView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            descTextView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 0),
            
            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTitleLabel.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 20),
            
            idTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idTextField.heightAnchor.constraint(equalToConstant: 50),
            idTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTextField.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
            
            pickerTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            pickerTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            pickerTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pickerTitleLabel.topAnchor.constraint(equalTo: idTextField.bottomAnchor, constant: 20),
            
            pickerLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            pickerLabel.heightAnchor.constraint(equalToConstant: 50),
            pickerLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pickerLabel.topAnchor.constraint(equalTo: pickerTitleLabel.bottomAnchor, constant: 0),
            
            tagTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            tagTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            tagTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            tagTitleLabel.topAnchor.constraint(equalTo: pickerLabel.bottomAnchor, constant: 20),
            
            tagContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
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
            
            buttonPanel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            buttonPanel.heightAnchor.constraint(equalToConstant: 80),
            buttonPanel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            buttonPanel.topAnchor.constraint(equalTo: tagContainerView.bottomAnchor, constant: 40),
//
//            cameraButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
//            cameraButton.heightAnchor.constraint(equalToConstant: 80),
//            cameraButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
//
//            imagePickerButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
//            imagePickerButton.heightAnchor.constraint(equalToConstant: 80),
//            imagePickerButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
            
            cameraButton.widthAnchor.constraint(equalToConstant: 80),
            cameraButton.heightAnchor.constraint(equalToConstant: 80),

            imagePickerButton.widthAnchor.constraint(equalToConstant: 80),
            imagePickerButton.heightAnchor.constraint(equalToConstant: 80),
            
            documentPickerButton.widthAnchor.constraint(equalToConstant: 80),
            documentPickerButton.heightAnchor.constraint(equalToConstant: 80),

            imagePreviewVC.view.topAnchor.constraint(equalTo: buttonPanel.bottomAnchor, constant: 20),
            imagePreviewVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imagePreviewVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imagePreviewConstraintHeight,
            
            postButton.topAnchor.constraint(equalTo: imagePreviewVC.view.bottomAnchor, constant: 40),
            postButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            postButton.heightAnchor.constraint(equalToConstant: 50),
            postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    // MARK: - buttonPressed
    @objc func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
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
                case 5:
                    configureProgress()
                case 6:
                    documentPicker = DocumentPicker(presentationController: self, delegate: self)
                    documentPicker.displayPicker()
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
    
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.url as QLPreviewItem
//        let previewItem = CustomPreviewItem(url: <Your URL>, title: <Title>)
//        return previewItem as QLPreviewItem
    }
    
    // MARK: - didPickDocument
    func didPickDocument(document: Document?) {
        if let pickedDoc = document {
            let fileURL = pickedDoc.fileURL
            url = fileURL
            
            var retrievedData: Data!
            do {
                retrievedData = try Data(contentsOf: fileURL)
            } catch {
                alert.show(error, for: self)
            }
            
            let preview = PreviewPDFViewController()
            preview.dataSource = self
//            preview.buttonAction = { [weak self] in
//                self?.dismiss(animated: true, completion: nil)

//                if let data = retrievedData {
//                    print("document data", data)
//                    
//                    self?.alert.withTextField(delegate: self!, controller: self!, data: data, completion: { (title, password) in
//                        //                        self?.uploadFile(fileData: data, title: title, password: password)
//
//                        self?.presendAnimation(completion: {
//                            self?.uploadData(data: data, title: title, password: password)
//                        })
//                    })
//                }
//            }
            present(preview, animated: true, completion: nil)
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
extension ParentPostViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
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

extension ParentPostViewController: PreviewDelegate {
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

extension ParentPostViewController {
    // MARK: - checkExistingId
    func checkExistingId(id: String, completion: @escaping (Bool) -> Void) {
        FirebaseService.shared.db.collection("post")
            .whereField("itemIdentifier", isEqualTo: id)
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
    
    @objc func configureProgress() {
        
    }
    
    func deleteAllFiles() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                print("fileURL", fileURL)
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  {
            print(error)
        }
    }
}

extension ParentPostViewController: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        showKeyboard = false
        mdbvc.view.alpha = 0
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        showKeyboard = false
        mdbvc.view.alpha = 0
    }
}

extension ParentPostViewController {
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
    
//                let from = ABI.Element.Event.Input(name: "from", type: .address, indexed: true)
//                let to = ABI.Element.Event.Input(name: "to", type: .address, indexed: true)
//                let tokenId = ABI.Element.Event.Input(name: "tokenId", type: .uint(bits: 256), indexed: true)
//                let abiEvent = ABI.Element.Event(name: "Transfer", inputs: [from, to, tokenId], anonymous: false)
//                print("abiEvent", abiEvent)
//
//                let eventLogData = Data(base64Encoded: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef")
//                let eventLogTopics = [
//                    Data(base64Encoded: "0x0000000000000000000000000000000000000000000000000000000000000000")!,
//                    Data(base64Encoded: "0x0000000000000000000000006879f0a123056b5bb56c7e787cf64a67f3a16a71")!,
//                    Data(base64Encoded: "0x0000000000000000000000000000000000000000000000000000000000000030")!
//                ]
//
//                let decodedLog = ABIDecoder.decodeLog(event: abiEvent, eventLogTopics: eventLogTopics, eventLogData: eventLogData!)
//                print("decodedLog", decodedLog as Any)
    }
}

extension ParentPostViewController: MessageDelegate, ImageUploadable {
    // MARK: - didReceiveMessage
    @objc func didReceiveMessage(topics: [String]) {
        // get the token ID to be uploaded to Firestore
        getTokenId(topics: topics) { [weak self](tokenId, error) in
            if let error = error {
                self?.alert.showDetail("Token ID Fetch Error", with: error.localizedDescription, for: self)
            }
            
            if let tokenId = tokenId {
                FirebaseService.shared.db.collection("post").document(self!.documentId).updateData([
                    "tokenId": tokenId
                ]) { (error) in
                    if let error = error {
                        self?.alert.showDetail("Error Loading TokenID", with: error.localizedDescription, for: self)
                    } else {
                        defer {
                            let update: [String: PostProgress] = ["update": .images]
                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                            self?.titleTextField.text?.removeAll()
                            self?.priceTextField.text?.removeAll()
                            self?.descTextView.text?.removeAll()
                            self?.idTextField.text?.removeAll()
                            self?.pickerLabel.text?.removeAll()
                            self?.tagTextField.tokens.removeAll()
                            
//                            self?.alert.showDetail("Success", with: "You have successfully minted a token", for: self) {
//                                self?.titleTextField.text?.removeAll()
//                                self?.priceTextField.text?.removeAll()
//                                self?.descTextView.text?.removeAll()
//                                self?.idTextField.text?.removeAll()
//                                self?.pickerLabel.text?.removeAll()
//                                self?.tagTextField.tokens.removeAll()
//                            }
                        }
                        // disconnect socket
                        self?.socketDelegate.disconnectSocket()
                        var imageCount: Int = 0
                        // upload images and delete them afterwards
                        if self!.imageNameArr.count > 0, let imageNameArr = self?.imageNameArr {
                            defer {
                                let update: [String: PostProgress] = ["update": .images]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                            }
                            for image in imageNameArr {
                                self?.uploadImages(image: image, userId: self!.userId) {(url) in
                                    defer {
                                        print("after getting url")
                                    }
                                    FirebaseService.shared.db.collection("post").document(self!.documentId).updateData([
                                        "images": FieldValue.arrayUnion(["\(url)"])
                                    ], completion: { (error) in
                                        defer {
                                            /// this runs last. place the success alert here. use the same image counter to check if all the images have been fulfilled
                                            /// there has to be a success alert for if you don't have images to upload
                                            print("after update data")
                                        }
                                        if let error = error {
                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                                        }
                                    })
                                }
                                imageCount += 1
                                if imageCount == imageNameArr.count, let ipvc = self?.imagePreviewVC {
                                    self?.imageNameArr.removeAll()
                                    ipvc.data.removeAll()
                                    ipvc.collectionView.reloadData()
                                    for imageName in imageNameArr {
                                        self?.deleteFile(fileName: imageName)
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

extension ParentPostViewController {
    func saveFile(fileName: String) {
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
            let data = try Data(contentsOf: fileURL)
            try data.write(to: fileURL)
        } catch let error {
            print("error saving file with error", error)
        }
    }
}

// MARK: - QLPreviewItem
class CustomPreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL, title: String?) {
        previewItemURL = url
        previewItemTitle = title
    }
}

// MARK: - QuickLookThumbnailing
extension CustomPreviewItem {
    func generateThumbnail(completion: @escaping (UIImage) -> Void) {
        // 1
        let size = CGSize(width: 128, height: 102)
        let scale = UIScreen.main.scale
        // 2
        let request = QLThumbnailGenerator.Request(
            fileAt: previewItemURL!,
            size: size,
            scale: scale,
            representationTypes: .all)
        
        // 3
        let generator = QLThumbnailGenerator.shared
        generator.generateBestRepresentation(for: request) { thumbnail, error in
            if let thumbnail = thumbnail {
                completion(thumbnail.uiImage)
            } else if let error = error {
                // Handle error
                print(error)
            }
        }
    }
}
