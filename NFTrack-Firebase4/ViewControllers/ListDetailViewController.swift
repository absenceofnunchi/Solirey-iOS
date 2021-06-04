//
//  ListDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import web3swift
import Firebase
import FirebaseFirestore
import BigInt
import CryptoKit
import CommonCrypto

class ListDetailViewController: UIViewController {
    // MARK: - Properties
    let alert = Alerts()
    let transactionService = TransactionService()
    var scrollView: UIScrollView!
    var contractAddress: EthereumAddress!
    var post: Post! {
        didSet {
            self.getStatus()
        }
    }
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
    var statusTitleLabel: UILabel!
    var statusLabel: UILabelPadding!
    var updateStatusButton = UIButton()
    var userId: String!
    var buttonPanel: UIView!
    var editButton: UIButton!
    var deleteButton: UIButton!
    var optionsBarItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureOptionsBar()
        configureBackground()
        configureData()
        configureUI()
        setConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: descLabel.bounds.size.height + 700)
    }
}

extension ListDetailViewController {
    
    // MARK: - configureBackground
    func configureBackground() {
        title = post.title
        view.backgroundColor = .white
        scrollView = UIScrollView()
//        scrollView.bounces = false
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
    func configureUI() {
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
        
        priceTitleLabel = UILabel()
        priceTitleLabel.text = "Price"
        priceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(priceTitleLabel)
        
        priceLabel = UILabelPadding()
        priceLabel.text = "\(post.price) ETH"
        priceLabel.layer.borderColor = UIColor.lightGray.cgColor
        priceLabel.layer.borderWidth = 0.5
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(priceLabel)
        
        descTitleLabel = UILabel()
        descTitleLabel.text = "Description"
        descTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descTitleLabel)
        
        descLabel = UILabelPadding()
        descLabel.lineBreakMode = .byClipping
        descLabel.text = post.description
        descLabel.numberOfLines = 0
        descLabel.sizeToFit()
        descLabel.layer.borderWidth = 0.5
        descLabel.layer.borderColor = UIColor.lightGray.cgColor
        descLabel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descLabel)
        
        idTitleLabel = UILabel()
        idTitleLabel.text = "Unique Identifier"
        idTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idTitleLabel)
        
        idLabel = UILabelPadding()
        idLabel.lineBreakMode = .byClipping
        idLabel.text = post.id
        idLabel.numberOfLines = 0
        idLabel.sizeToFit()
        idLabel.layer.borderWidth = 0.5
        idLabel.layer.borderColor = UIColor.lightGray.cgColor
        idLabel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idLabel)
        
        statusTitleLabel = UILabel()
        statusTitleLabel.text = "Status"
        statusTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(statusTitleLabel)
        
        statusLabel = UILabelPadding()
        statusLabel.layer.borderColor = UIColor.lightGray.cgColor
        statusLabel.layer.borderWidth = 0.5
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(statusLabel)
        
        updateStatusButton.backgroundColor = .black
        updateStatusButton.layer.cornerRadius = 5
        updateStatusButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        updateStatusButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(updateStatusButton)
    }
    
    // MARK: - configureStatusButton
    func configureStatusButton(buttonTitle: String = "Buy", tag: Int = 2) {
        updateStatusButton.tag = tag
        updateStatusButton.setTitle(buttonTitle, for: .normal)
    }
    
    // MARK: - configureEditButton
    func configureEditButton() {
        buttonPanel = UIView()
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(buttonPanel)
        
        editButton = UIButton()
        editButton.tag = 3
        editButton.backgroundColor = .blue
        editButton.setTitle("Edit", for: .normal)
        editButton.layer.cornerRadius = 5
        editButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(editButton)
        
        deleteButton = UIButton()
        deleteButton.tag = 4
        deleteButton.backgroundColor = .red
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.layer.cornerRadius = 6
        deleteButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            buttonPanel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            buttonPanel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            buttonPanel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            buttonPanel.heightAnchor.constraint(equalToConstant: 50),
            
            editButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            editButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
            editButton.heightAnchor.constraint(equalToConstant: 50),
            editButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
            
            deleteButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4)
        ])
    }
    
    // MARK: - setConstraints
    func setConstraints() {
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
            
            statusTitleLabel.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 40),
            statusTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            statusTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            statusLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 0),
            statusLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 50),
            
            updateStatusButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            updateStatusButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            updateStatusButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            updateStatusButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // MARK: - buttonPressed
    @objc func buttonPressed(_ sender: UIButton!) {
        switch sender.tag {
            case 1:
                // abort by the seller
                updateState(method: PurchaseMethods.abort.rawValue, status: .abort)
            case 2:
                // confirm purchase
                updateState(method: PurchaseMethods.confirmPurchase.rawValue, price: String(post.price), status: .pending)
            case 3:
                // confirm received
                updateState(method: PurchaseMethods.confirmReceived.rawValue, status: .complete)
            case 4:
                // sell
                let resellVC = ResellViewController()
                resellVC.modalPresentationStyle = .fullScreen
                resellVC.post = post
                self.present(resellVC, animated: true, completion: nil)
            case 5:
                // transfer ownership
                transferToken()
            default:
                break
        }
    }
}

