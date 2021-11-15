//
//  MainDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import FirebaseFirestore
import web3swift
import Combine
import FirebaseMessaging

class MainDetailViewController: ParentListViewController<Post>, PostParseDelegate, FetchContractAddress {
    var storage: Set<AnyCancellable>! = {
        return Set<AnyCancellable>()
    }()
    final var category: String! {
        didSet {
            guard let category = category else { return }
//                  let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) else { return }
            
            title = category
            firstListener = FirebaseService.shared.db.collection("post")
                .whereField("category", isEqualTo: category as String)
                .whereField("status", isEqualTo: "ready")
//                .whereField("bidders", notIn: [userId])
//                .order(by: "bidders")
                .order(by: "date", descending: true)
                .limit(to: 3)
                .addSnapshotListener({ [weak self] (querySnapshot: QuerySnapshot?, err: Error?) in
                    if let _ = err {
                        self?.alert.showDetail("Error", with: "Unable to fetch data. Please try again later.", for: self)
                    } else {
                        defer {
                            DispatchQueue.main.async {
                                self?.tableView?.reloadData()
                            }
                        }
                        
                        guard let querySnapshot = querySnapshot else {
                            return
                        }
                        
                        // All cache has to be removed because the listener could fetch the modified data at any point and disrupt the index path
                        // This means the index path saved in the cache would be inaccurate
                        self?.cache.removeAllObjects()
                        
                        guard let lastSnapshot = querySnapshot.documents.last else {
                            // The collection is empty.
                            return
                        }
                        
                        self?.lastSnapshot = lastSnapshot

                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.postArr = data
                        }
                    }
                })
        }
    }
    private var subscriptionButtonItem: UIBarButtonItem!
    private var isSubscribed: Bool! = false {
        didSet {
            configureNavigationItem()
        }
    }
    private var isSaved: Bool!
    private var customNavView: BackgroundView5!

    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationItem()
        fetchSubscriptionStatus()
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.navigationBar.sizeToFit()
        }
    }

    final override func configureUI() {
        super.configureUI()
        extendedLayoutIncludesOpaqueBars = true
//        edgesForExtendedLayout = []
        
        tableView = UITableView()
        tableView.register(ImageCardCell.self, forCellReuseIdentifier: ImageCardCell.identifier)
        tableView.register(NoImageCardCell.self, forCellReuseIdentifier: NoImageCardCell.identifier)
        tableView.estimatedRowHeight = 330
        tableView.rowHeight = 330
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        tableView.contentInsetAdjustmentBehavior = .always
        view.addSubview(tableView)
        tableView.fill()
        
        customNavView = BackgroundView5()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(customNavView)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -60),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureNavigationItem() {
        guard let bookmarkImage = UIImage(systemName: isSubscribed ? "bookmark.fill" : "bookmark") else { return }
        subscriptionButtonItem = UIBarButtonItem(image: bookmarkImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
        subscriptionButtonItem.tag = 0
        navigationItem.rightBarButtonItem = subscriptionButtonItem
    }
    
    private func fetchSubscriptionStatus() {
        print("userId", userId as Any)
        
        FirebaseService.shared.db
            .collection("deviceToken")
            .document(userId)
            .getDocument { [weak self] (document: DocumentSnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Error", with: "Unable to fetch the status of your subscription. Please try again later.", for: self)
                }
                
                guard let document = document,
                      let data = document.data(),
                      let title = self?.title else { return }
                
                var subscriptions: [String]!
                data.forEach { (item) in
                    switch item.key {
                        case "subscription":
                            subscriptions = item.value as? [String]
                            
                            let whitespaceCharacterSet = CharacterSet.whitespaces
                            let formattedTitle = title.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
                            if subscriptions.contains(formattedTitle) {
                                self?.isSubscribed = true
                            }
                        default:
                            break
                    }
                }
            }
    }
    
    private func refetch(lastSnapshot: QueryDocumentSnapshot) {
//        guard let userId = userId else { return }
        
        nextListener = FirebaseService.shared.db.collection("post")
            .whereField("category", isEqualTo: category as String)
            .whereField("status", isEqualTo: "ready")
//            .whereField("bidders", notIn: [userId])
//            .order(by: "bidders")
            .order(by: "date", descending: true)
            .limit(to: 3)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener({ [weak self] (querySnapshot: QuerySnapshot?, err: Error?) in
                if let _ = err {
                    self?.alert.showDetail("Error", with: "Unable to fetch data. Please try again later.", for: self)
                } else {
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                    
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    self?.cache.removeAllObjects()
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.append(contentsOf: data)
                    }
                }
            })
    }
    
    // refetch after the scrolled to the end
    final override func executeAfterDragging() {
        refetch(lastSnapshot: self.lastSnapshot)
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = postArr[indexPath.row]
        var newCell: CardCell!
        
        if let files = post.files, files.count > 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ImageCardCell.identifier) as? ImageCardCell else {
                fatalError("Sorry, could not load cell")
            }
        
            newCell = cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NoImageCardCell.identifier) as? NoImageCardCell else {
                fatalError("Sorry, could not load cell")
            }
    
            newCell = cell
        }
    
        newCell.updateAppearanceFor(.pending(post))
        newCell.selectionStyle = .none

        return newCell
    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        
        guard let paymentMethod = PaymentMethod(rawValue: post.paymentMethod),
              let postType = PostType(rawValue: post.type),
              let saleType = SaleType(rawValue: post.saleType),
              let deliveryMethod = DeliveryMethod(rawValue: post.deliveryMethod),
              let contractFormat = ContractFormat(rawValue: post.contractFormat) else {
            self.alert.showDetail("Error", with: "There was an error accessing the item data.", for: self)
            return
        }
        
        let saleConfig = SaleConfig.hybridMethod(
            postType: postType,
            saleType: saleType,
            delivery: deliveryMethod,
            payment: paymentMethod,
            contractFormat: contractFormat
        )
        
        switch saleConfig.value {
            case .tangibleNewSaleShippingEscrowIndividual:
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                // refreshes the MainDetailVC table when the user updates the status
                self.navigationController?.pushViewController(listDetailVC, animated: true)
                break
            case .digitalNewSaleOnlineDirectPaymentIndividual:
                let simpleVC = SimpleRevisedViewController()
                simpleVC.post = post
                self.navigationController?.pushViewController(simpleVC, animated: true)
                break
            case .digitalNewSaleAuctionBeneficiaryIntegral:
                guard let currentAddress = Web3swiftService.currentAddress,
                      let auctionContract = ContractAddresses.integralAuctionAddress else {
                    self.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
                    return
                }
                
                let integralAuctionVC = IntegralAuctionViewController(auctionContractAddress: auctionContract, myContractAddress: currentAddress, post: post)
                integralAuctionVC.post = post
                self.navigationController?.pushViewController(integralAuctionVC, animated: true)
                
                break
            case .digitalNewSaleAuctionBeneficiaryIndividual:
                guard let auctionHash = post.auctionHash else { return }
                getContractAddress(with: auctionHash) { [weak self] (contractAddress) in
                    guard let currentAddress = Web3swiftService.currentAddress else {
                        self?.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
                        auctionDetailVC.post = post
                        self?.navigationController?.pushViewController(auctionDetailVC, animated: true)
                    }
                }
                break
            default:
                break
        }
        
