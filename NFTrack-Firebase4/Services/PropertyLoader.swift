//
//  PropertyLoader.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-16.
//

/*
 Abstract:
 Fetches the values of the properties from a smart contract.
 Recursively fetches as some fetch requests can fail.
 Currently designed for the auction contract, but can swap out executeReadTransaction modularly for other contracts when needed.
 */

import Foundation
import Combine
import web3swift
import BigInt

class PropertyLoader {
    private let transactionService = TransactionService()
    private var propertiesToLoad: [AuctionContract.AuctionProperties]!
    private var transactionHash: String!
    var contractAddress: EthereumAddress!
    
    // 2 ways to use property loader
    // 1. when you're deploying a contract for the first time. You only need the deployment hash because the receipt will contain the address of the newly deployed contract.
    // 2. you already have a deployed contract and you want to load properties using new transaction hashes. You'll have to use the new transaction ID + the existing contract address
    // because the new receipt will not contain the contract address.
    init(
        propertiesToLoad: [AuctionContract.AuctionProperties],
        transactionHash: String,
        contractAddress: EthereumAddress? = nil
    ) {
        // this is a tuple since some properties like mapping requires a key
        self.propertiesToLoad = propertiesToLoad
        self.transactionHash = transactionHash
        self.contractAddress = contractAddress
    }
    