extension ListDetailViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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

extension ListDetailViewController {
    func updateState(method: String, price: String = "0", status: PostStatus? = nil) {
        transactionService.prepareTransactionForWriting(method: method, contractAddress: contractAddress, amountString: price) { [weak self](transaction, error) in
            if let error = error {
                switch error {
                    case .invalidAmountFormat:
                        self?.alert.showDetail("Error", with: "The ETH amount is not in a correct format!", for: self!)
                    case .zeroAmount:
                        self?.alert.showDetail("Error", with: "The ETH amount cannot be negative", for: self!)
                    case .insufficientFund:
                        self?.alert.showDetail("Error", with: "There is an insufficient amount of ETH in the wallet.", for: self!)
                    case .contractLoadingError:
                        self?.alert.showDetail("Error", with: "There was an error loading your contract.", for: self!)
                    case .createTransactionIssue:
                        self?.alert.showDetail("Error", with: "There was an error creating the transaction.", for: self!)
                    default:
                        self?.alert.showDetail("Sorry", with: "There was an error. Please try again.", for: self!)
                }
            }
            
            if let transaction = transaction {
                let detailVC = DetailViewController(height: 250, isTextField: true)
                detailVC.titleString = "Enter your password"
                detailVC.buttonAction = { vc in
                    if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                        self?.dismiss(animated: true, completion: {
                            self?.showSpinner {
                                DispatchQueue.global().async {
                                    do {
                                        let result = try transaction.send(password: password, transactionOptions: nil)
                                        
                                        if let status = status {
                                            switch status {
                                                case .ready:
                                                    break
                                                case .pending:
                                                    /// tag 2
                                                    /// confirmedPurchase
                                                    let buyerHash = Web3swiftService.currentAddressString
                                                    FirebaseService.sharedInstance.db.collection("post").document(self!.post.documentId).updateData([
                                                        "status": status.rawValue,
                                                        "buyerHash": buyerHash ?? "NA",
                                                        "buyerUserId": self?.userId ?? "NA",
                                                        "\(method)Hash": result.hash,
                                                        "\(method)Date": Date()
                                                    ], completion: { (error) in
                                                        if let error = error {
                                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                                                        } else {
                                                            self?.alert.showDetail("Success!", with: "You have confirmed the purchase as buyer. Your ether will be locked until you confirm receiving the item.", for: self!) {
                                                                self?.getStatus()
                                                            }
                                                        }
                                                    })
                                                case .complete:
                                                    /// tag 3
                                                    /// confirmRecieved
                                                    FirebaseService.sharedInstance.db.collection("post").document(self!.post.documentId).updateData([
                                                        "status": status.rawValue,
                                                        "\(method)Hash": result.hash,
                                                        "\(method)Date": Date()
                                                    ], completion: { (error) in
                                                        if let error = error {
                                                            self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                                                        } else {
                                                            self?.alert.showDetail("Success!", with: "You have confirmed that you recieved the item. Your ether will be released back to your account.", for: self!) {
                                                                self?.getStatus()
                                                            }
                                                        }
                                                    })
                                                case .abort:
                                                    FirebaseService.sharedInstance.db.collection("post").document(self!.post.documentId).delete() { err in
                                                        if let err = err {
                                                            self?.alert.showDetail("Error", with: err.localizedDescription, for: self!)
                                                        } else {
                                                            self?.alert.showDetail("Success!", with: "You have aborted the escrow. The deployed contract is now locked and your ether will be sent back to your account.", for: self!) {
                                                                self?.navigationController?.popViewController(animated: true)
                                                            }
                                                        }
                                                    }
                                            }
                                        }
                                    } catch Web3Error.nodeError(let desc) {
                                        if let index = desc.firstIndex(of: ":") {
                                            let newIndex = desc.index(after: index)
                                            let newStr = desc[newIndex...]
                                            self?.alert.showDetail("Alert", with: String(newStr), for: self!)
                                        }
                                    } catch {
                                        if let index = error.localizedDescription.firstIndex(of: "(") {
                                            let newStr = error.localizedDescription.prefix(upTo: index)
                                            self?.alert.showDetail("Alert", with: String(newStr), for: self!)
                                        }
                                        self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                                    }
                                }
                            }
                        })
                    }
                }
                self?.present(detailVC, animated: true, completion: nil)
            }
        }
    }
}