//        switch paymentMethod {
//            case .escrow:
//                let listDetailVC = ListDetailViewController()
//                listDetailVC.post = post
//                // refreshes the MainDetailVC table when the user updates the status
//                self.navigationController?.pushViewController(listDetailVC, animated: true)
//                break
//            case .auctionBeneficiary:
//                guard let auctionHash = post.auctionHash else { return }
//                getContractAddress(with: auctionHash) { [weak self] (contractAddress) in
//                    guard let currentAddress = Web3swiftService.currentAddress else {
//                        self?.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
//                        return
//                    }
//
//                    DispatchQueue.main.async {
//                        let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
//                        auctionDetailVC.post = post
//                        self?.navigationController?.pushViewController(auctionDetailVC, animated: true)
//                    }
//                }
//                break
//            case .directTransfer:
//                let simpleVC = SimpleRevisedViewController()
//                simpleVC.post = post
//                self.navigationController?.pushViewController(simpleVC, animated: true)
//                break
//            case .integralAuction:
//
//                break
//            default:
//                break
//        }
    }
}

extension MainDetailViewController {
    @objc final func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                guard let title = self.title else { return }
                let convertedTitle = title.trimmingAllSpaces(using: .whitespacesAndNewlines).lowercased()
                
                if isSubscribed == false {
                    self.alert.showDetail(
                        "Subscription",
                        with: "Would you like to get notified every time \(title) has a newly listed item? You can unsubscribe at any time.",
                        for: self,
                        alertStyle: .withCancelButton,
                        buttonAction: { [weak self] in
                            guard let self = self else { return }
                            
                            self.isSubscribed = !self.isSubscribed
                            
                            FirebaseService.shared.db.collection("deviceToken").document(self.userId).setData([
                                "subscription": FieldValue.arrayUnion(["\(convertedTitle)"])
                            ], merge: true) { [weak self] (error: Error?) in
                                if let _ = error {
                                    self?.alert.showDetail("Subscription Error", with: "Unable to subscribe. Please try again later.", for: self)
                                } else {
                                    Messaging.messaging().subscribe(toTopic: convertedTitle) { error in
                                        print("Subscribed to \(title) topic")
                                    }
                                }
                            }
                        }
                    )
                } else {
                    self.isSubscribed = !self.isSubscribed
                    
                    FirebaseService.shared.db.collection("deviceToken").document(self.userId).setData([
                        "subscription": FieldValue.arrayRemove(["\(convertedTitle)"])
                    ], merge: true) { [weak self] (error: Error?) in
                        if let _ = error {
                            self?.alert.showDetail("Subscription Error", with: "Unable to subscribe. Please try again later.", for: self)
                        } else {
                            Messaging.messaging().unsubscribe(fromTopic: convertedTitle) { error in
                                print("unsubscribed to \(title) topic")
                            }
                        }
                    }
                }
                break
            default:
                break
        }
    }
}

