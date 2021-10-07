//
//  SavedViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-13.
//

import UIKit
import FirebaseFirestore
import Combine

class SavedViewController: ParentListViewController<Post>, PostParseDelegate {
    private var first: Query!
    private var customNavView: BackgroundView5!
    private var isSaved: Bool!
    var storage: Set<AnyCancellable>! = {
        return Set<AnyCancellable>()
    }()

    final override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Items"
        fetchData()
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isMovingToParent {
            if firstListener != nil {
                firstListener.remove()
            }
            
            if nextListener != nil {
                nextListener.remove()
            }
        }
    }

    private func fetchData() {
        firstListener = FirebaseService.shared.db.collection("post")
            .whereField("savedBy", arrayContainsAny: [userId!])
            .limit(to: PAGINATION_LIMIT)
            .addSnapshotListener() { [weak self](querySnapshot: QuerySnapshot?, err: Error?) in
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the saved posts.", for: self)
                } else {
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
                        self?.postArr = data
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
    }
    
    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    final override func configureUI() {
        super.configureUI()
        
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
        
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -65),
            customNavView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50),
        ])
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
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = post
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }

    final override func executeAfterDragging() {
        guard postArr.count > 0 else { return }
        nextListener = FirebaseService.shared.db.collection("post")
            .whereField("savedBy", arrayContainsAny: [userId!])
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener() { [weak self](querySnapshot: QuerySnapshot?, err: Error?) in
                if let _ = err {
                    self?.alert.showDetail("Data Fetch Error", with: "There was an error fetching the saved posts.", for: self)
                } else {
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
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
    }
}

extension SavedViewController: ContextAction {
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
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSCopying, previewProvider: { [weak self] in self?.getPreviewVC(post: post) }) { _ in
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
