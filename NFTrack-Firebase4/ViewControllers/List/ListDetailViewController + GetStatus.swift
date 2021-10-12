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

extension ListDetailViewController: ParseAddressDelegate {
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
                    promise(.failure(.generalError(reason: "Could not load the contract address")))
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
                    self?.alert.showDetail("Info Retrieval Error", with: msg, for: self)
                case .finished:
                    print("status info finished")
                default:
                    self?.alert.showDetail("Info Retrieval Error", with: "Unable to fetch the contract information.", for: self)
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
                                             
                // The status that corresponds to 0, 1, and 2 refers to the variable on the Remote Purchase smart contract Created, Locked, or Inactive
                // They indicate the purchase status or where the transaction is at in the process of purchasing the item.
                switch "\(status)" {
                    case "0":
                        if post.sellerUserId == userId {
                            // The post edit button should only be allowed up until a buyer purchases the item
                            // after which the ability of a seller to edit the post ceases
                            DispatchQueue.main.async {
                                if self?.navigationItem.rightBarButtonItems?.filter({ $0.tag == 11 }).count == 0 {
                                    self?.postEditButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self?.buttonPressed(_:)))
                                    self?.postEditButtonItem.tag = 11
                                    guard let postEditButtonItem = self?.postEditButtonItem else { return }
                                    self?.navigationItem.rightBarButtonItems?.append(postEditButtonItem)
                                }
                            }
                            self?.configureStatusButton(buttonTitle: PurchaseMethods.abort.rawValue, tag: 1)
                        } else {
                            switch post.type {
                                case "tangible":
                                    self?.configureTangibleAndReadyStatus(post)
                                case "digital":
                                    // requires a contract that automatically transfers the token as soon as the buyer purchases which bypasses the step of 1. the ownership transfer by the seller and 2. the confirmation of the receipt.
                                    self?.configureStatusButton(buttonTitle: PurchaseMethods.confirmPurchase.rawValue, tag: 2)
                                default:
                                    break
                            }
                        }
                        break
                    case "1":
                        print("post.buyerUserId", post.buyerUserId as Any)
                        print("userId", userId as Any)
                        
                        if post.transferHash != nil {
                            if post.sellerUserId == userId {
                                self?.configureStatusButton(buttonTitle: "Receipt Pending", tag: 9)
                            } else if post.buyerUserId == userId {
                                self?.configureStatusButton(buttonTitle: PurchaseMethods.confirmReceived.rawValue, tag: 3)
                            }
                        } else {
                            if post.sellerUserId == userId {
                                // show the shipping address of the buyer to the seller so that the item could be shipped
                                DispatchQueue.main.async {
                                    self?.showBuyerAddress = true
                                }
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
    
    private func configureTangibleAndReadyStatus(_ post: Post) {
        // The purchase button should only be available to the potential buyer that meets the shipping criteria.
        guard let shippingInfo = post.shippingInfo else { return }
        if post.shippingInfo?.scope != .none {
            
            let shippingAddressChecker = ShippingAddressChecker(shippingInfo: shippingInfo)
            shippingAddressChecker.checkAddress()
                .sink { (_) in
                } receiveValue: { [weak self](shippingEligibility) in
                    switch shippingEligibility {
                        case .eligible:
                            // the buyer's address is within the seller's shipping limitation
                            self?.configureStatusButton(buttonTitle: PurchaseMethods.confirmPurchase.rawValue, tag: 2)
                        case .notEligible:
                            // the buyer's address is outside the seller's shipping limitation
                            self?.configureStatusButton(buttonTitle: "Shipping Unavailbable", tag: 201)
                        case .requiresBuyersShippingInfo:
                            self?.configureStatusButton(buttonTitle: "Requires Shipping Info", tag: 200)
                        case .unableToProcessAddress:
                            self?.alert.showDetail("Error in Buyer's Address", with: "There was an error processing your shipping address.", for: self)
                            self?.configureStatusButton(buttonTitle: "Error", tag: 202)
                    }
                }
                .store(in: &storage)
        } else {
            // The seller hasn't specified the shipping address. This should never reach.
            self.configureStatusButton(buttonTitle: "Unspecified Shipping Information", tag: 50000)
        }
    }
}

//if self?.post.shippingInfo?.scope != .none {
//    guard let shippingInfo = self?.post.shippingInfo else { return }
//    guard let address = UserDefaults.standard.string(forKey: UserDefaultKeys.address), address != "", address != "NA" else {
//        // The buyer has not registered their shipping address, therefore cannot be compared to the seller's shipping info.
//        self?.configureStatusButton(buttonTitle: "Requires Shipping Info", tag: 200)
//        return
//    }
//
//    let longitude = UserDefaults.standard.double(forKey: UserDefaultKeys.longitude)
//    let latitude = UserDefaults.standard.double(forKey: UserDefaultKeys.latitude)
//
//    guard longitude != 0 || latitude != 0 else {
//        self?.alert.showDetail("No Shipping Address", with: "You have not set the shipping address.", for: self)
//        return
//    }
//
//    let location = CLLocation(latitude: latitude, longitude: longitude)
//    let geocoder = CLGeocoder()
//
//    // Convert the CLLocation to placemark, not String to placemark because the latter only gives you the coordinates, not the address divided into city, country, etc
//    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
//        if let _ = error {
//            self?.alert.showDetail("Error in Buyer's Address", with: "There was an error processing your shipping address.", for: self)
//        }
//
//        guard let placemark = placemarks?.first else { return }
//        let mk = MKPlacemark(placemark: placemark)
//        // parses the buyer's address according to the scope that the seller has specified.
//        if let buyersAddress = self?.parseAddress(selectedItem: mk , scope: shippingInfo.scope),
//           shippingInfo.addresses.contains(buyersAddress) {
//            // the buyer's address is within the seller's shipping limitation
//            self?.configureStatusButton(buttonTitle: PurchaseMethods.confirmPurchase.rawValue, tag: 2)
//        } else {
//            // the buyer's address is outside the seller's shipping limitation
//            self?.configureStatusButton(buttonTitle: "Shipping Unavailbable", tag: 201)
//        }
//    }
//} else {
//    // The seller hasn't specified the shipping address. This should never reach.
//    self?.configureStatusButton(buttonTitle: "Unspecified Shipping Information", tag: 50000)
//}
