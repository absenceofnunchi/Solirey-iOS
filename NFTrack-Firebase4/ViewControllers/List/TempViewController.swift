//////
//////  ProfileReviewListViewController.swift
//////  NFTrack-Firebase4
//////
//////  Created by J C on 2021-06-22.
//////
////
//
//
////class ProfileReviewListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TableViewConfigurable {
////    let CELL_HEIGHT: CGFloat = 150
////    var tableView: UITableView!
////    var postArr = [Review]() {
////        didSet {
////            let tableViewHeight = CGFloat(postArr.count) * CELL_HEIGHT
////            NSLayoutConstraint.activate([
////                tableView.topAnchor.constraint(equalTo: view.topAnchor),
////                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
////                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////                tableView.heightAnchor.constraint(equalToConstant: tableViewHeight),
////            ])
////            tableView.reloadData()
////            preferredContentSize = CGSize(width: view.bounds.size.width, height: tableViewHeight + 700)
////        }
////    }
////
////    override func viewDidLoad() {
////        super.viewDidLoad()
////        configureUI()
////    }
////
////    func configureUI() {
////        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: ReviewCell.self, identifier: ReviewCell.identifier)
////        tableView.isScrollEnabled = false
////        tableView.translatesAutoresizingMaskIntoConstraints = false
////        view.addSubview(tableView)
////        //        tableView.fill()
////    }
////
////    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
////        return postArr.count
////    }
////
////    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
////        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReviewCell.identifier) as? ReviewCell else {
////            fatalError("Sorry, could not load cell")
////        }
////        cell.selectionStyle = .none
////        cell.accessoryType = .disclosureIndicator
////        let post = postArr[indexPath.row]
////        cell.configure(post)
////        return cell
////    }
////
////    //    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
////    //        let post = postArr[indexPath.row]
////    //        let listDetailVC = ListDetailViewController()
////    ////        listDetailVC.post = post
////    //        listDetailVC.tableViewRefreshDelegate = self
////    //        self.navigationController?.pushViewController(listDetailVC, animated: true)
////    //    }
////
////    //    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
////    //        return UITableView.automaticDimension
////    //    }
////}
//
////
////class ReviewCell: UITableViewCell {
////    var titleLabel: UILabel!
////    var reviewLabel: UILabelPadding!
////    
////    
////    class var identifier: String {
////        return "ReviewCell"
////    }
////    
////    func configure(_ post: Review?) {
////        guard let post = post else { return }
////        
////        //        guard let placeholderImage = UIImage(systemName: "person.crop.circle.fill") else { return }
////        //        thumbImageView.image = placeholderImage.withTintColor(.orange, renderingMode: .alwaysOriginal)
////        //        thumbImageView.contentMode = .scaleAspectFill
////        //        thumbImageView.clipsToBounds = true
////        //        thumbImageView.frame = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
////        //        thumbImageView.layer.cornerRadius = thumbImageView.bounds.size.height / 2
////        //        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
////        //        self.contentView.addSubview(thumbImageView)
////        //
////        //        titleLabel = UILabel()
////        //        titleLabel.adjustsFontForContentSizeCategory = true
////        //        titleLabel.text = post.reviewerDisplayName
////        //        titleLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .bold)
////        //        titleLabel.textColor = .lightGray
////        //        titleLabel.translatesAutoresizingMaskIntoConstraints = false
////        //        self.contentView.addSubview(titleLabel)
////        
////        
////        reviewLabel = UILabelPadding()
////        reviewLabel.text = post.review
////        //        reviewLabel.text = "lsfjaljdfl;ajsdlfjal;sdkfjaksjdfl;kajsfl;kajsldfjal lajsfklajsflkjasl; dflaksj dfaksjd flajs dfl;ajksdfkla dfljkal sdjflajksdf afjklajsdfl;jkf lqjwelrkqw eljq werhqwekhrkqwehr kqhwe rjkhqw jkrhq wkerh qkwehr kqhw ekrh qkwejhrk qhwer khqw ekjrhqw rkqwehr hqwerk jhqwekrjh qwkhr kqwhrkqwj hekrjhq wkhrkqwehr qkweh rkqjehw rkqheklhr qjkrh ej rehklr hkqjhr kjqweh rkjqehwjkr qehwrjkqh jrh qwkehrkqwehr kqhwr jkqehwrkqhw erkjqhw erkhq wekjrhqkwhrqkw ehrkqh erkehjwrkqehr h"
////        reviewLabel.numberOfLines = 0
////        reviewLabel.lineBreakMode = .byWordWrapping
////        //        reviewLabel.adjustsFontForContentSizeCategory = true
////        reviewLabel.textColor = .lightGray
////        reviewLabel.translatesAutoresizingMaskIntoConstraints = false
////        self.contentView.addSubview(reviewLabel)
////        
////        setConstraints()
////    }
////    
////    func setConstraints() {
////        NSLayoutConstraint.activate([
////            //            thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
////            //            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
////            //            thumbImageView.heightAnchor.constraint(equalToConstant: 50),
////            //            thumbImageView.widthAnchor.constraint(equalToConstant: 50),
////            //
////            //            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
////            //            titleLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
////            //            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 10),
////            //            titleLabel.heightAnchor.constraint(equalToConstant: 50),
////            
////            reviewLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
////            reviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
////            reviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 10),
////            reviewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
////        ])
////    }
////}
//
////class ProfileReviewListViewController: ParentListViewController<Review> {
////    let CELL_HEIGHT: CGFloat = 150
////    override var postArr: [Review] {
////        didSet {
////            let tableViewHeight = CGFloat(postArr.count) * CELL_HEIGHT
////            NSLayoutConstraint.activate([
////                tableView.topAnchor.constraint(equalTo: view.topAnchor),
////                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
////                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////                tableView.heightAnchor.constraint(equalToConstant: tableViewHeight),
////            ])
////            tableView.reloadData()
////            preferredContentSize = CGSize(width: view.bounds.size.width, height: tableViewHeight + 700)
////        }
////    }
////
////    override func setDataStore(postArr: [Review]) {
////        dataStore = ReviewImageDataStore(posts: postArr)
////    }
////
////    override func configureUI() {
////        super.configureUI()
////        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: ReviewCell.self, identifier: ReviewCell.identifier)
////        tableView.prefetchDataSource = self
////        tableView.isScrollEnabled = false
////        tableView.translatesAutoresizingMaskIntoConstraints = false
////        view.addSubview(tableView)
////    }
////
////    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
////        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReviewCell.identifier) as? ReviewCell else {
////            fatalError("Sorry, could not load cell")
////        }
////        cell.selectionStyle = .none
////        cell.accessoryType = .disclosureIndicator
////        let post = postArr[indexPath.row]
////        cell.updateAppearanceFor(.pending(post))
////        return cell
////    }
////
////    //    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
////    //        let post = postArr[indexPath.row]
////    //        let listDetailVC = ListDetailViewController()
////    ////        listDetailVC.post = post
////    //        listDetailVC.tableViewRefreshDelegate = self
////    //        self.navigationController?.pushViewController(listDetailVC, animated: true)
////    //    }
////
////    //    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
////    //        return UITableView.automaticDimension
////    //    }
////}
//
////class ReviewCell: ParentTableCell<Review> {
////    override class var identifier: String {
////        return "ReviewCell"
////    }
////    
////    var usernameLabel: UILabel!
////    var reviewLabel: UILabelPadding!
////    let IMAGE_HEIGHT: CGFloat = 40
////    
////    override func configure(_ post: Review?) {
////        guard let post = post else { return }
////        
////        guard let placeholderImage = UIImage(systemName: "person.crop.circle.fill") else { return }
////        thumbImageView.image = placeholderImage.withTintColor(.orange, renderingMode: .alwaysOriginal)
////        thumbImageView.contentMode = .scaleAspectFill
////        thumbImageView.clipsToBounds = true
////        thumbImageView.frame = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
////        thumbImageView.layer.cornerRadius = thumbImageView.bounds.size.height / 2
////        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
////        self.contentView.addSubview(thumbImageView)
////        
////        usernameLabel = UILabel()
////        usernameLabel.adjustsFontForContentSizeCategory = true
////        usernameLabel.text = post.reviewerDisplayName
////        usernameLabel.font = .rounded(ofSize: usernameLabel.font.pointSize, weight: .bold)
////        usernameLabel.textColor = .lightGray
////        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
////        self.contentView.addSubview(usernameLabel)
////        
////        reviewLabel = UILabelPadding()
////        reviewLabel.text = post.review
////        reviewLabel.numberOfLines = 0
////        reviewLabel.adjustsFontForContentSizeCategory = true
////        reviewLabel.textColor = .lightGray
////        reviewLabel.translatesAutoresizingMaskIntoConstraints = false
////        self.contentView.addSubview(reviewLabel)
////        
////        setConstraints()
////    }
////    
////    func setConstraints() {
////        NSLayoutConstraint.activate([
////            thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
////            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
////            thumbImageView.heightAnchor.constraint(equalToConstant: IMAGE_HEIGHT),
////            thumbImageView.widthAnchor.constraint(equalToConstant: IMAGE_HEIGHT),
////            
////            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
////            usernameLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
////            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 10),
////            usernameLabel.heightAnchor.constraint(equalToConstant: IMAGE_HEIGHT),
////            
////            reviewLabel.topAnchor.constraint(equalTo: thumbImageView.bottomAnchor, constant: 10),
////            reviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
////            reviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 10),
////            reviewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 10)
////        ])
////    }
////}
//
//
////
////  ReviewPostViewController.swift
////  NFTrack-Firebase4
////
////  Created by J C on 2021-06-21.
////
///*
// Where you create the review and submit it
// */
//
//////
////  ParentPostViewController.swift
////  NFTrack-Firebase4
////
////  Created by J C on 2021-06-01.
////
//
//import UIKit
//
//import UIKit
//import FirebaseFirestore
//import FirebaseStorage
//import Firebase
//import web3swift
//import QuickLook
//
//class ParentPostViewController: UIViewController, DocumentDelegate, QLPreviewControllerDataSource {
//    var scrollView: UIScrollView!
//    var titleLabel: UILabel!
//    var titleTextField: UITextField!
//    var priceLabel: UILabel!
//    var priceTextField: UITextField!
//    var descLabel: UILabel!
//    var descTextView: UITextView!
//    var idTitleLabel: UILabel!
//    var idTextField: UITextField!
//    var pickerTitleLabel: UILabel!
//    var pickerLabel: UILabelPadding!
//    var tagContainerView: UIView!
//    var tagTitleLabel: UILabel!
//    var tagTextField: UISearchTextField!
//    var addTagButton: UIButton!
//    var buttonPanel: UIStackView!
//    var cameraButton: UIButton!
//    var imagePickerButton: UIButton!
//    var documentPickerButton: UIButton!
//    var imageNameArr = [String]() {
//        didSet {
//            if imageNameArr.count > 0 {
//                imagePreviewVC.view.isHidden = false
//                imagePreviewConstraintHeight.constant = 170
//                UIView.animate(withDuration: 1) { [weak self] in
//                    self?.view.layoutIfNeeded()
//                }
//            } else {
//                imagePreviewVC.view.isHidden = true
//                imagePreviewConstraintHeight.constant = 0
//                UIView.animate(withDuration: 1) { [weak self] in
//                    self?.view.layoutIfNeeded()
//                }
//                
//            }
//        }
//    }
//    var imagePreviewVC: ImagePreviewViewController!
//    var postButton: UIButton!
//    let transactionService = TransactionService()
//    var alert: Alerts!
//    var imageAddresses = [String]()
//    let userDefaults = UserDefaults.standard
//    var observation: NSKeyValueObservation?
//    var userId: String!
//    var documentId: String!
//    var socketDelegate: SocketDelegate!
//    var documentPicker: DocumentPicker!
//    var url: URL!
//    var imagePreviewConstraintHeight: NSLayoutConstraint!
//    var documentArr: [Document]!
//    
//    let pvc = MyPickerVC()
//    /// MyDoneButtonVC
//    let mdbvc = MyDoneButtonVC()
//    var showKeyboard = false
//    
//    deinit {
//        if observation != nil {
//            observation?.invalidate()
//        }
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        configureNavigationBar(vc: self)
//        configureUI()
//        configureImagePreview()
//        setConstraints()
//        deleteAllFiles()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        imagePreviewVC.data = imageNameArr
//        
//        if observation != nil {
//            observation?.invalidate()
//        }
//    }
//}
//
//extension ParentPostViewController {
//    
//    @objc func configureUI() {
//        title = "Post"
//        self.hideKeyboardWhenTappedAround()
//        alert = Alerts()
//        
//        scrollView = UIScrollView()
//        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 1200)
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scrollView)
//        scrollView.fill()
//        
//        titleLabel = createTitleLabel(text: "Title")
//        scrollView.addSubview(titleLabel)
//        
//        titleTextField = createTextField(delegate: self)
//        titleTextField.autocorrectionType = .no
//        scrollView.addSubview(titleTextField)
//        
//        priceLabel = createTitleLabel(text: "Price")
//        scrollView.addSubview(priceLabel)
//        
//        priceTextField = createTextField(delegate: self)
//        priceTextField.keyboardType = .decimalPad
//        priceTextField.placeholder = "In ETH"
//        scrollView.addSubview(priceTextField)
//        
//        descLabel = createTitleLabel(text: "Description")
//        scrollView.addSubview(descLabel)
//        
//        descTextView = UITextView()
//        descTextView.delegate = self
//        descTextView.layer.borderWidth = 0.7
//        descTextView.layer.borderColor = UIColor.lightGray.cgColor
//        descTextView.layer.cornerRadius = 5
//        descTextView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
//        descTextView.clipsToBounds = true
//        descTextView.isScrollEnabled = true
//        descTextView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
//        descTextView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(descTextView)
//        
//        idTitleLabel = createTitleLabel(text: "Unique Identifier")
//        scrollView.addSubview(idTitleLabel)
//        
//        idTextField = createTextField(delegate: self)
//        idTextField.autocapitalizationType = .none
//        idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
//        scrollView.addSubview(idTextField)
//        
//        pickerTitleLabel = createTitleLabel(text: "Category")
//        scrollView.addSubview(pickerTitleLabel)
//        
//        pickerLabel = UILabelPadding()
//        pickerLabel.isUserInteractionEnabled = true
//        pickerLabel.layer.borderWidth = 0.7
//        pickerLabel.layer.cornerRadius = 5
//        pickerLabel.layer.borderColor = UIColor.lightGray.cgColor
//        pickerLabel.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(pickerLabel)
//        
//        self.mdbvc.delegate = self
//        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
//        pickerLabel.addGestureRecognizer(tap)
//        
//        tagContainerView = UIView()
//        tagContainerView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(tagContainerView)
//        
//        tagTitleLabel = createTitleLabel(text: "Tags")
//        scrollView.addSubview(tagTitleLabel)
//        
//        tagTextField = UISearchTextField()
//        tagTextField.placeholder = "Up to 5 tags"
//        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: tagTextField.frame.size.height))
//        tagTextField.leftView = paddingView
//        tagTextField.leftViewMode = .always
//        tagTextField.delegate = self
//        tagTextField.layer.borderWidth = 0.7
//        tagTextField.layer.cornerRadius = 5
//        tagTextField.layer.borderColor = UIColor.lightGray.cgColor
//        tagTextField.backgroundColor = .white
//        tagTextField.translatesAutoresizingMaskIntoConstraints = false
//        tagContainerView.addSubview(tagTextField)
//        
//        guard let addTagImage = UIImage(systemName: "plus") else { return }
//        addTagButton = UIButton.systemButton(with: addTagImage.withTintColor(.black, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonPressed))
//        addTagButton.layer.cornerRadius = 5
//        addTagButton.layer.borderWidth = 0.7
//        addTagButton.layer.borderColor = UIColor.lightGray.cgColor
//        addTagButton.tag = 4
//        addTagButton.translatesAutoresizingMaskIntoConstraints = false
//        tagContainerView.addSubview(addTagButton)
//        
//        buttonPanel = UIStackView()
//        buttonPanel.axis = .horizontal
//        buttonPanel.distribution = .fillEqually
//        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(buttonPanel)
//        
//        let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .medium)
//        let cameraImage = UIImage(systemName: "camera.circle")!
//            .withTintColor(UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), renderingMode: .alwaysOriginal)
//            .withConfiguration(configuration)
//        cameraButton = UIButton.systemButton(with: cameraImage, target: self, action: #selector(buttonPressed))
//        cameraButton.tag = 1
//        cameraButton.translatesAutoresizingMaskIntoConstraints = false
//        buttonPanel.addArrangedSubview(cameraButton)
//        
//        var imageName: String!
//        if #available(iOS 14.0, *) {
//            imageName = "rectangle.fill.on.rectangle.fill.circle"
//        } else {
//            imageName = "person.crop.circle.fill.badge.plus"
//        }
//        
//        let pickerImage = UIImage(systemName: imageName)!
//            .withTintColor(UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), renderingMode: .alwaysOriginal)
//            .withConfiguration(configuration)
//        imagePickerButton = UIButton.systemButton(with: pickerImage, target: self, action: #selector(buttonPressed(_:)))
//        imagePickerButton.tag = 2
//        imagePickerButton.translatesAutoresizingMaskIntoConstraints = false
//        buttonPanel.addArrangedSubview(imagePickerButton)
//        
//        let documentPickerImage = UIImage(systemName: "doc.circle")!
//            .withTintColor(UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), renderingMode: .alwaysOriginal)
//            .withConfiguration(configuration)
//        documentPickerButton = UIButton.systemButton(with: documentPickerImage, target: self, action: #selector(buttonPressed(_:)))
//        documentPickerButton.tag = 6
//        documentPickerButton.translatesAutoresizingMaskIntoConstraints = false
//        buttonPanel.addArrangedSubview(documentPickerButton)
//        
//        postButton = UIButton()
//        postButton.setTitle("Post", for: .normal)
//        postButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//        postButton.layer.cornerRadius = 5
//        postButton.backgroundColor = .black
//        postButton.tag = 3
//        postButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(postButton)
//    }
//    
//    // MARK: - setConstraints
//    @objc func setConstraints() {
//        imagePreviewConstraintHeight = imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 0)
//        
//        NSLayoutConstraint.activate([
//            titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            titleLabel.heightAnchor.constraint(equalToConstant: 50),
//            titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
//            
//            titleTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            titleTextField.heightAnchor.constraint(equalToConstant: 50),
//            titleTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
//            
//            priceLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            priceLabel.heightAnchor.constraint(equalToConstant: 50),
//            priceLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            priceLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
//            
//            priceTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            priceTextField.heightAnchor.constraint(equalToConstant: 50),
//            priceTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            priceTextField.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 0),
//            
//            descLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            descLabel.heightAnchor.constraint(equalToConstant: 50),
//            descLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            descLabel.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: 20),
//            
//            descTextView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            descTextView.heightAnchor.constraint(equalToConstant: 100),
//            descTextView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            descTextView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 0),
//            
//            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            idTitleLabel.heightAnchor.constraint(equalToConstant: 50),
//            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            idTitleLabel.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 20),
//            
//            idTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            idTextField.heightAnchor.constraint(equalToConstant: 50),
//            idTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            idTextField.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
//            
//            pickerTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            pickerTitleLabel.heightAnchor.constraint(equalToConstant: 50),
//            pickerTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            pickerTitleLabel.topAnchor.constraint(equalTo: idTextField.bottomAnchor, constant: 20),
//            
//            pickerLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            pickerLabel.heightAnchor.constraint(equalToConstant: 50),
//            pickerLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            pickerLabel.topAnchor.constraint(equalTo: pickerTitleLabel.bottomAnchor, constant: 0),
//            
//            tagTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            tagTitleLabel.heightAnchor.constraint(equalToConstant: 50),
//            tagTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            tagTitleLabel.topAnchor.constraint(equalTo: pickerLabel.bottomAnchor, constant: 20),
//            
//            tagContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            tagContainerView.heightAnchor.constraint(equalToConstant: 50),
//            tagContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            tagContainerView.topAnchor.constraint(equalTo: tagTitleLabel.bottomAnchor, constant: 0),
//            
//            tagTextField.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.7),
//            tagTextField.heightAnchor.constraint(equalToConstant: 50),
//            tagTextField.leadingAnchor.constraint(equalTo: tagContainerView.leadingAnchor),
//            tagTextField.topAnchor.constraint(equalTo: tagContainerView.topAnchor),
//            
//            addTagButton.widthAnchor.constraint(equalTo: tagContainerView.widthAnchor, multiplier: 0.2),
//            addTagButton.heightAnchor.constraint(equalToConstant: 50),
//            addTagButton.trailingAnchor.constraint(equalTo: tagContainerView.trailingAnchor),
//            addTagButton.topAnchor.constraint(equalTo: tagContainerView.topAnchor),
//            
//            buttonPanel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            buttonPanel.heightAnchor.constraint(equalToConstant: 80),
//            buttonPanel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            buttonPanel.topAnchor.constraint(equalTo: tagContainerView.bottomAnchor, constant: 40),
//            //
//            //            cameraButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
//            //            cameraButton.heightAnchor.constraint(equalToConstant: 80),
//            //            cameraButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
//            //
//            //            imagePickerButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
//            //            imagePickerButton.heightAnchor.constraint(equalToConstant: 80),
//            //            imagePickerButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
//            
//            cameraButton.widthAnchor.constraint(equalToConstant: 80),
//            cameraButton.heightAnchor.constraint(equalToConstant: 80),
//            
//            imagePickerButton.widthAnchor.constraint(equalToConstant: 80),
//            imagePickerButton.heightAnchor.constraint(equalToConstant: 80),
//            
//            documentPickerButton.widthAnchor.constraint(equalToConstant: 80),
//            documentPickerButton.heightAnchor.constraint(equalToConstant: 80),
//            
//            imagePreviewVC.view.topAnchor.constraint(equalTo: buttonPanel.bottomAnchor, constant: 20),
//            imagePreviewVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
//            imagePreviewVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            imagePreviewConstraintHeight,
//            
//            postButton.topAnchor.constraint(equalTo: imagePreviewVC.view.bottomAnchor, constant: 40),
//            postButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
//            postButton.heightAnchor.constraint(equalToConstant: 50),
//            postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//        ])
//    }
//    
//    // MARK: - buttonPressed
//    @objc func buttonPressed(_ sender: UIButton) {
//        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//        feedbackGenerator.impactOccurred()
//        
//        if imageNameArr.count < 7 {
//            switch sender.tag {
//                case 1:
//                    let vc = UIImagePickerController()
//                    vc.sourceType = .camera
//                    vc.allowsEditing = true
//                    vc.delegate = self
//                    present(vc, animated: true)
//                case 2:
//                    let imagePickerController = UIImagePickerController()
//                    imagePickerController.allowsEditing = false
//                    imagePickerController.sourceType = .photoLibrary
//                    imagePickerController.delegate = self
//                    imagePickerController.modalPresentationStyle = .fullScreen
//                    present(imagePickerController, animated: true, completion: nil)
//                case 3:
//                    mint()
//                case 4:
//                    if let text = tagTextField.text, !text.isEmpty {
//                        tagTextField.text?.removeAll()
//                        let token = createSearchToken(text: text, index: tagTextField.tokens.count)
//                        tagTextField.insertToken(token, at: tagTextField.tokens.count > 0 ? tagTextField.tokens.count : 0)
//                    }
//                case 5:
//                    configureProgress()
//                case 6:
//                    documentPicker = DocumentPicker(presentationController: self, delegate: self)
//                    documentPicker.displayPicker()
//                default:
//                    break
//            }
//        } else {
//            let detailVC = DetailViewController(height: 250)
//            detailVC.titleString = "Image Upload Limit"
//            detailVC.message = "There is a limit of 6 images per post."
//            detailVC.buttonAction = { [weak self]vc in
//                self?.dismiss(animated: true, completion: nil)
//            }
//            present(detailVC, animated: true, completion: nil)
//        }
//    }
//    
//    
//    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
//        return 1
//    }
//    
//    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
//        return self.url as QLPreviewItem
//        //        let previewItem = CustomPreviewItem(url: <Your URL>, title: <Title>)
//        //        return previewItem as QLPreviewItem
//    }
//    
//    // MARK: - didPickDocument
//    func didPickDocument(document: Document?) {
//        if let pickedDoc = document {
//            let fileURL = pickedDoc.fileURL
//            url = fileURL
//            
//            var retrievedData: Data!
//            do {
//                retrievedData = try Data(contentsOf: fileURL)
//            } catch {
//                alert.show(error, for: self)
//            }
//            
//            let preview = PreviewPDFViewController()
//            preview.dataSource = self
//            //            preview.buttonAction = { [weak self] in
//            //                self?.dismiss(animated: true, completion: nil)
//            
//            //                if let data = retrievedData {
//            //                    print("document data", data)
//            //
//            //                    self?.alert.withTextField(delegate: self!, controller: self!, data: data, completion: { (title, password) in
//            //                        //                        self?.uploadFile(fileData: data, title: title, password: password)
//            //
//            //                        self?.presendAnimation(completion: {
//            //                            self?.uploadData(data: data, title: title, password: password)
//            //                        })
//            //                    })
//            //                }
//            //            }
//            present(preview, animated: true, completion: nil)
//        }
//    }
//    
//    func createSearchToken(text: String, index: Int) -> UISearchToken {
//        let tokenColor = suggestedColor(fromIndex: index)
//        let image = UIImage(systemName: "circle.fill")?.withTintColor(tokenColor, renderingMode: .alwaysOriginal)
//        let searchToken = UISearchToken(icon: image, text: text)
//        searchToken.representedObject = text
//        return searchToken
//    }
//    
//    // colors for the tokens
//    func suggestedColor(fromIndex: Int) -> UIColor {
//        var suggestedColor: UIColor!
//        switch fromIndex {
//            case 0:
//                suggestedColor = UIColor.red
//            case 1:
//                suggestedColor = UIColor.orange
//            case 2:
//                suggestedColor = UIColor.yellow
//            case 3:
//                suggestedColor = UIColor.green
//            case 4:
//                suggestedColor = UIColor.blue
//            case 5:
//                suggestedColor = UIColor.purple
//            case 6:
//                suggestedColor = UIColor.brown
//            case 7:
//                suggestedColor = UIColor(red: 93/255, green: 109/255, blue: 126/255, alpha: 1)
//            case 8:
//                suggestedColor = UIColor(red: 245/255, green: 176/255, blue: 65/255, alpha: 1)
//            default:
//                suggestedColor = UIColor.cyan
//        }
//        
//        return suggestedColor
//    }
//    
//}
//
//// MARK: - Image picker
//extension ParentPostViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        picker.dismiss(animated: true)
//        
//        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//            print("No image found")
//            return
//        }
//        
//        let imageName = UUID().uuidString
//        imageNameArr.append(imageName)
//        saveImage(imageName: imageName, image: image)
//    }
//    
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
//}
//
//extension ParentPostViewController: PreviewDelegate {
//    // MARK: - configureImagePreview
//    func configureImagePreview() {
//        imagePreviewVC = ImagePreviewViewController()
//        imagePreviewVC.data = imageNameArr
//        imagePreviewVC.delegate = self
//        imagePreviewVC.view.translatesAutoresizingMaskIntoConstraints = false
//        addChild(imagePreviewVC)
//        imagePreviewVC.view.frame = view.bounds
//        view.addSubview(imagePreviewVC.view)
//        imagePreviewVC.didMove(toParent: self)
//    }
//    
//    // MARK: - didDeleteImage
//    func didDeleteImage(imageName: String) {
//        imageNameArr = imageNameArr.filter { $0 != imageName }
//    }
//}
//
//extension ParentPostViewController {
//    // MARK: - checkExistingId
//    func checkExistingId(id: String, completion: @escaping (Bool) -> Void) {
//        FirebaseService.shared.db.collection("post")
//            .whereField("itemIdentifier", isEqualTo: id)
//            .getDocuments() { (querySnapshot, err) in
//                if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
//                    completion(false)
//                } else {
//                    completion(true)
//                }
//            }
//    }
//    
//    @objc func mint() {
//    }
//    
//    @objc func configureProgress() {
//        
//    }
//    
//    func deleteAllFiles() {
//        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        
//        do {
//            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
//                                                                       includingPropertiesForKeys: nil,
//                                                                       options: .skipsHiddenFiles)
//            for fileURL in fileURLs {
//                print("fileURL", fileURL)
//                try FileManager.default.removeItem(at: fileURL)
//            }
//        } catch  {
//            print(error)
//        }
//    }
//}
//
//extension ParentPostViewController: UITextFieldDelegate, UITextViewDelegate {
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        showKeyboard = false
//        mdbvc.view.alpha = 0
//    }
//    
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        showKeyboard = false
//        mdbvc.view.alpha = 0
//    }
//}
//
//extension ParentPostViewController {
//    //    let eventABI = [
//    //        {
//    //            "indexed": true,
//    //            "internalType": "address",
//    //            "name": "from",
//    //            "type": "address"
//    //        },
//    //        {
//    //            "indexed": true,
//    //            "internalType": "address",
//    //            "name": "to",
//    //            "type": "address"
//    //        },
//    //        {
//    //            "indexed": true,
//    //            "internalType": "uint256",
//    //            "name": "tokenId",
//    //            "type": "uint256"
//    //        }
//    //    ]
//    
//    func mint(_ hash: Data) {
//        
//        
//        //        let from = ABI.Element.InOut(name: "from", type: .address)
//        //        let to = ABI.Element.InOut(name: "to", type: .address)
//        //        let tokenId = ABI.Element.InOut(name: "tokenId", type: .uint(bits: 256))
//        //        let abiElement = ABI.Element.Function(name: "Transfer", inputs: [from, to, tokenId], outputs: [], constant: false, payable: false)
//        //        print("abiElement", abiElement)
//        
//        //                let from = ABI.Element.Event.Input(name: "from", type: .address, indexed: true)
//        //                let to = ABI.Element.Event.Input(name: "to", type: .address, indexed: true)
//        //                let tokenId = ABI.Element.Event.Input(name: "tokenId", type: .uint(bits: 256), indexed: true)
//        //                let abiEvent = ABI.Element.Event(name: "Transfer", inputs: [from, to, tokenId], anonymous: false)
//        //                print("abiEvent", abiEvent)
//        //
//        //                let eventLogData = Data(base64Encoded: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef")
//        //                let eventLogTopics = [
//        //                    Data(base64Encoded: "0x0000000000000000000000000000000000000000000000000000000000000000")!,
//        //                    Data(base64Encoded: "0x0000000000000000000000006879f0a123056b5bb56c7e787cf64a67f3a16a71")!,
//        //                    Data(base64Encoded: "0x0000000000000000000000000000000000000000000000000000000000000030")!
//        //                ]
//        //
//        //                let decodedLog = ABIDecoder.decodeLog(event: abiEvent, eventLogTopics: eventLogTopics, eventLogData: eventLogData!)
//        //                print("decodedLog", decodedLog as Any)
//    }
//}
//
//extension ParentPostViewController: MessageDelegate, ImageUploadable {
//    // MARK: - didReceiveMessage
//    @objc func didReceiveMessage(topics: [String]) {
//        // get the token ID to be uploaded to Firestore
//        getTokenId(topics: topics) { [weak self](tokenId, error) in
//            if let error = error {
//                self?.alert.showDetail("Token ID Fetch Error", with: error.localizedDescription, for: self)
//            }
//            
//            if let tokenId = tokenId {
//                FirebaseService.shared.db.collection("post").document(self!.documentId).updateData([
//                    "tokenId": tokenId
//                ]) { (error) in
//                    if let error = error {
//                        self?.alert.showDetail("Error Loading TokenID", with: error.localizedDescription, for: self)
//                    } else {
//                        defer {
//                            let update: [String: PostProgress] = ["update": .images]
//                            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                            self?.titleTextField.text?.removeAll()
//                            self?.priceTextField.text?.removeAll()
//                            self?.descTextView.text?.removeAll()
//                            self?.idTextField.text?.removeAll()
//                            self?.pickerLabel.text?.removeAll()
//                            self?.tagTextField.tokens.removeAll()
//                            
//                            //                            self?.alert.showDetail("Success", with: "You have successfully minted a token", for: self) {
//                            //                                self?.titleTextField.text?.removeAll()
//                            //                                self?.priceTextField.text?.removeAll()
//                            //                                self?.descTextView.text?.removeAll()
//                            //                                self?.idTextField.text?.removeAll()
//                            //                                self?.pickerLabel.text?.removeAll()
//                            //                                self?.tagTextField.tokens.removeAll()
//                            //                            }
//                        }
//                        // disconnect socket
//                        self?.socketDelegate.disconnectSocket()
//                        var imageCount: Int = 0
//                        // upload images and delete them afterwards
//                        if self!.imageNameArr.count > 0, let imageNameArr = self?.imageNameArr {
//                            defer {
//                                let update: [String: PostProgress] = ["update": .images]
//                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                            }
//                            for image in imageNameArr {
//                                self?.uploadFile(image: image, userId: self!.userId) {(url) in
//                                    defer {
//                                        print("after getting url")
//                                    }
//                                    FirebaseService.shared.db.collection("post").document(self!.documentId).updateData([
//                                        "images": FieldValue.arrayUnion(["\(url)"])
//                                    ], completion: { (error) in
//                                        defer {
//                                            /// this runs last. place the success alert here. use the same image counter to check if all the images have been fulfilled
//                                            /// there has to be a success alert for if you don't have images to upload
//                                            print("after update data")
//                                        }
//                                        if let error = error {
//                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                        }
//                                    })
//                                }
//                                imageCount += 1
//                                if imageCount == imageNameArr.count, let ipvc = self?.imagePreviewVC {
//                                    self?.imageNameArr.removeAll()
//                                    ipvc.data.removeAll()
//                                    ipvc.collectionView.reloadData()
//                                    for imageName in imageNameArr {
//                                        self?.deleteFile(fileName: imageName)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - getTokenId
//    func getTokenId(topics: [String], completion: @escaping (String?, Error?) -> Void) {
//        // build request URL
//        guard let requestURL = URL(string: "https://us-central1-nftrack-69488.cloudfunctions.net/decodeLog") else {
//            return
//        }
//        
//        // prepare request
//        var request = URLRequest(url: requestURL)
//        request.httpMethod = "POST"
//        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
//        
//        let parameter: [String: Any] = [
//            "hexString": topics[0],
//            "topics": [
//                topics[1],
//                topics[2],
//                topics[3]
//            ]
//        ]
//        
//        let paramData = try? JSONSerialization.data(withJSONObject: parameter, options: [])
//        request.httpBody = paramData
//        
//        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
//            if let error = error {
//                completion(nil, error)
//            }
//            
//            
//            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
//                // handle HTTP server-side error
//                completion(nil, error)
//            }
//            
//            if let data = data {
//                do {
//                    if let responseObj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0)) as? [String:Any],
//                       let tokenId = responseObj["tokenId"] as? String {
//                        completion(tokenId, nil)
//                    }
//                } catch {
//                    completion(nil, error)
//                }
//            }
//        })
//        
//        observation = task.progress.observe(\.fractionCompleted) { (progress, _) in
//            print("progress", progress)
//            DispatchQueue.main.async {
//                //                self?.progressView.progress = Float(progress.fractionCompleted)
//                //                self?.progressLabel.text = String(Int(progress.fractionCompleted * 100)) + "%"
//            }
//        }
//        
//        task.resume()
//    }
//}
//
//extension ParentPostViewController {
//    func saveFile(fileName: String) {
//        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
//        let fileURL = documentsDirectory.appendingPathComponent(fileName)
//        
//        //Checks if file exists, removes it if so.
//        if FileManager.default.fileExists(atPath: fileURL.path) {
//            do {
//                try FileManager.default.removeItem(atPath: fileURL.path)
//            } catch let removeError {
//                print("couldn't remove file at path", removeError)
//            }
//        }
//        
//        do {
//            let data = try Data(contentsOf: fileURL)
//            try data.write(to: fileURL)
//        } catch let error {
//            print("error saving file with error", error)
//        }
//    }
//}
//
//// MARK: - QLPreviewItem
//class CustomPreviewItem: NSObject, QLPreviewItem {
//    var previewItemURL: URL?
//    var previewItemTitle: String?
//    
//    init(url: URL, title: String?) {
//        previewItemURL = url
//        previewItemTitle = title
//    }
//}
//
//// MARK: - QuickLookThumbnailing
//extension CustomPreviewItem {
//    func generateThumbnail(completion: @escaping (UIImage) -> Void) {
//        // 1
//        let size = CGSize(width: 128, height: 102)
//        let scale = UIScreen.main.scale
//        // 2
//        let request = QLThumbnailGenerator.Request(
//            fileAt: previewItemURL!,
//            size: size,
//            scale: scale,
//            representationTypes: .all)
//        
//        // 3
//        let generator = QLThumbnailGenerator.shared
//        generator.generateBestRepresentation(for: request) { thumbnail, error in
//            if let thumbnail = thumbnail {
//                completion(thumbnail.uiImage)
//            } else if let error = error {
//                // Handle error
//                print(error)
//            }
//        }
//    }
//}
//
//
///// hash image
///// https://stackoverflow.com/questions/55868751/sha256-hash-of-camera-image-differs-after-it-was-saved-to-photo-album
////let imageData = UIImage(named: "Example")!.pngData()!
////print(imageData.base64EncodedString())
////// 'iVBORw0KGgoAAAANSUhEUgAAAG8AAACACAQAAACv3v+8AAAM82lD [...] gAAAABJRU5ErkJggg=='
////let imageHash = getImageHash(data: imageData)
////print(imageHash)
////// '145036245c9f675963cc8de2147887f9feded5813b0539d2320d201d9ce63397'


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


