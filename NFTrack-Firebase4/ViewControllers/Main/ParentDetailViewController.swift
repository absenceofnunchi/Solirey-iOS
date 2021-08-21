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

import UIKit
import web3swift
import Firebase
import FirebaseFirestore
import BigInt

class ParentDetailViewController: UIViewController {
    // MARK: - Properties
    var alert: Alerts!
    let transactionService = TransactionService()
    var scrollView: UIScrollView!
    var contractAddress: EthereumAddress!
    var post: Post!
    var pvc: UIPageViewController!
    var galleries: [String]!
    var singlePageVC: ImagePageViewController!
    var usernameContainer: UIView!
    var dateLabel: UILabel!
    var profileImageView: UIImageView!
    var displayNameLabel: UILabel!
    var underLineView: UnderlineView!
    var priceTitleLabel: UILabel!
    var priceLabel: UILabelPadding!
    var descTitleLabel: UILabel!
    var descLabel: UILabelPadding!
    var idTitleLabel: UILabel!
    var idLabel: UILabelPadding!
    var listDetailTitleLabel: UILabel!
    var constraints: [NSLayoutConstraint]!
    var fetchedImage: UIImage!
    var userInfo: UserInfo! {
        didSet {
            userInfoDidSet()
        }
    }
    weak var delegate: RefetchDataDelegate?
    var chatButtonItem: UIBarButtonItem!
    var starButtonItem: UIBarButtonItem!
    var postEditButtonItem: UIBarButtonItem!
    var isSaved: Bool! = false {
        didSet {
            configureBuyerNavigationBar()
        }
    }
    var userId: String! {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId)
    }
    var imageHeightConstraint: NSLayoutConstraint!
    
    // to refresh after update
    weak var tableViewRefreshDelegate: TableViewRefreshDelegate?
    
    // listing detail
    var listingSpecView: SpecDisplayView!
    lazy var listingDetailArr = [
        SmartContractProperty(propertyName: "Delivery Method", propertyDesc: post.deliveryMethod),
        SmartContractProperty(propertyName: "Payment Method", propertyDesc: post.paymentMethod),
        SmartContractProperty(propertyName: "Sale Format", propertyDesc: post.saleFormat)
    ]
    let LIST_DETAIL_HEIGHT: CGFloat = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureBackground()
        /// UsernameBannerConfigurable
        configureNameDisplay(post: post, v: scrollView) { (profileImageView, displayNameLabel) in
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            profileImageView.addGestureRecognizer(tap)
            displayNameLabel.addGestureRecognizer(tap)
        }
        fetchUserData(id: post.sellerUserId)
        configureImageDisplay(post: post, v: scrollView)
        configureUI()
        setConstraints()
    }
    
    // called when fetchUserData fetched data and assigns it to userInfo
    // modular so that children view controllers can override it
    func userInfoDidSet() {
        processProfileImage()
    }
}

extension ParentDetailViewController: UsernameBannerConfigurable, PageVCConfigurable {
    // MARK: - configureBackground
    func configureBackground() {
        galleries = [String]()
        
        view.backgroundColor = .white
        scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.fill()
        
        alert = Alerts()
        constraints = [NSLayoutConstraint]()
    }
    
    // MARK: - configureUI
    @objc func configureUI() {
        priceTitleLabel = createTitleLabel(text: "Price")
        scrollView.addSubview(priceTitleLabel)
        
        priceLabel = createLabel(text: "\(post.price!) ETH")
        scrollView.addSubview(priceLabel)
        
        descTitleLabel = createTitleLabel(text: "Description")
        scrollView.addSubview(descTitleLabel)
        
        descLabel = createLabel(text: post.description)
        descLabel.lineBreakMode = .byClipping
        descLabel.numberOfLines = 0
        descLabel.sizeToFit()
        descLabel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        scrollView.addSubview(descLabel)
        
        idTitleLabel = createTitleLabel(text: "Unique Identifier")
        scrollView.addSubview(idTitleLabel)
        
        idLabel = createLabel(text: post.id)
        idLabel.lineBreakMode = .byClipping
        idLabel.numberOfLines = 0
        idLabel.sizeToFit()
        idLabel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        scrollView.addSubview(idLabel)
        
        listDetailTitleLabel = createTitleLabel(text: "Listing Detail")
        scrollView.addSubview(listDetailTitleLabel)
        
        listingSpecView = SpecDisplayView(listingDetailArr: listingDetailArr)
        listingSpecView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(listingSpecView)
    }
    
