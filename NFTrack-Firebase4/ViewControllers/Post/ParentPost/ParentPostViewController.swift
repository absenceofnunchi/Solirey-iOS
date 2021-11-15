//
//  ParentPostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-01.
//

/*
 Abstract:
 The main VC for posting new items. Used by both tangible (PostVC) and digital (DigitalAssetVC) item posting as well as a new item and a resale item.
 The resale is determined by the non-nil post property passed by ResaleVC.
 During resale:
    1. The digital resale config forbids the user from altering the files.
    2. The tangible resale omits the digital category from the picker.
    3. The Unique Identifier cannot be altered for both digital and tangible.
 */

import UIKit
import FirebaseFirestore
import FirebaseStorage
import web3swift
import QuickLook
import Combine

// test
import CryptoKit
import BigInt

class ParentPostViewController: UIViewController, ButtonPanelConfigurable, TokenConfigurable, ShippingDelegate, CoreSpotlightDelegate, FileUploadable, HandleError {
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
    var smartContractFormatTitleLabel: UILabel!
    var smartContractFormatInfoButton: UIButton!
    var smartContractFormatLabel: UILabel!
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
    var userId: String! {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId)
    }
    var socketDelegate: SocketDelegate!
    var documentPicker: DocumentPicker!
    var url: URL!
    var imagePreviewConstraintHeight: NSLayoutConstraint!
    var progressModal: ProgressModalViewController! // needed on a global scope?
    var constraints: [NSLayoutConstraint]!
    var panelButtons: [PanelButton] {
        return []
    }
    
    // All the pickers (DeliveryMethod, Category, PaymentMethod)
    // For resale items, 2 things have to be restricted:
    //  1. The PostType has to be the same as the original item. For example, a digital item cannot be resold as a tangible item, or vice versa. Aside from the obvious, this is forbidden because
    //     the digital item's Unique Identifier is derived from hashing of its digital item whereas the tangible item requires the user to input it. ResaleViewController arranges this even before the user gets the
    //     chance to choose anything.
    //  2. The Digital option from the Category picker has to be omitted for the Tangible resale.  This has to be done after the ParentPostVC (or PostVC) is loaded.
    //
    // For the In Person Pickup Delivery Method, the digital has to be eliminated
    let deliveryMethodPicker = MyPickerVC(currentPep: DeliveryMethod.shipping.rawValue, pep: [DeliveryMethod.shipping.rawValue, DeliveryMethod.inPerson.rawValue])
    lazy var pvc: MyPickerVC =  MyPickerVC(currentPep: Category.electronics.asString(), pep: self.post != nil ? Category.getTangibleResaleOptions() : Category.getAll())
    let paymentMethodPicker = MyPickerVC(currentPep: PaymentMethod.escrow.rawValue, pep: [PaymentMethod.escrow.rawValue, PaymentMethod.directTransfer.rawValue])
    let contractFormatPicker = MyPickerVC(currentPep: ContractFormat.integral.rawValue, pep: ContractFormat.getAll())
    
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
    
    var SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT: CGFloat! = 1750
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
    var postType: PostType!
    var storage = Set<AnyCancellable>()
    
    // The documentId is usually passed to the createFireStoreEntry method to be modified
    // so that it could be used outside of createFireStoreEntry for such things as sending FCM or calling the createSimpePayment method on NFTrack
    // This is to experiement with passing the reference instead.
    var ref: CollectionReference {
        return FirebaseService.shared.db.collection("post")
    }
    // Which means only of of these are needed: ref vs documentId
    var documentId: String!
    // The unique ID for a post on the smart contract
    var simplePaymentId: String!
    var txPackageArr = [TxPackage]()
    var txResultArr = [TxResult2]()
    var topicsRetainer: [String]!
    var tokenIdRetainer: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBarTintColorToTheNavigationBar()
        configureUI()
        configureImagePreview()
        setConstraints()
        setColorPatchView()
        configureOwnerOf()
        
        // Determine whether the postType is tangible or digital, which was set my the segmentedControl
        // This is to be used for minting
        postType = type(of: self) == PostViewController.self ? .tangible : .digital
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
    
    func getInfo() {
        let parameters: [AnyObject] = [41, "9d78038e487b15758beb4d90ea733b626c1fb7a7d756fb8a77c2fa1de838f730"] as [AnyObject]
        Deferred { [weak self] in
            Future<SmartContractProperty, PostingError> { promise in
                self?.transactionService.prepareTransactionForReading(
                    method: NFTrackContract.ContractMethods.getInfo.rawValue,
                    parameters: parameters,
                    abi: NFTrackABIRevisedABI,
                    contractAddress: ContractAddresses.NFTrackABIRevisedAddress!,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ (property) -> AnyPublisher<[String: Any], PostingError> in
            Future<[String: Any], PostingError> { promise in
                do {
                    guard let result = try property.transaction?.call() else {
                        promise(.failure(.generalError(reason: "Could not execute the transaction.")))
                        return
                    }
                    promise(.success(result))
                } catch {
                    promise(.failure(.generalError(reason: "Could not execute the transaction.")))
                }
            }
            .eraseToAnyPublisher()
        })
        .sink { (completion) in
            print(completion)
        } receiveValue: { (properties) in
            
            if let onSale = properties["0"] as? Bool {
                print("onSale", onSale)
            }
            
            if let price = properties["1"] as? BigUInt {
                print("price", price)
            }
            
            if let tokenId = properties["2"] as? BigUInt {
                print("tokenId", tokenId)
            }
            print("properties", properties)
        }
        .store(in: &storage)
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
    
    // Set only during resale for the digital PostType
    // 1. Set the existing image.
    // 2. Disable the ability to delete the image.
    // 3. Decrease the height of the button panel to 0.
    func resaleConfig() {}
    
    // MARK: - checkExistingId
    func checkExistingId(id: String, completion: @escaping (Bool?, Error?) -> Void) {
        db.collection("post")
            .whereField("itemIdentifier", isEqualTo: id)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    completion(nil, err)
                }
                
                if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
                    completion(false, nil)
                } else {
                    completion(true, nil)
                }
            }
    }
}

