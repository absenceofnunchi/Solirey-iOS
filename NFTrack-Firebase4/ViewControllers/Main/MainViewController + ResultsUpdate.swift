//
//  MainViewController + ResultsUpdate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchItems = searchController.searchBar.text else { return }
        let trimmed = searchItems.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // If the current view controller is not the intial search result view controller (SearchResultsVC),
        // pop back to the root VC as soon as the user searches another item into the search bar
        if let nav = searchController.searchResultsController as? UINavigationController,
           !(nav.topViewController is SearchResultsController) {
            nav.popToRootViewController(animated: true)
        }
        
        fetchData(category: category, searchItems: searchItems)
    }
}
