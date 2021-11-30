//
//  IntegralEscrowDetailViewController + GetStatus.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-28.
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

extension IntegralEscrowDetailViewController: ParseAddressDelegate {
    final func getStatus(
        transactionHash: String,
        executeReadTransaction: @escaping (_ propertyFetchModel: inout SmartContractProperty, _ promise: (Result<SmartContractProperty, PostingError>) -> Void) -> Void,
        contractAddress: EthereumAddress
    ) {
        let escrowInfoLoader = PropertyLoader<IntegralEscrowContract>(
            propertiesToLoad: [IntegralEscrowContract.ContractProperties._escrowInfo(self.solireyUid)],
            transactionHash: transactionHash,
            executeReadTransaction: executeReadTransaction,
            contractAddress: contractAddress,
            contractABI: integralEscrowABI
        )
        
        isPending = true
        escrowInfoLoader.initiateLoadSequence()
            .sink { [weak self] (completion) in
                self?.isPending = false
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
                        break
                    default:
                        self?.alert.showDetail("Auction Info Retrieval Error", with: "Unable to fetch the auction contract information.", for: self)
                }
            } receiveValue: { [weak self] (propertyFetchModels: [SmartContractProperty]) in
                self?.isPending = false
                
                DispatchQueue.main.async {
                    // if the count is different, then the arrangedSubview in the stack view of auctionSpecView will go out of bound
                    DispatchQueue.main.async {
                        self?.parseFetchResultToDisplay(propertyFetchModels)
                    }
                    
                    // socket to receive topics so that the auction specs could be re-updated
                    // whenever the current user or anybody else calls the method on the auction contract
                    // the socket will respond
                    // needs to be in the main thread, otherwise won't work
                    // only connect if the socket has timed out or disconnected
//                    self?.createSocket(topics: [Topics.IntegralAuction.bid, Topics.IntegralAuction.auctionEnd])
                }
                
                // receives the publisher events from AuctionButtonController
                // depending on the logic provided by AuctionButtonController,
                // the status will determine what the "big button" should display
//                guard let self = self else { return }
//                NotificationCenter.default.publisher(for: .auctionButtonDidUpdate)
//                    .compactMap { $0.object as? AuctionContract.ContractMethods }
//                    .sink { (status) in
//                        self.setButtonStatus(as: status)
//                    }
//                    .store(in: &self.storage)
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
            
            guard let buyer = result[IntegralEscrowProperties.EscrowInfo.buyer.rawValue] as? EthereumAddress,
                  let value = result[IntegralEscrowProperties.EscrowInfo.value.rawValue] as? BigUInt,
                  let seller = result[IntegralEscrowProperties.EscrowInfo.seller.rawValue] as? EthereumAddress,
                  let state = result[IntegralEscrowProperties.EscrowInfo.state.rawValue] as? BigUInt,
                  let tokenId = result[IntegralEscrowProperties.EscrowInfo.tokenId.rawValue] as? BigUInt else {
                promise(.failure(.generalError(reason: "Unable to create a read transaction.")))
                return
            }
            
            let escrowInfo = EscrowInfo(
                value: value.description,
                seller: seller.address,
                buyer: buyer.address,
                tokenId: tokenId.description,
                state: state.description
            )
                  
            propertyFetchModel.propertyDesc = escrowInfo

            promise(.success(propertyFetchModel))
        } catch {
            promise(.failure(.generalError(reason: "Unable to create a read transaction.")))
        }
    }
    
    final func parseFetchResultToDisplay(_ propertyFetchModels: [SmartContractProperty]) {
        propertyFetchModels.forEach { [weak self] (model) in
            guard let uid = self?.solireyUid,
                  model.propertyName == IntegralEscrowProperties._escrowInfo(uid).value.0,
                  let escrowInfo = model.propertyDesc as? EscrowInfo,
                  let state = escrowInfo.state,
                  let convertedInt = Int(state),
                  let purchaseStatue = PurchaseStatus(rawValue: convertedInt) else { return }
            
            DispatchQueue.main.async {
                self?.activityIndicatorView.stopAnimating()
                if self?.statusLabel != nil {
                    self?.statusLabel.text = purchaseStatue.rawValue
                }
            }
            
            // The status that corresponds to 0, 1, and 2 refers to the variable on the Remote Purchase smart contract Created, Locked, or Inactive
            // They indicate the purchase status or where the transaction is at in the process of purchasing the item.
            switch purchaseStatue {
                case .created:
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
                case .locked:
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
                case .inactive:
                    if post.sellerUserId == userId {
                        self?.configureStatusButton(buttonTitle: "Transfer Completed", tag: 10)
                    } else if post.buyerUserId == userId {
                        self?.configureStatusButton(buttonTitle: "Sell", tag: 4)
                    }
                    break
            }
        }
    }
    
    private func configureTangibleAndReadyStatus(_ post: Post) {
        self.configureStatusButton(buttonTitle: PurchaseMethods.confirmPurchase.rawValue, tag: 2)

        
        // The purchase button should only be available to the potential buyer that meets the shipping criteria.
//        guard let shippingInfo = post.shippingInfo else { return }
//        if post.shippingInfo?.scope != .none {
//
//            let shippingAddressChecker = ShippingAddressChecker(shippingInfo: shippingInfo)
//            shippingAddressChecker.checkAddress()
//                .sink { (_) in
//                } receiveValue: { [weak self](shippingEligibility) in
//                    switch shippingEligibility {
//                        case .eligible:
//                            // the buyer's address is within the seller's shipping limitation
//                            self?.configureStatusButton(buttonTitle: PurchaseMethods.confirmPurchase.rawValue, tag: 2)
//                        case .notEligible:
//                            // the buyer's address is outside the seller's shipping limitation
//                            self?.configureStatusButton(buttonTitle: "Shipping Unavailbable", tag: 201)
//                        case .requiresBuyersShippingInfo:
//                            self?.configureStatusButton(buttonTitle: "Requires Shipping Info", tag: 200)
//                        case .unableToProcessAddress:
//                            self?.alert.showDetail("Error in Buyer's Address", with: "There was an error processing your shipping address.", for: self)
//                            self?.configureStatusButton(buttonTitle: "Error", tag: 202)
//                    }
//                }
//                .store(in: &storage)
//        } else {
//            // The seller hasn't specified the shipping address. This should never reach.
//            self.configureStatusButton(buttonTitle: "Unspecified Shipping Information", tag: 50000)
//        }
    }
}
