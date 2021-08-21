//
//  ListDetailViewController + GetStatus.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-16.
//

/*
 Abstract:
 Fetches the "status" property from the escrow smart contract using latest transaction hash and the contract address.
 Once the status is fetched, it's used to update two things:
 1. The status label which shows one of three states - Created, Locked, Inactive
 2. The state update button which will display and execute different methods depending on the stage of the sale and also on whether the user is a seller or a buyer.
 */

import UIKit
import Combine
import web3swift
import BigInt

extension ListDetailViewController {
    // MARK: - getStatus
    final func getStatus() {
        /*
         The order of occurance:
         
         1. escrow hash
         2. confirmPurchaseHash
         3. transferHash
         4. confirmReceivedHash
         
         The property loader should check the latest hash and verify whether the block has been added before fetching the status property,
         which means to check from the last to first, reverse chronologically.
         */
        self.isPending = true
        var latestHash: String!
        if let confirmReceivedHash = post.confirmReceivedHash {
            latestHash = confirmReceivedHash
        } else if let transferHash = post.transferHash {
            latestHash = transferHash
        } else if let confirmPurchaseHash = post.confirmPurchaseHash {
            latestHash = confirmPurchaseHash
        } else if let escrowHash = post.escrowHash {
            latestHash = escrowHash
        }
        
        guard let escrowHash = self.post.escrowHash else {
            self.alert.showDetail("Error", with: "Could not load the escrow hash", for: self)
            return
        }
        
        Future<TransactionReceipt, PostingError> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let receipt = try Web3swiftService.web3instance.eth.getTransactionReceipt(escrowHash)
                    promise(.success(receipt))
                } catch {
                    promise(.failure(.generalError(reason: "Could not load the contract adderss")))
                }
            }
        }
        .eraseToAnyPublisher()
        .flatMap({ [weak self] (receipt) -> AnyPublisher<[SmartContractProperty], PostingError> in
            guard let contractAddress = receipt.contractAddress,
                  let executeReadTransaction = self?.executeReadTransaction else {
                return Fail(error: PostingError.generalError(reason: "Unable to load the contract address."))
                    .eraseToAnyPublisher()
            }
            self?.contractAddress = contractAddress
            
            let purchaseStatusLoader = PropertyLoader<PurchaseContract>(
                propertiesToLoad: [PurchaseContract.ContractProperties.state],
                transactionHash: latestHash,
                executeReadTransaction: executeReadTransaction,
                contractAddress: contractAddress,
                contractABI: purchaseABI2
            )
            
            return purchaseStatusLoader.initiateLoadSequence()
        })
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(.retrievingCurrentAddressError):
                    self?.alert.showDetail("Contract Address Error", with: "Unable to retrieve the current address of your wallet", for: self)
                case .failure(.contractLoadingError):
                    self?.alert.showDetail("Contract Address Error", with: "Unable to load the current address of your wallet", for: self)
                case .failure(.createTransactionIssue):
                    self?.alert.showDetail("Transaction Error", with: "Unable to create the transaction.", for: self)
                case .failure(.generalError(reason: let msg)):
                    self?.alert.showDetail("Auction Info Retrieval Error", with: msg, for: self)
                case .finished:
                    print("status info finished")
                default:
                    self?.alert.showDetail("Auction Info Retrieval Error", with: "Unable to fetch the auction contract information.", for: self)
            }
        } receiveValue: { [weak self] (propertyFetchModels: [SmartContractProperty]) in
            self?.parseFetchResultToDisplay(propertyFetchModels)
            self?.isPending = false
            
            guard let contractAddress = self?.contractAddress else { return }
            self?.createSocket(contractAddress: contractAddress)
        }
        .store(in: &self.storage)
    }
    
    final func executeReadTransaction(
        propertyFetchModel: inout SmartContractProperty,
        promise: (Result<SmartContractProperty, PostingError>) -> Void
    ) {
        do {
            guard let transaction = propertyFetchModel.transaction else {
                promise(.failure(.generalError(reason: "Unable to create a read transaction.")))
                return
            }
            
            let result: [String: Any] = try transaction.call()
            if let status = result["0"] as? BigUInt {
                propertyFetchModel.propertyDesc = status
                promise(.success(propertyFetchModel))
            } else {
                promise(.failure(.generalError(reason: "Unable to fetch the purchase status.")))
            }
        } catch {
            promise(.failure(.generalError(reason: "Unable to create a read transaction.")))
        }
    }
    
    final func parseFetchResultToDisplay(_ propertyFetchModels: [SmartContractProperty]) {
        propertyFetchModels.forEach { [weak self] (model) in
            if model.propertyName == PurchaseContract.ContractProperties.state.value.0 {
                DispatchQueue.main.async {
                    self?.activityIndicatorView.stopAnimating()
                }
                
                guard let status = model.propertyDesc as? BigUInt else { return }
                
                if let purchaseStatus = PurchaseStatus(rawValue: Int(status)) {
                    DispatchQueue.main.async {
                        if self?.statusLabel != nil {
                            self?.statusLabel.text = purchaseStatus.rawValue
                        }
                    }
                }
                                
                switch "\(status)" {
                    case "0":
                        if post.sellerUserId == userId {
                            self?.configureStatusButton(buttonTitle: PurchaseMethods.abort.rawValue, tag: 1)
                        } else {
                            self?.configureStatusButton(buttonTitle: PurchaseMethods.confirmPurchase.rawValue, tag: 2)
                        }
                        break
                    case "1":
                        if post.transferHash != nil {
                            if post.sellerUserId == userId {
                                self?.configureStatusButton(buttonTitle: "Receipt Pending", tag: 9)
                            } else if post.buyerUserId == userId {
                                self?.configureStatusButton(buttonTitle: PurchaseMethods.confirmReceived.rawValue, tag: 3)
                            }
                        } else {
                            print("post.sellerUserId", post.sellerUserId as Any)
                            print("post.buyerUserId", post.buyerUserId as Any)
                            print("userId", userId as Any)
                            if post.sellerUserId == userId {
                                self?.configureStatusButton(buttonTitle: "Transfer Ownership", tag: 5)
                            } else if post.buyerUserId == userId {
                                self?.configureStatusButton(buttonTitle: "Transfer Pending", tag: 8)
                            }
                        }
                        break
                    case "2":
                        if post.sellerUserId == userId {
                            self?.configureStatusButton(buttonTitle: "Transfer Completed", tag: 10)
                        } else if post.buyerUserId == userId {
                            self?.configureStatusButton(buttonTitle: "Sell", tag: 4)
                        }
                        break
                    default:
                        self?.configureStatusButton(buttonTitle: "Error", tag: 50)
                }
            }
        }
    }
}
