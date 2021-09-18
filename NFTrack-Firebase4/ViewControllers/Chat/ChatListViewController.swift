//
//  ChatListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit
import FirebaseFirestore
import Combine

class ChatListViewController: ParentChatListViewController, UISearchControllerDelegate, UISearchBarDelegate {
    var searchResultsController: ParentChatListViewController!
    var searchController: UISearchController!
    var searchCategory: ChatListCategory = .seller
    var searchTermRetainer: String!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        configureSearchBar()
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchChatList()
    }
    
    override func executeAfterDragging() {
        refetchChatList(
            lastSnapshot: lastSnapshot,
            category: searchCategory,
            searchTerm: searchTermRetainer
        )
    }
}

extension ChatListViewController {
    func configureSearchController() {
//        searchResultsController = ParentChatListViewController()
//        searchResultsController.delegate = self
//        let nav = UINavigationController(rootViewController: searchResultsController)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        //        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    
    final func configureSearchBar() {
        // search bar attributes
        let searchBar = searchController!.searchBar
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .black
        searchBar.searchBarStyle = .minimal
        searchBar.scopeButtonTitles = ChatListCategory.getAll()

        // search text field attributes
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.textColor = .gray
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Search Here", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
    }
}

extension ChatListViewController {
    func fetchChatList(category: ChatListCategory = .seller, searchTerm: String? = nil) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .limit(to: PAGINATION_LIMIT)
            .order(by: "sentAt", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to fetch your chat.", for: self)
                    return
                }

                defer {
                    self?.tableView.reloadData()
                }

                guard let querySnapshot = querySnapshot else {
                    return
                }

                self?.imageCache.removeAllObjects()
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    return
                }

                self?.lastSnapshot = lastSnapshot

                guard !querySnapshot.documents.isEmpty else {
                    return
                }

                self?.postArr.removeAll()
                if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
                    self?.postArr.append(contentsOf: chatListModels)
                }
            }
        
//        var ref = FirebaseService.shared.db
//            .collection("chatrooms")
//            .whereField("members", arrayContains: userId as String)
//            .limit(to: PAGINATION_LIMIT)
//            .order(by: "sentAt", descending: true)
//
//        if let searchTerm = searchTerm {
//            print("searchTerm", searchTerm as Any)
//            let displayNameField = category == .seller ? "sellerDisplayName" : "buyerDisplayName"
//            print("displayNameField", displayNameField as Any)
//            ref = ref.whereField(displayNameField, isEqualTo: searchTerm)
//        }
//
//        firstListener = ref.addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
//            if let _ = error {
//                self?.alert.showDetail("Sorry", with: "Unable to fetch your chat.", for: self)
//                return
//            }
//
//            defer {
//                self?.tableView.reloadData()
//            }
//
//            print("querySnapshot", querySnapshot)
//            guard let querySnapshot = querySnapshot else {
//                print("empty1")
//                return
//            }
        
//            self?.imageCache.removeAllObjects()
//
//            print("querySnapshot.documents.last", querySnapshot.documents.last as Any)
//            guard let lastSnapshot = querySnapshot.documents.last else {
//                return
//            }
//
//            self?.lastSnapshot = lastSnapshot
//
//            guard !querySnapshot.documents.isEmpty else {
//                print("empty2")
//                return
//            }
//
//            print("querySnapshot.documents", querySnapshot.documents as Any)
//            self?.postArr.removeAll()
//            if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
//                print("chatListModels", chatListModels)
//                self?.postArr.append(contentsOf: chatListModels)
//            }
//        }
    }
    
    func refetchChatList(
        lastSnapshot: QueryDocumentSnapshot,
        category: ChatListCategory = .seller,
        searchTerm: String? = nil
    ) {
        var ref = FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .order(by: "sentAt", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
            
        if let searchTerm = searchTerm {
            let displayNameField = category == .seller ? "sellerDisplayName" : "buyerDisplayName"
            ref = ref.whereField(displayNameField, isEqualTo: searchTerm)
        }
        
        nextListener = ref.addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                if let _ = error {
                    self?.alert.showDetail("Sorry", with: "Unable to fetch your chat.", for: self)
                    return
                }
                
                defer {
                    self?.tableView.reloadData()
                }
                
                guard let querySnapshot = querySnapshot else {
                    return
                }
            
                self?.imageCache.removeAllObjects()
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                guard !querySnapshot.documents.isEmpty else {
                    return
                }
                
                if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
                    self?.postArr.append(contentsOf: chatListModels)
                }
            }
    }
}

extension ChatListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.searchBar.text?.isEmpty == true {
            fetchChatList()
        }
    }
    
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let selectedCategory = ChatListCategory.getCategory(num: selectedScope) else { return }
        self.searchCategory = selectedCategory
    }
    
    // MARK: - searchBarSearchButtonClicked
    final func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchController.searchBar.text else { return }
        self.searchTermRetainer = searchTerm
        // Strip out all the leading and trailing spaces.
//        let whitespaceCharacterSet = CharacterSet.whitespaces
//        let strippedString = text.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
//        let searchItems = strippedString.components(separatedBy: " ") as [String]
        
        fetchChatList(category: searchCategory, searchTerm: searchTerm)
        searchBar.resignFirstResponder()
    }
}
