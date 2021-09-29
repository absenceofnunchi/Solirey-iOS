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
        searchResultsController.keyboardDelegate = self
        let nav = UINavigationController(rootViewController: searchResultsController)
        searchController = UISearchController(searchResultsController: nav)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
//        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = true

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
        searchBar.scopeButtonTitles = ScopeButtonCategory.getAll()
//        searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], for: .application)

        // Selected text
        let titleTextAttributesSelected = [NSAttributedString.Key.foregroundColor: UIColor.black]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributesSelected, for: .selected)
        
        // Normal text
        let titleTextAttributesNormal = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributesNormal, for: .normal)
        
        // background color for the non-selected background
        UISegmentedControl.appearance().backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        
        let cancelButtonAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: UIControl.State.normal)
        
        // search text field attributes
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.backgroundColor = .white
//        searchTextField.layer.borderWidth = 1
//        searchTextField.layer.borderColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1).cgColor
        searchTextField.textColor = .gray
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Search Here", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
    }
    
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let selectedCategory = ScopeButtonCategory.getCategory(num: selectedScope) {
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
                            }
                        }
                    }
                    self.present(filterVC, animated: true, completion: nil)
            }
            
        }
    }
    
    // MARK: - searchBarSearchButtonClicked
    final func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchItems = searchController.searchBar.text else { return }
        fetchData(category: category, searchItems: searchItems)
        searchBar.resignFirstResponder()
    }
    
    final func fetchData(category: ScopeButtonCategory, searchItems: String) {
        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = searchItems.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
        let searchItems = strippedString.components(separatedBy: " ") as [String]
        
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

extension MainViewController: RefetchDataDelegate, PostParseDelegate, GeneralPurposeDelegate {
    func getLatestSearchPosts(searchItems: [String]) {
        var first = db?.collection("post")
            .limit(to: PAGINATION_LIMIT)
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
                return
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
            .limit(to: PAGINATION_LIMIT)
            .start(afterDocument: lastSnapshot)
        
        if !searchItems.isEmpty, searchItems.count > 0 {
            next = next?.whereField("tags", arrayContainsAny: searchItems)
        }
        
        next?.getDocuments(completion: { [weak self] (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                self?.alert.showDetail("Sorry", with: "Unable to fetch data.", for: self)
                return
            }
            
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                return
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
            .limit(to: PAGINATION_LIMIT)

        if !searchItems.isEmpty, searchItems.count > 0 {
            first = first?.whereField("tags", arrayContainsAny: searchItems)
        }
        
        if let itemIndexPath = decoded.itemIndexPath,
           let category = Category(rawValue: itemIndexPath.item) {
            first = first?.whereField("category", isEqualTo: category.asString())
        }

        first?.getDocuments(completion: { [weak self] (querySnapshot, error) in
            print("error", error as Any)
            
            guard let querySnapshot = querySnapshot else {
                self?.alert.showDetail("Sorry", with: "Unable to fetch data.", for: self)
                return
            }
            
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                return
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
            .limit(to: PAGINATION_LIMIT)
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
                return
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
    
    func doSomething() {
        navigationItem.searchController?.searchBar.endEditing(true)
    }
}