extension ListDetailViewController {
    func transferToken() {
        FirebaseService.sharedInstance.db.collection("post")
            .whereField("postId", isEqualTo: post.postId)
            .getDocuments() { [weak self](querySnapshot, err) in
                if let err = err {
                    self?.alert.showDetail("Error", with: err.localizedDescription, for: self!)
                } else {
                    guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else {
                        self?.alert.showDetail("Error", with: "No post found", for: self!)
                        return
                    }
                    
                    for document in querySnapshot.documents {
                        guard document.exists == true else { return }
                        print("\(document.documentID) => \(document.data())")
                        let data = document.data()
                        var buyerHash: String!
                        var tokenId: String!
                        data.forEach { (item) in
                            switch item.key {
                                case "buyerHash":
                                    buyerHash = item.value as? String
                                case "tokenId":
                                    tokenId = item.value as? String
                                default:
                                    break
                            }
                        }
                        guard let bh = buyerHash else {
                            self?.alert.showDetail("Error", with: "The item has not been purchased by a buyer yet.", for: self!)
                            return
                        }
                        
                        guard let ti = tokenId else {
                            self?.alert.showDetail("Error", with: "The item does not have token ID registered.", for: self!)
                            return
                        }
                        
                        let fromAddress = Web3swiftService.currentAddress
                        let toAddress = EthereumAddress(bh)
                        let param: [AnyObject] = [fromAddress!, toAddress!, ti] as [AnyObject]
                        self?.transactionService.prepareTransactionForWriting(method: "transferFrom", abi: NFTrackABI, param: param, contractAddress: erc721ContractAddress!, completion: { (transaction, error) in
                            if let error = error {
                                switch error {
                                    case .invalidAmountFormat:
                                        self?.alert.showDetail("Error", with: "The ETH amount is not in a correct format!", for: self!)
                                    case .zeroAmount:
                                        self?.alert.showDetail("Error", with: "The ETH amount cannot be negative", for: self!)
                                    case .insufficientFund:
                                        self?.alert.showDetail("Error", with: "There is an insufficient amount of ETH in the wallet.", for: self!)
                                    case .contractLoadingError:
                                        self?.alert.showDetail("Error", with: "There was an error loading your contract.", for: self!)
                                    case .createTransactionIssue:
                                        self?.alert.showDetail("Error", with: "There was an error creating the transaction.", for: self!)
                                    default:
                                        self?.alert.showDetail("Sorry", with: "There was an error. Please try again.", for: self!)
                                }
                            }
                            
                            if let transaction = transaction {
                                let detailVC = DetailViewController(height: 250, isTextField: true)
                                detailVC.titleString = "Enter your password"
                                detailVC.buttonAction = { vc in
                                    if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                                        self?.dismiss(animated: true, completion: {
                                            self?.showSpinner({
                                                DispatchQueue.global().async {
                                                    do {
                                                        let receipt = try transaction.send(password: password, transactionOptions: nil)
                                                        FirebaseService.sharedInstance.db.collection("post").document(document.documentID).updateData([
                                                            "transferHash": receipt.hash,
                                                            "transferDate": Date()
                                                        ], completion: { (error) in
                                                            if let error = error {
                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                                                            } else {
                                                                self?.alert.showDetail("Success!", with: "The token has been successfully transferred.", for: self!)
                                                            }
                                                        })
                                                    } catch Web3Error.nodeError(let desc) {
                                                        if let index = desc.firstIndex(of: ":") {
                                                            let newIndex = desc.index(after: index)
                                                            let newStr = desc[newIndex...]
                                                            self?.alert.showDetail("Alert", with: String(newStr), for: self!)
                                                        }
                                                    } catch {
                                                        self?.alert.showDetail("Error", with: "There was an error with the transfer transaction.", for: self!)
                                                    }
                                                }
                                            })
                                        })
                                    }
                                }
                                self?.present(detailVC, animated: true, completion: nil)
                            }
                        })
                    }
                }
            }
    }
}