extension MainDetailViewController: ContextAction {
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        animator.addAnimations { [weak self] in
            self?.show(destinationViewController, sender: self)
        }
    }
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    final override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let post = postArr[indexPath.row]
        var actionArray = [UIAction]()
        
        if let savedBy = post.savedBy, savedBy.contains(userId) {
            isSaved = true
        } else {
            isSaved = false
        }
        
        let starImage = isSaved ? "star.fill" : "star"
        let posting = UIAction(title: "Save", image: UIImage(systemName: starImage)) { [weak self] action in
            self?.savePost(post)
        }
        actionArray.append(posting)
        
        let profile = UIAction(title: "Profile", image: UIImage(systemName: "person.crop.circle")) { [weak self] action in
            self?.navToProfile(post)
        }
        actionArray.append(profile)
        
        if let files = post.files, files.count > 0 {
            let images = UIAction(title: "Images", image: UIImage(systemName: "photo")) { [weak self] action in
                self?.imagePreivew(post)
            }
            
            actionArray.append(images)
        }
        
        let history = UIAction(title: "Tx Detail", image: UIImage(systemName: "rectangle.stack")) { [weak self] action in
            self?.navToHistory(post)
        }
        actionArray.append(history)
        
        let reviews = UIAction(title: "Reviews", image: UIImage(systemName: "square.and.pencil")) { [weak self] action in
            self?.navToReviews(post)
        }
        actionArray.append(reviews)
        
        if userId != post.sellerUserId {
            let chat = UIAction(title: "Chat", image: UIImage(systemName: "message")) { [weak self] action in
                self?.navToChatVC(userId: self?.userId, post: post)
            }
            actionArray.append(chat)
            
            let report = UIAction(title: "Report", image: UIImage(systemName: "flag")) { [weak self] action in
                guard let userId = self?.userId else { return }
                self?.navToReport(userId: userId, post: post)
            }
            actionArray.append(report)
        }
        
        return UIContextMenuConfiguration(identifier: "MainDetailPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: actionArray)
        }
    }

    private func savePost(_ post: Post) {
        // saving the favourite post
        isSaved = !isSaved
        FirebaseService.shared.db
            .collection("post")
            .document(post.documentId)
            .updateData([
                "savedBy": isSaved ? FieldValue.arrayUnion(["\(userId!)"]) : FieldValue.arrayRemove(["\(userId!)"])
                ]) {(error) in
                if let error = error {
                    self.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                }
            }
    }
}
