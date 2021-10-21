//
//  SearchResultsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import Combine
import FirebaseFirestore

class SearchResultsController: ParentListViewController<Post>, UISearchBarDelegate, FetchContractAddress {
    let CELL_HEIGHT: CGFloat = 330
    var isSaved: Bool!
    var storage: Set<AnyCancellable>! = {
        return Set<AnyCancellable>()
    }()
    weak final var delegate: RefetchDataDelegate?
    weak final var keyboardDelegate: GeneralPurposeDelegate?
    override var postArr: [Post] {
        didSet {
            tableView.contentSize = CGSize(width: self.view.bounds.size.width, height: CGFloat(postArr.count) * CELL_HEIGHT + 80)
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func configureUI() {
        super.configureUI()
        applyBarTintColorToTheNavigationBar()
        
        tableView = UITableView()
        tableView.register(ImageCardCell.self, forCellReuseIdentifier: ImageCardCell.identifier)
        tableView.register(NoImageCardCell.self, forCellReuseIdentifier: NoImageCardCell.identifier)
        tableView.estimatedRowHeight = CELL_HEIGHT
        tableView.rowHeight = CELL_HEIGHT
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        tableView.contentInsetAdjustmentBehavior = .always
        view.addSubview(tableView)
        tableView.fill()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SearchResultsController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        keyboardDelegate?.doSomething()
        let post = postArr[indexPath.row]
        
        guard let paymentMethod = PaymentMethod(rawValue: post.paymentMethod) else {
            self.alert.showDetail("Error", with: "There was an error accessing the item data.", for: self)
            return
        }
        
        switch paymentMethod {
            case .escrow:
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                // refreshes the MainDetailVC table when the user updates the status
                self.navigationController?.pushViewController(listDetailVC, animated: true)
                break
            case .auctionBeneficiary:
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
            case .directTransfer:
                let simpleVC = SimpleRevisedViewController()
                simpleVC.post = post
                self.navigationController?.pushViewController(simpleVC, animated: true)
                
//                guard let escrowHash = post.escrowHash else { return }
//                getContractAddress(with: escrowHash) { [weak self] (contractAddress) in
//                    let simplePaymentDetailVC = SimplePaymentDetailViewController(deployedContractAddress: contractAddress)
//                    simplePaymentDetailVC.post = post
//                    self?.navigationController?.pushViewController(simplePaymentDetailVC, animated: true)
//                }
                break
        }
    }
    
    override func executeAfterDragging() {
        if postArr.count > 0 {
            delegate?.didFetchData()
        }
    }
    
    @objc override func dismissKeyboard() {
        super.dismissKeyboard()
        navigationController?.navigationItem.searchController?.searchBar.resignFirstResponder()
        navigationItem.searchController?.searchBar.resignFirstResponder()
    }
}

extension SearchResultsController: ContextAction {
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        view.endEditing(true)
        animator.addAnimations { [weak self] in
            self?.show(destinationViewController, sender: self)
        }
    }
    
    final override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    final override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let post = postArr[indexPath.row]
        view.endEditing(true)
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
        
        return UIContextMenuConfiguration(identifier: "SearchResultsPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
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
