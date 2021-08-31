//
//  FilteredLocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-30.
//

import UIKit
import MapKit

class FilteredLocationSearchViewController: LocationSearchViewController {
    var items = [String]()
    var scope: ShippingRestriction! = .cities
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
            if let error = error {
                print("error", error)
                return
            }

            guard let response = response,
                  let scope = self?.scope else { return }
            self?.items.removeAll()

            var itemSet = Set<String>()
            response.mapItems.forEach { (item) in
                let i = self!.parseAddress(selectedItem: item.placemark, scope: scope)
                itemSet.insert(i)
            }
//            let parsed = response.mapItems.map { self!.parseAddress(selectedItem: $0.placemark, scope: scope) }
            self?.items.append(contentsOf: itemSet)
            self?.tableView.reloadData()
        }
    }
    
//    func scopeAddress(items: [MKMapItem], scope: ShippingRestriction) {
//        let result = items.map { (item)  in
//            return parseAddress(selectedItem: item.placemark, scope: scope)
//        }
//        
//    }
}

extension FilteredLocationSearchViewController: UISearchBarDelegate {
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//        print("selectedScope", selectedScope)
//        guard let scope = ShippingRestriction(rawValue: selectedScope) else { return }
        
    }
}

// MARK: - Table view data source
extension FilteredLocationSearchViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseIdentifier, for: indexPath) as? AddressCell else {
            fatalError()
        }
        
        let selectedItem = items[indexPath.row]
        cell.mainLabel.text = selectedItem
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let selectedItem = matchingItems[indexPath.row].placemark
//        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
//        dismiss(animated: true, completion: nil)
    }
}
