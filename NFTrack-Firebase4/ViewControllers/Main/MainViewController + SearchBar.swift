//
//  MainViewController + SearchBar.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-30.
//

import UIKit
import FirebaseFirestore

extension MainViewController: UISearchBarDelegate, UISearchControllerDelegate  {
    // configure search controller
    func configureSearchController() {
        searchResultsController = SearchResultsController()
        searchResultsController.delegate = self
        let nav = UINavigationController(rootViewController: searchResultsController)
        searchController = UISearchController(searchResultsController: nav)
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
        searchBar.scopeButtonTitles = ScopeButtonCategory.getAll()
        
        // search text field attributes
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1).cgColor
        searchTextField.textColor = .gray
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Search Here", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
    }
    
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let selectedCategory = ScopeButtonCategory.getCategory(num: selectedScope) {
            //            self.category = selectedCategory.rawValue
            //            fetchData(category: self.category)
            self.category = selectedCategory
            switch selectedCategory {
                case .latest:
                    break
                case .categoryFilter:
                    searchBar.resignFirstResponder()
                    let filterVC = FilterViewController()
                    filterVC.onDoneBlock = { [weak self] vc in
                        vc.dismiss(animated: true) {
                            DispatchQueue.main.async {
                                self?.searchResultsController.postArr.removeAll()
                                self?.getFilteredPosts(searchItems: self?.searchItems ?? [])
                                self?.searchResultsController.tableView.reloadData()
//                                searchBar.searchTextField.becomeFirstResponder()
                            }
                        }
                    }
                    self.present(filterVC, animated: true, completion: nil)
            }
            
        }
        //        updateSearchResults(for: searchController)
    }
    
    // MARK: - searchBarSearchButtonClicked
    final func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchController.searchBar.text else { return }
        
        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = text.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
        let searchItems = strippedString.components(separatedBy: " ") as [String]
        
        fetchData(category: category, searchItems: searchItems)
        searchBar.resignFirstResponder()
    }
    
    final func fetchData(category: ScopeButtonCategory, searchItems: [String]) {
        searchResultsController.postArr.removeAll()
        self.searchItems = searchItems
        switch category {
            case .latest:
                getLatestSearchPosts(searchItems: searchItems)
            case .categoryFilter:
                getFilteredPosts(searchItems: searchItems)
        }
    }
}

extension MainViewController: RefetchDataDelegate, PostParseDelegate {
    func getLatestSearchPosts(searchItems: [String]) {
        var first = db?.collection("post")
            .limit(to: 10)
            .order(by: "date", descending: true)
        
        if !searchItems.isEmpty, searchItems.count > 0 {
            // tag also contains the separated array of the title sentence
            first = first?.whereField("tags", arrayContainsAny: searchItems)
        }
        
        first?.getDocuments (completion: {[weak self] (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                self?.alert.showDetail("Sorry", with: "There was an error fetching the search result.", for: self)
                return
            }
            
            if let _ = error {
                self?.alert.showDetail("Sorry", with: "There was an error fetching the search result.", for: self)
            }
            
            if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                self?.searchResultsController.postArr = postArr
            }
            
            if let lastSnapshot = querySnapshot.documents.last {
                self?.lastSnapshot = lastSnapshot
            }
        })
    }

    func refetchLatestSearchPost() {
        var next = db?.collection("post")
            .order(by: "date", descending: true)
            .limit(to: 10)
            .start(afterDocument: lastSnapshot)
        
        if !searchItems.isEmpty, searchItems.count > 0 {
            next = next?.whereField("tags", arrayContainsAny: searchItems)
        }
        
        next?.getDocuments(completion: { [weak self] (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                self?.alert.showDetail("Sorry", with: error?.localizedDescription, for: self)
                return
            }
            
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
            }
            
            if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                self?.searchResultsController.postArr.append(contentsOf: postArr)
            }
            
            if let lastSnapshot = querySnapshot.documents.last {
                self?.lastSnapshot = lastSnapshot
            }
        })
    }
        
    func getFilteredPosts(searchItems: [String]) {
        guard let filterSettings = UserDefaults.standard.object(forKey: UserDefaultKeys.filterSettings) as? Data,
              let decoded = try? JSONDecoder().decode(FilterSettings.self, from: filterSettings) else {
            view.endEditing(true)
            let filterVC = FilterViewController()
            self.present(filterVC, animated: true, completion: nil)
            return
        }
        
        var first = db?.collection("post")
            .whereField("price", isLessThan: String(decoded.priceLimit))
            .order(by: "price", descending: decoded.priceIsDescending)
            .order(by: "date", descending: decoded.dateIsDescending)
            .limit(to: 8)

        if !searchItems.isEmpty, searchItems.count > 0 {
            first = first?.whereField("tags", arrayContainsAny: searchItems)
        }
        
        if let itemIndexPath = decoded.itemIndexPath,
           let category = Category(rawValue: itemIndexPath.item) {
            first = first?.whereField("category", isEqualTo: category.asString())
        }

        first?.getDocuments(completion: { [weak self] (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                self?.alert.showDetail("Sorry", with: error?.localizedDescription, for: self)
                return
            }
            
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
            }

            if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                self?.searchResultsController.postArr.append(contentsOf: postArr)
            }

            if let lastSnapshot = querySnapshot.documents.last {
                self?.lastSnapshot = lastSnapshot
            }
        })
    }
    
    func refetchFilteredPosts() {
        guard let filterSettings = UserDefaults.standard.object(forKey: UserDefaultKeys.filterSettings) as? Data,
              let decoded = try? JSONDecoder().decode(FilterSettings.self, from: filterSettings) else {
            view.endEditing(true)
            let filterVC = FilterViewController()
            self.present(filterVC, animated: true, completion: nil)
            return
        }
        
        var next = db?.collection("post")
            .whereField("price", isLessThan: decoded.priceLimit)
            .order(by: "price", descending: decoded.priceIsDescending)
            .order(by: "date", descending: decoded.dateIsDescending)
            .limit(to: 8)
            .start(afterDocument: lastSnapshot)

        if !searchItems.isEmpty, searchItems.count > 0 {
            next = next?.whereField("tags", arrayContainsAny: searchItems)
        }
        
        if let itemIndexPath = decoded.itemIndexPath,
           let category = Category(rawValue: itemIndexPath.item) {
            next = next?.whereField("category", isEqualTo: category.asString())
        }
            
        next?.getDocuments(completion: { [weak self] (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("querySnapshot error")
                return
            }
            
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
            }
            
            if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                self?.searchResultsController.postArr.append(contentsOf: postArr)
            }
            
            if let lastSnapshot = querySnapshot.documents.last {
                self?.lastSnapshot = lastSnapshot
            }
        })
    }
    
    func didFetchData() {
        switch self.category {
            case .latest:
                refetchLatestSearchPost()
            case .categoryFilter:
                refetchFilteredPosts()
            default:
                break
        }
    }
}
