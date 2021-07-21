//
//  PropertyLoader.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-16.
//

import Foundation
import Combine
import web3swift
import BigInt

class PropertyLoader {
    private let transactionService = TransactionService()
    private var propertiesToLoad: [String]!
    private var deploymentHash: String!
    var contractAddress: EthereumAddress!
    
    init(propertiesToLoad: [String], deploymentHash: String) {
        self.propertiesToLoad = propertiesToLoad
        self.deploymentHash = deploymentHash
    }
    
    private func loadInfo(propertiesToLoad: [String], deploymentHash: String) -> AnyPublisher<[SmartContractProperty], PostingError> {
        return Future<TransactionReceipt, PostingError> { promise in
            Web3swiftService.getReceipt(hash: deploymentHash, promise: promise)
        }
        .eraseToAnyPublisher()
        .flatMap { [weak self] (receipt) -> AnyPublisher<[SmartContractProperty], PostingError>  in
            guard let contractAddress = receipt.contractAddress else {
                return Fail(error: PostingError.generalError(reason: "Could not obtain the auction contract."))
                    .eraseToAnyPublisher()
            }
            
            self?.contractAddress = contractAddress
            let listOfPrepPublishers = propertiesToLoad.map { (propertyToRead) in
                return Future<SmartContractProperty, PostingError> { promise in
                    self?.transactionService.prepareTransactionForReading(method: propertyToRead, abi: auctionABI, contractAddress: contractAddress, promise: promise)
                }
            }
            return Publishers.MergeMany(listOfPrepPublishers)
                .collect()
                .eraseToAnyPublisher()
        }
        .flatMap { [weak self] (propertyFetchModels) -> AnyPublisher<[SmartContractProperty], PostingError> in
            let listOfReadPublishers = propertyFetchModels.map { (propertyFetchModel) in
                return Future<SmartContractProperty, PostingError> { promise in
                    var mutableModel = propertyFetchModel
                    self?.executeReadTransaction(propertyFetchModel: &mutableModel, promise: promise)
                }
            }
            return Publishers.MergeMany(listOfReadPublishers)
                .collect()
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func initiateLoadSequence() -> AnyPublisher<[SmartContractProperty], PostingError> {
        if #available(iOS 14.0, *) {
            let propertyArrayPublisher = CurrentValueSubject<[String], Never>(propertiesToLoad)
            return propertyArrayPublisher
                .flatMap { (properties) -> AnyPublisher<[SmartContractProperty], PostingError> in
                    //                    guard let propertiesToLoad = self?.propertiesToLoad,
                    //                          let deploymentHash = self?.deploymentHash else {
                    //                        return Fail(error: PostingError.generalError(reason: "Could not fetch properties."))
                    //                            .eraseToAnyPublisher()
                    //                    }
                    return self.loadInfo(propertiesToLoad: self.propertiesToLoad, deploymentHash: self.deploymentHash)
                }
                .handleEvents(receiveOutput: { (response: [SmartContractProperty]) in
                    let unretrievedProperties = response.compactMap { (model) -> String? in
                        if model.propertyDesc == nil {
                            return model.propertyName
                        } else {
                            return nil
                        }
                    }
                    
                    if unretrievedProperties.count == 0 {
                        propertyArrayPublisher.send(completion: .finished)
                    } else {
                        propertyArrayPublisher.send(unretrievedProperties)
                    }
                })
                .reduce([SmartContractProperty](), { allModels, response in
                    return allModels + response
                })
                .eraseToAnyPublisher()
        } else {
            // Fallback on earlier versions
            return self.loadInfo(propertiesToLoad: self.propertiesToLoad, deploymentHash: self.deploymentHash)
                .tryMap ({ [weak self] (propertyFetchModels) -> [SmartContractProperty] in
                    print("self?.propertiesToLoad.count", self?.propertiesToLoad.count as Any)
                    print("propertyFetchModels.count", propertyFetchModels.count)
                    // the stackview in the spec view will go out of bound if the count is different
                    // the downside is that even though the fetch will grab some property values, if they're not all of them, none will show
                    if propertyFetchModels.count != self?.propertiesToLoad.count {
                        throw PostingError.generalError(reason: "Couldn't fetch the auction properties.")
                    } else {
                        return propertyFetchModels
                    }
                })
                .retryWithDelay(retries: 5, delay: 1, scheduler: DispatchQueue.global())
                .mapError { $0 as? PostingError ?? PostingError.generalError(reason: "Property fetching error.")}
                .eraseToAnyPublisher()
        }
    }
    
    private final func executeReadTransaction(propertyFetchModel: inout SmartContractProperty, promise: (Result<SmartContractProperty, PostingError>) -> Void) {
        do {
            guard let transaction = propertyFetchModel.transaction else {
                promise(.failure(.generalError(reason: "Unable to create a transaction.")))
                return
            }
            
            let result: [String: Any] = try transaction.call()
            switch AuctionProperties(rawValue: propertyFetchModel.propertyName) {
                case .startingBid:
                    if let startingBid = result["0"] as? BigUInt,
                       var bidInEth = Web3.Utils.formatToEthereumUnits(startingBid, toUnits: .eth, decimals: 8) {
                        
                        // remove the unnecessary zeros in the decimal
                        var index = bidInEth.index(before: bidInEth.endIndex)
                        while bidInEth[index] == "0" {
                            bidInEth.removeLast()
                            index = bidInEth.index(before: bidInEth.endIndex)
                        }
                        
                        propertyFetchModel.propertyDesc = "\(bidInEth.description) ETH"
                    }
                case .auctionEndTime:
                    if let auctionEndTime = result["0"] as? BigUInt {
//                        propertyFetchModel.propertyDesc = auctionEndTime.description
                        let date = Date(timeIntervalSince1970: Double(auctionEndTime))
                        propertyFetchModel.propertyDesc = date
//                        let formatter = DateFormatter()
//                        formatter.timeStyle = .short
//                        formatter.dateStyle = .short
//                        formatter.timeZone = .current
//                        let formattedDate = formatter.string(from: date)
//                        propertyFetchModel.propertyDesc = formattedDate
                    }
                case .highestBid:
                    if let startingBid = result["0"] as? BigUInt,
                       let bidInEth = Web3.Utils.parseToBigUInt(startingBid.description, units: .eth) {
                        propertyFetchModel.propertyDesc = "\(bidInEth.description) ETH"
                    }
                case .highestBidder:
                    if let propertyDesc = result["0"] as? EthereumAddress {
                        if propertyDesc.address == "0x0000000000000000000000000000000000000000" {
                            propertyFetchModel.propertyDesc = "No Bidder"
                        } else {
                            propertyFetchModel.propertyDesc = propertyDesc.address
                        }
                    }
                default:
                    break
            }
            
            promise(.success(propertyFetchModel))
        } catch {
            promise(.failure(.generalError(reason: "Could not read the properties from the blockchain.")))
        }
    }
}
