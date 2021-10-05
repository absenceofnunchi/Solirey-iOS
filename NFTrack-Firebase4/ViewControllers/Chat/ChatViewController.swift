//
//  ChatViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-10.
//

/*
 Abstract:
 Real time chat between two users.
 
 Important:
 UserInfo always pertains to the recipient regardless of whether it is the buyer or the seller. Therefore, UserInfo cannot be used to determine whether a user is a buyer or a seller.
 
 There are two ways to arrive on this view controller:
    1) ListDetailVC: A previous chat might not exists, in which case a new chat is created using getDocId(), a unique identifer for each chat channel
    2) ChatListVC: The chat already exists. ChatListVC passes post (PostCoreModel), which sets the document ID, which in turn, fetches the chat data using the document ID
 
 Only the potential buyer can initiate the conversation and the seller cannot. When the buyer terminates the conversation, they can reinitate the conversation whereas the seller cannot. The seller can terminate the conversation as well, but the buyer can reinitate.
    1) Buyer
        A. Terminates the conversation by removing their user ID from the channel's Members.
        B. Prevent the seller from contacting the buyer.
        C. When the buyer re-initiates the conversation, the chat is initiated from ListDetail, not ChatList.  The buyer's user ID is inserted to Members
    2) Seller
        A. Terminates the conversation by removing their user ID from the channel's Members.
        B. The seller can still be contacted by the buyer even if their user ID has been removed
 */

import UIKit
import FirebaseFirestore
import Combine