extension ParentPostViewController {
    @objc func configureUI() {
        view.backgroundColor = .white
        
        previewDataArr = [PreviewData]()
        
        self.hideKeyboardWhenTappedAround()
        alert = Alerts()
        constraints = [NSLayoutConstraint]()
        extendedLayoutIncludesOpaqueBars = true
        
        scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .onDrag
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
        
        paymentMethodTitleLabel = createTitleLabel(text: "Payment Method")
        paymentMethodTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(paymentMethodTitleLabel)
        
        paymentInfoButton = UIButton.systemButton(with: infoImage, target: self, action: #selector(buttonPressed(_:)))
        paymentInfoButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodTitleLabel.addSubview(paymentInfoButton)
        
        paymentMethodLabel = createLabel(text: "")
        scrollView.addSubview(paymentMethodLabel)
        
        smartContractFormatTitleLabel = createTitleLabel(text: "Smart Contract Format")
        smartContractFormatTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(smartContractFormatTitleLabel)
        
        smartContractFormatInfoButton = UIButton.systemButton(with: infoImage, target: self, action: #selector(buttonPressed(_:)))
        smartContractFormatInfoButton.tag = 6
        smartContractFormatInfoButton.translatesAutoresizingMaskIntoConstraints = false
        smartContractFormatTitleLabel.addSubview(smartContractFormatInfoButton)
        
        smartContractFormatLabel = createLabel(text: "")
        smartContractFormatLabel.isUserInteractionEnabled = true
        smartContractFormatLabel.tag = 49
        scrollView.addSubview(smartContractFormatLabel)        
        smartContractFormatLabel.addGestureRecognizer(tap)
        
        let paymentLabelTap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
        paymentMethodLabel.addGestureRecognizer(paymentLabelTap)
        
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
        
        smartContractFormatTitleLabel.topAnchor.constraint(equalTo: paymentMethodLabel.bottomAnchor, constant: 20).isActive = true
        smartContractFormatTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        smartContractFormatTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        smartContractFormatTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        smartContractFormatInfoButton.trailingAnchor.constraint(equalTo: paymentMethodTitleLabel.trailingAnchor).isActive = true
        smartContractFormatInfoButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        smartContractFormatLabel.topAnchor.constraint(equalTo: smartContractFormatTitleLabel.bottomAnchor, constant: 0).isActive = true
        smartContractFormatLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        smartContractFormatLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        smartContractFormatLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        // category
        pickerTitleLabel.topAnchor.constraint(equalTo: smartContractFormatLabel.bottomAnchor, constant: 20).isActive = true
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
        
        switch sender.tag {
            case 3:
                if let categoryText = self.pickerLabel.text,
                   let category = Category(rawValue: categoryText),
                   category == .digital {
                    guard previewDataArr.count < 2 else {
                        self.alert.showDetail(
                            "Upload Limit",
                            with: "There is a limit of 1 file per post.",
                            for: self
                        )
                        return
                    }
                } else {
                    guard previewDataArr.count < 7 else {
                        self.alert.showDetail(
                            "Upload Limit",
                            with: "There is a limit of 6 files per post.",
                            for: self
                        )
                        return
                    }
                }
                
                mint()
                break
            case 4:
                if let text = tagTextField.text, !text.isEmpty {
                    tagTextField.text?.removeAll()
                    let token = createSearchToken(text: text, index: tagTextField.tokens.count)
                    tagTextField.insertToken(token, at: tagTextField.tokens.count > 0 ? tagTextField.tokens.count : 0)
                }
                break
            case 5:
                configureProgress()
                break
            case 6:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Smart Contract Format", detail: InfoText.contractFormatInfo)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 7:
                let scannerVC = ScannerViewController()
                scannerVC.delegate = self
                scannerVC.modalPresentationStyle = .fullScreen
                self.present(scannerVC, animated: true, completion: nil)
                break
            case 8:
                if let categoryText = self.pickerLabel.text,
                   let category = Category(rawValue: categoryText),
                   category == .digital {
                    guard previewDataArr.count < 1 else {
                        self.alert.showDetail(
                            "Upload Limit",
                            with: "There is a limit of 1 file per post.",
                            for: self
                        )
                        return
                    }
                } else {
                    guard previewDataArr.count < 6 else {
                        self.alert.showDetail(
                            "Upload Limit",
                            with: "There is a limit of 6 files per post.",
                            for: self
                        )
                        return
                    }
                }
                
                
                let vc = UIImagePickerController()
                vc.sourceType = .camera
                vc.allowsEditing = true
                vc.delegate = self
                present(vc, animated: true)
                break
            case 9:
                if let categoryText = self.pickerLabel.text,
                   let category = Category(rawValue: categoryText),
                   category == .digital {
                    guard previewDataArr.count < 1 else {
                        self.alert.showDetail(
                            "Upload Limit",
                            with: "There is a limit of 1 file per post.",
                            for: self
                        )
                        return
                    }
                } else {
                    guard previewDataArr.count < 6 else {
                        self.alert.showDetail(
                            "Upload Limit",
                            with: "There is a limit of 6 files per post.",
                            for: self
                        )
                        return
                    }
                }
                
                let imagePickerController = UIImagePickerController()
                imagePickerController.allowsEditing = false
                imagePickerController.sourceType = .photoLibrary
                imagePickerController.delegate = self
                imagePickerController.modalPresentationStyle = .fullScreen
                present(imagePickerController, animated: true, completion: nil)
                break
            case 10:
                documentPicker = DocumentPicker(presentationController: self, delegate: self)
                documentPicker.displayPicker()
                break
            case 24:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Pricing", detail: InfoText.pricing)])
                self.present(infoVC, animated: true, completion: nil)
                break
            default:
                break
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
            if shippingInfo.addresses.count > 0 {
                addressLabel.text = "\(address), etc"
            } else {
                addressLabel.text = address
            }
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
//    // MARK: - didDeleteImage
//    func didDeleteFileFromPreview(filePath: URL) {
//        previewDataArr = previewDataArr.filter { $0.filePath != filePath }
//    }
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

// MARK: - Check Ownership
extension ParentPostViewController {
    // The option to check the ownership of the token. Automatically prompted prior to the resale.
    // Given as an option because it's recommended, but not necessary. It's read method, not a property.
    private func configureOwnerOf() {
        guard post != nil else { return }
        
        let buttonInfoArr = [
            ButtonInfo(title: "Check", tag: 500, backgroundColor: .black)
        ]
        
        let infoVC = InfoViewController(
            infoModelArr: [InfoModel(title: "Check Ownership", detail: InfoText.ownerOf)],
            buttonInfoArr: buttonInfoArr
        )
        
        infoVC.buttonAction = { [weak self] tag in
            switch tag {
                case 500:
                    self?.dismiss(animated: true, completion: {
                        self?.checkOwnership()
                    })
                default:
                    break
            }
        }
        
        self.present(infoVC, animated: true, completion: nil)
    }
    
    private func checkOwnership() {
        guard let solireyMintContractAddress = ContractAddresses.solireyMintContractAddress else {
            alert.showDetail("Error", with: "Unable to retrieve the smart contract address for checking the ownership.", for: self)
            return
        }
        
        guard let tokenId = post?.tokenID else {
            self.alert.showDetail("Sorry", with: "Failed to load the Token ID for the current item.", for: self)
            return
        }
        
        let ownerOfParameters: [AnyObject] = [tokenId] as [AnyObject]
        
        // First ensure that the current wallet address is the owner of the item by invoking the ownerOf method on NFTrack.
        // This is to to be executed first to prevent the SimplePayment contract to be launched only to discover that the token cannot be transferred into it.
        // Since this is a "view" method that doesn't modify any states on the contract, no gas should be consumed and should be left out of the gas estimate.
        
        self.showSpinner {
            Deferred {
//                Future<SmartContractProperty, PostingError> { promise in
//                    self.transactionService.prepareTransactionForReading(
//                        method: NFTrackContract.ContractMethods.ownerOf.rawValue,
//                        parameters: ownerOfParameters,
//                        abi: mintContractABI,
//                        contractAddress: solireyMintContractAddress,
//                        promise: promise
//                    )
//                }
                Future<SmartContractProperty, PostingError> { promise in
                    self.transactionService.prepareTransactionForReading(
                        method: NFTrackContract.ContractMethods.ownerOf.rawValue,
                        parameters: ownerOfParameters,
                        abi: mintContractABI,
                        contractAddress: solireyMintContractAddress,
                        promise: promise
                    )
                }
                .eraseToAnyPublisher()
            }
            .flatMap { (propertyFetchModel) -> AnyPublisher<EthereumAddress, PostingError> in
                Future<EthereumAddress, PostingError> { promise in
                    guard let transaction = propertyFetchModel.transaction else {
                        promise(.failure(.generalError(reason: "Unable to prepare the read transaction.")))
                        return
                    }
                    
                    do {
                        let result: [String: Any] = try transaction.call()
                        print("result", result as Any)
                        if let ownerAddress = result["0"] as? EthereumAddress {
                            promise(.success(ownerAddress))
                        }
                    }  catch {
                        promise(.failure(.generalError(reason: "Unable to parse data from the smart contract.")))
                    }
                }
                .eraseToAnyPublisher()
            }
            .sink { [weak self] (completion) in
                switch completion {
                    case .failure(let error):
                        self?.processFailure(error)
                    case .finished:
                        break
                }
            } receiveValue: { [weak self] (ownerAddress) in
                self?.hideSpinner({
                    if ownerAddress == Web3swiftService.currentAddress {
                        self?.ownershipCheckResultPrompt(detail: "The current wallet is the owner of the item. You may proceed with the resale.")
                    } else {
                        self?.ownershipCheckResultPrompt(detail: "The current wallet is not the owner of the item. You will not be able to proceed with the resale.")
                    }
                })
            }
            .store(in: &self.storage)
        } // showSpinner
    }
    
    private func ownershipCheckResultPrompt(detail: String) {
        DispatchQueue.main.async { [weak self] in
            let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Ownership Status", detail: detail)])
            self?.present(infoVC, animated: true, completion: nil)
        }
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

extension ParentPostViewController {
    // MARK: - afterPostReset
    func afterPostReset() {
        // reset the fields
        DispatchQueue.main.async {
            self.titleTextField.text?.removeAll()
            self.priceTextField.text?.removeAll()
            self.descTextView.text?.removeAll()
            self.idTextField.text?.removeAll()
            self.deliveryMethodLabel.text?.removeAll()
            self.pickerLabel.text?.removeAll()
            self.tagTextField.tokens.removeAll()
            self.paymentMethodLabel.text?.removeAll()
            self.addressLabel.text?.removeAll()
            self.addressLabelConstraintHeight.constant = 0
            self.addressTitleLabel.alpha = 0
            self.addressLabel.alpha = 0
            self.addressLabel.isUserInteractionEnabled = false
            self.addressTitleLabelConstraintHeight.constant = 0
            self.addressLabelConstraintHeight.constant = 0
        }
        
        // remove the image and file previews
        if self.previewDataArr.count > 0 {
            self.previewDataArr.removeAll()
            self.imagePreviewVC.data.removeAll()
            DispatchQueue.main.async {
                self.imagePreviewVC.collectionView.reloadData()
            }
        }
    }
}
