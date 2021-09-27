//
//  ChatListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit
import FirebaseFirestore
import Combine

class ChatListViewController: ParentChatListViewController {
    private var searchController: UISearchController!
    private var searchCategory: String = "searchableSellerDisplayName"
    private var searchTermRetainer: String!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        configureSearchBar()
        
        fetchChatList()
    }

    override func executeAfterDragging() {
        guard postArr.count > 0 else { return }
        refetchChatList(lastSnapshot: lastSnapshot)
    }
}

extension ChatListViewController {
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        
        guard let searchBar = searchController?.searchBar else { return }
        searchBar.sizeToFit()
//        searchBar.placeholder = "Search for places"
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    
    final func configureSearchBar() {
        // search bar attributes
        guard let searchController = searchController else { return }
        let searchBar = searchController.searchBar
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
    final func fetchChatList() {
        loadingOperations.removeAll()
        loadingQueue.cancelAllOperations()

        FirebaseService.shared.db
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

                self?.cache.removeAllObjects()
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    return
                }

                self?.lastSnapshot = lastSnapshot

                guard !querySnapshot.documents.isEmpty else {
                    return
                }

                if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
                    self?.postArr = chatListModels
                }
            }
    }
        
    final func refetchChatList(lastSnapshot: QueryDocumentSnapshot) {
        FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .order(by: "sentAt", descending: true)
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
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
            
                self?.cache.removeAllObjects()
                
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

extension ChatListViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    final func updateSearchResults(for searchController: UISearchController) {
        guard searchController.searchBar.text?.isEmpty != true,
              let searchTerm = searchController.searchBar.text else {
            fetchChatList()
            return
        }
        fetchSearchedData(selectedCategory: searchCategory, searchTerm: searchTerm)
    }
    
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let selectedCategory: String = ChatListCategory.getCategory(num: selectedScope),
              let searchTerm = searchBar.text, !searchTerm.isEmpty else { return }
        fetchSearchedData(selectedCategory: selectedCategory, searchTerm: searchTerm)
    }
    
    // MARK: - searchBarSearchButtonClicked
    final func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {//        guard let searchTerm = searchBar.text else { return }
        guard let searchTerm = searchBar.text, !searchTerm.isEmpty else { return }
        fetchSearchedData(selectedCategory: searchCategory, searchTerm: searchTerm)
        searchBar.resignFirstResponder()
    }

    final func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        fetchChatList()
    }
    
    final func fetchSearchedData(selectedCategory: String, searchTerm: String) {
        let strippedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !strippedSearchTerm.isEmpty else { return }
        searchTermRetainer = strippedSearchTerm
        searchCategory = selectedCategory

        print("selectedCategory", selectedCategory)
        print("strippedSearchTerm", strippedSearchTerm)
        loadingOperations.removeAll()
        loadingQueue.cancelAllOperations()
        
        FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .whereField(selectedCategory, isEqualTo: strippedSearchTerm)
            .limit(to: PAGINATION_LIMIT)
            .order(by: "sentAt", descending: true)
            .getDocuments { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                print("error", error)
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
                
                self?.cache.removeAllObjects()
                
                guard let lastSnapshot = querySnapshot.documents.last else {
                    print("1")
                    self?.postArr.removeAll()
                    return
                }
                
                self?.lastSnapshot = lastSnapshot
                
                guard !querySnapshot.documents.isEmpty else {
                    print("2")
                    self?.postArr.removeAll()
                    return
                }
                
                self?.postArr.removeAll()
                if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
                    print("chatListModels", chatListModels)
                    self?.postArr = chatListModels
                }
            }
    }
    
    func refetchSearchedData(lastSnapshot: QueryDocumentSnapshot, selectedCategory: String, searchTerm: String) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .whereField(selectedCategory, isEqualTo: searchTerm)
            .limit(to: PAGINATION_LIMIT)
            .order(by: "sentAt", descending: true)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                print("error", error as Any)
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
                
                self?.cache.removeAllObjects()
                
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
