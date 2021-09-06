//
//  MapViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-29.
//

import UIKit
import MapKit

class MapViewController: AddressViewController, MKMapViewDelegate, SharableDelegate, HandleMapSearch {
    var mapView: MKMapView!
    var selectedPin: MKPlacemark? = nil
    var shareButtonItem: UIBarButtonItem!
    
    init() {
        super.init(nibName: nil, bundle: nil)
        mapView = MKMapView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
    }
    
    override func configureUI() {
        super.configureUI()
        title = "Shipping Address"
        hideKeyboardWhenTappedAround()
        
        configureMapView()
    }
    
    func configureNavigationBar() {
        shareButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(mapButtonPressed))
        shareButtonItem.tag = 2
        self.navigationItem.rightBarButtonItem = shareButtonItem
    }
    
    func configureMapView() {
        view.addSubview(mapView)
        mapView.fill()
        mapView.delegate = self
    }
    
    override func configureSearch() {
        super.configureSearch()
        
        // When the search result is tapped, the pin is dropped onto the map
        // MapVC designates itself as the delegate to do the pin dropping
        locationSearchVC.handleMapSearchDelegate = self
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //        guard let annotation = annotation as? MyAnnotation else { return nil }
        let identifier = "marker"
        var annotationView: MKMarkerAnnotationView
        if let deqeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            deqeuedView.annotation = annotation
            annotationView = deqeuedView
        } else {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.isEnabled = true
            annotationView.canShowCallout = true
            annotationView.calloutOffset = CGPoint(x: -5, y: 5)
            
            let mapButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
            mapButton.setBackgroundImage(UIImage(systemName: "checkmark.circle"), for: UIControl.State())
            mapButton.addTarget(self, action: #selector(mapButtonPressed), for: .touchUpInside)
            mapButton.tag = 1
            annotationView.rightCalloutAccessoryView = mapButton
        }
        
        return annotationView
    }
    
    @objc func mapButtonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 1:
                if let selectedPin = selectedPin {
                    fetchPlacemarkDelegate?.dropPinZoomIn(placemark: selectedPin, addressString: nil, scope: nil)
                    _ = navigationController?.popViewController(animated: true)
                }
                break
            case 2:
                guard let title = title else { return }
                share([title as AnyObject])
                break
            default:
                break
        }
    }
    
    override func centerMapOnLocation() {
        guard let location = location else { return }
        selectedPin = MKPlacemark(coordinate: location)
        let coorindateRegion = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coorindateRegion, animated: true)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func dropPinZoomIn(placemark: MKPlacemark, addressString: String?, scope: ShippingRestriction?) {
        // cache the pin
        selectedPin = placemark
        
        // clear the existing pins
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(placemark)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func resetSearchResults() {
    }
}
