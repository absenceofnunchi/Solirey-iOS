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
    var searchController: UISearchController!
    var searchCategory: String = "sellerDisplayName"
    var searchTermRetainer: String!
    
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
    func fetchChatList() {
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

                self?.postArr.removeAll()
                if let chatListModels = self?.parseChatListModels(querySnapshot.documents) {
                    self?.postArr.append(contentsOf: chatListModels)
                }
            }
    }
        
    func refetchChatList(lastSnapshot: QueryDocumentSnapshot) {
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
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.searchBar.text?.isEmpty != true,
              let searchTerm = searchController.searchBar.text else {
            print("search bar empty")
            return
        }
        let strippedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTermRetainer = strippedSearchTerm
        fetchSearchedData(selectedCategory: searchTermRetainer, searchTerm: strippedSearchTerm)
    }
    
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let selectedCategory: String = ChatListCategory.getCategory(num: selectedScope) else { return }
        searchCategory = selectedCategory
        fetchSearchedData(selectedCategory: selectedCategory, searchTerm: searchTermRetainer)
    }
    
    // MARK: - searchBarSearchButtonClicked
    final func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text else { return }
        // Strip out all the leading and trailing spaces.
        let strippedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        fetchSearchedData(selectedCategory: searchTermRetainer, searchTerm: strippedSearchTerm)
        searchBar.resignFirstResponder()
    }
    
    func fetchSearchedData(selectedCategory: String, searchTerm: String) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .whereField(selectedCategory, isEqualTo: searchTerm)
            .limit(to: PAGINATION_LIMIT)
            .order(by: "sentAt", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
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
    
    func refetchSearchedData(lastSnapshot: QueryDocumentSnapshot, selectedCategory: String, searchTerm: String) {
        firstListener = FirebaseService.shared.db
            .collection("chatrooms")
            .whereField("members", arrayContains: userId as String)
            .whereField(selectedCategory, isEqualTo: searchTerm)
            .limit(to: PAGINATION_LIMIT)
            .order(by: "sentAt", descending: true)
            .start(afterDocument: lastSnapshot)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
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
