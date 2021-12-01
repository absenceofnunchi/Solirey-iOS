//
//  ParentPostViewController + Escrow.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-30.
//

import UIKit

extension ParentPostViewController {
    // MARK: - mint
    /// 1. check for existing ID
    /// 2. deploy the escrow contract
    /// 3. mint
    /// 4. upload to the firestore
    /// 5. get the token ID through the subscription to the google functions
    /// 6. update the firestore with the urls of the photos and the token information
    
    final func processEscrow(_ mintParameters: MintParameters) {
        guard let price = mintParameters.price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
//        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
//            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
//            return
//        }
        guard let convertedPrice = Double(price) else {
            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
            return
        }
        let deposit = convertedPrice * Double(2)
        let finalDeposit = NSDecimalNumber(value: deposit)
        
        //        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
        //            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
        //            return
        //        }
        
        switch mintParameters.saleConfigValue {
            case .tangibleNewSaleInPersonEscrowIndividual, .tangibleNewSaleShippingEscrowIndividual:
                escrowIndividual(mintParameters, price: finalDeposit.stringValue)
                break
            case .tangibleNewSaleInPersonEscrowIntegral, .tangibleNewSaleShippingEscrowIntegral:
                escrowIntegral(mintParameters, price: finalDeposit.stringValue)
                break
            case .tangibleResaleShippingEscrowIntegral,
                 .tangibleResaleInPersonEscrowIntegral:
                escrowIntegral(mintParameters, price: finalDeposit.stringValue, isResale: true)
            default:
                break
        }
    }
}
