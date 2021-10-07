//
//  ParentPostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-01.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import web3swift
import QuickLook

class ParentPostViewController: UIViewController, ButtonPanelConfigurable, TokenConfigurable, ShippingDelegate, CoreSpotlightDelegate {
    let db = FirebaseService.shared.db!
    var scrollView: UIScrollView!
    var infoImage: UIImage! {
        return UIImage(systemName: "info.circle")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
    }
    let tintColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
    var backgroundView: BackgroundView4!
    var titleLabel: UILabel!
    var titleTextField: UITextField!
    var priceLabel: UILabel!
    var priceTextField: UITextField!
    var priceInfoButton: UIButton!
    var priceLabelConstraintHeight: NSLayoutConstraint!
    var priceTextFieldConstraintHeight: NSLayoutConstraint!
    var descLabel: UILabel!
    var descTextView: UITextView!
    var deliveryMethodTitleLabel: UILabel!
    var deliveryInfoButton: UIButton!
    var deliveryMethodLabel: UILabel!
    // If the delivery method is shipping, the seller has to set the address and the distance limit
    var isShipping: Bool! {
        didSet {
            if isShipping == true {
                addressTitleLabel.alpha = 1
                addressLabel.alpha = 1
                addressLabel.isUserInteractionEnabled = true
                addressTitleLabelConstraintHeight.constant = 50
                addressLabelConstraintHeight.constant = 50
                saleMethodTopConstraint.constant = 20
                UIView.animate(withDuration: 0.5) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            } else {
                addressTitleLabel.alpha = 0
                addressLabel.alpha = 0
                addressLabel.isUserInteractionEnabled = false
                addressTitleLabelConstraintHeight.constant = 0
                addressLabelConstraintHeight.constant = 0
                saleMethodTopConstraint.constant = 0
                
                UIView.animate(withDuration: 0.5) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
        }
    }
    lazy var addressTitleLabelConstraintHeight: NSLayoutConstraint = addressTitleLabel.heightAnchor.constraint(equalToConstant: 0)
    lazy var addressLabelConstraintHeight: NSLayoutConstraint = addressLabel.heightAnchor.constraint(equalToConstant: 0)
    var addressTitleLabel: UILabel!
    var addressLabel: UILabel!
    var paymentMethodTitleLabel: UILabel!
    var paymentInfoButton: UIButton!
    var paymentMethodLabel: UILabel!
    lazy var saleMethodTopConstraint: NSLayoutConstraint! = saleMethodTitleLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 0)
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
                    UIView.animate(withDuration: 0.4) {
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
                    UIView.animate(withDuration: 0.4) {
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
    
    var SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT: CGFloat! = 1650
    var IMAGE_PREVIEW_HEIGHT: CGFloat! = 180
    lazy var SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW: CGFloat! = SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT + IMAGE_PREVIEW_HEIGHT
    var escrowHash: String!
    var mintHash: String!
    var senderAddress: String!
    var shippingInfo: ShippingInfo!
    var colorPatchView = UIView()
    lazy var colorPatchViewHeight: NSLayoutConstraint = colorPatchView.heightAnchor.constraint(equalToConstant: 0)
    // Value to be passed from ListDetailVC -> NewPostVC -> PostParentVC only during resale
    var post: Post?
    var buttonPanelHeight: NSLayoutConstraint!
    var BUTTON_PANEL_HEIGHT: CGFloat = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBarTintColorToTheNavigationBar()
        configureUI()
        configureImagePreview()
        setConstraints()
        setColorPatchView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.navigationBar.sizeToFit()
        }
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
    func createIDField(post: Post? = nil) {}
    
    /// no scanner for digital asset
    func setIDFieldConstraints(post: Post? = nil) {}
    
    /// where the subclasses override the ImagePreview post type.
    /// This has to be done before setConstraints
    func configureImagePreview() {
        configureImagePreview(postType: .tangible, superView: scrollView, closeButtonEnabled: true)
    }
    
    // Set only during resale
    // 1. Set the existing image.
    // 2. Disable the ability to delete the image.
    // 3. Decrease the height of the button panel to 0.
    func resaleConfig() {}
}

extension ParentPostViewController {
    @objc func configureUI() {
        view.backgroundColor = .white
        title = "Post"
        
        previewDataArr = [PreviewData]()
        
        self.hideKeyboardWhenTappedAround()
        alert = Alerts()
        constraints = [NSLayoutConstraint]()
        extendedLayoutIncludesOpaqueBars = true
        
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
        view.addSubview(scrollView)
        scrollView.fill()
        
        let colors = [tintColor.cgColor, tintColor.cgColor]
        backgroundView = BackgroundView4(colors: colors)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(backgroundView)
        
        titleLabel = createTitleLabel(text: "Title")
        scrollView.addSubview(titleLabel)
        
        titleTextField = createTextField(delegate: self)
        titleTextField.autocorrectionType = .no
        scrollView.addSubview(titleTextField)
        
        priceLabel = createTitleLabel(text: "Price")
        scrollView.addSubview(priceLabel)
        
        priceInfoButton = UIButton.systemButton(with: infoImage, target: self, action: #selector(buttonPressed(_:)))
        priceInfoButton.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.addSubview(priceInfoButton)
        
        priceTextField = createTextField(delegate: self)
        priceTextField.keyboardType = .decimalPad
        priceTextField.placeholder = "In ETH"
        scrollView.addSubview(priceTextField)
    
        descLabel = createTitleLabel(text: "Description")
        scrollView.addSubview(descLabel)
        
        descTextView = UITextView()
        descTextView.delegate = self
        descTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 245/255)
        descTextView.layer.cornerRadius = 10
        descTextView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        descTextView.clipsToBounds = true
        descTextView.isScrollEnabled = true
        descTextView.font = UIFont.preferredFont(forTextStyle: .body)
        descTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descTextView)
        
