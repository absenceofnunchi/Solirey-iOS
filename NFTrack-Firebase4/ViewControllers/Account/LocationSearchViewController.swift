//
//  LocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-27.
//


import UIKit
import MapKit

class LocationSearchViewController: UITableViewController {
    var matchingItems = [MKMapItem]()
    var handleMapSearchDelegate: HandleMapSearch? = nil
    var request: MKLocalSearch.Request!
    var regionRadius: CLLocationDistance!
    var location: CLLocationCoordinate2D! {
        didSet {
            if request != nil {
                request.region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            }
        }
    }
    var alert: Alerts!
    
    init(regionRadius: CLLocationDistance) {
        super.init(nibName: nil, bundle: nil)
        self.regionRadius = regionRadius
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(AddressCell.self, forCellReuseIdentifier: AddressCell.reuseIdentifier)
        tableView.rowHeight = 70
        tableView.keyboardDismissMode = .onDrag
        
        alert = Alerts()
    }
}

// MARK:- Location search results
extension LocationSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        guard let location = location else {
            self.alert.fading(text: "Please enable your location.", controller: self, toBePasted: nil, width: 250, location: .top) {
//                self.delay(0.5) {
//                    searchController.searchBar.searchTextField.resignFirstResponder()
//                }
            }
            return
        }
        
//        let searchCompleter = MKLocalSearchCompleter()
//        searchCompleter.delegate = self
//        searchCompleter.region = MKCoordinateRegion(.world)
//        searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.address])
//        searchCompleter.queryFragment = searchBarText

        request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        request.pointOfInterestFilter = .excludingAll
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            guard let response = response else { return }
            self?.matchingItems.removeAll()
            self?.matchingItems.append(contentsOf: response.mapItems)
            self?.tableView.reloadData()
        }
    }
}

// MARK: - Table view data source
extension LocationSearchViewController: ParseAddressDelegate {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseIdentifier, for: indexPath) as? AddressCell else {
            fatalError()
        }
        
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.mainLabel.text = selectedItem.name
        cell.detailLabel.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem, addressString: nil, scope: nil)
        dismiss(animated: true, completion: nil)
    }
}
