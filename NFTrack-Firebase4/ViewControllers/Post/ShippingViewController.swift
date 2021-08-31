//
//  ShippingViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-30.
//

import UIKit
import CoreLocation

class ShippingViewController: AddressViewController {
    var filteredSearchVC: FilteredLocationSearchViewController!
    
    override func configureUI() {
        super.configureUI()
        title = "Shipping Info"
    }
    
    override func configureSearch() {
        filteredSearchVC = FilteredLocationSearchViewController(regionRadius: regionRadius)
        
        if let location = location {
            filteredSearchVC.location = location
        }
        
        resultSearchController = UISearchController(searchResultsController: filteredSearchVC)
        resultSearchController.searchResultsUpdater = filteredSearchVC
        navigationItem.searchController = resultSearchController

        guard let searchBar = resultSearchController?.searchBar else { return }
        searchBar.sizeToFit()
        searchBar.delegate = filteredSearchVC
        searchBar.placeholder = "Search for places"
        searchBar.scopeButtonTitles = ShippingRestriction.getAll()
//        navigationItem.titleView = searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = true
        resultSearchController?.obscuresBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
}

extension ShippingViewController {
    override func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        filteredSearchVC.location = location
    }
}
