//
//  IntegralEscrowDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-28.
//

import UIKit
import Combine
import FirebaseFirestore
import web3swift
import MapKit
import BigInt

class IntegralEscrowDetailViewController: ParentDetailViewController {
    private var statusTitleLabel: UILabel!
    final var statusLabel: UILabelPadding!
    final var updateStatusButton = UIButton()
    final var activityIndicatorView: UIActivityIndicatorView!
    final var historyVC: HistoryViewController!
    lazy var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    final var observation: NSKeyValueObservation?
    var socketDelegate: SocketDelegate!
    private var pendingIndicatorView: PendingIndicatorView!
    // indicator to show whether the transaction is pending or not
    // toggled when any events like purchase confirm or abort is emitted
    lazy var isPending: Bool = false {
        didSet {
            guard let pendingIndicatorView = self.pendingIndicatorView else { return }
            if isPending == true {
                DispatchQueue.main.async {
                    pendingIndicatorView.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    pendingIndicatorView.isHidden = true
                }
            }
        }
    }
    
    // to show address when the item is to be shipped and the buyer purchases
    var showBuyerAddress: Bool! = false {
        didSet {
            if showBuyerAddress == true {
                if addressLabel != nil {
                    addressLabel.isUserInteractionEnabled = true
                }
                addressTitleConstraintHeight.constant = ADDRESS_TITLE_HEIGHT
                addressConstraintHeight.constant = ADDRESS_LABEL_HEIGHT
            } else {
                if addressLabel != nil {
                    addressLabel.isUserInteractionEnabled = false
                }
                addressTitleConstraintHeight.constant = 0
                addressConstraintHeight.constant = 0
            }
            
            DispatchQueue.main.async { [weak self] in
                UIView.animate(withDuration: 0.5) {
                    self?.scrollView.layoutIfNeeded()
                }
            }
        }
    }
    // the height of the address field
    let ADDRESS_TITLE_HEIGHT: CGFloat = 40
    let ADDRESS_LABEL_HEIGHT: CGFloat = 50
    var addressTitleLabel: UILabel!
    var addressLabel: UILabel!
    lazy var addressTitleConstraintHeight: NSLayoutConstraint = addressTitleLabel.heightAnchor.constraint(equalToConstant: 0)
    lazy var addressConstraintHeight: NSLayoutConstraint = addressLabel.heightAnchor.constraint(equalToConstant: 0)
    
    // optional images to display for the item
    let IMAGE_HEIGHT: CGFloat = 250
    // rest of the fields and labels
    let REST_HEIGHT: CGFloat = 1000
    var statusInfoButton: UIButton!
    var solireyUid: BigUInt!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let tempId = post.solireyUid,
              let id = BigUInt(tempId) else { return }
        
        solireyUid = id
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if observation != nil {
            observation?.invalidate()
        }
        
        // This function is here instead of in the property observer of post because the latter sets isPending prior to pendingActivityController
        // which means the activity controller won't show
        guard let escrowHash = post.escrowHash,
              let escrowContractAddress = ContractAddresses.integralEscrowAddress else { return }
        
        getStatus(transactionHash: escrowHash, executeReadTransaction: executeReadTransaction, contractAddress: escrowContractAddress)
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if observation != nil {
            observation?.invalidate()
        }
        
        if socketDelegate != nil {
            socketDelegate.disconnectSocket()
        }
    }
    
    final override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if let container = container as? HistoryViewController {
            historyVCHeightConstraint.constant = container.preferredContentSize.height
            
            var totalHeight: CGFloat!
            if let files = post.files, files.count > 0 {
                totalHeight = container.preferredContentSize.height + descLabel.bounds.size.height + REST_HEIGHT + IMAGE_HEIGHT + ADDRESS_TITLE_HEIGHT + ADDRESS_LABEL_HEIGHT
            } else {
                totalHeight = container.preferredContentSize.height + descLabel.bounds.size.height + REST_HEIGHT + ADDRESS_TITLE_HEIGHT + ADDRESS_LABEL_HEIGHT
            }
            
            let adjustedSize = CGSize(
                width: container.preferredContentSize.width,
                height: totalHeight
            )
            
            self.scrollView.contentSize =  adjustedSize
        }
    }
    
    final override func userInfoDidSet() {
        super.userInfoDidSet()
        
        guard let status = post.status,
              status != PostStatus.complete.rawValue else { return }
        
        if userInfo.uid != userId {
            configureBuyerNavigationBar()
            fetchSavedPostData()
        } else if post.sellerUserId == userId {
            configureSellerNavigationBar()
        }
    }
    
    final override func didUpdatePost(title: String, desc: String, imagesString: [String]?) {
        self.title = title
        descLabel.text = desc
        
        if let imagesString = imagesString,
           imagesString.count > 0,
           let firstImageString = imagesString.first {
            pvc.galleries = imagesString
            singlePageVC = SmallSinglePageViewController(gallery: firstImageString, galleries: imagesString)
            imageHeightConstraint.constant = 250
        } else {
            pvc.galleries?.removeAll()
            //            singlePageVC = nil
            imageHeightConstraint.constant = 0
        }
        
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        
        // in case TangibleListEditVC gets pushed again
        post.title = title
        post.description = desc
        post.files = imagesString
    }
}