        deliveryMethodTitleLabel = createTitleLabel(text: "Delivery Method")
        deliveryMethodTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(deliveryMethodTitleLabel)
        
        deliveryInfoButton = UIButton.systemButton(with: infoImage, target: self, action: #selector(buttonPressed(_:)))
        deliveryInfoButton.translatesAutoresizingMaskIntoConstraints = false
        deliveryMethodTitleLabel.addSubview(deliveryInfoButton)
        
        deliveryMethodLabel = createLabel(text: "")
        scrollView.addSubview(deliveryMethodLabel)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
        deliveryMethodLabel.addGestureRecognizer(tap)
        
        addressTitleLabel = createTitleLabel(text: "Shipping Restriction")
        scrollView.addSubview(addressTitleLabel)
        
        addressLabel = createLabel(text: "")
        addressLabel.tag = 11
        let addressTap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addressLabel.addGestureRecognizer(addressTap)
        scrollView.addSubview(addressLabel)
        
        paymentMethodTitleLabel = createTitleLabel(text: "Payment Method")
        paymentMethodTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(paymentMethodTitleLabel)
        
        saleMethodTitleLabel = createTitleLabel(text: "Sale Format")
        saleMethodTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(saleMethodTitleLabel)
        
        saleMethodInfoButton = UIButton.systemButton(with: infoImage, target: self, action: #selector(buttonPressed(_:)))
        saleMethodInfoButton.translatesAutoresizingMaskIntoConstraints = false
        saleMethodTitleLabel.addSubview(saleMethodInfoButton)
        
        saleMethodLabelContainer = UIView()
        saleMethodLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(saleMethodLabelContainer)
        
        saleMethodLabel = createLabel(text: "")
        saleMethodLabelContainer.addSubview(saleMethodLabel)
        
        paymentInfoButton = UIButton.systemButton(with: infoImage, target: self, action: #selector(buttonPressed(_:)))
        paymentInfoButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodTitleLabel.addSubview(paymentInfoButton)
        
        paymentMethodLabel = createLabel(text: "")
        scrollView.addSubview(paymentMethodLabel)
        
        idTitleLabel = createTitleLabel(text: "Unique Identifier")
        scrollView.addSubview(idTitleLabel)
        
        createIDField(post: post)
        
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
        
        let bgColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        tagTextField = UISearchTextField()
        tagTextField.placeholder = "Up to 5 tags"
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: tagTextField.frame.size.height))
        paddingView.backgroundColor = bgColor
        tagTextField.leftView = paddingView
        tagTextField.leftViewMode = .always
        tagTextField.delegate = self
        tagTextField.layer.cornerRadius = 10
        tagTextField.backgroundColor = bgColor
        tagTextField.alpha = 0.5
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

        createButtonPanel(panelButtons: panelButtons, superView: scrollView) { (buttonsArr) in
            buttonsArr.forEach { (button) in
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            }
        }
        
        // Placed after buttonPanel is initialized because buttonPanel's height has to be modified
        resaleConfig()
        
        postButton = UIButton()
        postButton.setTitle("Post", for: .normal)
        postButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        postButton.layer.cornerRadius = 5
        postButton.backgroundColor = .black
        postButton.tag = 3
        postButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(postButton)
    }

