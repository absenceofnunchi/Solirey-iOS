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
        
        let biddingTime = numOfDays.intValue * 60 * 60 * 24
//        let biddingTime = 400

        mintParameters.biddingTime = biddingTime
        mintParameters.startingBid = startingBid
        
        self.hideSpinner {
            switch mintParameters.saleConfigValue {
                case .digitalNewSaleAuctionBeneficiaryIntegral:
                    self.transactionService.preLaunch(mintParameters: mintParameters, transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                        
                        guard let getIndividualAuctionEstimate = self?.getIntegralAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIndividualAuctionEstimate(transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        if let error = error {
                            self?.processFailure(error)
                        }
                        
                        print("txPackage outside", txPackage)
                        
                        if let estimates = estimates,
                           let txPackage = txPackage {
                            print("txPackage inside", txPackage)

                            self?.executeIntegralAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage
                            )
                        }
                    }
                    break
                case .digitalNewSaleAuctionBeneficiaryIndividual:
                    self.transactionService.preLaunch(mintParameters: mintParameters, transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                        
                        guard let getIndividualAuctionEstimate = self?.getIndividualAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIndividualAuctionEstimate(transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        print("txPackage", txPackage as Any)
                        
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
                default:
                    break
            }
        } // hideSpinner
    }
    
//    // MARK: - prelaunch
//    /// The purposes of prelaunch are two folds:
//    ///     1. Checking for the duplicate on firestore (eventually eliminate the checkExistingId method if prelaunch is universalized)
//    ///     2. Estimate the total gas fee in the format that the execution completion handler can understand with the transaction of any kind provided as a parameter
//    final func preLaunch(
//        mintParameters: MintParameters,
//        transactionToEstimate: @escaping () -> AnyPublisher<TxPackage, PostingError>,
//        completion: @escaping ((totalGasCost: String, balance: String, gasPriceInGwei: String)) -> Void
//    ) {
//        Deferred { [weak self] in
//            Future<Bool, PostingError> { promise in
//                self?.db.collection("post")
//                    .whereField("itemIdentifier", isEqualTo: mintParameters.convertedId)
//                    .whereField("status", isNotEqualTo: "complete")
//                    .getDocuments() { (querySnapshot, err) in
//                        if let err = err {
//                            print("error from the duplicate check", err)
//                            promise(.failure(PostingError.generalError(reason: "Unable to check for the Unique Identifier duplicates")))
//                            return
//                        }
//
//                        if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
//                            promise(.success(true))
//                        } else {
//                            promise(.failure(PostingError.generalError(reason: "The item already exists. Please resell it through the app instead of selling it as a new item.")))
//                        }
//                    }
//            }
//        }
//        .flatMap { (_) -> AnyPublisher<TxPackage, PostingError> in
//            return transactionToEstimate()
//        }
//        .flatMap({ [weak self] (txPackage) -> AnyPublisher<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> in
//            self?.txPackageArr.append(txPackage)
//            return Future<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> { promise in
//                self?.transactionService.estimateGas(
//                    gasEstimate: txPackage.gasEstimate,
//                    promise: promise
//                )
//            }
//            .eraseToAnyPublisher()
//        })
//        .sink { [weak self] (completion) in
//            switch completion {
//                case .finished:
//                    break
//                case .failure(let error):
//                    self?.processFailure(error)
//                    break
//            }
//        } receiveValue: { [weak self] (estimates) in
//            self?.hideSpinner()
//            completion(estimates)
//        }
//        .store(in: &self.storage)
//    }
}