extension IntegralEscrowDetailViewController {
    final override func configureUI() {
        super.configureUI()
        title = post.title
        
        statusTitleLabel = createTitleLabel(text: "Status")
        statusTitleLabel.sizeToFit()
        scrollView.addSubview(statusTitleLabel)
        
        pendingIndicatorView = PendingIndicatorView()
        pendingIndicatorView.isHidden = true
        pendingIndicatorView.buttonAction = { [weak self] _ in
            let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Pending Transaction", detail: InfoText.pendingEscrow)])
            self?.present(infoVC, animated: true, completion: nil)
        }
        pendingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pendingIndicatorView)
        
        guard let paymentInfoImage = UIImage(systemName: "info.circle") else { return }
        statusInfoButton = UIButton.systemButton(with: paymentInfoImage, target: self, action: #selector(buttonPressed(_:)))
        statusInfoButton.tag = 15
        statusInfoButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(statusInfoButton)
        
        statusLabel = createLabel(text: "")
        scrollView.addSubview(statusLabel)
        
        addressTitleLabel = createTitleLabel(text: "Shipping Address")
        addressTitleLabel.sizeToFit()
        scrollView.addSubview(addressTitleLabel)
        
        addressLabel = createLabel(text: "")
        addressLabel.isUserInteractionEnabled = true
        addressLabel.tag = 14
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addressLabel.addGestureRecognizer(tap)
        addressLabel.text = post.address
        
        scrollView.addSubview(addressLabel)
        
        updateStatusButton.backgroundColor = .black
        updateStatusButton.isEnabled = false
        updateStatusButton.layer.cornerRadius = 5
        updateStatusButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        updateStatusButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(updateStatusButton)
        
        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        updateStatusButton.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        historyVC = HistoryViewController()
        historyVC.itemIdentifier = post.id
        addChild(historyVC)
        historyVC.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyVC.view)
        historyVC.didMove(toParent: self)
    }
    
    final override func setConstraints() {
        super.setConstraints()
        NSLayoutConstraint.activate([
            statusTitleLabel.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 25),
            statusTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            
            pendingIndicatorView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -10),
            pendingIndicatorView.leadingAnchor.constraint(equalTo: statusTitleLabel.trailingAnchor, constant: 20),
            pendingIndicatorView.heightAnchor.constraint(equalToConstant: 28),
            pendingIndicatorView.widthAnchor.constraint(equalToConstant: 100),
            
            statusInfoButton.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -10),
            statusInfoButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            statusInfoButton.heightAnchor.constraint(equalToConstant: 20),
            
            statusLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 50),
            
            addressTitleLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            addressTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            addressTitleConstraintHeight,
            
            addressLabel.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 0),
            addressLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            addressConstraintHeight,
            
            updateStatusButton.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 40),
            updateStatusButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            updateStatusButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            updateStatusButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicatorView.centerYAnchor.constraint(equalTo: updateStatusButton.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: updateStatusButton.centerXAnchor),
            
            historyVC.view.topAnchor.constraint(equalTo: updateStatusButton.bottomAnchor, constant: 40),
            historyVC.view.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyVC.view.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            historyVCHeightConstraint,
        ])
    }
}