//
//  ParentDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//
/*
 Abstract:
 Parent view controller for ListDetailViewController and HistoryDetailViewControler
 */
//
//import UIKit
//import web3swift
//import Firebase
//import FirebaseFirestore
//import BigInt
//
//class ParentDetailViewController: UIViewController {
//    // MARK: - Properties
//    let alert = Alerts()
//    let transactionService = TransactionService()
//    var scrollView: UIScrollView!
//    var contractAddress: EthereumAddress!
//    var post: Post!
//    var pvc: UIPageViewController!
//    var galleries = [String]()
//    var usernameContainer: UIView!
//    var dateLabel: UILabel!
//    let profileImageView = UIImageView()
//    var displayNameLabel = UILabel()
//    var underLineView: UnderlineView!
//    var priceTitleLabel: UILabel!
//    var priceLabel: UILabelPadding!
//    var descTitleLabel: UILabel!
//    var descLabel: UILabelPadding!
//    var idTitleLabel: UILabel!
//    var idLabel: UILabelPadding!
//    var constraints = [NSLayoutConstraint]()
//    var fetchedImage: UIImage!
//    var userInfo: UserInfo! {
//        didSet {
//            userInfoDidSet()
//        }
//    }
//    
//    // to refresh after update
//    weak var tableViewRefreshDelegate: TableViewRefreshDelegate?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        configureBackground()
//        fetchUserData(id: post.sellerUserId)
//        configureImageDisplay()
//        configureUI()
//        setConstraints()
//    }
//}
//
//extension ParentDetailViewController {
//    // MARK: - configureBackground
//    func configureBackground() {
//        view.backgroundColor = .white
//        scrollView = UIScrollView()
//        scrollView.backgroundColor = .white
//        view.addSubview(scrollView)
//        scrollView.fill()
//    }
//    
//    func fetchUserData(id: String) {
//        DispatchQueue.global(qos: .utility).async {
//            let docRef = FirebaseService.shared.db.collection("user").document(id)
//            docRef.getDocument { [weak self] (document, error) in
//                if let document = document, document.exists {
//                    if let data = document.data() {
//                        let displayName = data[UserDefaultKeys.displayName] as? String
//                        let photoURL = data[UserDefaultKeys.photoURL] as? String
//                        let userInfo = UserInfo(email: nil, displayName: displayName!, photoURL: photoURL, uid: id)
//                        self?.userInfo = userInfo
//                    }
//                } else {
//                    self?.hideSpinner {
//                        return
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - configureImageDisplay
//    func configureImageDisplay() {
//        // image
//        if let files = post.files, files.count > 0 {
//            self.galleries.append(contentsOf: files)
//            let singlePageVC = ImagePageViewController(gallery: galleries[0])
//            pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
//            pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
//            pvc.dataSource = self
//            pvc.delegate = self
//            addChild(pvc)
//            scrollView.addSubview(pvc.view)
//            pvc.view.translatesAutoresizingMaskIntoConstraints = false
//            pvc.didMove(toParent: self)
//            
//            let pageControl = UIPageControl.appearance()
//            pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
//            pageControl.currentPageIndicatorTintColor = .gray
//            pageControl.backgroundColor = .white
//        }
//    }
//    
//    @objc func userInfoDidSet() {
//        displayNameLabel.text = userInfo.displayName
//        if let info = self.userInfo, info.photoURL != "NA" {
//            FirebaseService.shared.downloadImage(urlString: self.userInfo.photoURL!) { [weak self] (image, error) in
//                guard let strongSelf = self else { return }
//                if let error = error {
//                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: strongSelf)
//                }
//                
//                if let image = image {
//                    strongSelf.fetchedImage = image
//                    strongSelf.profileImageView.image = image
//                    strongSelf.profileImageView.layer.cornerRadius = strongSelf.profileImageView.bounds.height/2.0
//                    strongSelf.profileImageView.contentMode = .scaleToFill
//                    strongSelf.profileImageView.clipsToBounds = true
//                    
//                    strongSelf.profileImageView.isUserInteractionEnabled = true
//                    strongSelf.displayNameLabel.isUserInteractionEnabled = true
//                }
//            }
//        } else {
//            profileImageView.isUserInteractionEnabled = true
//            displayNameLabel.isUserInteractionEnabled = true
//        }
//    }
//    
//    // MARK: - configureUI
//    @objc func configureUI() {
//        usernameContainer = UIView()
//        usernameContainer.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(usernameContainer)
//        
//        dateLabel = UILabel()
//        dateLabel.textAlignment = .right
//        let formatter = DateFormatter()
//        formatter.dateStyle = .long
//        let formattedDate = formatter.string(from: post.date)
//        dateLabel.text = formattedDate
//        dateLabel.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(dateLabel)
//        
//        guard let image = UIImage(systemName: "person.crop.circle.fill") else {
//            self.dismiss(animated: true, completion: nil)
//            return
//        }
//        let profileImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal)
//        profileImageView.image = profileImage
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
//        profileImageView.addGestureRecognizer(tap)
//        profileImageView.tag = 1
//        profileImageView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(profileImageView)
//        
//        displayNameLabel.addGestureRecognizer(tap)
//        displayNameLabel.tag = 1
//        displayNameLabel.text = userInfo?.displayName
//        displayNameLabel.lineBreakMode = .byTruncatingTail
//        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(displayNameLabel)
//        
//        underLineView = UnderlineView()
//        underLineView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(underLineView)
//        
//        priceTitleLabel = createTitleLabel(text: "Price")
//        scrollView.addSubview(priceTitleLabel)
//        
//        priceLabel = createLabel(text: "\(post.price!) ETH")
//        scrollView.addSubview(priceLabel)
//        
//        descTitleLabel = createTitleLabel(text: "Description")
//        scrollView.addSubview(descTitleLabel)
//        
//        descLabel = createLabel(text: post.description)
//        descLabel.lineBreakMode = .byClipping
//        descLabel.numberOfLines = 0
//        descLabel.sizeToFit()
//        descLabel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
//        scrollView.addSubview(descLabel)
//        
//        idTitleLabel = createTitleLabel(text: "Unique Identifier")
//        scrollView.addSubview(idTitleLabel)
//        
//        idLabel = createLabel(text: post.id)
//        idLabel.lineBreakMode = .byClipping
//        idLabel.numberOfLines = 0
//        idLabel.sizeToFit()
//        idLabel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
//        scrollView.addSubview(idLabel)
//    }
//    
//    //    // MARK: - configureEditButton
//    //    func configureEditButton() {
//    //        buttonPanel = UIView()
//    //        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
//    //        scrollView.addSubview(buttonPanel)
//    //
//    //        editButton = UIButton()
//    //        editButton.tag = 3
//    //        editButton.backgroundColor = .blue
//    //        editButton.setTitle("Edit", for: .normal)
//    //        editButton.layer.cornerRadius = 5
//    //        editButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//    //        editButton.translatesAutoresizingMaskIntoConstraints = false
//    //        buttonPanel.addSubview(editButton)
//    //
//    //        deleteButton = UIButton()
//    //        deleteButton.tag = 4
//    //        deleteButton.backgroundColor = .red
//    //        deleteButton.setTitle("Delete", for: .normal)
//    //        deleteButton.layer.cornerRadius = 6
//    //        deleteButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//    //        deleteButton.translatesAutoresizingMaskIntoConstraints = false
//    //        buttonPanel.addSubview(deleteButton)
//    //
//    //        NSLayoutConstraint.activate([
//    //            buttonPanel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
//    //            buttonPanel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//    //            buttonPanel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//    //            buttonPanel.heightAnchor.constraint(equalToConstant: 50),
//    //
//    //            editButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
//    //            editButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
//    //            editButton.heightAnchor.constraint(equalToConstant: 50),
//    //            editButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
//    //
//    //            deleteButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
//    //            deleteButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
//    //            deleteButton.heightAnchor.constraint(equalToConstant: 50),
//    //            deleteButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4)
//    //        ])
//    //    }
//    //
//    // MARK: - setConstraints
//    @objc func setConstraints() {
//        if let files = post.files, files.count > 0 {
//            guard let pv = pvc.view else { return }
//            constraints.append(contentsOf: [
//                pv.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0),
//                pv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                pv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//                pv.heightAnchor.constraint(equalToConstant: 250),
//                dateLabel.topAnchor.constraint(equalTo: pv.bottomAnchor, constant: 50),
//                profileImageView.topAnchor.constraint(equalTo: pv.bottomAnchor, constant: 50),
//                displayNameLabel.topAnchor.constraint(equalTo: pv.bottomAnchor, constant: 50)
//            ])
//        } else {
//            constraints.append(contentsOf: [
//                dateLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
//                profileImageView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
//                displayNameLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50)
//            ])
//        }
//        
//        constraints.append(contentsOf: [
//            dateLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            dateLabel.heightAnchor.constraint(equalToConstant: 50),
//            dateLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.4),
//            
//            profileImageView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            profileImageView.heightAnchor.constraint(equalToConstant: 40),
//            profileImageView.widthAnchor.constraint(equalToConstant: 40),
//            
//            displayNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
//            displayNameLabel.heightAnchor.constraint(equalToConstant: 50),
//            displayNameLabel.widthAnchor.constraint(lessThanOrEqualTo: scrollView.widthAnchor, multiplier: 0.6),
//            
//            underLineView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
//            underLineView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            underLineView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            underLineView.heightAnchor.constraint(equalToConstant: 0.5),
//            
//            priceTitleLabel.topAnchor.constraint(equalTo: underLineView.bottomAnchor, constant: 40),
//            priceTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            priceTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            priceTitleLabel.heightAnchor.constraint(equalToConstant: 50),
//            
//            priceLabel.topAnchor.constraint(equalTo: priceTitleLabel.bottomAnchor, constant: 0),
//            priceLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            priceLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            priceLabel.heightAnchor.constraint(equalToConstant: 50),
//            
//            descTitleLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 40),
//            descTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            descTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            
//            descLabel.topAnchor.constraint(equalTo: descTitleLabel.bottomAnchor, constant: 10),
//            descLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            descLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            descLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
//            
//            idTitleLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 40),
//            idTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            idTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            
//            idLabel.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 10),
//            idLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            idLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            idLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
//        ])
//        
//        NSLayoutConstraint.activate(constraints)
//    }
//    
//    @objc func tapped(_ sender: UITapGestureRecognizer!) {
//        let tag = sender.view?.tag
//        switch tag {
//            case 1:
//                let profileDetailVC = ProfileDetailViewController()
//                profileDetailVC.userInfo = userInfo
//                profileDetailVC.profileImage = fetchedImage
//                self.navigationController?.pushViewController(profileDetailVC, animated: true)
//            default:
//                break
//        }
//    }
//}
//
//extension ParentDetailViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
//        index -= 1
//        if index < 0 {
//            return nil
//        }
//        
//        return ImagePageViewController(gallery: galleries[index])
//    }
//    
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
//        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
//        index += 1
//        if index >= galleries.count {
//            return nil
//        }
//        
//        return ImagePageViewController(gallery: galleries[index])
//    }
//    
//    func presentationCount(for pageViewController: UIPageViewController) -> Int {
//        return self.galleries.count
//    }
//    
//    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
//        let page = pageViewController.viewControllers![0] as! ImagePageViewController
//        
//        if let gallery = page.gallery {
//            return self.galleries.firstIndex(of: gallery)!
//        } else {
//            return 0
//        }
//    }
//}
//
////FirebaseService.sharedInstance.db.collection("escrow").whereField("postId", isEqualTo: post.postId)
////    .getDocuments() { [weak self](querySnapshot, err) in
////        if let err = err {
////            print("Error getting documents: \(err)")
////        } else {
////            for document in querySnapshot!.documents {
////                let data = document.data()
////                guard let txHash = data["transactionHash"] as? String else { return }
////                DispatchQueue.global().async {
////                    do {
////                        let receipt = try Web3swiftService.web3instance.eth.getTransactionReceipt(txHash)
////                        self?.contractAddress = receipt.contractAddress
////                        self?.transactionService.prepareTransactionForReading(method: "state", contractAddress: receipt.contractAddress!, completion: { (transaction, error) in
////                            if let error = error {
////                                switch error {
////                                    case .contractLoadingError:
////                                        self?.alert.showDetail("Error", with: "Contract Loading Error", for: self)
////                                    case .createTransactionIssue:
////                                        self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self)
////                                    default:
////                                        self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
////                                }
////                            }
////
////                            if let transaction = transaction {
////                                DispatchQueue.global().async {
////                                    do {
////                                        self?.result = try transaction.call()
////                                        print("result", self?.result as Any)
////                                        //                                                self?.status = result["0"] as String
////                                    } catch {
////                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
////                                    }
////                                }
////                            }
////                        })
////                    } catch {
////                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
////                    }
////                }
////            }
////        }
////    }
//
//// 20.8769
//
//let eventABI = """
//        [
//        {
//        "indexed": true,
//        "internalType": "address",
//        "name": "from",
//        "type": "address"
//        },
//        {
//        "indexed": true,
//        "internalType": "address",
//        "name": "to",
//        "type": "address"
//        },
//        {
//        "indexed": true,
//        "internalType": "uint256",
//        "name": "tokenId",
//        "type": "uint256"
//        }
//        ]
//        """

