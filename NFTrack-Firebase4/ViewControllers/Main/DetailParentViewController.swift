//
//  DetailParentViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//
/*
 Abstract:
 Parent view controller for DetailParentViewController and HistoryDetailViewControler
 */

import UIKit
import web3swift
import Firebase
import FirebaseFirestore
import BigInt

class DetailParentViewController: UIViewController {
    // MARK: - Properties
    let alert = Alerts()
    let transactionService = TransactionService()
    var scrollView: UIScrollView!
    var contractAddress: EthereumAddress!
    var post: Post!
    var pvc: UIPageViewController!
    var galleries = [String]()
    var dateLabel: UILabel!
    var underLineView: UnderlineView!
    var priceTitleLabel: UILabel!
    var priceLabel: UILabelPadding!
    var descTitleLabel: UILabel!
    var descLabel: UILabelPadding!
    var idTitleLabel: UILabel!
    var idLabel: UILabelPadding!
    
    // to refresh after update
    weak var tableViewRefreshDelegate: TableViewRefreshDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureData()
        configureUI()
        setConstraints()
    }
}

extension DetailParentViewController {
    
    // MARK: - configureBackground
    func configureBackground() {
        title = post.title
        view.backgroundColor = .white
        scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
    }
    
    // MARK: - configureData
    func configureData() {
        // image
        if let images = post.images, images.count > 0 {
            self.galleries.append(contentsOf: images)
            configurePageVC(gallery: galleries[0])
            
            guard let pv = pvc.view else { return }
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: pv.bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            scrollView.fill()
        }
    }
    
    // MARK: - configurePageVC
    func configurePageVC(gallery: String) {
        let singlePageVC = ImagePageViewController(gallery: gallery)
        pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        pvc.dataSource = self
        pvc.delegate = self
        addChild(pvc)
        view.addSubview(pvc.view)
        pvc.didMove(toParent: self)
        pvc.view.layer.zPosition = 100
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
        pageControl.currentPageIndicatorTintColor = .gray
        pageControl.backgroundColor = .white
        
        guard let pv = pvc.view else { return }
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: view.topAnchor),
            pv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pv.heightAnchor.constraint(equalToConstant: 250),
        ])
    }
    
    // MARK: - configureUI
    @objc func configureUI() {
        dateLabel = UILabel()
        dateLabel.textAlignment = .right
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let formattedDate = formatter.string(from: post.date)
        dateLabel.text = formattedDate
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(dateLabel)
        
        underLineView = UnderlineView()
        underLineView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(underLineView)
        
        priceTitleLabel = createTitleLabel(text: "Price")
        scrollView.addSubview(priceTitleLabel)
        
        priceLabel = createLabel(text: "\(post.price) ETH")
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
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
            dateLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            dateLabel.heightAnchor.constraint(equalToConstant: 50),
            dateLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.4),
            
            underLineView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
            underLineView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            underLineView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            underLineView.heightAnchor.constraint(equalToConstant: 0.5),
            
            priceTitleLabel.topAnchor.constraint(equalTo: underLineView.bottomAnchor, constant: 40),
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
        ])
    }
}

extension DetailParentViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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



//FirebaseService.sharedInstance.db.collection("escrow").whereField("postId", isEqualTo: post.postId)
//    .getDocuments() { [weak self](querySnapshot, err) in
//        if let err = err {
//            print("Error getting documents: \(err)")
//        } else {
//            for document in querySnapshot!.documents {
//                let data = document.data()
//                guard let txHash = data["transactionHash"] as? String else { return }
//                DispatchQueue.global().async {
//                    do {
//                        let receipt = try Web3swiftService.web3instance.eth.getTransactionReceipt(txHash)
//                        self?.contractAddress = receipt.contractAddress
//                        self?.transactionService.prepareTransactionForReading(method: "state", contractAddress: receipt.contractAddress!, completion: { (transaction, error) in
//                            if let error = error {
//                                switch error {
//                                    case .contractLoadingError:
//                                        self?.alert.showDetail("Error", with: "Contract Loading Error", for: self!)
//                                    case .createTransactionIssue:
//                                        self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self!)
//                                    default:
//                                        self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self!)
//                                }
//                            }
//
//                            if let transaction = transaction {
//                                DispatchQueue.global().async {
//                                    do {
//                                        self?.result = try transaction.call()
//                                        print("result", self?.result as Any)
//                                        //                                                self?.status = result["0"] as String
//                                    } catch {
//                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
//                                    }
//                                }
//                            }
//                        })
//                    } catch {
//                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
//                    }
//                }
//            }
//        }
//    }

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
