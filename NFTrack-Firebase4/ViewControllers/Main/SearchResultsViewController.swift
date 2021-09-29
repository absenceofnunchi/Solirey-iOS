//
//  SearchResultsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import Combine
import FirebaseFirestore

class SearchResultsController: ParentListViewController<Post>, UISearchBarDelegate {
    let CELL_HEIGHT: CGFloat = 330
    var isSaved: Bool!
    var storage = Set<AnyCancellable>()
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
        
        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: CardCell.self, identifier: CardCell.identifier)
        tableView.prefetchDataSource = self
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.fill()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SearchResultsController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
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
        keyboardDelegate?.doSomething()
        
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
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

extension SearchResultsController: FetchUserConfigurable {
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

        if let savedBy = post.savedBy, savedBy.contains(userId) {
            isSaved = true
        } else {
            isSaved = false
        }
        let starImage = isSaved ? "star.fill" : "star"
        let posting = UIAction(title: "Save", image: UIImage(systemName: starImage)) { [weak self] action in
            self?.savePost(post)
        }
        
        let profile = UIAction(title: "Profile", image: UIImage(systemName: "person.crop.circle")) { [weak self] action in
            guard let post = self?.postArr[indexPath.row] else { return }
            self?.navToProfile(post)
        }
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
            UIMenu(title: "", children: [posting, profile])
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
    
    private func navToProfile(_ post: Post) {
        showSpinner { [weak self] in
            Future<UserInfo, PostingError> { promise in
                self?.fetchUserData(userId: post.sellerUserId, promise: promise)
            }
            .sink { (completion) in
                switch completion {
                    case .failure(.generalError(reason: let err)):
                        self?.alert.showDetail("Error", with: err, for: self)
                        break
                    case .finished:
                        break
                    default:
                        break
                }
            } receiveValue: { (userInfo) in
                self?.hideSpinner({
                    DispatchQueue.main.async {
                        let profileDetailVC = ProfileDetailViewController()
                        profileDetailVC.userInfo = userInfo
                        self?.navigationController?.pushViewController(profileDetailVC, animated: true)
                    }
                })
            }
            .store(in: &self!.storage)
        }
    }
    
    private func getPreviewVC(post: Post) -> ListDetailViewController {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        return listDetailVC
    }
}
