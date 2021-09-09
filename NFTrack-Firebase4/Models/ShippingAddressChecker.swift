//
//  ShippingAddressChecker.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-05.
//

import Foundation
import Combine
import MapKit

enum ShippingEligibility {
    case eligible
    case notEligible
    case requiresBuyersShippingInfo
    //    case requiresSellersShippingInfo
    case unableToProcessAddress
}

class ShippingAddressChecker: ParseAddressDelegate {
    var shippingInfo: ShippingInfo!
    
    init(shippingInfo: ShippingInfo) {
        self.shippingInfo = shippingInfo
    }
    
    func checkAddress() -> AnyPublisher<ShippingEligibility, PostingError> {
        Future<ShippingEligibility, PostingError> { promise in
            guard let address = UserDefaults.standard.string(forKey: UserDefaultKeys.address), address != "", address != "NA" else {
                // The buyer has not registered their shipping address, therefore cannot be compared to the seller's shipping info.
                return promise(.success(.requiresBuyersShippingInfo))
            }
            
            let longitude = UserDefaults.standard.double(forKey: UserDefaultKeys.longitude)
            let latitude = UserDefaults.standard.double(forKey: UserDefaultKeys.latitude)
            
            guard longitude != 0 || latitude != 0 else {
                return promise(.success(.requiresBuyersShippingInfo))
            }
            
            let buyerLocation = CLLocation(latitude: latitude, longitude: longitude)
            let geocoder = CLGeocoder()
            
            // Convert the CLLocation to placemark, not String to placemark because the latter only gives you the coordinates, not the address divided into city, country, etc
            geocoder.reverseGeocodeLocation(buyerLocation) { (placemarks, error) in
                if let _ = error {
                    promise(.success(.unableToProcessAddress))
                }
                                
                guard let placemark = placemarks?.first else { return }
                let mk = MKPlacemark(placemark: placemark)
                // parses the buyer's address according to the scope that the seller has specified.
                let buyersAddress = self.parseAddress(selectedItem: mk , scope: self.shippingInfo.scope)
                
                if self.shippingInfo.scope == .distance {
                    guard let sellerLongitude = self.shippingInfo.longitude,
                          let sellerLatitude = self.shippingInfo.latitude else { return }
                    
                    let sellerLocation = CLLocation(latitude: sellerLatitude, longitude: sellerLongitude)
                    let distanceInMeters: CLLocationDistance = sellerLocation.distance(from: buyerLocation)
                    
                    if distanceInMeters < self.shippingInfo.radius {
                        promise(.success(.eligible))
                    } else {
                        promise(.success(.notEligible))
                    }
                } else {
                    if self.shippingInfo.addresses.contains(buyersAddress) {
                        // the buyer's address is within the seller's shipping limitation
                        promise(.success(.eligible))
                    } else {
                        // the buyer's address is outside the seller's shipping limitation
                        promise(.success(.notEligible))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
