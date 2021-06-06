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

class ListDetailViewController: DetailParentViewController {
    override var post: Post! {
        didSet {
            self.getStatus()
            self.getHistory()
        }
    }
    var optionsBarItem: UIBarButtonItem!
    var statusTitleLabel: UILabel!
    var statusLabel: UILabelPadding!
    var updateStatusButton = UIButton()
    var userId: String!
//    var buttonPanel: UIView!
//    var editButton: UIButton!
//    var deleteButton: UIButton!
    
    // history table view below the status update button
    var historyTableViewHeight: CGFloat! = 0
    var historyTableView: UITableView!
    var historicData = [Post]()
    let CELL_HEIGHT: CGFloat = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setHistoryVC()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: descLabel.bounds.size.height + 800 + historyTableViewHeight)
    }
}

extension ListDetailViewController {
    override func configureUI() {
        super.configureUI()
        
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
    
    override func setConstraints() {
        super.setConstraints()
        NSLayoutConstraint.activate([
            statusTitleLabel.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 40),
            statusTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 50),
            
            updateStatusButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            updateStatusButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            updateStatusButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            updateStatusButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}

extension ListDetailViewController {
    // MARK: - buttonPressed
    @objc func buttonPressed(_ sender: UIButton!) {
        switch sender.tag {
            case 1:
                // abort by the seller
                updateState(method: PurchaseMethods.abort.rawValue, status: .aborted)
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
    
    // MARK: - configureStatusButton
    func configureStatusButton(buttonTitle: String = "Buy", tag: Int = 2) {
        updateStatusButton.tag = tag
        updateStatusButton.setTitle(buttonTitle, for: .normal)
    }
}

extension ListDetailViewController {
    // MARK: - getStatus
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
                                                
                                                if self.post.transferHash != nil {
                                                    buyerButtonTitle = "Confirm Received"
                                                    buyerTag = 3
                                                } else {
                                                    buyerButtonTitle = "Transfer Pending"
                                                    buyerTag = 7
                                                }
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
                                        if  userId != self.post.sellerUserId {
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
                                                                self?.navigationController?.popViewController(animated: true)
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
                                                                self?.tableViewRefreshDelegate?.didRefreshTableView()
                                                                self?.navigationController?.popViewController(animated: true)
                                                            }
                                                        }
                                                    })
                                                case .aborted:
                                                    FirebaseService.sharedInstance.db.collection("post").document(self!.post.documentId).delete() { err in
                                                        if let err = err {
                                                            self?.alert.showDetail("Error", with: err.localizedDescription, for: self!)
                                                        } else {
                                                            self?.alert.showDetail("Success!", with: "You have aborted the escrow. The deployed contract is now locked and your ether will be sent back to your account.", for: self!) {
                                                                self?.navigationController?.popViewController(animated: true)
                                                            }
                                                        }
                                                    }
                                                default:
                                                    break
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
                                                            "transferDate": Date(),
                                                            "status": PostStatus.transferred.rawValue
                                                        ], completion: { (error) in
                                                            if let error = error {
                                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                                                            } else {
                                                                self?.alert.showDetail("Success!", with: "The token has been successfully transferred.", for: self!) {
                                                                    
                                                                }
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