//
//  SearchResultsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//
//
//import UIKit
//import FirebaseFirestore
//
//class SearchResultsController: ParentListViewController<Post> {
//    private var lastSnapshot: QueryDocumentSnapshot!
//    private let db = FirebaseService.shared
//    typealias FetchResult = Post
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        db.searchResultDelegate = self
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: animated)
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: animated)
//    }
//    
//    override func configureUI() {
//        super.configureUI()
//        
//        tableView = configureTableView(delegate: self, dataSource: self, height: 330, cellType: CardCell.self, identifier: CardCell.identifier)
//        tableView.prefetchDataSource = self
//        view.addSubview(tableView)
//        tableView.fill()
//    }
//    
//    override func setDataStore(postArr: [Post]) {
//        dataStore = PostImageDataStore(posts: postArr)
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.identifier) as? CardCell else {
//            fatalError("Sorry, could not load cell")
//        }
//        cell.selectionStyle = .none
//        let post = postArr[indexPath.row]
//        cell.updateAppearanceFor(.pending(post))
//        return cell
//    }
//    
//    //    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//    //        guard let cell = cell as? CardCell else { return }
//    //
//    //        // How should the operation update the cell once the data has been loaded?
//    //        let updateCellClosure: (UIImage?) -> () = { [unowned self] (image) in
//    //            cell.updateAppearanceFor(.fetched(image))
//    //            self.loadingOperations.removeValue(forKey: indexPath)
//    //        }
//    //
//    //        // Try to find an existing data loader
//    //        if let dataLoader = loadingOperations[indexPath] {
//    //            // Has the data already been loaded?
//    //            if let image = dataLoader.image {
//    //                cell.updateAppearanceFor(.fetched(image))
//    //                loadingOperations.removeValue(forKey: indexPath)
//    //            } else {
//    //                // No data loaded yet, so add the completion closure to update the cell once the data arrives
//    //                dataLoader.loadingCompleteHandler = updateCellClosure
//    //            }
//    //        } else {
//    //            // Need to create a data loaded for this index path
//    //            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
//    //                // Provide the completion closure, and kick off the loading operation
//    //                dataLoader.loadingCompleteHandler = updateCellClosure
//    //                loadingQueue.addOperation(dataLoader)
//    //                loadingOperations[indexPath] = dataLoader
//    //            }
//    //        }
//    //    }
//    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let listDetailVC = ListDetailViewController()
//        listDetailVC.post = postArr[indexPath.row]
//        self.navigationController?.pushViewController(listDetailVC, animated: true)
//    }
//    
//}
//
//extension SearchResultsController: PaginateFetchDelegate {
//    func didGetLastSnapshot(_ lastSnapshot: QueryDocumentSnapshot) {
//        self.lastSnapshot = lastSnapshot
//    }
//    
//    func didFetchPaginate(postArr: [Post]?,  error: Error?) {
//        if let error = error {
//            self.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
//        }
//        
//        if let postArr = postArr {
//            self.postArr.append(contentsOf:postArr)
//        }
//    }
//    
//    
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        let offset = scrollView.contentOffset
//        let bounds = scrollView.bounds
//        let size = scrollView.contentSize
//        let inset = scrollView.contentInset
//        let y = offset.y + bounds.size.height - inset.bottom
//        let h = size.height
//        let reload_distance:CGFloat = 10.0
//        if y > (h + reload_distance) {
//            //            guard let uid = userInfo.uid else { return }
//            //            db.refetchReviews(uid: uid, lastSnapshot: self.lastSnapshot)
//        }
//    }
//}


//
//  TangibleAssetViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-28.
//

//import UIKit
//import web3swift
//import CryptoKit
//import BigInt
//import Combine
//
//enum SaleFormat: String {
//    case onlineDirect = "Online Direct"
//    case openAuction = "Open Auction"
//}
//
//class DigitalAssetViewController: ParentPostViewController {
//    lazy var idContainerViewHeightConstraint: NSLayoutConstraint = idContainerView.heightAnchor.constraint(equalToConstant: 50)
//    lazy var idTitleLabelHeightConstraint: NSLayoutConstraint = idTitleLabel.heightAnchor.constraint(equalToConstant: 50)
//    
//    var auctionDurationTitleLabel: UILabel!
//    var auctionDurationLabel: UILabel!
//    var auctionStartingPriceTitleLabel: UILabel!
//    var auctionStartingPriceTextField: UITextField!
//    /// for auction duration
//    let auctionDurationPicker = MyPickerVC(currentPep: "3", pep: Array(3...20).map { String($0) })
//    /// sale format for digital
//    let saleFormatPicker = MyPickerVC(currentPep: SaleFormat.onlineDirect.rawValue, pep: [SaleFormat.onlineDirect.rawValue, SaleFormat.openAuction.rawValue])
//    let CONTENT_SIZE_HEIGHT_WITH_AUCTION_FIELDS: CGFloat = 1850
//    
//    // to be used for transferring the token into the auction contract
//    var auctionHash: String!
//    var walletAuthorizationCode: String!
//    var getTxReceipt: AnyCancellable?
//    
//    override var previewDataArr: [PreviewData]! {
//        didSet {
//            if previewDataArr.count > 0 {
//                DispatchQueue.main.async { [weak self] in
//                    self?.idTitleLabelHeightConstraint.constant = 50
//                    self?.idContainerViewHeightConstraint.constant = 50
//                    self?.idTitleLabel.isHidden = false
//                    self?.idContainerView.isHidden = false
//                    UIView.animate(withDuration: 0.5) {
//                        self?.view.layoutIfNeeded()
//                    }
//                }
//            } else {
//                DispatchQueue.main.async { [weak self] in
//                    self?.idTitleLabel.isHidden = true
//                    self?.idTitleLabelHeightConstraint.constant = 0
//                    
//                    self?.idContainerView.isHidden = true
//                    self?.idContainerViewHeightConstraint.constant = 0
//                    UIView.animate(withDuration: 0.5) {
//                        self?.view.layoutIfNeeded()
//                    }
//                }
//            }
//        }
//    }
//    
//    override var panelButtons: [PanelButton] {
//        let buttonPanels = [
//            PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
//            PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
//        ]
//        return buttonPanels
//    }
//    
//    var saleFormatObserver: NSKeyValueObservation?
//    final override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        saleFormatObserver = saleMethodLabel.observe(\.text) { [weak self] (label, observedChange) in
//            guard let text = label.text, let saleFormat = SaleFormat(rawValue: text) else { return }
//            switch saleFormat {
//                case .onlineDirect:
//                    self?.paymentMethodLabel.text = PaymentMethod.escrow.rawValue
//                    self?.auctionDurationLabel.isUserInteractionEnabled = false
//                    
//                    /// hide the auction duration and the starting price labels when the sale format is selected to open auction
//                    DispatchQueue.main.async { [weak self] in
//                        self?.saleMethodContainerConstraintHeight.constant = 50
//                        self?.priceTextFieldConstraintHeight.constant = 50
//                        self?.priceTextField.alpha = 1
//                        self?.priceLabelConstraintHeight.constant = 50
//                        self?.priceLabel.alpha = 1
//                        self?.auctionDurationTitleLabel.alpha = 0
//                        self?.auctionDurationLabel.alpha = 0
//                        self?.auctionStartingPriceTitleLabel.alpha = 0
//                        self?.auctionStartingPriceTextField.alpha = 0
//                        UIView.animate(withDuration: 0.5) {
//                            self?.view.layoutIfNeeded()
//                        }
//                        
//                        guard let `self` = self else { return }
//                        //                        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.scrollView.contentSize.height - self.AUCTION_FIELDS_HEIGHT)
//                        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
//                    }
//                case .openAuction:
//                    self?.paymentMethodLabel.text = PaymentMethod.auctionBeneficiary.rawValue
//                    /// show the auction duration and the starting price labels when the sale format is selected to open auction
//                    DispatchQueue.main.async { [weak self] in
//                        self?.saleMethodContainerConstraintHeight.constant = 290
//                        self?.auctionDurationLabel.isUserInteractionEnabled = true
//                        self?.priceLabelConstraintHeight.constant = 0
//                        self?.priceLabel.alpha = 0
//                        self?.priceTextFieldConstraintHeight.constant = 0
//                        self?.priceTextField.alpha = 0
//                        
//                        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {
//                            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
//                                self?.view.layoutIfNeeded()
//                            }
//                            
//                            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.3) {
//                                self?.auctionDurationTitleLabel.alpha = 1
//                                self?.auctionDurationLabel.alpha = 1
//                                
//                                self?.auctionStartingPriceTitleLabel.alpha = 1
//                                self?.auctionStartingPriceTextField.alpha = 1
//                            }
//                        } completion: { (_) in
//                            guard let `self` = self else { return }
//                            self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.CONTENT_SIZE_HEIGHT_WITH_AUCTION_FIELDS)
//                        }
//                    }
//            }
//        }
//    }
//    
//    final override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        if saleFormatObserver != nil {
//            saleFormatObserver?.invalidate()
//        }
//    }
//    
//    override func configureUI() {
//        super.configureUI()
//        
//        deliveryInfoButton.isHidden = true
//        deliveryInfoButton.isEnabled = false
//        deliveryMethodLabel.text = "Online Transfer"
//        
//        paymentInfoButton.tag = 21
//        paymentMethodLabel.isUserInteractionEnabled = true
//        paymentMethodLabel.tag = 50
//        let paymentMethodTap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
//        paymentMethodLabel.addGestureRecognizer(paymentMethodTap)
//        
//        saleMethodInfoButton.tag = 23
//        
//        saleMethodLabel.isUserInteractionEnabled = true
//        saleMethodLabel.tag = 3
//        let saleMethodTap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy))
//        saleMethodLabel.addGestureRecognizer(saleMethodTap)
//        
//        pickerLabel.text = "Digital"
//        
//        auctionDurationTitleLabel = createTitleLabel(text: "Auction Duration")
//        auctionDurationTitleLabel.alpha = 0
//        saleMethodLabelContainer.addSubview(auctionDurationTitleLabel)
//        
//        auctionDurationLabel = createLabel(text: "")
//        auctionDurationLabel.alpha = 0
//        /// for picker
//        auctionDurationLabel.tag = 50
//        auctionDurationLabel.textColor = .lightGray
//        auctionDurationLabel.text = "Number of days"
//        saleMethodLabelContainer.addSubview(auctionDurationLabel)
//        
//        let auctionDurationTap = UITapGestureRecognizer(target: self, action: #selector(doPickBoy(_:)))
//        auctionDurationLabel.addGestureRecognizer(auctionDurationTap)
//        
//        auctionStartingPriceTitleLabel = createTitleLabel(text: "Auction Starting Price")
//        auctionStartingPriceTitleLabel.alpha = 0
//        saleMethodLabelContainer.addSubview(auctionStartingPriceTitleLabel)
//        
//        auctionStartingPriceTextField = createTextField(placeHolder: "In ETH", content: nil, delegate: self)
//        auctionStartingPriceTextField.keyboardType = .decimalPad
//        auctionStartingPriceTextField.alpha = 0
//        saleMethodLabelContainer.addSubview(auctionStartingPriceTextField)
//    }
//    
//    override func setConstraints() {
//        super.setConstraints()
//        
//        NSLayoutConstraint.activate([
//            auctionDurationTitleLabel.topAnchor.constraint(equalTo: saleMethodLabel.bottomAnchor, constant: 20),
//            auctionDurationTitleLabel.heightAnchor.constraint(equalToConstant: 50),
//            auctionDurationTitleLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
//            auctionDurationTitleLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
//            
//            auctionDurationLabel.topAnchor.constraint(equalTo: auctionDurationTitleLabel.bottomAnchor),
//            auctionDurationLabel.heightAnchor.constraint(equalToConstant: 50),
//            auctionDurationLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
//            auctionDurationLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
//            
//            auctionStartingPriceTitleLabel.topAnchor.constraint(equalTo: auctionDurationLabel.bottomAnchor, constant: 20),
//            auctionStartingPriceTitleLabel.heightAnchor.constraint(equalToConstant: 50),
//            auctionStartingPriceTitleLabel.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
//            auctionStartingPriceTitleLabel.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
//            
//            auctionStartingPriceTextField.topAnchor.constraint(equalTo: auctionStartingPriceTitleLabel.bottomAnchor),
//            auctionStartingPriceTextField.heightAnchor.constraint(equalToConstant: 50),
//            auctionStartingPriceTextField.leadingAnchor.constraint(equalTo: saleMethodLabelContainer.leadingAnchor),
//            auctionStartingPriceTextField.trailingAnchor.constraint(equalTo: saleMethodLabelContainer.trailingAnchor),
//        ])
//    }
//    
//    override func createIDField() {
//        idContainerView = UIView()
//        idContainerView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(idContainerView)
//        
//        idTextField = createTextField(delegate: self)
//        idTextField.autocapitalizationType = .none
//        idTextField.isUserInteractionEnabled = false
//        idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
//        idContainerView.addSubview(idTextField)
//    }
//    
//    override func setIDFieldConstraints() {
//        constraints.append(contentsOf: [
//            idTitleLabel.topAnchor.constraint(equalTo: tagContainerView.bottomAnchor, constant: 20),
//            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            idTitleLabelHeightConstraint,
//            
//            idContainerView.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
//            idContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            idContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
//            idContainerViewHeightConstraint,
//            
//            idTextField.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: 1),
//            idTextField.heightAnchor.constraint(equalToConstant: 50),
//        ])
//    }
//    
//    override func configureImagePreview() {
//        configureImagePreview(postType: .digital)
//    }
//    
//    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        super.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
//        
//        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//            print("No image found")
//            return
//        }
//        
//        if let imageData = originalImage.pngData() {
//            let hashedImage = SHA256.hash(data: imageData)
//            let imageHash = hashedImage.description
//            if let index = imageHash.firstIndex(of: ":") {
//                let newIndex = imageHash.index(after: index)
//                let newStr = imageHash[newIndex...]
//                idTextField.text = newStr.description
//            }
//        }
//    }
//    
//    final override func buttonPressed(_ sender: UIButton) {
//        super.buttonPressed(sender)
//        
//        switch sender.tag {
//            case 21:
//                /// payment method info button
//                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Auction Beneficiary", detail: InfoText.auctionBeneficiary), InfoModel(title: "Escrow", detail: InfoText.escrow)])
//                self.present(infoVC, animated: true, completion: nil)
//            case 23:
//                /// sale format info button
//                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Online Direct", detail: InfoText.onlineDigital), InfoModel(title: "Open Auction", detail: InfoText.auction)])
//                self.present(infoVC, animated: true, completion: nil)
//            default:
//                break
//        }
//    }
//    
//    @objc final func tapped(_ sender: UITapGestureRecognizer) {
//        /// payment method label
//        let detailVC = DetailViewController(messageTextAlignment: .left)
//        detailVC.titleString = "Payment Method"
//        detailVC.message = "The payment method for digital items is determined by the sale format. Please select from the picker right below the payment method's field."
//        detailVC.buttonAction = { [weak self] _ in
//            self?.dismiss(animated: true, completion: nil)
//        }
//        self.present(detailVC, animated: true, completion: nil)
//    }
//    
//    final override func processMint(price: String?, title: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
//        
//        guard let sm = SaleFormat(rawValue: saleFormat) else { return }
//        switch sm {
//            case .onlineDirect:
//                guard let price = price, !price.isEmpty else {
//                    self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
//                    return
//                }
//                
//                onlineDirect(price: price, title: title, desc: desc, category: category, convertedId: convertedId, tokensArr: tokensArr, userId: userId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod)
//            case .openAuction:
//                guard let auctionDuration = auctionDurationLabel.text,
//                      !auctionDuration.isEmpty else {
//                    self.alert.showDetail("Incomplete", with: "Please specify the auction duration.", for: self)
//                    return
//                }
//                guard let auctionStartingPrice = auctionStartingPriceTextField.text,
//                      !auctionStartingPrice.isEmpty else {
//                    self.alert.showDetail("Incomplete", with: "Please specify the starting price for your auction.", for: self)
//                    return
//                }
//                
//                auction(price: "0", title: title, desc: desc, category: category, convertedId: convertedId, tokensArr: tokensArr, userId: userId, deliveryMethod: deliveryMethod, saleFormat: saleFormat, paymentMethod: paymentMethod, auctionDuration: auctionDuration, auctionStartingPrice: auctionStartingPrice)
//        }
//    }
//    
//    final func onlineDirect(price: String, title: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String) {
//        // escrow deployment
//        self.transactionService.prepareTransactionForNewContract(contractABI: purchaseABI2, value: String(price), completion: { [weak self](transaction, error, estimatedGasForDeploying) in
//            guard let `self` = self else { return }
//            if let error = error {
//                switch error {
//                    case .invalidAmountFormat:
//                        self.alert.showDetail("Error", with: "The price is in a wrong format", for: self)
//                    case .contractLoadingError:
//                        self.alert.showDetail("Error", with: "Escrow Contract Loading Error", for: self)
//                    case .createTransactionIssue:
//                        self.alert.showDetail("Error", with: "Escrow Contract Transaction Issue", for: self)
//                    case .retrievingEstimatedGasError:
//                        self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
//                    case .retrievingCurrentAddressError:
//                        self.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
//                    default:
//                        self.alert.showDetail("Error", with: "There was an error deploying your escrow contract.", for: self)
//                }
//            }
//            
//            // minting
//            self.transactionService.prepareTransactionForMinting { (mintTransaction, mintError, estimatedGasForMinting) in
//                if let error = mintError {
//                    switch error {
//                        case .contractLoadingError:
//                            self.alert.showDetail("Error", with: "Minting Contract Loading Error", for: self)
//                        case .createTransactionIssue:
//                            self.alert.showDetail("Error", with: "Minting Contract Transaction Issue", for: self)
//                        case .retrievingEstimatedGasError:
//                            self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
//                        default:
//                            self.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
//                    }
//                }
//                
//                /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
//                let localDatabase = LocalDatabase()
//                guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
//                    self.alert.showDetail("Sorry", with: "There was an error retrieving your wallet.", for: self)
//                    return
//                }
//                
//                var balanceResult: BigUInt!
//                do {
//                    balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
//                } catch {
//                    self.alert.showDetail("Sorry", with: "An error retrieving the balance of your wallet.", for: self)
//                    return
//                }
//                
//                guard let estimatedGasForMinting = estimatedGasForMinting,
//                      let estimatedGasForDeploying = estimatedGasForDeploying,
//                      let priceInWei = Web3.Utils.parseToBigUInt(String(price), units: .eth),
//                      (estimatedGasForMinting + estimatedGasForDeploying + priceInWei) < balanceResult else {
//                    self.alert.showDetail("Sorry", with: "Insufficient funds in your wallet to cover both the gas fee and the deposit for the escrow.", height: 300, for: self)
//                    return
//                }
//                
//                // escrow deployment transaction
//                if let transaction = transaction {
//                    self.hideSpinner {
//                        DispatchQueue.main.async {
//                            let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
//                            detailVC.titleString = "Enter your password"
//                            detailVC.buttonAction = { vc in
//                                if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
//                                    // to be used to transfer the token into the auction contract
//                                    self.walletAuthorizationCode = password
//                                    self.dismiss(animated: true, completion: {
//                                        self.progressModal = ProgressModalViewController(postType: .tangible)
//                                        self.progressModal.titleString = "Posting In Progress"
//                                        self.present(self.progressModal, animated: true, completion: {
//                                            DispatchQueue.global(qos: .background).async {
//                                                do {
//                                                    // create new contract
//                                                    let result = try transaction.send(password: password, transactionOptions: nil)
//                                                    print("deployment result", result)
//                                                    let update: [String: PostProgress] = ["update": .deployingEscrow]
//                                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                                                    
//                                                    // mint transaction
//                                                    if let mintTransaction = mintTransaction {
//                                                        do {
//                                                            let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
//                                                            print("mintResult", mintResult)
//                                                            
//                                                            // firebase
//                                                            let senderAddress = result.transaction.sender!.address
//                                                            let ref = self.db.collection("post")
//                                                            let id = ref.document().documentID
//                                                            
//                                                            // for deleting photos afterwards
//                                                            self.documentId = id
//                                                            
//                                                            // txHash is either minting or transferring the ownership
//                                                            self.db.collection("post").document(id).setData([
//                                                                "sellerUserId": userId,
//                                                                "senderAddress": senderAddress,
//                                                                "escrowHash": result.hash,
//                                                                "mintHash": mintResult.hash,
//                                                                "date": Date(),
//                                                                "title": title,
//                                                                "description": desc,
//                                                                "price": price,
//                                                                "category": category,
//                                                                "status": PostStatus.ready.rawValue,
//                                                                "tags": Array(tokensArr),
//                                                                "itemIdentifier": convertedId,
//                                                                "isReviewed": false,
//                                                                "type": "digital",
//                                                                "deliveryMethod": deliveryMethod,
//                                                                "saleFormat": saleFormat,
//                                                                "paymentMethod": paymentMethod
//                                                            ]) { (error) in
//                                                                if let error = error {
//                                                                    self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                                } else {
//                                                                    /// no need for a socket if you don't have images to upload?
//                                                                    /// show the success alert here
//                                                                    /// apply the same for resell
//                                                                    self.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c")
//                                                                    self.socketDelegate.delegate = self
//                                                                }
//                                                            }
//                                                        } catch Web3Error.nodeError(let desc) {
//                                                            if let index = desc.firstIndex(of: ":") {
//                                                                let newIndex = desc.index(after: index)
//                                                                let newStr = desc[newIndex...]
//                                                                DispatchQueue.main.async {
//                                                                    self.alert.showDetail("Alert", with: String(newStr), for: self)
//                                                                }
//                                                            }
//                                                        } catch Web3Error.transactionSerializationError {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                                            }
//                                                        } catch Web3Error.connectionError {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                                            }
//                                                        } catch Web3Error.dataError {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                                            }
//                                                        } catch Web3Error.inputError(_) {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                                            }
//                                                        } catch Web3Error.processingError(let desc) {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Alert", with: desc, height: 320, for: self)
//                                                            }
//                                                        } catch {
//                                                            self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                        }
//                                                    }
//                                                    
//                                                } catch Web3Error.nodeError(let desc) {
//                                                    if let index = desc.firstIndex(of: ":") {
//                                                        let newIndex = desc.index(after: index)
//                                                        let newStr = desc[newIndex...]
//                                                        DispatchQueue.main.async {
//                                                            self.alert.showDetail("Alert", with: String(newStr), for: self)
//                                                        }
//                                                    }
//                                                } catch Web3Error.transactionSerializationError {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                                    }
//                                                } catch Web3Error.connectionError {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                                    }
//                                                } catch Web3Error.dataError {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                                    }
//                                                } catch Web3Error.inputError(_) {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                                    }
//                                                } catch Web3Error.processingError(let desc) {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Alert", with: desc, height: 320, for: self)
//                                                    }
//                                                } catch {
//                                                    self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                }
//                                            } // DispatchQueue.global background
//                                        }) // end of self.present completion for ProgressModalVC
//                                    }) // end of self.dismiss completion
//                                } // end of let password = dvc.textField.text
//                            } // detailVC.buttonAction
//                            self.present(detailVC, animated: true, completion: nil)
//                        } // hide spinner
//                    } // DispathQueue.main.asyc
//                } // transaction
//            } // end of prepareTransactionForMinting
//        }) // end of prepareTransactionForNewContract
//    }
//    
//    // MARK: - auction mint
//    final func auction(price: String, title: String, desc: String, category: String, convertedId: String, tokensArr: Set<String>, userId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String, auctionDuration: String, auctionStartingPrice: String) {
//        
//        guard let index = auctionDuration.firstIndex(of: "d") else { return }
//        let newIndex = auctionDuration.index(before: index)
//        let newStr = auctionDuration[..<newIndex]
//        guard let numOfDays = NumberFormatter().number(from: String(newStr)) else {
//            self.alert.showDetail("Sorry", with: "Could not convert the auction duration into a proper format. Please try again.", for: self)
//            return
//        }
//        
//        guard let startingBidInWei = Web3.Utils.parseToBigUInt(auctionStartingPrice, units: .eth) else {
//            self.alert.showDetail("Sorry", with: "Could not convert the auction starting price into a proper format. Pleas try again.", for: self)
//            return
//        }
//        
//        let biddingTime = numOfDays.intValue * 60 * 60 * 24
//        print("startingBid", startingBidInWei)
//        print("biddingTime", biddingTime)
//        print("string", String(biddingTime))
//        
//        // auction deployment
//        self.transactionService.prepareTransactionForNewContract(contractABI: auctionABI, value: String(price), parameters: [biddingTime, startingBidInWei] as [AnyObject], completion: { [weak self](transaction, error, estimatedGasForDeploying) in
//            guard let `self` = self else { return }
//            if let error = error {
//                switch error {
//                    case .invalidAmountFormat:
//                        self.alert.showDetail("Error", with: "The price is in a wrong format", for: self)
//                    case .contractLoadingError:
//                        self.alert.showDetail("Error", with: "Auction Contract Loading Error", for: self)
//                    case .createTransactionIssue:
//                        self.alert.showDetail("Error", with: "Auction Contract Transaction Issue", for: self)
//                    case .retrievingEstimatedGasError:
//                        self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
//                    case .retrievingCurrentAddressError:
//                        self.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
//                    default:
//                        self.alert.showDetail("Error", with: "There was an error deploying your auction contract.", for: self)
//                }
//            }
//            
//            // minting
//            self.transactionService.prepareTransactionForMinting { (mintTransaction, mintError, estimatedGasForMinting) in
//                if let error = mintError {
//                    switch error {
//                        case .contractLoadingError:
//                            self.alert.showDetail("Error", with: "Minting Contract Loading Error", for: self)
//                        case .createTransactionIssue:
//                            self.alert.showDetail("Error", with: "Minting Contract Transaction Issue", for: self)
//                        case .retrievingEstimatedGasError:
//                            self.alert.showDetail("Error", with: "There was an error getting the estimating the gas limit.", for: self)
//                        case .retrievingCurrentAddressError:
//                            self.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
//                        default:
//                            self.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
//                    }
//                }
//                
//                /// check the balance of the wallet against the gas limit for two transactions: minting and deploying the contract
//                //                let localDatabase = LocalDatabase()
//                //                guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
//                //                    self.alert.showDetail("Sorry", with: "There was an error retrieving your wallet.", for: self)
//                //                    return
//                //                }
//                //
//                //                var balanceResult: BigUInt!
//                //                do {
//                //                    balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
//                //                } catch {
//                //                    self.alert.showDetail("Sorry", with: "An error retrieving the balance of your wallet.", for: self)
//                //                    return
//                //                }
//                //
//                //                guard let currentGasPrice = try? Web3swiftService.web3instance.eth.getGasPrice() else {
//                //                    self.alert.showDetail("Sorry", with: "An error retreiving the current gas price.", for: self)
//                //                    return
//                //                }
//                //
//                // gas estimation for transferring the token into the auction contract
//                // tricky because impossible to get the exact estimation before minting the very token that you're trying to transfer
//                //                let estimatedGasForTransferringToken: BigUInt = 64000
//                
//                //                print("estimatedGasForMinting", estimatedGasForMinting)
//                //                print("estimatedGasForDeploying", estimatedGasForDeploying)
//                //                print("balanceResult", balanceResult)
//                
//                //                guard let estimatedGasForMinting = estimatedGasForMinting,
//                //                      let estimatedGasForDeploying = estimatedGasForDeploying,
//                //                      let balance = balanceResult else {
//                //                    print("no")
//                //                    return
//                //                }
//                //
//                //                guard ((estimatedGasForMinting + estimatedGasForTransferringToken) * currentGasPrice) < balanceResult else {
//                //                    let content = """
//                //                    Insufficient funds in your wallet to cover the gas fee for deploying the auction contract and minting a token.
//                //
//                //                    A. Estimated gas for minting your token: \(estimatedGasForMinting) units
//                //                    B. Estimated gas for deploying the auction contract: \(estimatedGasForDeploying) units
//                //                    C. Estimated gas for transferring the token: \(estimatedGasForTransferringToken) units
//                //                    D. Current gas price: \(currentGasPrice) Gwei
//                //                    E. Your current balance: \(balance) Wei
//                //
//                //                    (A + B + C) * D = \((estimatedGasForMinting + estimatedGasForTransferringToken) * currentGasPrice) Wei
//                //                    """
//                //                    self.alert.showDetail("Insufficient Fund", with: content, height: 550, alignment: .left, for: self)
//                //                    return
//                //                }
//                
//                // auction deployment transaction
//                if let transaction = transaction {
//                    self.hideSpinner {
//                        DispatchQueue.main.async {
//                            let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
//                            detailVC.titleString = "Enter your password"
//                            detailVC.buttonAction = { vc in
//                                if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
//                                    self.dismiss(animated: true, completion: {
//                                        self.progressModal = ProgressModalViewController(postType: .tangible)
//                                        self.progressModal.titleString = "Posting In Progress"
//                                        self.present(self.progressModal, animated: true, completion: {
//                                            DispatchQueue.global(qos: .background).async {
//                                                do {
//                                                    // create an auction contract
//                                                    let result = try transaction.send(password: password, transactionOptions: nil)
//                                                    print("auction deployment result", result)
//                                                    
//                                                    // to be used for transferring the token into the auction contract
//                                                    self.auctionHash = result.hash
//                                                    let senderAddress = result.transaction.sender!.address
//                                                    
//                                                    let update: [String: PostProgress] = ["update": .deployingEscrow]
//                                                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                                                    
//                                                    // mint transaction
//                                                    if let mintTransaction = mintTransaction {
//                                                        do {
//                                                            let mintResult = try mintTransaction.send(password: password,transactionOptions: nil)
//                                                            print("mintResult", mintResult)
//                                                            
//                                                            // firebase
//                                                            //                                                            let senderAddress = result.transaction.sender!.address
//                                                            let ref = self.db.collection("post")
//                                                            let id = ref.document().documentID
//                                                            
//                                                            // for deleting photos afterwards
//                                                            self.documentId = id
//                                                            
//                                                            // txHash is either minting or transferring the ownership
//                                                            self.db.collection("post").document(id).setData([
//                                                                "sellerUserId": userId,
//                                                                "senderAddress": senderAddress,
//                                                                "escrowHash": "N/A",
//                                                                "auctionHash": result.hash,
//                                                                "mintHash": mintResult.hash,
//                                                                "date": Date(),
//                                                                "title": title,
//                                                                "description": desc,
//                                                                "price": price,
//                                                                "category": category,
//                                                                "status": PostStatus.ready.rawValue,
//                                                                "tags": Array(tokensArr),
//                                                                "itemIdentifier": convertedId,
//                                                                "isReviewed": false,
//                                                                "type": "digital",
//                                                                "deliveryMethod": deliveryMethod,
//                                                                "saleFormat": saleFormat,
//                                                                "paymentMethod": paymentMethod
//                                                            ]) { (error) in
//                                                                if let error = error {
//                                                                    self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                                } else {
//                                                                    /// no need for a socket if you don't have images to upload?
//                                                                    /// show the success alert here
//                                                                    /// apply the same for resell
//                                                                    self.socketDelegate = SocketDelegate(contractAddress: "0x656f9bf02fa8eff800f383e5678e699ce2788c5c")
//                                                                    self.socketDelegate.delegate = self
//                                                                }
//                                                            }
//                                                        } catch Web3Error.nodeError(let desc) {
//                                                            if let index = desc.firstIndex(of: ":") {
//                                                                let newIndex = desc.index(after: index)
//                                                                let newStr = desc[newIndex...]
//                                                                DispatchQueue.main.async {
//                                                                    self.alert.showDetail("Alert", with: String(newStr), for: self)
//                                                                }
//                                                            }
//                                                        } catch Web3Error.transactionSerializationError {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                                            }
//                                                        } catch Web3Error.connectionError {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                                            }
//                                                        } catch Web3Error.dataError {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                                            }
//                                                        } catch Web3Error.inputError(_) {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                                            }
//                                                        } catch Web3Error.processingError(let desc) {
//                                                            DispatchQueue.main.async {
//                                                                self.alert.showDetail("Alert", with: desc, height: 320, for: self)
//                                                            }
//                                                        } catch {
//                                                            self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                        }
//                                                    }
//                                                    
//                                                } catch Web3Error.nodeError(let desc) {
//                                                    if let index = desc.firstIndex(of: ":") {
//                                                        let newIndex = desc.index(after: index)
//                                                        let newStr = desc[newIndex...]
//                                                        DispatchQueue.main.async {
//                                                            self.alert.showDetail("Alert", with: String(newStr), for: self)
//                                                        }
//                                                    }
//                                                } catch Web3Error.transactionSerializationError {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                                    }
//                                                } catch Web3Error.connectionError {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                                    }
//                                                } catch Web3Error.dataError {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                                    }
//                                                } catch Web3Error.inputError(_) {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Alert", with: "Failed to sign the transaction. \n\nPlease try logging out of your wallet (not the Buroku account) and logging back in. \n\nEnsure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                                    }
//                                                } catch Web3Error.processingError(let desc) {
//                                                    DispatchQueue.main.async {
//                                                        self.alert.showDetail("Alert", with: desc, height: 320, for: self)
//                                                    }
//                                                } catch {
//                                                    self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                }
//                                            } // DispatchQueue.global background
//                                        }) // end of self.present completion for ProgressModalVC
//                                    }) // end of self.dismiss completion
//                                } // end of let password = dvc.textField.text
//                            } // detailVC.buttonAction
//                            self.present(detailVC, animated: true, completion: nil)
//                        } // hide spinner
//                    } // DispathQueue.main.asyc
//                } // transaction
//            } // prepareTransactionForMinting
//        }) // end of prepareTransactionForNewContract
//    } // end of auction
//}
//
//// MARK: - Picker
//extension DigitalAssetViewController {
//    override var inputView: UIView? {
//        switch pickerTag {
//            case 3:
//                return self.saleFormatPicker.inputView
//            case 50:
//                return self.auctionDurationPicker.inputView
//            default:
//                return nil
//        }
//    }
//    
//    @objc func doDone() { // user tapped button in accessory view
//        switch pickerTag {
//            case 3:
//                self.saleMethodLabel.text = saleFormatPicker.currentPep
//            case 50:
//                self.auctionDurationLabel.textColor = .black
//                self.auctionDurationLabel.text = auctionDurationPicker.currentPep + " days"
//            default:
//                break
//        }
//        self.resignFirstResponder()
//        self.showKeyboard = false
//    }
//}
//
//extension DigitalAssetViewController {
//    override func didReceiveMessage(topics: [String]) {
//        guard let saleFormat = self.saleMethodLabel.text,
//              let sm = SaleFormat(rawValue: saleFormat) else { return }
//        
//        switch sm {
//            case .onlineDirect:
//                super.didReceiveMessage(topics: topics)
//            case .openAuction:
//                getTxReceipt = Web3swiftService.getReceipt(hash: auctionHash)
//                    .sink { (completion) in
//                        switch completion {
//                            case .finished:
//                                print("finished")
//                            case .failure(_):
//                                self.alert.showDetail("Error", with: "There was an error getting the auction contract address.", for: self)
//                        }
//                    } receiveValue: { (receipt) in
//                        guard let address = receipt.contractAddress?.address else {
//                            self.alert.showDetail("Error", with: "There was an error getting the auction contract address.", for: self)
//                            return
//                        }
//                        self.transferTokenIntoAuction(topics: topics, auctionContractAddress: address)
//                    }
//        }
//    }
//    
//    func transferTokenIntoAuction(topics: [String], auctionContractAddress: String) {
//        // get the token ID from Clouds Function
//        // safeTransferFrom seller to the auction contract
//        getTokenId(topics: topics) { [weak self](tokenId, res) in
//            guard let res = res else { return }
//            switch res {
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
//                            // upload images
//                            self?.uploadFiles()
//                            
//                            print("Web3swiftService.currentAddress", Web3swiftService.currentAddress as Any)
//                            print("tokenId", tokenId as Any)
//                            print("erc721ContractAddress", erc721ContractAddress as Any)
//                            
//                            guard let fromAddress = Web3swiftService.currentAddress,
//                                  let tokenId = tokenId,
//                                  let erc721ContractAddress = erc721ContractAddress else {
//                                self?.alert.showDetail("Error", with: "Could not set the parameters to transfer the token into the auction contract.", for: self)
//                                return
//                            }
//                            
//                            //                            print("fromAddress", fromAddress as Any)
//                            //                            print("tokenId", tokenId as Any)
//                            //                            print("erc721ContractAddress", erc721ContractAddress as Any)
//                            
//                            let param: [AnyObject] = [fromAddress, auctionContractAddress, tokenId] as [AnyObject]
//                            self?.transactionService.prepareTransactionForWriting(method: "safeTransferFrom", abi: NFTrackABI, param: param, contractAddress: erc721ContractAddress, completion: { (transaction, error) in
//                                if let error = error {
//                                    switch error {
//                                        case .invalidAmountFormat:
//                                            self?.alert.showDetail("Error", with: "The ETH amount is not in a correct format!", for: self)
//                                        case .zeroAmount:
//                                            self?.alert.showDetail("Error", with: "The ETH amount cannot be negative", for: self)
//                                        case .insufficientFund:
//                                            self?.alert.showDetail("Error", with: "There is an insufficient amount of ETH in the wallet.", for: self)
//                                        case .contractLoadingError:
//                                            self?.alert.showDetail("Error", with: "There was an error loading your contract.", for: self)
//                                        case .createTransactionIssue:
//                                            self?.alert.showDetail("Error", with: "There was an error creating the transaction.", for: self)
//                                        default:
//                                            self?.alert.showDetail("Sorry", with: "There was an error. Please try again.", for: self)
//                                    }
//                                }
//                                
//                                if let transaction = transaction {
//                                    DispatchQueue.global().async {
//                                        do {
//                                            guard let walletAuthorizationCode = self?.walletAuthorizationCode, let documentID = self?.documentId else {
//                                                self?.alert.showDetail("Sorry", with: "Could not get the wallet authorization passcode.", for: self)
//                                                return
//                                            }
//                                            
//                                            let receipt = try transaction.send(password: walletAuthorizationCode, transactionOptions: nil)
//                                            FirebaseService.shared.db.collection("post").document(documentID).updateData([
//                                                "initialAuctionTokenTransferHash": receipt.hash,
//                                            ], completion: { (error) in
//                                                if let error = error {
//                                                    self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                                                } else {
//                                                    self?.alert.showDetail("Success!", with: "You have successfully listed your item.", for: self)
//                                                }
//                                            })
//                                        } catch Web3Error.nodeError(let desc) {
//                                            if let index = desc.firstIndex(of: ":") {
//                                                let newIndex = desc.index(after: index)
//                                                let newStr = desc[newIndex...]
//                                                self?.alert.showDetail("Alert", with: String(newStr), for: self)
//                                            }
//                                        } catch Web3Error.transactionSerializationError {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Sorry", with: "There was a transaction serialization error. Please try logging out of your wallet and back in.", height: 300, alignment: .left, for: self)
//                                            }
//                                        } catch Web3Error.connectionError {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Sorry", with: "There was a connection error. Please try again.", for: self)
//                                            }
//                                        } catch Web3Error.dataError {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Sorry", with: "There was a data error. Please try again.", for: self)
//                                            }
//                                        } catch Web3Error.inputError(_) {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Alert", with: "Failed to sign the transaction. You may be using an incorrect password. \n\nOtherwise, please try logging out of your wallet (not the NFTrack account) and logging back in. Ensure that you remember the password and the private key.", height: 370, alignment: .left, for: self)
//                                            }
//                                        } catch Web3Error.processingError(let desc) {
//                                            DispatchQueue.main.async {
//                                                self?.alert.showDetail("Alert", with: "\(desc). Ensure that you're using the same address used in the original transaction.", height: 320, alignment: .left, for: self)
//                                            }
//                                        } catch {
//                                            self?.alert.showDetail("Error", with: "There was an error with the transfer transaction.", for: self)
//                                        }
//                                    } // dispatchQueue
//                                }
//                            })
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
//                case is GeneralErrors:
//                    switch res as! GeneralErrors {
//                        case .decodingError:
//                            self?.alert.showDetail("Error", with: "There was an error decoding the token ID. Please contact the admin.", for: self)
//                        default:
//                            break
//                    }
//                default:
//                    self?.alert.showDetail("Error in Minting", with: res.localizedDescription, for: self)
//            }
//        }
//    }
//}
