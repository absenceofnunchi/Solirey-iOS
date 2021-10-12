//
//  FilteredLocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-30.
//

import UIKit
import MapKit

class FilteredLocationSearchViewController: ParentLocationSearchViewController {
    var data = [String]()
    var scopeRetainer: ShippingRestriction! = .cities
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        self.searchController = searchController
        
        scopedSearch(
            searchBar: searchController.searchBar,
            searchController: searchController,
            location: location,
            scope: scopeRetainer
        )
    }
}

extension FilteredLocationSearchViewController {
    func scopedSearch(
        searchBar: UISearchBar,
        searchController: UISearchController,
        location: CLLocationCoordinate2D?,
        scope: ShippingRestriction
    ) {
        guard let searchBarText = searchBar.text else { return }
        guard let location = location else {
            self.alert.fading(text: "Please enable your location.", controller: self, toBePasted: nil, width: 250) {
                self.delay(0.5) {
                    searchController.searchBar.searchTextField.resignFirstResponder()
                }
            }
            return
        }

        request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = MKCoordinateRegion(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        request.pointOfInterestFilter = .excludingAll
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            if let error = error {
                print("error", error)
                return
            }
            
            guard let response = response else { return }
            self?.data.removeAll()
            var itemSet = Set<String>()
            response.mapItems.forEach { (item) in
                guard let self = self else { return }
                let i = self.parseAddress(selectedItem: item.placemark, scope: scope)
                itemSet.insert(i)
            }
            //            let parsed = response.mapItems.map { self!.parseAddress(selectedItem: $0.placemark, scope: scope) }
            self?.data.append(contentsOf: itemSet)
            self?.tableView.reloadData()
        }
    }
}

extension FilteredLocationSearchViewController {
    final func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let scope = ShippingRestriction(rawValue: selectedScope) else { return }
        scopeRetainer = scope
        handleMapSearchDelegate?.resetSearchResults()
//        if searchBar.searchTextField.tokens.count > 0 {
//            for i in stride(from: searchBar.searchTextField.tokens.count - 1, through: 0, by: -1) {
//                searchBar.searchTextField.removeToken(at: i)
//            }
//        }

        scopedSearch(
            searchBar: searchBar,
            searchController: searchController,
            location: location,
            scope: scope
        )
    }
}

// MARK: - Table view data source
extension FilteredLocationSearchViewController: HandleMapSearch {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let selectedItem = data[indexPath.row]
        cell.textLabel?.text = selectedItem
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = data[indexPath.row]
//        addTag(selectedItem)
        
        dismiss(animated: true, completion: nil)
        
        getPlacemark(addressString: selectedItem) { [weak self] (placemark, error) in
            if let error = error {
                print("error", error)
                return
            }
            
            if let placemark = placemark {
                self?.handleMapSearchDelegate?.dropPinZoomIn(
                    placemark: placemark,
                    addressString: selectedItem,
                    scope: self?.scopeRetainer
                )
            }
        }
    }
}

extension FilteredLocationSearchViewController: TokenConfigurable {
    func addTag(_ address: String) {
        let tagTextField = self.searchController.searchBar.searchTextField
        tagTextField.text?.removeAll()
        let token = createSearchToken(text: address, index: tagTextField.tokens.count)
        tagTextField.insertToken(token, at: tagTextField.tokens.count > 0 ? tagTextField.tokens.count : 0)
    }
}
