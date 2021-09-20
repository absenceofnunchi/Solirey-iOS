//
//  ParentLocationSearchViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-19.
//

import UIKit
import MapKit

class ParentLocationSearchViewController<T>: UITableViewController, ParseAddressDelegate, UISearchResultsUpdating {
    var data = [T]()
    var request: MKLocalSearch.Request!
    var regionRadius: CLLocationDistance!
    var location: CLLocationCoordinate2D! {
        didSet {
            if request != nil, location != nil {
                request.region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            }
        }
    }
    var alert: Alerts!
    weak var handleMapSearchDelegate: HandleMapSearch? = nil
    
    init(regionRadius: CLLocationDistance) {
        super.init(nibName: nil, bundle: nil)
        self.regionRadius = regionRadius
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        alert = Alerts()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func updateSearchResults(for searchController: UISearchController) { }
}
