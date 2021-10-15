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
 executeReadTransaction is a call back function which parses the result of the fetched properties.
 It's modularized because the parsing process is different depending on the properties you fetch.
 
 The class is generic because different struct that encapsulates both the methods and properties of a smart contract is used for different smart contracts.
 For example, AuctionMethods and AuctionProperties can be replaced by PurchaseMethods and PurchaseProperties
 The structs (and the enums within) are used to both display proper labels as well as fed into PropertyLoader to be fetched.
 */

import Foundation
import Combine
import web3swift
import BigInt

class PropertyLoader<T: PropertyLoadable> {
    private let transactionService = TransactionService()
    private var propertiesToLoad: [T.ContractProperties]!
    private var transactionHash: String!
    private var executeReadTransaction: (_ propertyFetchModel: inout SmartContractProperty, _ promise: (Result<SmartContractProperty, PostingError>) -> Void) -> Void
    var contractAddress: EthereumAddress!
    var contractABI: String!
    private var storage = Set<AnyCancellable>()
    
    // 2 ways to use the property loader
    // 1. when you're deploying a contract for the first time. You only need the deployment hash because the receipt will contain the address of the newly deployed contract.
    // 2. you already have a deployed contract and you want to load properties using new transaction hashes. You'll have to use the new transaction ID + the existing contract address
    // because the new receipt will not contain the contract address since it's not the has used in deploying the contract.
    init(
        propertiesToLoad: [T.ContractProperties],
        transactionHash: String,
        executeReadTransaction: @escaping (
            inout SmartContractProperty,
            (Result<SmartContractProperty, PostingError>) -> Void
        ) -> Void,
        contractAddress: EthereumAddress? = nil,
        contractABI: String
    ) {
        // this is a tuple since some properties like mapping requires a key
        self.propertiesToLoad = propertiesToLoad
        self.transactionHash = transactionHash
        self.executeReadTransaction = executeReadTransaction
        self.contractAddress = contractAddress
        self.contractABI = contractABI
    }
    
    func initiateLoadSequence() -> AnyPublisher<[SmartContractProperty], PostingError> {
        let propertyArrayPublisher = CurrentValueSubject<[T.ContractProperties], PostingError>(propertiesToLoad)
        return propertyArrayPublisher
            .flatMap { (properties) -> AnyPublisher<[SmartContractProperty], PostingError> in
                return self.loadInfoWithConfirmation(
                    propertiesToLoad: self.propertiesToLoad,
                    transactionHash: self.transactionHash,
                    existingDeploymentAddress: self.contractAddress
                )
            }
            .handleEvents(receiveOutput: { (response: [SmartContractProperty]) in
                let unretrievedProperties = response.compactMap { (model) -> T.ContractProperties? in
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
    
    // Attempt to subdivide the Combine sequence so that retries don't restart the sequence from the very beginning of the sequence, but only from its own subdivision
    func initiateLoadSequence1(completion: @escaping ([SmartContractProperty]?, PostingError?) -> Void) {
        self.transactionService.confirmReceipt(txHash: transactionHash)
            .sink { (completion) in
                print(completion)
            } receiveValue: { [weak self] (receipt) in
                print(receipt)
                // confirm that the block is added to the chain
                self?.transactionService.confirmTransactions(receipt)
                    .sink(receiveCompletion: { (completion) in
                        print(completion)
                    }, receiveValue: { (receipt) in
                        guard let propertiesToLoad = self?.propertiesToLoad else {
                            completion(nil, PostingError.generalError(reason: "Unable to fetch the properties from the smart contract."))
                            return
                        }
                        // Now that we know the transaction has been added to the blockchain for certain, fetch the properties from the smart contract
                        self?.fetchPropertiesFromSmartContract(
                            propertiesToLoad: propertiesToLoad,
                            receipt: receipt,
                            existingDeploymentAddress: self?.contractAddress
                        )
                        .sink { (completion) in
                            print(completion)
                        } receiveValue: { (properties) in
                            completion(properties, nil)
                        }
                        .store(in: &self!.storage)
                    })
                    .store(in: &self!.storage)
            }
            .store(in: &self.storage)
    }
    
    func fetchPropertiesFromSmartContract(
        propertiesToLoad: [T.ContractProperties],
        receipt: TransactionReceipt,
        existingDeploymentAddress: EthereumAddress? = nil
    ) -> AnyPublisher<[SmartContractProperty], PostingError> {
        // if the existing contract address is provided, it means the transaction hash isn't a deployment hash and therefore, the receipt would not have contained the address of the deployed contract
        // simply assign the address to contractAddress and bypass the process of getting it from the receipt
        if existingDeploymentAddress != nil {
            guard let existingDeploymentAddress = existingDeploymentAddress else {
                return Fail(error: PostingError.generalError(reason: "Could not obtain the auction contract."))
                    .eraseToAnyPublisher()
            }
            
            self.contractAddress = existingDeploymentAddress
        } else {
            // since the contract address has not been provided, it means that the transaction hash is a deployment hash which contains the address of the newly deployed contract.
            guard let contractAddress = receipt.contractAddress else {
                return Fail(error: PostingError.generalError(reason: "Could not obtain the auction contract."))
                    .eraseToAnyPublisher()
            }
            
            self.contractAddress = contractAddress
        }
        
        guard let address = self.contractAddress else {
            return Fail(error: PostingError.retrievingCurrentAddressError)
                .eraseToAnyPublisher()
        }
        
        let listOfPrepPublishers = propertiesToLoad.map { (propertyToRead) in
            return Future<SmartContractProperty, PostingError> { [weak self] promise in
                let parameters: [AnyObject]? = (propertyToRead.value.1 != nil) ? [propertyToRead.value.1] as [AnyObject] : nil
                
                guard let contractABI = self?.contractABI else {
                    promise(.failure(.generalError(reason: "Failed to fetch the contract ABI")))
                    return
                }
                
                self?.transactionService.prepareTransactionForReading(
                    method: propertyToRead.value.0,
                    parameters: parameters,
                    abi: contractABI,
                    contractAddress: address,
                    promise: promise
                )
            }
        }
        
        return Publishers.MergeMany(listOfPrepPublishers)
            .collect()
            .eraseToAnyPublisher()
            .flatMap { [weak self] (propertyFetchModels) -> AnyPublisher<[SmartContractProperty], PostingError> in
                let listOfReadPublishers = propertyFetchModels.map { (propertyFetchModel) in
                    return Future<SmartContractProperty, PostingError> { promise in
                        var mutableModel = propertyFetchModel
                        self?.executeReadTransaction(&mutableModel, promise)
                    }
                }
                return Publishers.MergeMany(listOfReadPublishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // 1. confirms whether the current block is more than the specified number of blocks away from the block in question. If not, repeat the query
    // 2. prepares the read transaction
    // 3. execute the read transaction
    // 4. return the fetched values
    private func loadInfoWithConfirmation(
        propertiesToLoad: [T.ContractProperties],
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
                    
                        guard let contractABI = self?.contractABI else {
                            promise(.failure(.generalError(reason: "Failed to fetch the contract ABI")))
                            return
                        }
                        
                        self?.transactionService.prepareTransactionForReading(
                            method: propertyToRead.value.0,
                            parameters: parameters,
                            abi: contractABI,
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
                        self?.executeReadTransaction(&mutableModel, promise)
                    }
                }
                return Publishers.MergeMany(listOfReadPublishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