    // MARK: - setConstraints
    @objc func setConstraints() {
        priceLabelConstraintHeight = priceLabel.heightAnchor.constraint(equalToConstant: 50)
        priceTextFieldConstraintHeight = priceTextField.heightAnchor.constraint(equalToConstant: 50)
        saleMethodContainerConstraintHeight = saleMethodLabelContainer.heightAnchor.constraint(equalToConstant: 50)
        imagePreviewConstraintHeight = imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 0)
        
        backgroundView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20).isActive = true
        
        titleTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        titleTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        titleTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0).isActive = true
        
        priceLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        priceLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        priceLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20).isActive = true
        priceLabelConstraintHeight.isActive = true
        
        priceInfoButton.trailingAnchor.constraint(equalTo: priceLabel.trailingAnchor).isActive = true
        priceInfoButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        priceTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        priceTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        priceTextField.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 0).isActive = true
        priceTextFieldConstraintHeight.isActive = true
        
        descLabel.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: 20).isActive = true
        descLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        descLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        descLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        descTextView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        descTextView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        descTextView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        descTextView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 0).isActive = true
        
        deliveryMethodTitleLabel.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 20).isActive = true
        deliveryMethodTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        deliveryMethodTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        deliveryMethodTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        deliveryInfoButton.trailingAnchor.constraint(equalTo: deliveryMethodTitleLabel.trailingAnchor).isActive = true
        deliveryInfoButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        deliveryMethodLabel.topAnchor.constraint(equalTo: deliveryMethodTitleLabel.bottomAnchor, constant: 0).isActive = true
        deliveryMethodLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        deliveryMethodLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        deliveryMethodLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        addressTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        addressTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        addressTitleLabel.topAnchor.constraint(equalTo: deliveryMethodLabel.bottomAnchor, constant: 20).isActive = true
        addressTitleLabelConstraintHeight.isActive = true
        
        addressLabel.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 0).isActive = true
        addressLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        addressLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        addressLabelConstraintHeight.isActive = true
        
        saleMethodTopConstraint.isActive = true
        saleMethodTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        saleMethodTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saleMethodTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        saleMethodInfoButton.trailingAnchor.constraint(equalTo: saleMethodTitleLabel.trailingAnchor).isActive = true
        saleMethodInfoButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        saleMethodLabelContainer.topAnchor.constraint(equalTo: saleMethodTitleLabel.bottomAnchor, constant: 0).isActive = true
        saleMethodLabelContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        saleMethodLabelContainer.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        saleMethodContainerConstraintHeight.isActive = true
        
        saleMethodLabel.topAnchor.constraint(equalTo: saleMethodLabelContainer.topAnchor).isActive = true
        saleMethodLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor).isActive = true
        saleMethodLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor).isActive = true
        saleMethodLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        paymentMethodTitleLabel.topAnchor.constraint(equalTo: saleMethodLabelContainer.bottomAnchor, constant: 20).isActive = true
        paymentMethodTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        paymentMethodTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        paymentMethodTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        paymentInfoButton.trailingAnchor.constraint(equalTo: paymentMethodTitleLabel.trailingAnchor).isActive = true
        paymentInfoButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        paymentMethodLabel.topAnchor.constraint(equalTo: paymentMethodTitleLabel.bottomAnchor, constant: 0).isActive = true
        paymentMethodLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        paymentMethodLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        paymentMethodLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        // category
        pickerTitleLabel.topAnchor.constraint(equalTo: paymentMethodLabel.bottomAnchor, constant: 20).isActive = true
        pickerTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        pickerTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        pickerTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        pickerLabel.topAnchor.constraint(equalTo: pickerTitleLabel.bottomAnchor, constant: 0).isActive = true
        pickerLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        pickerLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        pickerLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        tagTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        tagTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        tagTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        tagTitleLabel.topAnchor.constraint(equalTo: pickerLabel.bottomAnchor, constant: 20).isActive = true
        
        tagContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        tagContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        tagContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        tagContainerView.topAnchor.constraint(equalTo: tagTitleLabel.bottomAnchor, constant: 0).isActive = true
        
        tagTextField.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.75).isActive = true
        tagTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        tagTextField.leadingAnchor.constraint(equalTo: tagContainerView.leadingAnchor).isActive = true
        tagTextField.topAnchor.constraint(equalTo: tagContainerView.topAnchor).isActive = true
        
        addTagButton.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.2).isActive = true
        addTagButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        addTagButton.trailingAnchor.constraint(equalTo: tagContainerView.trailingAnchor).isActive = true
        addTagButton.topAnchor.constraint(equalTo: tagContainerView.topAnchor).isActive = true

        setIDFieldConstraints(post: post)
        setButtonPanelConstraints(topView: idContainerView, heightConstant: BUTTON_PANEL_HEIGHT)
        
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
                case 24:
                    let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Pricing", detail: InfoText.pricing)])
                    self.present(infoVC, animated: true, completion: nil)
                default:
                    break
            }
        } else {
            self.alert.showDetail(
                "Upload Limit",
                with: "There is a limit of 6 files per post.",
                for: self) {
                print("something")
            } completion:  {}
        }
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        guard let v = sender.view else { return }
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch v.tag {
            case 11:
                let shippingVC = ShippingViewController()
                shippingVC.shippingDelegate = self
                navigationController?.pushViewController(shippingVC, animated: true)
            default:
                break
        }
    }
    
    func didFetchShippingInfo(_ shippingInfo: ShippingInfo) {
        self.shippingInfo = shippingInfo
        
        if let address = shippingInfo.addresses.first {
            addressLabel.text = address
        }
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
//    // MARK: - configureImagePreview
//    func configureImagePreview(postType: PostType) {
//        imagePreviewVC = ImagePreviewViewController(postType: postType)
//        imagePreviewVC.data = previewDataArr
//        imagePreviewVC.delegate = self
//        imagePreviewVC.view.translatesAutoresizingMaskIntoConstraints = false
//        addChild(imagePreviewVC)
//        imagePreviewVC.view.frame = view.bounds
//        view.addSubview(imagePreviewVC.view)
//        imagePreviewVC.didMove(toParent: self)
//    }
//    
//    // MARK: - didDeleteImage
//    func didDeleteFileFromPreview(filePath: URL) {
//        previewDataArr = previewDataArr.filter { $0.filePath != filePath }
//    }
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
    
    // gs://nftrack-69488.appspot.com/ZT6HvzMcoRg1gOjNz6iS9uVf7Hq1/E7AAEBD5-C15B-4786-AA88-BAB40C87E3BC.png
    // https://firebasestorage.googleapis.com/v0/b/nftrack-69488.appspot.com/o/vcHixrcSsLMpLiafMYrAmCvnlLU2%2F2CA3EC02-450D-4DB1-BF71-E86338CE1135.jpeg?alt=media&token=66fc9e87-09a6-4db6-813b-2a763ce1f5dd
    
    @objc func mint1() {
        for i in 0...10 {
            FirebaseService.shared.db
                .collection("post")
                .document("\(i)")
                .updateData([
                    "sellerUserId": "vcHixrcSsLMpLiafMYrAmCvnlLU2",
                    "senderAddress": "\(i)",
                    "escrowHash": "\(i)",
                    "auctionHash": "\(i)",
                    "mintHash": "\(i)",
                    "date": Date(),
                    "title": "\(i)",
                    "description": "\(i)",
                    "price": "\(i)",
                    "category": Category.realEstate.asString(),
                    "status": AuctionStatus.ready.rawValue,
                    "tags": ["example"],
                    "itemIdentifier": "\(i)",
                    "isReviewed": false,
                    "type": "tangible",
                    "deliveryMethod": "Shipping",
                    "saleFormat": "Online Direct",
                    "files": ["https://firebasestorage.googleapis.com/v0/b/nftrack-69488.appspot.com/o/vcHixrcSsLMpLiafMYrAmCvnlLU2%2FE366991C-B770-4A68-9CC7-862B793455CB.jpeg?alt=media&token=bbe4a96a-c5ea-4a77-8291-4357a7fc6963"],
                    "IPFS": "NA",
                    "paymentMethod": "Escrow",
                    "bidderTokens": [],
                    "bidders": []
                ])
        }
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
            
            // process id
            let whitespaceCharacterSet = CharacterSet.whitespaces
            let convertedId = id.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
            
            let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
            guard convertedId.rangeOfCharacter(from: characterset.inverted) == nil else {
                self?.alert.showDetail("Invalid Characters", with: "The unique identifier cannot contain any space or special characters.", for: self)
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
            
            if let _ = self?.post {
                print("resale")
                self?.processResale(
                    price: self?.priceTextField.text,
                    itemTitle: itemTitle,
                    desc: desc,
                    category: category,
                    convertedId: convertedId,
                    tokensArr: tokensArr,
                    userId: userId,
                    deliveryMethod: deliveryMethod,
                    saleFormat: saleFormat,
                    paymentMethod: paymentMethod
                )
            } else {
                self?.checkExistingId(id: convertedId) { (isDuplicate) in
                    if isDuplicate {
                        self?.alert.showDetail("Duplicate", with: "The item has already been registered. Please transfer the ownership instead of re-posting it.", height: 350, for: self)
                    } else {
                        self?.processMint(
                            price: self?.priceTextField.text,
                            itemTitle: itemTitle,
                            desc: desc,
                            category: category,
                            convertedId: convertedId,
                            tokensArr: tokensArr,
                            userId: userId,
                            deliveryMethod: deliveryMethod,
                            saleFormat: saleFormat,
                            paymentMethod: paymentMethod
                        )
                    } // not duplicate
                } // end of checkExistingId
            }
        }
    }
    
    @objc func processMint(
        price: String?,
        itemTitle: String,
        desc: String,
        category: String,
        convertedId: String,
        tokensArr: Set<String>,
        userId: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String
    ) {
        
    }
    
    @objc func processResale(
        price: String?,
        itemTitle: String,
        desc: String,
        category: String,
        convertedId: String,
        tokensArr: Set<String>,
        userId: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String
    ) {
        
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

extension ParentPostViewController: UIScrollViewDelegate {
    // To fill the gap that shows during the scroll view bounce.
    // Since the backgroundView and the navigationBar are separate, when the scrollView is dragged downward, the white view behind is shown through.
    // If the bounce is set false, it feels unnatural. Pluse the large title disappears when scrolled.
    func setColorPatchView() {
        colorPatchView.backgroundColor = tintColor
        colorPatchView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorPatchView)
        
        colorPatchView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        colorPatchView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        colorPatchView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        colorPatchViewHeight.isActive = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if -scrollView.contentOffset.y > 0 {
            colorPatchViewHeight.constant = -scrollView.contentOffset.y
        }
    }
}
