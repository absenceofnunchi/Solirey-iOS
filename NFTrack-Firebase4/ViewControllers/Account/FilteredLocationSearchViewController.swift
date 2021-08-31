//
//  FilteredLocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-30.
//

import UIKit
import MapKit

class FilteredLocationSearchViewController: LocationSearchViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension FilteredLocationSearchViewController {
    override func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        guard let location = location else {
            self.alert.fading(text: "Please enable your location.", controller: self, toBePasted: nil, width: 250) {
                self.delay(0.5) {
                    searchController.searchBar.searchTextField.resignFirstResponder()
                }
            }
            return
        }
 
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        request.pointOfInterestFilter = .excludingAll
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            if let _ = error {
                self?.alert.showDetail("Error", with: "Unable to fetch the addresses.", for: self)
            }
            
            guard let response = response else { return }
            self?.matchingItems.removeAll()
            
//            response.mapItems.map { (item) in
//                <#code#>
//            }
            self?.matchingItems.append(contentsOf: response.mapItems)
            self?.tableView.reloadData()
        }
    }
    
    func processAddress(items: [MKMapItem], scope: ShippingRestriction) {
        switch scope {
            case .cities:
                <#code#>
            default:
                break
        }
    }
}

extension FilteredLocationSearchViewController: UISearchBarDelegate {
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("selectedScope", selectedScope)
        guard let scope = ShippingRestriction(rawValue: selectedScope) else { return }
        
    }
}
