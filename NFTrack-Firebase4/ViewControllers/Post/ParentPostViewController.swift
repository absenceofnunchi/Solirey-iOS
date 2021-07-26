//
//  ParentPostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-01.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import Firebase
import web3swift
import QuickLook

class ParentPostViewController: UIViewController, ButtonPanelConfigurable {
    let db = FirebaseService.shared.db!
    var scrollView: UIScrollView!
    var titleLabel: UILabel!
    var titleTextField: UITextField!
    var priceLabel: UILabel!
    var priceTextField: UITextField!
    var priceLabelConstraintHeight: NSLayoutConstraint!
    var priceTextFieldConstraintHeight: NSLayoutConstraint!
    var descLabel: UILabel!
    var descTextView: UITextView!
    var deliveryMethodTitleLabel: UILabel!
    var deliveryInfoButton: UIButton!
    var deliveryMethodLabel: UILabel!
    var paymentMethodTitleLabel: UILabel!
    var paymentInfoButton: UIButton!
    var paymentMethodLabel: UILabel!
    var saleMethodInfoButton: UIButton!
    var saleMethodTitleLabel: UILabel!
    var saleMethodLabelContainer: UIView!
    var saleMethodContainerConstraintHeight: NSLayoutConstraint!
    var saleMethodLabel: UILabel!
    var idTitleLabel: UILabel!
    var idContainerView: UIView!
    var idTextField: UITextField!
    var scanButton: UIButton!
    var pickerTitleLabel: UILabel!
    var pickerLabel: UILabelPadding!
    var tagContainerView: UIView!
    var tagTitleLabel: UILabel!
    var tagTextField: UISearchTextField!
    var addTagButton: UIButton!
    var buttonPanel: UIStackView!
    var previewDataArr: [PreviewData]! {
        didSet {
            /// shows the image preview when an image or a doc is selected
            if previewDataArr.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.imagePreviewVC.view.isHidden = false
                    self?.imagePreviewConstraintHeight.constant = self!.IMAGE_PREVIEW_HEIGHT
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    } completion: { (_) in
                        guard let `self` = self else { return }
                        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW)
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.imagePreviewVC.view.isHidden = true
                    self?.imagePreviewConstraintHeight.constant = 0
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    } completion: { (_) in
                        guard let `self` = self else { return }
                        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
                    }
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
    var progressModal: ProgressModalViewController!
    var constraints: [NSLayoutConstraint]!
    var panelButtons: [PanelButton] {
        return []
    }
    
    /// payment method
    let deliveryMethodPicker = MyPickerVC(currentPep: DeliveryMethod.shipping.rawValue, pep: [DeliveryMethod.shipping.rawValue, DeliveryMethod.inPerson.rawValue])
    /// category picker
    let pvc = MyPickerVC(currentPep: Category.electronics.asString(), pep: Category.getAll())

    /// done button for the picker
    let mdbvc = MyDoneButtonVC()
    var showKeyboard = false
    
    /// to determine which picker to invoke
    var pickerTag: Int!
    let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .medium)
    var pickerImageName: String! {
        var imageName: String!
        if #available(iOS 14.0, *) {
            imageName = "rectangle.fill.on.rectangle.fill.circle"
        } else {
            imageName = "tv.circle"
        }
        return imageName
    }
    
    let SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT: CGFloat = 1650
    let IMAGE_PREVIEW_HEIGHT: CGFloat = 180
    lazy var SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW: CGFloat = SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT + IMAGE_PREVIEW_HEIGHT
    
    var escrowHash: String!
    var mintHash: String!
    var senderAddress: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar(vc: self)
        configureUI()
        configureImagePreview()
        setConstraints()
    }
 

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// whenever the image picker is dismissed, the collection view has to be updated
        imagePreviewVC.data = previewDataArr
        
        if observation != nil {
            observation?.invalidate()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if observation != nil {
            observation?.invalidate()
        }
        
        if socketDelegate != nil {
            socketDelegate.disconnectSocket()
        }
    }
    
    /// Tangible asset: user registers
    /// Digital asset: image is hashed
    func createIDField() {}
    
    /// no scanner for digital asset
    func setIDFieldConstraints() {}
    
    /// where the subclasses override the ImagePreview post type.
    /// This has to be done before setConstraints
    func configureImagePreview() {}
}

