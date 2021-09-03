//
//  FilteredLocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-30.
//

import UIKit
import MapKit

class FilteredLocationSearchViewController: UITableViewController {
    var items = [String]()
    var scopeRetainer: ShippingRestriction! = .cities
    var regionRadius: CLLocationDistance!
    var request: MKLocalSearch.Request!
    weak var handleMapSearchDelegate: HandleMapSearch? = nil
    var location: CLLocationCoordinate2D! {
        didSet {
            if request != nil {
                request.region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            }
        }
    }
    var alert: Alerts!
    var searchController: UISearchController!
    
    init(regionRadius: CLLocationDistance) {
        super.init(nibName: nil, bundle: nil)
        self.regionRadius = regionRadius
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .onDrag
        
        alert = Alerts()
    }
}

extension FilteredLocationSearchViewController: UISearchResultsUpdating, ParseAddressDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        self.searchController = searchController

        scopedSearch(
            searchBar: searchController.searchBar,
            searchController: searchController,
            location: location,
            scope: scopeRetainer
        )
    }
    
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
            self?.items.removeAll()
            var itemSet = Set<String>()
            response.mapItems.forEach { (item) in
                guard let self = self else { return }
                let i = self.parseAddress(selectedItem: item.placemark, scope: scope)
                itemSet.insert(i)
            }
            //            let parsed = response.mapItems.map { self!.parseAddress(selectedItem: $0.placemark, scope: scope) }
            self?.items.append(contentsOf: itemSet)
            self?.tableView.reloadData()
        }
    }
}

extension FilteredLocationSearchViewController: UISearchBarDelegate {
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
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let selectedItem = items[indexPath.row]
        cell.textLabel?.text = selectedItem
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = items[indexPath.row]
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