class ChatViewController: ParentListViewController<Message>, FileUploadable, SingleDocumentFetchDelegate, ChatDelegate {
    final var userInfo: UserInfo!
    final var docId: String! {
        didSet {
            if docId != nil {
                fetchMessages(docId)
            } else {
                alert.showDetail("Error", with: "Unable to generate the chat ID.", for: self)
            }
        }
    }
    final var itemName: String!
    final var postingId: String!
    final var toolBarView: ToolBarView!
    private var toolBarBottomConstraint: NSLayoutConstraint!
//    private var imageName: String!
    // If chatListModel is set, it means the channel info already exists, therefore the chat is not new
    final var chatListModel: ChatListModel! {
        didSet {
            chatIsNew = false
            postingId = chatListModel.postingId
            docId = chatListModel.documentId
        }
    }
    // Toggled on and off by fetchChanelInfo() depending on whether the channel info exists or not
    // If new, create the channel info along with the very first message.
    final var chatIsNew: Bool! = true
    private var spinner: UIActivityIndicatorView!
    final override var PAGINATION_LIMIT: Int {
        get {
            return 40
        }
        set {}
    }
    private var optionsBarItem: UIBarButtonItem!
    private var postBarButton: UIBarButtonItem!
    private var reportBarButton: UIBarButtonItem!
    final var storage: Set<AnyCancellable>!
    final var postCache: NSCache<NSString, Post>!
    private var lastContentOffset: CGFloat = 0
    final var senderDisplayName: String! {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.displayName)
    }
    private var onlineStatusListener: ListenerRegistration!
    final var lastSeenDate: Date!
    final lazy var isOnline: Bool = false {
        didSet {
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
    }
    private var customTitleView: CustomTitleView!
    private var customNavView: BackgroundView7!
    
    final override func setDataStore(postArr: [Message]) {
        dataStore = MessageImageDataStore(posts: postArr)
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureNavigationBar()
        setConstraints()
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureOnlineStatus()
        resignFirstResponder()
    }
    
    final override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver()

        // If navigated to ChatVC from SearchResultsVC, the tab bar is still visible
        if let parentVC = parent?.parent, parentVC.isKind(of: UISearchController.self),
           let window = UIApplication.shared.windows.first,
           let rootVC = window.rootViewController as? CustomTabBarViewController {
            rootVC.tabBar.isHidden = true
        } else {
            self.tabBarController?.tabBar.isHidden = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let parentVC = parent?.parent, parentVC.isKind(of: UISearchController.self),
           let window = UIApplication.shared.windows.first,
           let rootVC = window.rootViewController as? CustomTabBarViewController {
            rootVC.tabBar.isHidden = false
        } else {
            self.tabBarController?.tabBar.isHidden = false
        }
        
        
        Future<Bool, PostingError> { [weak self] promise in
            self?.registerOnlineStatus(false, promise: promise)
        }
        .sink { (_) in
        } receiveValue: { (_) in
        }
        .store(in: &storage)
        
        if isMovingFromParent {
            postCache.removeObject(forKey: "CachedPost")
        }
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver()
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    final override func configureUI() {
        super.configureUI()
        view.backgroundColor = .white
        alert = Alerts()
        postCache = NSCache<NSString, Post>()
        storage = Set<AnyCancellable>()
        navigationController?.navigationBar.tintColor = .white
        
        tableView = UITableView()
        tableView.allowsSelection = false
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: ImageMessageCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.prefetchDataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(tableView)
        
        customNavView = BackgroundView7()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(customNavView, aboveSubview: tableView)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        toolBarView = ToolBarView()
        toolBarView.buttonAction = { [weak self] tag in
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            switch tag {
                case 1:
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { action in
                        let vc = UIImagePickerController()
                        vc.sourceType = .camera
                        vc.allowsEditing = true
                        vc.delegate = self
                        self?.present(vc, animated: true)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { action in
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.allowsEditing = false
                        imagePickerController.sourceType = .photoLibrary
                        imagePickerController.delegate = self
                        imagePickerController.modalPresentationStyle = .fullScreen
                        self?.present(imagePickerController, animated: true, completion: nil)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Location", style: .default, handler: { action in
//                        let shippingVC = ShippingViewController()
//                        shippingVC.shippingDelegate = self
//                        self?.navigationController?.pushViewController(shippingVC, animated: true)
                        
                        let mapVC = ChatMapViewController()
                        mapVC.title = "Send Location"
                        mapVC.fetchPlacemarkDelegate = self
                        self?.navigationController?.pushViewController(mapVC, animated: true)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
                    
                    self?.present(alert, animated: true)
                case 2:
                    self?.sendMessage()
                default:
                    break
            }
        }
        
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBarView)
        
        spinner = UIActivityIndicatorView()
        spinner.stopAnimating()
        spinner.hidesWhenStopped = true
        spinner.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60)
        tableView.tableFooterView = spinner
    }
    
    private func setConstraints() {
        toolBarBottomConstraint = toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50),
            
            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBarView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            toolBarBottomConstraint
        ])
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        let post = postArr[indexPath.row]
        
        if let _ = post.imageURL {
            guard let imageCell = tableView.dequeueReusableCell(withIdentifier: ImageMessageCell.identifier, for: indexPath) as? ImageMessageCell else {
                fatalError("Unable to dequeue the custom table cell")
            }
            
            imageCell.myUserId = userId
            imageCell.selectionStyle = .none
            let post = postArr[indexPath.row]
            imageCell.configure(post)
            
            let interaction = UIContextMenuInteraction(delegate: self)
            imageCell.thumbImageView.addInteraction(interaction)
            imageCell.buttonAction = { [weak self] in
                self?.createImageAction(
                    imageCell: imageCell,
                    post: post,
                    indexPath: indexPath
                )
            }

            cell = imageCell
        } else {
            guard let messageCell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as? MessageCell else {
                fatalError("Unable to dequeue the custom table cell")
            }
            
            messageCell.myUserId = userId
            messageCell.selectionStyle = .none
            let post = postArr[indexPath.row]
            messageCell.configure(post)
            
            let interaction = UIContextMenuInteraction(delegate: self)
            messageCell.messageLabel.isUserInteractionEnabled = true
            messageCell.messageLabel.addInteraction(interaction)
            
            if post.id == userId, indexPath == IndexPath(row: 0, section: 0) {
                let isSeen = setSeenIndicator(isOnline: isOnline, seenTime: lastSeenDate, sentTime: post.sentAtFull)
                messageCell.seenImageView.alpha = isSeen ? 1 : 0
            }
            
            cell = messageCell
        }

        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
    
    // If the image is a map for location sharing, navigate to ChatMapVC to pinpoint the location
    // If not, enlarge the image.
    final func createImageAction(
        imageCell: ImageMessageCell,
        post: Message,
        indexPath: IndexPath
    ) {
        if post.type == .location {
            let mapVC = ChatMapViewController()
            mapVC.sharedLocation = post.location
            navigationController?.pushViewController(mapVC, animated: true)
        } else {
            if let image = imageCell.thumbImageView.image {
                self.openImage(image)
            } else {
                if let cachedImage = self.cache[indexPath.row as NSNumber] as? UIImage {
                    self.openImage(cachedImage)
                } else {
                    guard let imageURL = post.imageURL else { return }
                    self.openImage(imageURL)
                }
            }
        }
    }
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] suggestedActions in
            let locationInTableView = interaction.location(in: self?.tableView)
            guard let indexPath = self?.tableView.indexPathForRow(at: locationInTableView) else {
                return nil
            }
                        
            if let contentLabel = interaction.view as? UILabel,
               let message = contentLabel.text {
                return self?.createMessageMenu(message: message, at: indexPath.row)
            } else if let imageView = interaction.view as? UIImageView {
                guard let image = imageView.image else { return nil }
                return self?.createImageMenu(image: image, at: indexPath.row)
            } else {
                return nil
            }
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        let reload_distance:CGFloat = 10.0
        
        // Only refresh if pulled down
        if lastContentOffset > scrollView.contentOffset.y && lastContentOffset < scrollView.contentSize.height - scrollView.frame.height {
            // 
        } else if lastContentOffset < scrollView.contentOffset.y && scrollView.contentOffset.y > 0 {
            // update the new position acquired
            lastContentOffset = scrollView.contentOffset.y
            if y > (h + reload_distance) {
                guard self.postArr.count > 0 else { return }
                executeAfterDragging()
            }
        }
    }

    final override func executeAfterDragging() {
        guard postArr.count > 0 else { return }
        spinner.startAnimating()
        delay(0.5) { [weak self] in
            guard let lastSnapshot = self?.lastSnapshot,
                  let docId = self?.docId else { return }
            self?.refetchMessages(lastSnapshot, docId: docId)
        }
    }
}