extension ParentPostViewController {
    @objc func configureUI() {
        title = "Post"
        previewDataArr = [PreviewData]()
        self.hideKeyboardWhenTappedAround()
        alert = Alerts()
        constraints = [NSLayoutConstraint]()
        
        scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
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
        descTextView.font = UIFont.preferredFont(forTextStyle: .body)
        descTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descTextView)
        
        deliveryMethodTitleLabel = createTitleLabel(text: "Delivery Method")
        deliveryMethodTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(deliveryMethodTitleLabel)
        
        guard let infoImage = UIImage(systemName: "info.circle") else { return }
        deliveryInfoButton = UIButton.systemButton(with: infoImage, target: self, action: #selector(buttonPressed(_:)))
        deliveryInfoButton.translatesAutoresizingMaskIntoConstraints = false
        deliveryMethodTitleLabel.addSubview(deliveryInfoButton)
        
        deliveryMethodLabel = createLabel(text: "")
        scrollView.addSubview(deliveryMethodLabel)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
        deliveryMethodLabel.addGestureRecognizer(tap)
        
        paymentMethodTitleLabel = createTitleLabel(text: "Payment Method")
        paymentMethodTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(paymentMethodTitleLabel)
        
        saleMethodTitleLabel = createTitleLabel(text: "Sale Format")
        saleMethodTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(saleMethodTitleLabel)
        
        guard let saleInfoImage = UIImage(systemName: "info.circle") else { return }
        saleMethodInfoButton = UIButton.systemButton(with: saleInfoImage, target: self, action: #selector(buttonPressed(_:)))
        saleMethodInfoButton.translatesAutoresizingMaskIntoConstraints = false
        saleMethodTitleLabel.addSubview(saleMethodInfoButton)
        
        saleMethodLabelContainer = UIView()
        saleMethodLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(saleMethodLabelContainer)
        
        saleMethodLabel = createLabel(text: "")
        saleMethodLabelContainer.addSubview(saleMethodLabel)
        
        guard let paymentInfoImage = UIImage(systemName: "info.circle") else { return }
        paymentInfoButton = UIButton.systemButton(with: paymentInfoImage, target: self, action: #selector(buttonPressed(_:)))
        paymentInfoButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodTitleLabel.addSubview(paymentInfoButton)
        
        paymentMethodLabel = createLabel(text: "")
        scrollView.addSubview(paymentMethodLabel)
        
        idTitleLabel = createTitleLabel(text: "Unique Identifier")
        scrollView.addSubview(idTitleLabel)
        
        createIDField()
        
        pickerTitleLabel = createTitleLabel(text: "Category")
        scrollView.addSubview(pickerTitleLabel)
        
        pickerLabel = createLabel(text: "")
        scrollView.addSubview(pickerLabel)
        
        self.mdbvc.delegate = self
        
        let categoryLabelTap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
        pickerLabel.addGestureRecognizer(categoryLabelTap)
        
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

        createButtonPanel(panelButtons: panelButtons) { (buttonsArr) in
            buttonsArr.forEach { (button) in
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            }
        }
        
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
        priceLabelConstraintHeight = priceLabel.heightAnchor.constraint(equalToConstant: 50)
        priceTextFieldConstraintHeight = priceTextField.heightAnchor.constraint(equalToConstant: 50)
        saleMethodContainerConstraintHeight = saleMethodLabelContainer.heightAnchor.constraint(equalToConstant: 50)
        imagePreviewConstraintHeight = imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 0)
        constraints.append(contentsOf: [
            titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            
            titleTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),
            titleTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            
            priceLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            priceLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            priceLabelConstraintHeight,
            
            priceTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            priceTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            priceTextField.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 0),
            priceTextFieldConstraintHeight,
            
            descLabel.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: 20),
            descLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            descLabel.heightAnchor.constraint(equalToConstant: 50),
            descLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            descTextView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            descTextView.heightAnchor.constraint(equalToConstant: 150),
            descTextView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            descTextView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 0),
            
