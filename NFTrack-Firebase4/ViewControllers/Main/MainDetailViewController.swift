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

class MainDetailViewController: ParentListViewController<Post>, PostParseDelegate {
    var storage = Set<AnyCancellable>()
    var category: String! {
        didSet {
            guard let category = category,
                  let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) else { return }
            
            title = category
            firstListener = FirebaseService.shared.db.collection("post")
                .whereField("category", isEqualTo: category as String)
                .whereField("status", isEqualTo: "ready")
                .whereField("bidders", notIn: [userId])
                .order(by: "bidders")
                .order(by: "date", descending: true)
                .limit(to: 12)
                .addSnapshotListener({ [weak self] (querySnapshot, err) in
                if let err = err {
                    self?.alert.showDetail("Error fetching data", with: err.localizedDescription, for: self)
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    
                    guard let lastSnapshot = querySnapshot.documents.last else {
                        // The collection is empty.
                        return
                    }
                    
                    self?.lastSnapshot = lastSnapshot
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }

                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr = data
//                        self?.dataStore = PostImageDataStore(posts: data)
                    }
                }
            })
        }
    }
    var subscriptionButtonItem: UIBarButtonItem!
    var isSubscribed: Bool! = false {
        didSet {
            configureNavigationItem()
        }
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationItem()
        fetchSubscriptionStatus()
    }
    
    // MARK: - didRefreshTableView
    override func didRefreshTableView(index: Int) {
    }
    
    override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: 330, cellType: CardCell.self, identifier: CardCell.identifier)
        tableView.prefetchDataSource = self
        
        view.addSubview(tableView)
        tableView.fill()
    }
    
    func configureNavigationItem() {
        guard let bookmarkImage = UIImage(systemName: isSubscribed ? "bookmark.fill" : "bookmark") else { return }
        subscriptionButtonItem = UIBarButtonItem(image: bookmarkImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
        subscriptionButtonItem.tag = 0
        navigationItem.rightBarButtonItem = subscriptionButtonItem
    }
    
    func fetchSubscriptionStatus() {
        FirebaseService.shared.db
            .collection("deviceToken")
            .document(userId)
            .getDocument { [weak self] (document, error) in
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
    
    func refetch(lastSnapshot: QueryDocumentSnapshot) {
        guard let userId = userId else { return }
        
        nextListener = FirebaseService.shared.db.collection("post")
            .whereField("category", isEqualTo: category as String)
            .whereField("status", isEqualTo: "ready")
            .whereField("bidders", notIn: [userId])
            .order(by: "bidders")
            .order(by: "date", descending: true)
            .limit(to: 12)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener({ [weak self] (querySnapshot, err) in
            if let err = err {
                self?.alert.showDetail("Error fetching data", with: err.localizedDescription, for: self)
            } else {
                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    // The collection is empty.
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }
                
                if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                    self?.postArr.append(contentsOf: data)
//                    self?.dataStore = PostImageDataStore(posts: data)
                }
            }
        })
    }
    
    // refetch after the scrolled to the end
    override func executeAfterDragging() {
        refetch(lastSnapshot: self.lastSnapshot)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.identifier) as? CardCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        
        guard let saleFormat = SaleFormat(rawValue: post.saleFormat) else {
            self.alert.showDetail("Error", with: "There was an error accessing the item data.", for: self)
            return
        }
        
        switch saleFormat {
            case .onlineDirect:
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                // refreshes the MainDetailVC table when the user updates the status
                listDetailVC.tableViewRefreshDelegate = self
                self.navigationController?.pushViewController(listDetailVC, animated: true)
            case .openAuction:
                guard let auctionHash = post.auctionHash else { return }
                Future<TransactionReceipt, PostingError> { promise in
                    Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
                }
                .sink { [weak self] (completion) in
                    switch completion {
                        case .failure(let error):
                            self?.alert.showDetail("Contract Address Loading Error", with: error.localizedDescription, for: self)
                        case .finished:
                            break
                    }
                } receiveValue: { [weak self] (receipt) in
                    guard let contractAddress = receipt.contractAddress,
                          let currentAddress = Web3swiftService.currentAddress else {
                        self?.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
                        auctionDetailVC.post = post
                        self?.navigationController?.pushViewController(auctionDetailVC, animated: true)
                    }
                }
                .store(in: &storage)
        }
    }
}

extension MainDetailViewController {
    @objc func buttonPressed(_ sender: UIButton) {
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
                            ], merge: true) { [weak self] (error) in
                                if let _ = error {
                                    self?.alert.showDetail("Subscription Error", with: "Unable to subscribe. Please try again later.", for: self)
                                } else {
                                    Messaging.messaging().subscribe(toTopic: convertedTitle) { error in
                                        print("Subscribed to \(title) topic")
                                    }
                                    
                                    print("sub")
                                }
                            }
                        }
                    )
                } else {
                    self.isSubscribed = !self.isSubscribed
                    
                    FirebaseService.shared.db.collection("deviceToken").document(self.userId).setData([
                        "subscription": FieldValue.arrayRemove(["\(convertedTitle)"])
                    ], merge: true) { [weak self] (error) in
                        if let _ = error {
                            self?.alert.showDetail("Subscription Error", with: "Unable to subscribe. Please try again later.", for: self)
                        } else {
                            Messaging.messaging().unsubscribe(fromTopic: convertedTitle) { error in
                                print("unsubscribed to \(title) topic")
                            }
                            
                            print("unsub")
                        }
                    }
                }
                break
            default:
                break
        }
    }
}
