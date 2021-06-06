//
//  MainViewController + ResultsUpdate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
//        guard let text = searchController.searchBar.text else { return }
//        
//        print("text", text)
//        
//        var filtered = data
//        
//        // Strip out all the leading and trailing spaces.
//        let whitespaceCharacterSet = CharacterSet.whitespaces
//        let strippedString = text.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
//        let searchItems = strippedString.components(separatedBy: " ") as [String]
//        
//        // Filter results down by matching words. Can include multiple properties if the data type has them.
//        var curTerm = searchItems[0]
//        var idx = 0
////        while curTerm != "" {
////            filtered = filtered.filter { $0.name.lowercased().contains(curTerm) }
////            idx += 1
////            curTerm = (idx < searchItems.count) ? searchItems[idx] : ""
////        }
////
////        self.searchResultsController.data = filtered
//        
//        DispatchQueue.main.async {
//            self.searchResultsController.tableView.reloadData()
//        }
    }
}