            deliveryMethodTitleLabel.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 20),
            deliveryMethodTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            deliveryMethodTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            deliveryMethodTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            deliveryInfoButton.trailingAnchor.constraint(equalTo: deliveryMethodTitleLabel.trailingAnchor),
            deliveryInfoButton.heightAnchor.constraint(equalToConstant: 50),
            
            deliveryMethodLabel.topAnchor.constraint(equalTo: deliveryMethodTitleLabel.bottomAnchor, constant: 0),
            deliveryMethodLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            deliveryMethodLabel.heightAnchor.constraint(equalToConstant: 50),
            deliveryMethodLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            saleMethodTitleLabel.topAnchor.constraint(equalTo: deliveryMethodLabel.bottomAnchor, constant: 20),
            saleMethodTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            saleMethodTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            saleMethodTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            saleMethodInfoButton.trailingAnchor.constraint(equalTo: saleMethodTitleLabel.trailingAnchor),
            saleMethodInfoButton.heightAnchor.constraint(equalToConstant: 50),
            
            saleMethodLabelContainer.topAnchor.constraint(equalTo: saleMethodTitleLabel.bottomAnchor, constant: 0),
            saleMethodLabelContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            saleMethodLabelContainer.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            saleMethodContainerConstraintHeight,
            
            saleMethodLabel.topAnchor.constraint(equalTo: saleMethodLabelContainer.topAnchor),
            saleMethodLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
            saleMethodLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
            saleMethodLabel.heightAnchor.constraint(equalToConstant: 50),
            
            paymentMethodTitleLabel.topAnchor.constraint(equalTo: saleMethodLabelContainer.bottomAnchor, constant: 20),
            paymentMethodTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            paymentMethodTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            paymentMethodTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            paymentInfoButton.trailingAnchor.constraint(equalTo: paymentMethodTitleLabel.trailingAnchor),
            paymentInfoButton.heightAnchor.constraint(equalToConstant: 50),
            
            paymentMethodLabel.topAnchor.constraint(equalTo: paymentMethodTitleLabel.bottomAnchor, constant: 0),
            paymentMethodLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            paymentMethodLabel.heightAnchor.constraint(equalToConstant: 50),
            paymentMethodLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            // category
            pickerTitleLabel.topAnchor.constraint(equalTo: paymentMethodLabel.bottomAnchor, constant: 20),
            pickerTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            pickerTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            pickerTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            pickerLabel.topAnchor.constraint(equalTo: pickerTitleLabel.bottomAnchor, constant: 0),
            pickerLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            pickerLabel.heightAnchor.constraint(equalToConstant: 50),
            pickerLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            tagTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            tagTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            tagTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            tagTitleLabel.topAnchor.constraint(equalTo: pickerLabel.bottomAnchor, constant: 20),
            
            tagContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            tagContainerView.heightAnchor.constraint(equalToConstant: 50),
            tagContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            tagContainerView.topAnchor.constraint(equalTo: tagTitleLabel.bottomAnchor, constant: 0),
            
            tagTextField.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.75),
            tagTextField.heightAnchor.constraint(equalToConstant: 50),
            tagTextField.leadingAnchor.constraint(equalTo: tagContainerView.leadingAnchor),
            tagTextField.topAnchor.constraint(equalTo: tagContainerView.topAnchor),
            
            addTagButton.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.2),
            addTagButton.heightAnchor.constraint(equalToConstant: 50),
            addTagButton.trailingAnchor.constraint(equalTo: tagContainerView.trailingAnchor),
            addTagButton.topAnchor.constraint(equalTo: tagContainerView.topAnchor),
        ])
        
        setIDFieldConstraints()
        setButtonPanelConstraints(topView: idContainerView)
        
        constraints.append(contentsOf: [
            imagePreviewVC.view.topAnchor.constraint(equalTo: buttonPanel.bottomAnchor, constant: 20),
            imagePreviewVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            imagePreviewVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imagePreviewConstraintHeight,
            
            postButton.topAnchor.constraint(equalTo: imagePreviewVC.view.bottomAnchor, constant: 40),
            postButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            postButton.heightAnchor.constraint(equalToConstant: 50),
            postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - buttonPressed
    @objc func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        if previewDataArr.count < 6 {
            switch sender.tag {
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
                case 7:
                    let scannerVC = ScannerViewController()
                    scannerVC.delegate = self
                    scannerVC.modalPresentationStyle = .fullScreen
                    self.present(scannerVC, animated: true, completion: nil)
                case 8:
                    let vc = UIImagePickerController()
                    vc.sourceType = .camera
                    vc.allowsEditing = true
                    vc.delegate = self
                    present(vc, animated: true)
                case 9:
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.allowsEditing = false
                    imagePickerController.sourceType = .photoLibrary
                    imagePickerController.delegate = self
                    imagePickerController.modalPresentationStyle = .fullScreen
                    present(imagePickerController, animated: true, completion: nil)
                case 10:
                    documentPicker = DocumentPicker(presentationController: self, delegate: self)
                    documentPicker.displayPicker()
                default:
                    break
            }
        } else {
            self.alert.showDetail(
                "Upload Limit",
                with: "There is a limit of 6 files per review.",
                for: self) {
                print("something")
            } completion:  {}
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
        
        guard let filePath = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            print("No image found")
            return
        }
        
        let previewData = PreviewData(header: .image, filePath: filePath)
        previewDataArr.append(previewData)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ParentPostViewController: PreviewDelegate {
    // MARK: - configureImagePreview
    func configureImagePreview(postType: PostType) {
        imagePreviewVC = ImagePreviewViewController(postType: postType)
        imagePreviewVC.data = previewDataArr
        imagePreviewVC.delegate = self
        imagePreviewVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(imagePreviewVC)
        imagePreviewVC.view.frame = view.bounds
        view.addSubview(imagePreviewVC.view)
        imagePreviewVC.didMove(toParent: self)
    }
    
    // MARK: - didDeleteImage
    func didDeleteFileFromPreview(filePath: URL) {
        previewDataArr = previewDataArr.filter { $0.filePath != filePath }
    }
}

extension ParentPostViewController {
    // MARK: - checkExistingId
    func checkExistingId(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("post")
            .whereField("itemIdentifier", isEqualTo: id)
            .getDocuments() { (querySnapshot, err) in
                if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
    
//    @objc func mint() {
//        self.test()
//    }

    @objc func test() {
        
    }
    
    @objc func mint() {
        self.showSpinner { [weak self] in
            guard let userId = self?.userDefaults.string(forKey: UserDefaultKeys.userId) else {
                self?.alert.showDetail("Sorry", with: "You need to be logged in.", for: self)
                return
            }
            self?.userId = userId
            
            guard let itemTitle = self?.titleTextField.text, !itemTitle.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please fill in the title field.", for: self)
                return
            }
            
            guard let desc = self?.descTextView.text, !desc.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please fill in the description field.", for: self)
                return
            }
            
            guard let deliveryMethod = self?.deliveryMethodLabel.text,
                  !deliveryMethod.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please select the delivery method.", for: self)
                return
            }
            
            guard let saleFormat = self?.saleMethodLabel.text,
                  !saleFormat.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please select the sale method.", for: self)
                return
            }
            
            guard let paymentMethod = self?.paymentMethodLabel.text,
                  !paymentMethod.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please select the payment method.", for: self)
                return
            }
            
            guard let category = self?.pickerLabel.text, !category.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please choose the category.", for: self)
                return
            }
            
            guard let id = self?.idTextField.text,!id.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please select the digital asset.", for: self)
                return
            }
        
            
            guard let tagTextField = self?.tagTextField, tagTextField.tokens.count > 0 else {
                self?.alert.showDetail("Missing Tags", with: "Please add the tags using the plus sign.", for: self)
                return
            }
            
            guard tagTextField.tokens.count < 6 else {
                self?.alert.showDetail("Tag Limit", with: "You can add up to 5 tags.", for: self)
                return
            }
            
            // process id
            let whitespaceCharacterSet = CharacterSet.whitespaces
            let convertedId = id.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
            
            self?.checkExistingId(id: convertedId) { (isDuplicate) in
                if isDuplicate {
                    self?.alert.showDetail("Duplicate", with: "The item has already been registered. Please transfer the ownership instead of re-posting it.", height: 350, for: self)
                } else {
                    // add both the tokens and the title to the tokens field
                    var tokensArr = Set<String>()
                    let strippedString = itemTitle.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
                    let searchItems = strippedString.components(separatedBy: " ") as [String]
                    searchItems.forEach { (item) in
                        tokensArr.insert(item)
                    }
                    
                    for token in self!.tagTextField.tokens {
                        if let retrievedToken = token.representedObject as? String {
                            tokensArr.insert(retrievedToken.lowercased())
                        }
                    }
                    
                    self?.processMint(price: self?.priceTextField.text, itemTitle: itemTitle, desc: desc, category: category, convertedId: convertedId, tokensArr: tokensArr, userId: userId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod)
                    
                } // not duplicate
            } // end of checkExistingId
        } // 
    }
    
    @objc func processMint(price: String?, itemTitle: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
        
    }
    
    @objc func configureProgress() {
        
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

extension ParentPostViewController: SocketMessageDelegate, FileUploadable {
    // MARK: - didReceiveMessage
    @objc func didReceiveMessage(topics: [String]) {

        
        
        // get the token ID to be uploaded to Firestore
        getTokenId(topics: topics) { [weak self](_, res) in
            guard let res = res else { return }
            switch res {
                
//                case is HTTPStatusCode:
//                    switch res as! HTTPStatusCode {
//                        case .badRequest:
//                            self?.alert.showDetail("Error", with: "Bad request. Please contact the support.", for: self)
//                        case .unauthorized:
//                            self?.alert.showDetail("Error", with: "Unauthorized request. Please contact the support.", for: self)
//                        case .internalServerError:
//                            self?.alert.showDetail("Error", with: "Internal Server Error. Please contact the support.", for: self)
//                        case .serviceUnavailable:
//                            self?.alert.showDetail("Error", with: "Service Unavailable. Please contact the support.", for: self)
//                        case .ok, .created, .accepted:
//                            let update: [String: PostProgress] = ["update": .minting]
//                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//
//                            self?.uploadFiles()
//
//                            DispatchQueue.main.async {
//                                self?.titleTextField.text?.removeAll()
//                                self?.priceTextField.text?.removeAll()
//                                self?.deliveryMethodLabel.text?.removeAll()
//                                self?.descTextView.text?.removeAll()
//                                self?.idTextField.text?.removeAll()
//                                self?.pickerLabel.text?.removeAll()
//                                self?.tagTextField.tokens.removeAll()
//                                self?.paymentMethodLabel.text?.removeAll()
//                            }
//                        default:
//                            self?.alert.showDetail("Error", with: "Unknown Network Error. Please contact the admin.", for: self)
//                    }
                case is GeneralErrors:
                    switch res as! GeneralErrors {
                        case .decodingError:
                            self?.alert.showDetail("Error", with: "There was an error decoding the token ID. Please contact the admin.", for: self)
                        default:
                            break
                    }
                default:
                    self?.alert.showDetail("Error in Minting", with: res.localizedDescription, for: self)
            }
        }
    }
    
//    func uploadFiles(_ promise: @escaping (Result<[String], PostingError>) -> Void) {
//        var fileCount: Int = 0
//        var urlStringArr = [String]()
//        if self.previewDataArr.count > 0 {
//            for previewData in previewDataArr {
//                self.uploadFile(fileURL: previewData.filePath, userId: self.userId, promise: promise)
////                    guard let strongSelf = self else { return }
//                    urlStringArr.append("\(url)")
////                    strongSelf.db.collection("post").document(strongSelf.documentId).updateData([
////                        "files": FieldValue.arrayUnion(["\(url)"])
////                    ], completion: { (error) in
////                        if let error = error {
////                            strongSelf.alert.showDetail("Error", with: error.localizedDescription, for: self)
////                        }
////                    })
//
//                fileCount += 1
//                if fileCount == previewDataArr.count {
//                    self.previewDataArr.removeAll()
//                    self.imagePreviewVC.data.removeAll()
//                    DispatchQueue.main.async { [weak self] in
//                        self?.imagePreviewVC.collectionView.reloadData()
//                    }
//                    let update: [String: PostProgress] = ["update": .images]
//                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                    print("urlStrings in uploadFiels", urlStringArr)
//                    promise(.success(urlStringArr))
//                }
//            }
//        } else {
//            let update: [String: PostProgress] = ["update": .images]
//            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//        }
//    }
    
    // MARK: - getTokenId
    /// uploads the receipt to the Firebase function to get the token number, which will update the Firestore
    func getTokenId(topics: [String], completion: @escaping (Int?, Error?) -> Void) {
        // build request URL
        guard let requestURL = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/decodeLog-decodeLog") else {
            return
        }
//        guard let requestURL = URL(string: "http://localhost:5001/nftrack-69488/us-central1/decodeLog") else {
//            return
//        }
                
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
            ],
            "documentID": self.documentId!
        ]
        
        let paramData = try? JSONSerialization.data(withJSONObject: parameter, options: [])
        request.httpBody = paramData
        
        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                completion(nil, error)
            }
            
            if let response = response as? HTTPURLResponse {
                print("response from decodeLog", response)
                
                let httpStatusCode = APIError.HTTPStatusCode(rawValue: response.statusCode)
                completion(nil, httpStatusCode)
                
//                if !(200...299).contains(response.statusCode) {
//                    print("start1")
//                    // handle HTTP server-side error
//                }
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    guard let convertedJson = json as? NSNumber else {
                        // default error
                        completion(nil, GeneralErrors.decodingError)
                        return
                    }
                    print("convertedJson.intValue", convertedJson.intValue)
                    completion(convertedJson.intValue, nil)
                } catch {
                    completion(nil, GeneralErrors.decodingError)
                }
            }
        })
        
        observation = task.progress.observe(\.fractionCompleted) { [weak self] (progress, _) in
            print("decode log progress", progress)
            DispatchQueue.main.async {
                self?.progressModal.progressView.isHidden = false
                self?.progressModal.progressLabel.isHidden = false
                self?.progressModal.progressView.progress = Float(progress.fractionCompleted)
                self?.progressModal.progressLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
                self?.progressModal.progressView.isHidden = true
                self?.progressModal.progressLabel.isHidden = true
            }
        }
        
        task.resume()
    }
}

