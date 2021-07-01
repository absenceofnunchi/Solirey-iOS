//
//  MainViewController + SearchBar.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-30.
//

import UIKit

extension MainViewController {
    final func configureSearchBar() {
        // search bar attributes
        let searchBar = searchController!.searchBar
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .black
        searchBar.searchBarStyle = .minimal
        searchBar.scopeButtonTitles = ["Latest", "Category Filter", "User"]
        
        // search text field attributes
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1).cgColor
        searchTextField.textColor = .gray
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Search Here", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
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
        switch category {
            case .latest:
                FirebaseService.shared.getLatestSearchPosts(searchItems: searchItems)
            case .categoryFilter:
                FirebaseService.shared.getFilteredPosts()
            case .users:
                break
        }
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
                    self.present(filterVC, animated: true, completion: nil)
                case .users:
                    break
            }
            
        }
        //        updateSearchResults(for: searchController)
    }

    final func configureCategoryFilter() {
        let filterVC = FilterViewController()
        self.present(filterVC, animated: true, completion: nil)
    }
}