    func initiateLoadSequence() -> AnyPublisher<[SmartContractProperty], PostingError> {
        let propertyArrayPublisher = CurrentValueSubject<[AuctionContract.AuctionProperties], PostingError>(propertiesToLoad)
        return propertyArrayPublisher
            .flatMap { (properties) -> AnyPublisher<[SmartContractProperty], PostingError> in
                return self.loadInfoWithConfirmation(
                    propertiesToLoad: self.propertiesToLoad,
                    transactionHash: self.transactionHash,
                    existingDeploymentAddress: self.contractAddress
                )
            }
            .handleEvents(receiveOutput: { (response: [SmartContractProperty]) in
                let unretrievedProperties = response.compactMap { (model) -> AuctionContract.AuctionProperties? in
                    // if propertyDesc is empty, it means the property has not been fetched
                    if model.propertyDesc == nil {
                        return self.propertiesToLoad.first(where: { $0.value.0 == model.propertyName })
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
    }
    
    // 1. confirms whether the current block is more than the specified number of blocks away from the block in question. If not, repeat the query
    // 2. prepares the read transaction
    // 3. execute the read transaction
    // 4. return the fetched values
//    private func loadInfoWithConfirmation(
//        propertiesToLoad: [AuctionContract.AuctionProperties],
//        transactionHash: String
//    ) -> AnyPublisher<[SmartContractProperty], PostingError> {
//        transactionService.confirmEtherTransactionsNoDelay(txHash: transactionHash)
//        .flatMap { [weak self] (receipts) -> AnyPublisher<[SmartContractProperty], PostingError>  in
//            guard let receipt = receipts.first,
//                  let contractAddress = receipt.contractAddress else {
//                return Fail(error: PostingError.generalError(reason: "Could not obtain the auction contract."))
//                    .eraseToAnyPublisher()
//            }
//
//            self?.contractAddress = contractAddress
//            let listOfPrepPublishers = propertiesToLoad.map { (propertyToRead) in
//                return Future<SmartContractProperty, PostingError> { promise in
//                    let parameters: [AnyObject]? = (propertyToRead.value.1 != nil) ? [propertyToRead.value.1] as [AnyObject] : nil
//                    self?.transactionService.prepareTransactionForReading(
//                        method: propertyToRead.value.0,
//                        parameters: parameters,
//                        abi: auctionABI,
//                        contractAddress: contractAddress,
//                        promise: promise
//                    )
//                }
//            }
//            return Publishers.MergeMany(listOfPrepPublishers)
//                .collect()
//                .eraseToAnyPublisher()
//        }
//        .flatMap { [weak self] (propertyFetchModels) -> AnyPublisher<[SmartContractProperty], PostingError> in
//            let listOfReadPublishers = propertyFetchModels.map { (propertyFetchModel) in
//                return Future<SmartContractProperty, PostingError> { promise in
//                    var mutableModel = propertyFetchModel
//                    self?.executeReadTransaction(propertyFetchModel: &mutableModel, promise: promise)
//                }
//            }
//            return Publishers.MergeMany(listOfReadPublishers)
//                .collect()
//                .eraseToAnyPublisher()
//        }
//        .eraseToAnyPublisher()
//    }
    
    private func loadInfoWithConfirmation(
        propertiesToLoad: [AuctionContract.AuctionProperties],
        transactionHash: String,
        existingDeploymentAddress: EthereumAddress? = nil
    ) -> AnyPublisher<[SmartContractProperty], PostingError> {
        return transactionService.confirmEtherTransactionsNoDelay(txHash: transactionHash)
            .flatMap { [weak self] (receipts) -> AnyPublisher<[SmartContractProperty], PostingError>  in
                // if the existing contract address is provided, it means the transaction hash isn't a deployment hash and therefore, the receipt would not have contained the address of the deployed contract
                // simply assign the address to contractAddress and bypass the process of getting it from the receipt
                if existingDeploymentAddress != nil {
                    guard let existingDeploymentAddress = existingDeploymentAddress else {
                        return Fail(error: PostingError.generalError(reason: "Could not obtain the auction contract."))
                            .eraseToAnyPublisher()
                    }
                    
                    self?.contractAddress = existingDeploymentAddress
                } else {
                    // since the contract address has not been provided, it means that the transaction hash is a deployment hash which contains the address of the newly deployed contract.
                    guard let receipt = receipts.first,
                          let contractAddress = receipt.contractAddress else {
                        return Fail(error: PostingError.generalError(reason: "Could not obtain the auction contract."))
                            .eraseToAnyPublisher()
                    }
                    
                    self?.contractAddress = contractAddress
                }
                
                guard let address = self? .contractAddress else {
                    return Fail(error: PostingError.retrievingCurrentAddressError)
                        .eraseToAnyPublisher()
                }
                
                let listOfPrepPublishers = propertiesToLoad.map { (propertyToRead) in
                    return Future<SmartContractProperty, PostingError> { promise in
                        let parameters: [AnyObject]? = (propertyToRead.value.1 != nil) ? [propertyToRead.value.1] as [AnyObject] : nil
                        self?.transactionService.prepareTransactionForReading(
                            method: propertyToRead.value.0,
                            parameters: parameters,
                            abi: auctionABI,
                            contractAddress: address,
                            promise: promise
                        )
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
        
    private final func executeReadTransaction(
        propertyFetchModel: inout SmartContractProperty,
        promise: (Result<SmartContractProperty, PostingError>) -> Void
    ) {
        do {
            guard let transaction = propertyFetchModel.transaction else {
                promise(.failure(.generalError(reason: "Unable to create a transaction.")))
                return
            }
            
            let result: [String: Any] = try transaction.call()
            switch propertyFetchModel.propertyName {
                case AuctionContract.AuctionProperties.startingBid.value.0:
                    if let startingBid = result["0"] as? BigUInt,
                       let bidInEth = Web3.Utils.formatToEthereumUnits(startingBid, toUnits: .eth, decimals: 9) {
                        // remove the unnecessary zeros in the decimal
                        let trimmed = self.transactionService.stripZeros(bidInEth)
                        propertyFetchModel.propertyDesc = "\(trimmed) ETH"
                    }
                case AuctionContract.AuctionProperties.auctionEndTime.value.0:
                    if let auctionEndTime = result["0"] as? BigUInt {
                        let date = Date(timeIntervalSince1970: Double(auctionEndTime))
                        propertyFetchModel.propertyDesc = date
                    }
                case AuctionContract.AuctionProperties.highestBid.value.0:
                    if let highestBid = result["0"] as? BigUInt {
                        if let converted = Web3.Utils.formatToEthereumUnits(highestBid, toUnits: .eth, decimals: 9) {
                            let trimmed = transactionService.stripZeros(converted)
                            propertyFetchModel.propertyDesc = "\(trimmed) ETH"
                        }
                    }
                case AuctionContract.AuctionProperties.highestBidder.value.0:
                    if let propertyDesc = result["0"] as? EthereumAddress {
                        if propertyDesc.address == "0x0000000000000000000000000000000000000000" {
                            propertyFetchModel.propertyDesc = "No Bidder"
                        } else {
                            propertyFetchModel.propertyDesc = propertyDesc.address
                        }
                    }
                case AuctionContract.AuctionProperties.ended.value.0:
                    if let ended = result["0"] as? Bool {
                        propertyFetchModel.propertyDesc = ended
                    }
                case AuctionContract.AuctionProperties.pendingReturns(self.contractAddress).value.0:
                    if let pendingReturns = result["0"] as? BigUInt,
                       let converted = Web3.Utils.formatToEthereumUnits(pendingReturns, toUnits: .eth, decimals: 9) {
                        let trimmed = self.transactionService.stripZeros(converted.description)
                        propertyFetchModel.propertyDesc = trimmed
                    }
                case AuctionContract.AuctionProperties.beneficiary.value.0:
                    if let propertyDesc = result["0"] as? EthereumAddress {
                        if propertyDesc.address == "0x0000000000000000000000000000000000000000" {
                            propertyFetchModel.propertyDesc = "N/A"
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