extension ChatViewController: PostParseDelegate {
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        if parent != nil && self.navigationItem.titleView == nil {

        }
    }
    
    private func configureNavigationBar() {
        self.navigationItem.largeTitleDisplayMode = .never
        customTitleView = CustomTitleView(displayName: userInfo.displayName, imageString: "circle.fill")
//        let width = customTitleView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        let width: CGFloat = view.bounds.size.width / 0.7
        customTitleView.frame = CGRect(origin:CGPoint.zero, size:CGSize(width: width, height: 500))
        navigationItem.titleView = customTitleView
        
        customTitleView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        customTitleView.addGestureRecognizer(tap)

        guard let postBarImage = UIImage(systemName: "list.bullet.below.rectangle"),
              let reportImage = UIImage(systemName: "flag") else {
            return
        }
        
        // Chat should only be able to navigate to the posting if the view controller was pushed from ChatListVC because if it was pushed from ListDetailVC, it's entirely redundant
        if #available(iOS 14.0, *) {
            var buttonArr: [UIAction] = [UIAction(title: NSLocalizedString("Report", comment: ""), image: reportImage, handler: menuHandler)]
            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
                if let _ = viewController as? ChatListViewController {
                    buttonArr.append(UIAction(title: NSLocalizedString("Posting", comment: ""), image: postBarImage, handler: menuHandler))
                }
            }
            let barButtonMenu = UIMenu(title: "", children: buttonArr)
            
            let image = UIImage(systemName: "line.horizontal.3.decrease")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            optionsBarItem = UIBarButtonItem(title: nil, image: image, primaryAction: nil, menu: barButtonMenu)
            navigationItem.rightBarButtonItem = optionsBarItem
        } else {
            var buttonArr = [UIBarButtonItem]()
            reportBarButton = UIBarButtonItem(image: reportImage.withTintColor(.white, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
            reportBarButton.tag = 1
            buttonArr.append(reportBarButton)

            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
                if let _ = viewController as? ChatListViewController {
                    postBarButton = UIBarButtonItem(image: postBarImage.withTintColor(.white, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed(_:)))
                    postBarButton.tag = 2
                    buttonArr.append(postBarButton)
                }
            }

            self.navigationItem.rightBarButtonItems = buttonArr
        }
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                let profileDetailVC = ProfileDetailViewController()
                profileDetailVC.userInfo = userInfo
                self.navigationController?.pushViewController(profileDetailVC, animated: true)
                break
            case 1:
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let reportVC = ReportViewController()
                    reportVC.post = fetchedPost
                    reportVC.userId = self?.userId
                    self?.navigationController?.pushViewController(reportVC, animated: true)
                }
                break
            case 2:
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let listDetailVC = ListDetailViewController()
                    listDetailVC.post = fetchedPost
                    self?.navigationController?.pushViewController(listDetailVC, animated: true)
                }
            default:
                break
        }
    }
    
    @objc private func menuHandler(action: UIAction) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        guard let postingId = postingId else { return }
        switch action.title {
            case "Posting":
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let listDetailVC = ListDetailViewController()
                    listDetailVC.post = fetchedPost
                    self?.navigationController?.pushViewController(listDetailVC, animated: true)
                }
                break
            case "Report":
                getPost(with: postingId) { [weak self] (fetchedPost) in
                    let reportVC = ReportViewController()
                    reportVC.post = fetchedPost
                    reportVC.userId = self?.userId
                    self?.navigationController?.pushViewController(reportVC, animated: true)
                }
                break
            default:
                break
        }
    }
    
    @objc func tapped() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        let profileDetailVC = ProfileDetailViewController()
        profileDetailVC.userInfo = userInfo
        navigationController?.pushViewController(profileDetailVC, animated: true)
    }
}