    // MARK: - setConstraints
    @objc func setConstraints() {
        guard let pvc = pvc,
              let pv = pvc.view else { return }
        
        if let files = post.files, files.count > 0 {
            imageHeightConstraint = pv.heightAnchor.constraint(equalToConstant: 250)
        } else {
            imageHeightConstraint = pv.heightAnchor.constraint(equalToConstant: 0)
        }
        
        setImageDisplayConstraints(v: scrollView)
        setNameDisplayConstraints(topView: pv)
        
        constraints.append(contentsOf: [
            priceTitleLabel.topAnchor.constraint(equalTo: usernameContainer.bottomAnchor, constant: 40),
            priceTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            priceTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            priceTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            priceLabel.topAnchor.constraint(equalTo: priceTitleLabel.bottomAnchor, constant: 0),
            priceLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            priceLabel.heightAnchor.constraint(equalToConstant: 50),
            
            descTitleLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 40),
            descTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            descTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: descTitleLabel.bottomAnchor, constant: 10),
            descLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            descLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            idTitleLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 40),
            idTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            idTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            idLabel.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 10),
            idLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            idLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            idLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            listDetailTitleLabel.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 40),
            listDetailTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            listDetailTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            listingSpecView.topAnchor.constraint(equalTo: listDetailTitleLabel.bottomAnchor, constant: 10),
            listingSpecView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            listingSpecView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            listingSpecView.heightAnchor.constraint(equalToConstant: CGFloat(listingDetailArr.count) * LIST_DETAIL_HEIGHT),
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer!) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        let tag = sender.view?.tag
        switch tag {
            case 1:
                // tapping on the user profile
                let profileDetailVC = ProfileDetailViewController()
                profileDetailVC.userInfo = userInfo
                profileDetailVC.profileImage = fetchedImage
                self.navigationController?.pushViewController(profileDetailVC, animated: true)
            default:
                break
        }
    }
    
    final func fetchSavedPostData() {
        if let savedBy = post.savedBy, savedBy.contains(userId) {
            isSaved = true
        } else {
            isSaved = false
        }
    }
    
    final func configureBuyerNavigationBar() {
        var buttonItemsArr = [UIBarButtonItem]()
        
        guard let chatImage = UIImage(systemName: "message"),
              let starImage = UIImage(systemName: "star"),
              let starImageFill = UIImage(systemName: "star.fill") else {
            return
        }
        chatButtonItem = UIBarButtonItem(image: chatImage.withTintColor(.gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
        chatButtonItem.tag = 6
        buttonItemsArr.append(chatButtonItem)
        
        let finalImage = isSaved ? starImageFill : starImage
        starButtonItem = UIBarButtonItem(image: finalImage.withTintColor(isSaved ? .red : .gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
        starButtonItem.tag = 7
        buttonItemsArr.append(starButtonItem)
        
        self.navigationItem.rightBarButtonItems = buttonItemsArr
    }
    
    // needs a corresponding buttonPressed selector in the subclass
    // for example, the tangible items will assign the tag in ListDetailVC and the digital items in AuctionDetailVC
    // the reason for this is because the tangible items can have their title, description, and the media files modified
    // whereas the digital item can only have their title and the description modified
    // the former will be done in TangibleListEditVC and the latter in DigitalListEditVC
    func configureSellerNavigationBar() {
        postEditButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(buttonPressed(_:)))
        postEditButtonItem.tag = 11
        self.navigationItem.rightBarButtonItems = [postEditButtonItem]
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 6:
                let chatVC = ChatViewController()
                chatVC.userInfo = userInfo
                chatVC.post = post
                // to display the title on ChatList when multiple items under the same owner
                // or maybe search for pre-existing chat room first and join the same one
                // chatVC.itemName = title
                self.navigationController?.pushViewController(chatVC, animated: true)
            case 7:
                // saving the favourite post
                isSaved = !isSaved
                FirebaseService.shared.db.collection("post").document(post.documentId).updateData([
                    "savedBy": isSaved ? FieldValue.arrayUnion(["\(userId!)"]) : FieldValue.arrayRemove(["\(userId!)"])
                ]) {(error) in
                    if let error = error {
                        self.alert.showDetail("Sorry", with: error.localizedDescription, for: self) { [weak self] in
                            DispatchQueue.main.async {
                                self?.navigationController?.popViewController(animated: true)
                            }
                        } completion: {}
                    } else {
                        self.delegate?.didFetchData()
                    }
                }
            default:
                break
        }
    }
}

extension ParentDetailViewController {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index -= 1
        if index < 0 {
            return nil
        }
        
        return ImagePageViewController(gallery: galleries[index])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index += 1
        if index >= galleries.count {
            return nil
        }
        
        return ImagePageViewController(gallery: galleries[index])
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.galleries.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let page = pageViewController.viewControllers![0] as! ImagePageViewController
        
        if let gallery = page.gallery {
            return self.galleries.firstIndex(of: gallery)!
        } else {
            return 0
        }
    }
}

extension ParentDetailViewController: UpdatePostDelegate {
    func didUpdatePost(titleString: String, desc: String, files: [String]? = nil) {
        self.title = titleString
        self.descLabel?.text = desc
        imageHeightConstraint.constant = 0
        
        guard let files = files else { return }
        galleries = files
        singlePageVC = ImagePageViewController(gallery: galleries[0])
        imageHeightConstraint.constant = 250
    }
}

// 20.8769

let eventABI = """
        [
        {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
        },
        {
        "indexed": true,
        "internalType": "address",
        "name": "to",
        "type": "address"
        },
        {
        "indexed": true,
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
        }
        ]
        """