extension IntegralEscrowDetailViewController: FetchUserConfigurable, HandleMapSearch {
    // MARK: - buttonPressed
    @objc final override func buttonPressed(_ sender: UIButton) {
        super.buttonPressed(sender)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 1:
                // abort by the seller
                callEscrowMethod(for: .abort)
            case 2:
                // confirm purchase or "buy"
                if let deliveryMethod = listingDetailArr.filter({ $0.propertyName == "Delivery Method" }).first,
                   deliveryMethod.propertyDesc as? String == DeliveryMethod.shipping.rawValue {
                    // if the delivery method is shipping, first check with the buyer that they'll have to disclose the shipping address
                    self.alert.showDetail(
                        "Shipping Address Disclosure",
                        with: "This item is delivered through shipping and requires sharing your shipping address with the seller. Would you like to proceed?",
                        for: self,
                        alertStyle: .withCancelButton,
                        buttonAction: { [weak self] in
                            guard let price = self?.post.price,
                                  let userId = self?.userId else { return }
                            
                            Future<ShippingAddress?, PostingError> { promise in
                                self?.fetchAddress(userId: userId, promise: promise)
                            }
                            .sink { (completion) in
                                switch completion {
                                    case .failure(.generalError(reason: let err)):
                                        self?.alert.showDetail("Error", with: err, for: self)
                                        break
                                    case .finished:
                                        break
                                    default:
                                        self?.alert.showDetail("Error", with: "There was an error fetching the address info.", for: self)
                                        break
                                }
                            } receiveValue: { (shippingAddress) in
                                if let address = shippingAddress?.address, address != "NA" {
                                    self?.callEscrowMethod(for: .confirmPurchase, price: String(price))
                                    self?.updateAddress(address: address)
                                } else {
                                    self?.alert.showDetail(
                                        "Address Required",
                                        with: "The required shipping address is missing from your profile. Set it now?",
                                        for: self,
                                        alertStyle: .withCancelButton,
                                        buttonAction: {
                                            self?.dismiss(animated: true, completion: {
                                                DispatchQueue.main.async {
                                                    let profileVC = ProfileViewController()
                                                    let nav = UINavigationController(rootViewController: profileVC)
                                                    nav.modalPresentationStyle = .fullScreen
                                                    self?.present(nav, animated: true, completion: nil)
                                                }
                                            })
                                        }
                                    )
                                }
                            }
                            .store(in: &self!.storage)
                        }
                    )
                } else {
                    // not shipping so doesn't require an address
                    self.callEscrowMethod(for: .confirmPurchase, price: String(self.post.price))
                }
            case 3:
                // confirm received
                callEscrowMethod(for: .confirmReceived)
            case 4:
                // sell
                let resaleVC = ResaleViewController()
                resaleVC.post = post
                resaleVC.title = "Resale"
                navigationController?.pushViewController(resaleVC, animated: true)
            case 5:
                // transfer ownership
                transferToken(for: .safeTransferFrom)
            case 8:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.transferPending)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 9:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.receiptPending)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 10:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.transferCompleted)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 11:
                let listEditVC = TangibleListEditViewController()
                listEditVC.delegate = self
                listEditVC.post = post
                listEditVC.userId = userId
                self.navigationController?.pushViewController(listEditVC, animated: true)
                break
            case 15:
                let infoVC = InfoViewController(
                    infoModelArr: [
                        InfoModel(title: "Created", detail: InfoText.created),
                        InfoModel(title: "Locked", detail: InfoText.locked),
                        InfoModel(title: "Inactive", detail: InfoText.inactive)
                    ]
                )
                self.present(infoVC, animated: true, completion: nil)
            case 200:
                DispatchQueue.main.async {
                    let profileVC = ProfileViewController()
                    profileVC.delegate = self
                    let nav = UINavigationController(rootViewController: profileVC)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                }
                break
            case 201:
                let infoVC = InfoViewController(
                    infoModelArr: [
                        InfoModel(title: "Shipping Unavailable", detail: InfoText.shippingUnavailable)
                    ]
                )
                self.present(infoVC, animated: true, completion: nil)
            case 202:
                navigationController?.popViewController(animated: true)
                break
            default:
                break
        }
    }
    
    override func tapped(_ sender: UITapGestureRecognizer!) {
        super.tapped(sender)
        
        let tag = sender.view?.tag
        switch tag {
            case 14:
                // To display the address of the buyer when the seller has to ship the item
                // This is to be displayed under two conditions:
                // 1. The seller has specified the tangible item to be shipped
                // 2. The buyer has purchased the item (ConfirmPurchase for the buyer, Transfer Ownership for the seller)
                guard let address = post.address else {
                    self.alert.showDetail("No Address", with: "The buyer has not specified any shipping address. Please contact the buyer.", for: self)
                    return
                }
                
                getPlacemark(addressString: address) { [weak self] (placemark, error) in
                    if let _ = error {
                        self?.alert.showDetail("Error", with: "Unable to display the address on the map.", for: self)
                        return
                    }
                    
                    if let placemark = placemark {
                        let mapVC = MapViewController()
                        mapVC.title = "Shipping Address"
                        mapVC.initialPlacemark = placemark
                        self?.navigationController?.pushViewController(mapVC, animated: true)
                    }
                }
            default:
                break
        }
    }
    
    // MARK: - configureStatusButton
    final func configureStatusButton(buttonTitle: String = "Buy", tag: Int = 2) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusButton.tag = tag
            self?.updateStatusButton.isEnabled = true
            self?.updateStatusButton.setTitle(buttonTitle, for: .normal)
        }
    }
    
    final func updateAddress(address: String) {
        FirebaseService.shared.db
            .collection("post")
            .document(self.post.documentId)
            .updateData([
                "address": address
            ]) { (error) in
                if let _ = error {
                    //                    self?.alert.showDetail("Error", with: "Unable to register the shipping address. Please contact the support.", for: self)
                }
            }
    }
}