extension ChatViewController {
    private func fetchMessages(_ docId: String) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .limit(to: 5)
            .order(by: "sentAt", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
                }
                
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.tableView.scrollToTop()
                    }
                }
                
                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    // The collection is empty.
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                if let messages = self?.parseMessage(querySnapshot.documents) {
                    self?.postArr = messages
                }
            }
    }
    
    private func refetchMessages(_ lastSnapshot: QueryDocumentSnapshot, docId: String) {
        nextListener = FirebaseService.shared.db
            .collection("chatrooms")
            .document(docId)
            .collection("messages")
            .order(by: "sentAt", descending: true)
            .limit(to: 5)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to receive messages at the moment.", for: self)
                }
                
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.tableView.scrollToBottom()
                        DispatchQueue.main.async {
                            self?.spinner.stopAnimating()
                        }
                    }
                }
                
                guard let querySnapshot = querySnapshot else {
                    return
                }
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    // The collection is empty.
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                if let messages = self?.parseMessage(querySnapshot.documents) {
                    self?.postArr.append(contentsOf: messages)
                }
            }
    }
    
    private func parseMessage(_ documents: [QueryDocumentSnapshot]) -> [Message] {
        return documents.map { docSnapshot -> Message in
            let data = docSnapshot.data()
            let senderId = data["sender"] as? String ?? ""
            let content = data["content"] as? String ?? ""
            let sentAtBuffer = data["sentAt"] as? Timestamp
            let sentAt = sentAtBuffer?.dateValue() ?? Date()
            let imageURL = data["imageURL"] as? String
            let senderDisplayName = data["senderDisplayName"] as? String ?? ""
            let recipientDisplayName = data["recipientDisplayName"] as? String ?? ""

            var messageType: MessageType!
            if let type = data["type"] as? String {
                messageType = MessageType(rawValue: type)
            }
            
            var location: ShippingAddress!
            if let locationBuffer = data["location"] as? [String: Any],
               let address = locationBuffer["address"] as? String,
               let latitude = locationBuffer["latitude"] as? Double,
               let longitude = locationBuffer["longitude"] as? Double {
                location = ShippingAddress(address: address, longitude: longitude, latitude: latitude)
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let formattedDate = formatter.string(from: sentAt)
            
            return Message(
                id: senderId,
                content: content,
                sentAt: formattedDate,
                sentAtFull: sentAt,
                imageURL: imageURL,
                location: location,
                type: messageType ?? .text,
                senderDisplayName: senderDisplayName,
                recipientDisplayName: recipientDisplayName
            )
        }
    }
}