extension ListDetailViewController {
    func getStatus() {
        DispatchQueue.global().async {
            do {
                let receipt = try Web3swiftService.web3instance.eth.getTransactionReceipt(self.post.escrowHash)
                self.contractAddress = receipt.contractAddress
                self.transactionService.prepareTransactionForReading(method: "state", contractAddress: receipt.contractAddress!, completion: { (transaction, error) in
                    if let error = error {
                        switch error {
                            case .contractLoadingError:
                                self.alert.showDetail("Error", with: "Contract Loading Error", for: self)
                            case .createTransactionIssue:
                                self.alert.showDetail("Error", with: "Contract Transaction Issue", for: self)
                            default:
                                self.alert.showDetail("Error", with: "There was an error minting your token.", for: self)
                        }
                    }
                    
                    if let transaction = transaction {
                        DispatchQueue.global().async {
                            do {
                                let result: [String: Any] = try transaction.call()
                                if let value = result["0"] as? BigUInt {
                                    let serialized = value.serialize()
                                    
                                    print("serialized.count", serialized.count)
                                    
                                    var status: String!
                                    var buyerButtonTitle: String!
                                    var sellerButtonTitle: String!
                                    var sellerTag: Int!
                                    var buyerTag: Int!
                                    
                                    if serialized.count == 0 {
                                        // abort
                                        status = PurchaseStatus.created.rawValue
                                        sellerButtonTitle = "Abort"
                                        sellerTag = 1
                                        
                                        // buy
                                        buyerButtonTitle = "Buy"
                                        buyerTag = 2
                                    } else if serialized.count == 1 {
                                        let statusCode = serialized[0]
                                        print("statusCode", statusCode)
                                        switch statusCode {
                                            case 1:
                                                status = PurchaseStatus.locked.rawValue
                                                sellerButtonTitle = "Transfer Ownership"
                                                // default
                                                sellerTag = 5
                                                
                                                buyerButtonTitle = "Confirm Received"
                                                buyerTag = 3
                                            case 2:
                                                status = "Inactive"
                                                sellerButtonTitle = "Transaction Completed"
                                                sellerTag = 5
                                                
                                                buyerButtonTitle = "Sell"
                                                buyerTag = 4
                                            default:
                                                break
                                        }
                                    }
                                    
                                    if let userId = UserDefaults.standard.string(forKey: "userId") {
                                        self.userId = userId
                                        if  userId != self.post.userId {
                                            DispatchQueue.main.async {
                                                self.configureStatusButton(buttonTitle: buyerButtonTitle, tag: buyerTag)
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                self.configureStatusButton(buttonTitle: sellerButtonTitle, tag: sellerTag)
                                            }
                                        }
                                    } else {
                                        self.alert.showDetail("Authorization", with: "You need to be logged in!", for: self) {
                                            self.navigationController?.popViewController(animated: true)
                                        }
                                    }
                                    
                                    if self.statusLabel != nil {
                                        DispatchQueue.main.async {
                                            self.statusLabel.text = status
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                }
                            } catch {
                                self.alert.showDetail("Error", with: error.localizedDescription, for: self) {
                                    DispatchQueue.main.async {
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                }
                            }
                        }
                    }
                })
            }  catch Web3Error.nodeError(let desc) {
                if let index = desc.firstIndex(of: ":") {
                    let newIndex = desc.index(after: index)
                    let newStr = desc[newIndex...]
                    self.alert.showDetail("Alert", with: String(newStr), for: self)
                }
            } catch {
                self.alert.showDetail("Error", with: "Unable to retrieve the contract adddress", for: self) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
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