extension IntegralEscrowDetailViewController {
    final func createSocket(){}
//    final func createSocket(contractAddress: EthereumAddress, topics: [String]? = nil) {
//        guard socketDelegate == nil else { return }
//        socketDelegate = SocketDelegate(
//            contractAddress: contractAddress,
//            topics: topics,
//            passThroughSubject: PassthroughSubject<[String: Any], PostingError>()
//        )
//
//        socketDelegate.passThroughSubject
//            .sink(receiveCompletion: { [weak self] (completion) in
//                switch completion {
//                    case .failure(let err):
//                        self?.alert.showDetail("Auction Detail Fetch Error", with: err.localizedDescription, for: self)
//                    case .finished:
//                        print("")
//                        break
//                }
//            }, receiveValue: { [weak self] (webSocketMessage) in
//                self?.isPending = true
//
//                guard let topics = webSocketMessage["topics"] as? [String],
//                      let txHash = webSocketMessage["transactionHash"] as? String else { return }
//
//                switch topics {
//                    case _ where topics.contains(Topics.Transfer) || topics.contains(Topics.Transfer2):
//                        self?.getStatus()
//                        //                        self?.isPending = true
//                        //                        guard let executeReadTransaction = self?.executeReadTransaction else { return }
//                        //                        self?.getAuctionInfo(
//                        //                            transactionHash: txHash,
//                        //                            executeReadTransaction: executeReadTransaction,
//                        //                            contractAddress: contractAddress
//                        //                        )
//                        print("transfer event")
//                        break
//                    case _ where topics.contains(Topics.PurchaseConfirmed):
//                        self?.getStatus()
//                        print("PurchaseConfirmed event")
//                        break
//                    case _ where topics.contains(Topics.ItemReceived):
//                        self?.getStatus()
//                        print("ItemReceived event")
//                        break
//                    case _ where topics.contains(Topics.Aborted):
//                        self?.getStatus()
//                        print("Aborted event")
//                        break
//                    default:
//                        print("other events")
//                }
//            })
//            .store(in: &storage)
//    }
}

// Called when ProfileVC is closed
// ProfileVC called on two occasions:
// 1. Before the potential buyer decides to buy. The address of the buyer is analyzed against the shipping limitation, but if the buyer doesn't have their shipping address registered,
//    the Buy button will lead the buyer to ProfileVC
// 2. After the potential buyer decides to buy. The "Buy" button will prompt the buyer to let them know that their shipping address will be shared. If they decide to proceed and doesn't have a shipping addres,
//    they will be led to ProfileVC
// After they register the shipping address and the ProfileVC model closes, getStatus() will be refetched to reflect the Buy button status.
extension IntegralEscrowDetailViewController: RefetchDataDelegate {
    final func didFetchData() {
        guard let escrowHash = post.escrowHash,
              let escrowContractAddress = ContractAddresses.integralEscrowAddress else { return }
        
        getStatus(transactionHash: escrowHash, executeReadTransaction: executeReadTransaction, contractAddress: escrowContractAddress)
    }
}