class OnlineStatus {
    var lastSeen = [String: Date]()
    var isOnline: [String: Bool]!
    
    convenience init(querySnapshot: DocumentSnapshot) {
        self.init()
        self.isOnline = querySnapshot.get("isOnline") as? [String: Bool]
        if let lastSeenBuffer = querySnapshot.get("lastSeen") as? [String: Timestamp] {
            for (key, value) in lastSeenBuffer {
                lastSeen.updateValue(value.dateValue(), forKey: key)
            }
        }
    }
}

extension ChatViewController {
    @objc func appMovedToBackground() {
        Future<Bool, PostingError> { [weak self] promise in
            self?.registerOnlineStatus(false, promise: promise)
        }
        .sink { (_) in
        } receiveValue: { (_) in
        }
        .store(in: &storage)
    }
    
    @objc func appMovedToForeground() {
        configureOnlineStatus()
    }
    
    private func configureOnlineStatus2() {
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        Future<Bool, PostingError> { [weak self] promise in
            self?.registerOnlineStatus(true, promise: promise)
        }
        .eraseToAnyPublisher()
        .flatMap { [weak self] (_) -> AnyPublisher<OnlineStatus, PostingError> in
            Future<OnlineStatus, PostingError> { [weak self] promise in
                self?.getOnlineStatus(promise: promise)
            }
            .eraseToAnyPublisher()
        }
        .sink { (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    print(err)
                    break
                case .finished:
                    break
                default:
                    break
            }
        } receiveValue: { [weak self] (onlineStatus) in
            self?.showOnlineStatus(onlineStatus)
//            self?.lastSeen = onlineStatus.lastSeen
//            self?.showOnlineStatus(onlineStatus.isOnline)
        }
        .store(in: &storage)
    }
    
    private func configureOnlineStatus() {
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

        Future<Bool, PostingError> { [weak self] promise in
            self?.registerOnlineStatus(true, promise: promise)
        }
        .eraseToAnyPublisher()
        .sink { (completion) in
            switch completion {
                case .failure(.generalError(reason: let err)):
                    print(err)
                    break
                case .finished:
                    break
                default:
                    break
            }
        } receiveValue: { [weak self] (isRegistered) in
            guard isRegistered == true,
                  let docId = self?.docId else { return }
            
            self?.onlineStatusListener = FirebaseService.shared.db
                .collection("onlineStatus")
                .document(docId)
                .addSnapshotListener { (querySnapshot, error) in
                    if let _ = error {
                        return
                    }
                    
                    guard let querySnapshot = querySnapshot else { return }
                    let onlineStatus = OnlineStatus(querySnapshot: querySnapshot)
                    self?.showOnlineStatus(onlineStatus)
//                    self?.lastSeen = onlineStatus.lastSeen
//                    self?.showOnlineStatus(onlineStatus.isOnline)
                }
        }
        .store(in: &storage)
    }
    
    private func showOnlineStatus(_ retrievedOnlineStatus: [String: Bool]) {
        guard let recipientId = retrievedOnlineStatus.keys.filter({ $0 != userId }).first,
              let isOnline = retrievedOnlineStatus[recipientId] else { return }
        
        self.isOnline = isOnline
        DispatchQueue.main.async { [weak self] in
            self?.customTitleView.isOnline = isOnline
        }
    }
    
