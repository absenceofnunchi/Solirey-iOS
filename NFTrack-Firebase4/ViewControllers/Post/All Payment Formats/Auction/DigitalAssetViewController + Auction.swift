//
//  DigitalAssetViewController + Auction.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-05.
//

import UIKit
import Combine
import web3swift

extension DigitalAssetViewController {
    // MARK: - auction mint
    final override func processAuction(_ mintParameters: MintParameters) {
//    final func test100() {
//        let mintParameters = MintParameters(price: nil, itemTitle: "Test", desc: "Test", category: "Electronics", convertedId: "dsddfgg", tokensArr: [], userId: "343fdf", deliveryMethod: "online", saleFormat: "Auction", paymentMethod: "Auction", contractFormat: "Auction", postType: "Digital", saleConfigValue: .digitalNewSaleAuctionBeneficiaryIndividual)
        
        guard let auctionDuration = auctionDurationLabel.text,
              !auctionDuration.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the auction duration.", for: self)
            return
        }
        guard let auctionStartingPrice = auctionStartingPriceTextField.text,
              !auctionStartingPrice.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the starting price for your auction.", for: self)
            return
        }

        guard let index = auctionDuration.firstIndex(of: "d") else { return }

        let newIndex = auctionDuration.index(before: index)
        let newStr = auctionDuration[..<newIndex]

        guard let numOfDays = NumberFormatter().number(from: String(newStr)) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction duration into a proper format. Please try again.", for: self)
            return
        }

        guard let startingBidInWei = Web3.Utils.parseToBigUInt(auctionStartingPrice, units: .eth),
              let startingBid = NumberFormatter().number(from: startingBidInWei.description) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction starting price into a proper format. Pleas try again.", for: self)
            return
        }
        
//        let startingBid = 100 as NSNumber
        
//        let bidding`Time = numOfDays.intValue * 60 * 60 * 24
        let biddingTime = 150

        mintParameters.biddingTime = biddingTime
        mintParameters.startingBid = startingBid
        
        self.hideSpinner {
            switch mintParameters.saleConfigValue {
                case .digitalNewSaleAuctionBeneficiaryIntegral:
                    self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                        
                        guard let getIntegralAuctionEstimate = self?.getIntegralAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIntegralAuctionEstimate(.createAuction, transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        if let error = error {
                            self?.processFailure(error)
                        }
                                                
                        if let estimates = estimates,
                           let txPackage = txPackage {

                            self?.executeIntegralAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage
                            )
                        }
                    }
                    break
                case .digitalNewSaleAuctionBeneficiaryIndividual:
                    self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                        
                        guard let getIndividualAuctionEstimate = self?.getIndividualAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIndividualAuctionEstimate(transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        
                        if let error = error {
                            self?.processFailure(error)
                        }
                        
                        if let estimates = estimates,
                           let txPackage = txPackage {
                            self?.executeIndividualAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage
                            )
                        }
                    }
                    break
                case .digitalResaleAuctionBeneficiaryIntegral:
                    self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        guard let tokenId = self?.post?.tokenID else {
                            return Fail(error: PostingError.generalError(reason: "Unable to get the token ID."))
                                .eraseToAnyPublisher()
                        }
                        
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid, tokenId] as [AnyObject]
                        
                        guard let getIntegralAuctionEstimate = self?.getIntegralAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIntegralAuctionEstimate(.resell, transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        if let error = error {
                            self?.processFailure(error)
                        }
                        
                        if let estimates = estimates,
                           let txPackage = txPackage {
                            
                            self?.executeIntegralAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage
                            )
                        }
                    }
                    break
                default:
                    break
            }
        } // hideSpinner
    }   
}
