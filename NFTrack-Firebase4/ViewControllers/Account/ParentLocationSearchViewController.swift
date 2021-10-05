//
//  ParentLocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-19.
//

import UIKit
import MapKit

class ParentLocationSearchViewController: UITableViewController, ParseAddressDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    var request: MKLocalSearch.Request!
    var regionRadius: CLLocationDistance!
    var location: CLLocationCoordinate2D! {
        didSet {
            print("didSet location", location as Any)
            if request != nil, location != nil {
                request.region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            }
        }
    }
    var alert: Alerts!
    weak var handleMapSearchDelegate: HandleMapSearch? = nil
    
    init(regionRadius: CLLocationDistance, location: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        self.regionRadius = regionRadius
        self.location = location
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        alert = Alerts()
    }
    
    func updateSearchResults(for searchController: UISearchController) { }
}