    private func showOnlineStatus(_ onlineStatus: OnlineStatus) {
        guard let retrievedOnlineStatus = onlineStatus.isOnline,
              let recipientId = retrievedOnlineStatus.keys.filter({ $0 != userId }).first,
              let isOnline = retrievedOnlineStatus[recipientId],
              let lastSeenDate = onlineStatus.lastSeen[recipientId] else { return }

        // to be used for the in message indicator
        self.isOnline = isOnline
        self.lastSeenDate = lastSeenDate
        
        // to be used for the custom title view
        DispatchQueue.main.async { [weak self] in
            self?.customTitleView.isOnline = isOnline
        }
    }
    
    private func registerOnlineStatus(
        _ isOnline: Bool,
        promise: @escaping (Result<Bool, PostingError>) -> Void
    ) {
        guard chatIsNew == false else { return }
        var onlineStatus: [String: Any]!
        
        if isOnline {
            onlineStatus = [
                "lastSeen": [
                    userId: Date(),
                ],
                "isOnline": [
                    userId: true
                ]
            ]
        } else {
            onlineStatusListener?.remove()
            onlineStatus = [
                "isOnline": [
                    userId: false
                ]
            ]
        }
        
        FirebaseService.shared.db
            .collection("onlineStatus")
            .document(docId)
            .setData(onlineStatus, merge: true) { (error) in
                if let _ = error {
                    promise(.failure(.generalError(reason: "Unable to register your online status.")))
                    return
                } else {
                    promise(.success(true))
                }
            }
    }
    
    private func getOnlineStatus(promise: @escaping (Result<OnlineStatus, PostingError>) -> Void) {
        onlineStatusListener = FirebaseService.shared.db
            .collection("onlineStatus")
            .document(docId)
            .addSnapshotListener { (querySnapshot, error) in
                if let _ = error {
                    promise(.failure(.generalError(reason: "Unable to get the online status of the chat member")))
                    return
                }
                
                guard let querySnapshot = querySnapshot else { return }
                let onlineStatus = OnlineStatus(querySnapshot: querySnapshot)
                promise(.success(onlineStatus))
            }
    }
}

extension ChatViewController {
    // MARK: - addKeyboardObserver
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    private func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            guard let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
            let keyboardViewEndFrame = view.convert(keyBoardFrame, from: view.window)
            let keyboardHeight = keyboardViewEndFrame.height

            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt

            self.tableView.frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: self.view.bounds.size.width,
                    height: self.view.bounds.size.height - keyboardHeight
                )
            )

            self.toolBarBottomConstraint.constant = -keyboardHeight
            self.view.setNeedsLayout()
            let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
            UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
                self.view.layoutIfNeeded()
            })
            tableView.scrollToTop()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt

        let insets: UIEdgeInsets = .zero
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
        tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
        
//        self.tableView.frame.origin.y = .zero
        self.toolBarBottomConstraint.constant = 0
        view.setNeedsLayout()
        let curveAnimationOptions = UIView.AnimationOptions(rawValue: curve << 16)
        UIView.animate(withDuration: duration, delay: 0, options: curveAnimationOptions, animations: {
            //                    self.toolBarView.frame = CGRect(origin: CGPoint(x: 0, y: self.view.frame.size.height - self.toolBarView.bounds.size.height - keyboardHeight), size: CGSize(width: self.view.bounds.size.width, height: 60))
            self.view.layoutIfNeeded()
        })
    }
}

// Get the screenshot and the location from ChatMapVC
// The sender sharing a location to the recipient
extension ChatViewController: HandleMapSearch {
    final func getScreenshot(image: UIImage, address: ShippingAddress) {
        sendLocation(
            image: image,
            imageName: UUID().uuidString,
            userId: userId,
            address: address
        )
    }
}