extension ParentPostViewController: DocumentDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        //        return self.url as QLPreviewItem
        let  docTitle = UUID().uuidString
        let previewItem = CustomPreviewItem(url: url, title: docTitle)
        return previewItem as QLPreviewItem
    }
    
    // MARK: - didPickDocument
    func didPickDocument(document: Document?) {
        if let pickedDoc = document {
            let fileURL = pickedDoc.fileURL
            guard fileURL.pathExtension == "pdf" else {
                self.alert.showDetail("Sorry", with: "The document has to be a PDF file", for: self)
                return
            }
            url = fileURL
            let previewData = PreviewData(header: .document, filePath: fileURL)
            previewDataArr.append(previewData)

            let preview = PreviewPDFViewController()
            preview.delegate = self
            preview.dataSource = self
            present(preview, animated: true, completion: nil)
        }
    }
}

extension ParentPostViewController: ScannerDelegate {
    // MARK: - scannerDidOutput
    func scannerDidOutput(code: String) {
        idTextField.text = code
    }
}


/// hash image
/// https://stackoverflow.com/questions/55868751/sha256-hash-of-camera-image-differs-after-it-was-saved-to-photo-album
//let imageData = UIImage(named: "Example")!.pngData()!
//print(imageData.base64EncodedString())
//// 'iVBORw0KGgoAAAANSUhEUgAAAG8AAACACAQAAACv3v+8AAAM82lD [...] gAAAABJRU5ErkJggg=='
//let imageHash = getImageHash(data: imageData)
//print(imageHash)
//// '145036245c9f675963cc8de2147887f9feded5813b0539d2320d201d9ce63397'

// when you send the receipt, send the image and file binaries as well
// the token gets sent to firestore directly
// the image and file binaries get sent to storage
// the storage trigger updates the firestore
