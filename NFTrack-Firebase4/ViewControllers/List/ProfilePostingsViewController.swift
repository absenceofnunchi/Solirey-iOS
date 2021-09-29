//
//  ProfilePostingsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-22.
//

import UIKit
import FirebaseFirestore
import Combine

class ProfilePostingsViewController: ProfileListViewController<Post>, PostParseDelegate {
    private var isSaved: Bool!
    private var storage = Set<AnyCancellable>()
    
    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    final override func configureUI() {
        super.configureUI()
        tableView = configureTableView(
            delegate: self,
            dataSource: self,
            height: CELL_HEIGHT,
            cellType: ProfilePostCell.self,
            identifier: ProfilePostCell.identifier
        )
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
 
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfilePostCell.identifier) as? ProfilePostCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
    
    final override func fetchData() {
        guard let uid = userInfo.uid else { return }
        firstListener = db?.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .addSnapshotListener { [weak self] (querySnapshot, err) in
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
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
                
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the user's posts.", for: self)
                } else {
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr = data
                    }
                }
            }
    }
    
    final override func refetchData(lastSnapshot: QueryDocumentSnapshot) {
        guard let uid = userInfo.uid else { return }
        nextListener = db?.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .order(by: "date", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener { [weak self] (querySnapshot, err) in
                defer {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
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
                
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the user's posts.", for: self)
                } else {
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr.append(contentsOf: data)
                    }
                }
            }
    }
}

extension ProfilePostingsViewController: FetchUserConfigurable {
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let profileAction = profileContextualAction(forRowAt: indexPath)
        
        profileAction.backgroundColor = UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1)
        let configuration = UISwipeActionsConfiguration(actions: [profileAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func profileContextualAction(forRowAt indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Profile") { [weak self] (action, swipeButtonView, completion) in
            guard let post = self?.postArr[indexPath.row] else { return }
            self?.navToProfile(post)
            completion(true)
        }
    }
}

