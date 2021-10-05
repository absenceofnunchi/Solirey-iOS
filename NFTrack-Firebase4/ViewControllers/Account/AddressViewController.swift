//
//  AddressViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-26.
//

import UIKit
import CoreLocation
import MapKit

class AddressViewController: UIViewController, CLLocationManagerDelegate {
    var resultSearchController: UISearchController!
    var locationManager: CLLocationManager!
    let regionRadius: CLLocationDistance = 10000
    var fetchPlacemarkDelegate: HandleMapSearch? = nil
    var locationSearchVC: ParentLocationSearchViewController!
    var location: CLLocationCoordinate2D! {
        guard let location = locationManager.location?.coordinate else {
            checkLocationServices()
            return nil
        }
        
        return location
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureSearchVC()
    }
    
    func configureUI() {
        view.backgroundColor = .white
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }

    func configureSearchVC() {
        locationSearchVC = ParentLocationSearchViewController(regionRadius: regionRadius, location: location)
        
        resultSearchController = UISearchController(searchResultsController: locationSearchVC)
        resultSearchController.searchResultsUpdater = locationSearchVC
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.obscuresBackgroundDuringPresentation = true
        
        configureSearchBar(resultSearchController)
    }
    
    func configureSearchBar(_ resultSearchController: UISearchController?) {
        guard let searchBar = resultSearchController?.searchBar else { return }
        searchBar.sizeToFit()
        searchBar.tintColor = .black
        searchBar.searchBarStyle = .minimal
        //        navigationItem.titleView = searchBar
        navigationItem.searchController = resultSearchController
        
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.backgroundColor = .white
        searchTextField.textColor = .gray
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Search Here", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        
        definesPresentationContext = true
    }
    
    // subclassed to view controllers with a map view
    func centerMapOnLocation() {}
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if locationSearchVC != nil {
            locationSearchVC.location = manager.location?.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // When the authorization is given, the location should be updated.
        // The location should be set here so that the LocationVC shouldn't be prevented from being instantiated. But even before the authorization is given
        if locationSearchVC != nil {
            locationSearchVC.location = manager.location?.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location updated")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

extension AddressViewController {
    // MARK:- Location permission
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            checkLocationAuthorization()
        } else {
            showAlert()
        }
    }
    
    func showAlert() {
        let ac = UIAlertController(title: "Your location settings need to be turned on", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let bundleId = Bundle.main.bundleIdentifier,
               let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleId)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = ac.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(ac, animated: true)
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
            case .authorizedWhenInUse:
                centerMapOnLocation()
            case .denied:
                showAlert()
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                showAlert()
            case .authorizedAlways:
                break
            default:
                break
        }
    }
}
