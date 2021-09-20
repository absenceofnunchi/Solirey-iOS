//
//  LocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-27.
//


import UIKit
import MapKit

class LocationSearchViewController: ParentLocationSearchViewController<MKMapItem> {    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(AddressCell.self, forCellReuseIdentifier: AddressCell.reuseIdentifier)
        tableView.rowHeight = 70
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        guard let location = location else {
            self.alert.fading(text: "Please enable your location.", controller: self, toBePasted: nil, width: 250, location: .top)
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
            self?.data.removeAll()
            self?.data.append(contentsOf: response.mapItems)
            self?.tableView.reloadData()
        }
    }
}

// MARK: - Table view data source
extension LocationSearchViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseIdentifier, for: indexPath) as? AddressCell else {
            fatalError()
        }
        
        let selectedItem = data[indexPath.row].placemark
        cell.mainLabel.text = selectedItem.name
        cell.detailLabel.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = data[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem, addressString: nil, scope: nil)
        dismiss(animated: true, completion: nil)
    }
}
