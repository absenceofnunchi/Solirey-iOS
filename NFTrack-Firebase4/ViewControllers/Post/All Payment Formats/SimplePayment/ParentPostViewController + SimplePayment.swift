//
//  ParentPostViewController + SimplePayment.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-16.
//

/*
 Abstract:
 Shows both the integral and the individual Simple Payment
 */

import UIKit
import Combine
import web3swift

extension ParentPostViewController {
    func processSimplePayment(_ mintParameters: MintParameters) {
//        guard let shippingInfo = mintParameters.shippingInfo, shippingInfo != nil else {
//            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
//            return
//        }
        
        guard let price = mintParameters.price,
              !price.isEmpty,
              let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth) else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        // change to this after testing
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        switch mintParameters.saleConfigValue {
            case .tangibleNewSaleInPersonDirectPaymentIntegral:
                self.transactionService.preLaunch (transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                    guard let processIntegralSimplePayment = self?.processIntegralSimplePayment else {
                        return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                            .eraseToAnyPublisher()
                    }
                    
                    let parameters: [AnyObject] = [priceInWei] as [AnyObject]
                    return processIntegralSimplePayment(.createPayment, parameters)
                    
                }) { [weak self] (estimates, txPackage, error) in
                    if let error = error {
                        self?.processFailure(error)
                    }
                    
                    if let estimates = estimates,
                       let txPackage = txPackage {
                        
                        self?.executeIntegralSimplePayment(
                            estimates: estimates,
                            mintParameters: mintParameters,
                            txPackage: txPackage
                        )
                    }
                }
                break
            case .tangibleResaleInPersonDirectPaymentIntegral:
                break
            default:
                break
        }
    }

}
