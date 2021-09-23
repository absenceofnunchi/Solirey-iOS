//
//  ChatMapViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-19.
//
/*
 Abstract:
    1. Let's the sender of a chat pick a location and send it to the recipient of the chat.
    2. Let's the recipient of the location pinpoint the location on the map view with the annotation.
 */

import UIKit
import MapKit

class ChatMapViewController: MapViewController {
    private let IMAGE_VIEW_HEIGHT: CGFloat = 200
    private let REGION_DISTANCE: Double = 1000
    private lazy var IMAGE_VIEW_WIDTH: CGFloat = view.bounds.size.width * 0.7
    // This property is only utilized when pushed from ChatVC
    final var sharedLocation: ShippingAddress! {
        didSet {
            addAnnotation(sharedLocation)
            title = "Send Location"
        }
    }
    
    final override func didSelectPin(_ selectedPin: MKPlacemark) {
        alert.showDetail(
            "Location Share",
            with: "Would you like to share this location?",
            for: self,
            alertStyle: .withCancelButton,
            buttonAction: { [weak self] in
                self?.sendSnapShot(selectedPin)
            }
        )
    }
    
    final func sendSnapShot(_ selectedPin: MKPlacemark) {
        showSpinner { [weak self]  in
            self?.takeSnapShot(selectedPin: selectedPin) { (image, error) in
                if let error = error {
                    self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
                }
                
                if let image = image {
                    guard let parsedAddress = self?.parseAddress(selectedItem: selectedPin) else { return }
                    let address = ShippingAddress(address: parsedAddress, longitude: selectedPin.coordinate.longitude, latitude: selectedPin.coordinate.latitude)
                    self?.fetchPlacemarkDelegate?.getScreenshot(image: image, address: address)
                    self?.hideSpinner({
                        let _ = self?.navigationController?.popViewController(animated: true)
                    })
                }
            }
        }
    }
    
    final func takeSnapShot(selectedPin: MKPlacemark, _ completion: @escaping (UIImage?, Error?) -> Void) {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        // Set the region of the map that is rendered. (by one specified coordinate)
        let location = CLLocationCoordinate2D(latitude: selectedPin.coordinate.latitude, longitude: selectedPin.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, latitudinalMeters: REGION_DISTANCE, longitudinalMeters: REGION_DISTANCE)
        mapSnapshotOptions.region = region
        
        // Set the scale of the image. We'll just use the scale of the current device, which is 2x scale on Retina screens.
        mapSnapshotOptions.scale = UIScreen.main.scale
        
        // Set the size of the image output.
        mapSnapshotOptions.size = CGSize(width: IMAGE_VIEW_WIDTH, height: IMAGE_VIEW_HEIGHT)
        
        // Show buildings and Points of Interest on the snapshot
        mapSnapshotOptions.showsBuildings = true
//        mapSnapshotOptions.showsPointsOfInterest = true
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        
        snapShotter.start() { snapshot, error in
            if error != nil {
                completion(nil, error)
            }
            
            guard let snapshot = snapshot else {
                return
            }
            
            completion(snapshot.image, nil)
        }
    }
    
    final func addAnnotation(_ location: ShippingAddress) {
        guard let latitude = location.latitude,
              let longitude = location.longitude else { return }
                
        let clLocation = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(clLocation) { [weak self] (placemarks, error) in
            if let error = error {
                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
            }
            
            guard let pm = placemarks?.first else { return }
            let placemark = MKPlacemark(placemark: pm)
            self?.placemark = placemark
            self?.mapView.addAnnotation(placemark)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
            self?.mapView.setRegion(region, animated: true)
        }
    }
}
