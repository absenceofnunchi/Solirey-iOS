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
    // to refresh after update
    weak var tableViewRefreshDelegate: TableViewRefreshDelegate?
    
    // listing detail
    var listingSpecView: SpecDisplayView!
    lazy var listingDetailArr = [
        SpecDetailModel(propertyName: "Delivery Method", propertyDesc: post.deliveryMethod),
        SpecDetailModel(propertyName: "Payment Method", propertyDesc: post.paymentMethod),
        SpecDetailModel(propertyName: "Sale Format", propertyDesc: post.saleFormat)
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
    
//    // MARK: - configureEditButton
//    func configureEditButton() {
//        buttonPanel = UIView()
//        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(buttonPanel)
//
//        editButton = UIButton()
//        editButton.tag = 3
//        editButton.backgroundColor = .blue
//        editButton.setTitle("Edit", for: .normal)
//        editButton.layer.cornerRadius = 5
//        editButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//        editButton.translatesAutoresizingMaskIntoConstraints = false
//        buttonPanel.addSubview(editButton)
//
//        deleteButton = UIButton()
//        deleteButton.tag = 4
//        deleteButton.backgroundColor = .red
//        deleteButton.setTitle("Delete", for: .normal)
//        deleteButton.layer.cornerRadius = 6
//        deleteButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
//        deleteButton.translatesAutoresizingMaskIntoConstraints = false
//        buttonPanel.addSubview(deleteButton)
//
//        NSLayoutConstraint.activate([
//            buttonPanel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
//            buttonPanel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//            buttonPanel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//            buttonPanel.heightAnchor.constraint(equalToConstant: 50),
//
//            editButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
//            editButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
//            editButton.heightAnchor.constraint(equalToConstant: 50),
//            editButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
//
//            deleteButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
//            deleteButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
//            deleteButton.heightAnchor.constraint(equalToConstant: 50),
//            deleteButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4)
//        ])
//    }
//
    // MARK: - setConstraints
    @objc func setConstraints() {
        if let files = post.files, files.count > 0 {
            guard let pv = pvc.view else { return }
            setImageDisplayConstraints(v: scrollView)
            setNameDisplayConstraints(topView: pv)
        } else {
            setNameDisplayConstraints(topView: scrollView)
        }
        
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

