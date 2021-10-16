//
//  PropertyLoader + Utilities.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-15.
//

import Foundation
import web3swift

protocol ContractMethodsEnum {}
protocol ContractPropertiesEnum {
    var value: (String, AnyObject?) { get }
    func toDisplay() -> String
}

// The generic enum is needed to cater to different types of properties available
// For example, AuctionMethods and AuctionProperties can be replaced by PurchaseMethods and PurchaseProperties
// The structs (and the enums within) are used to both display proper labels as well as fed into PropertyLoader to be fetched.
protocol PropertyLoadable {
    associatedtype ContractMethods: RawRepresentable where ContractMethods.RawValue: StringProtocol, ContractMethods: ContractMethodsEnum
    associatedtype ContractProperties: ContractPropertiesEnum
}

// MARK: - PurchaseMethods
enum PurchaseMethods: String, ContractMethodsEnum {
    case abort = "Abort"
    case confirmPurchase = "Buy"
    case confirmReceived = "Confirm Received"
    case transferOwnership = "Transfer Ownership"
    
    var methodName: String {
        switch self {
            case .abort:
                return "abort"
            case .confirmPurchase:
                return "confirmPurchase"
            case .confirmReceived:
                return "confirmReceived"
            case .transferOwnership:
                // this one actually doesn't exists
                // the transfer method is in the Open Zeppelin contract
                // not in the escrow contract
                return "transfer"
        }
    }
}

enum PurchaseProperties: ContractPropertiesEnum {
    case state
    var value: (String, AnyObject?) {
        return ("state", nil)
    }
    
    func toDisplay() -> String {
        return "Status"
    }
}

// MARK: - PurchaseStatus
enum PurchaseStatus {
    case created
    case locked
    case inactive
}

extension PurchaseStatus: RawRepresentable {
    typealias RawValue = String
    
    var rawValue: RawValue {
        switch self {
            case .created:
                return "Created"
            case .locked:
                return "Locked"
            case .inactive:
                return "Inactive"
        }
    }
    
    //    var rawValue: RawValue {
    //        switch self {
    //            case .created:
    //                return 0
    //            case .locked:
    //                return 1
    //            case .inactive:
    //                return 2
    //        }
    //    }
    
    init?(rawValue: String) {
        switch rawValue {
            case "created":
                self = .created
            case "locked":
                self = .locked
            case "inactive":
                self = .inactive
            default:
                return nil
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
            case 0:
                self = .created
            case 1:
                self = .locked
            case 2:
                self = .inactive
            default:
                return nil
        }
    }
}

// MARK: - PostStatus
/// determines whether to show the post or not
/// when the seller first posts: ready
/// when the seller aborts: ready
/// when the buyer buys: pending
/// when the seller transfers the token: transferred
/// when the transaction is complete: complete
enum PostStatus: String {
    case ready, pending, aborted, complete, resold, transferred
    
    var toDisplay: String! {
        switch self {
            case .pending:
                return "Purchased"
            case .transferred:
                return "Transferred"
            case .complete:
                return "Received"
            default:
                return "Ready"
        }
    }
}

struct PurchaseContract: PropertyLoadable {
    typealias ContractMethods = PurchaseMethods
    typealias ContractProperties = PurchaseProperties
}

// MARK: - Auction
enum AuctionMethods: String, ContractMethodsEnum {
    case bid
    case withdraw
    case auctionEnd
    case getTheHighestBid
    case transferToken
}

enum AuctionProperties: ContractPropertiesEnum {
    case startingBid
    case highestBid
    case highestBidder
    case auctionEndTime
    case ended
    case pendingReturns(EthereumAddress)
    case beneficiary
    
    // tuple because some properties like mapping requires a key such as pendingReturns
    var value: (String, AnyObject?) {
        switch self {
            case .startingBid:
                return ("startingBid", nil)
            case .highestBid:
                return ("highestBid", nil)
            case .highestBidder:
                return ("highestBidder", nil)
            case .auctionEndTime:
                return ("auctionEndTime", nil)
            case .ended:
                return ("ended", nil)
            case .pendingReturns(let parameter):
                return ("pendingReturns", parameter as AnyObject)
            case .beneficiary:
                return ("beneficiary", nil)
        }
    }
    
    func toDisplay() -> String {
        switch self {
            case .startingBid:
                return "Starting Bid"
            case .highestBid:
                return "Highest Bid"
            case .highestBidder:
                return "Highest Bidder"
            case .auctionEndTime:
                return "Auction End Time"
            case .ended:
                return "Auction Status"
            case .pendingReturns(_):
                return "Amount To Withdraw"
            case .beneficiary:
                return "Beneficiary"
        }
    }
    
    //        static func allCasesString() -> [String] {
    //            return AuctionProperties.allCases.map { $0.rawValue }
    //        }
}

struct AuctionContract: PropertyLoadable {
    typealias ContractMethods = AuctionMethods
    typealias ContractProperties = AuctionProperties
}

enum AuctionStatus: String {
    case ready, bid, ended, transferred
    
    var toDisplay: String! {
        switch self {
            case .bid:
                return "Bid"
            case .ended:
                return "Auction Ended"
            case .transferred:
                return "Transferred"
            default:
                return "ready"
        }
    }
}

// MARK: - Simple Payment Contract
enum SimplePaymentMethods: String, ContractMethodsEnum {
    case pay
    case withdraw
    case withdrawFee
    case abort
    
    // display name and the tag for the button in SimplePaymentDetailVC
    var methodName: (String, Int) {
        switch self {
            case .pay:
                return ("Buy Now", 0)
            case .withdraw:
                return ("Withdraw", 1)
            case .withdrawFee:
                return ("Withdraw Fee", 2)
            case .abort:
                return ("Abort", 3)
        }
    }
}

enum SimplePaymentProperties: ContractPropertiesEnum {
    case tokenAdded, paid, price
    // Tuple since the property could be mapping that requires a key
    var value: (String, AnyObject?) {
        switch self {
            case .tokenAdded:
                return ("tokenAdded", nil)
            case .paid:
                return ("paid", nil)
            case .price:
                return ("price", nil)
        }
    }
    
    func toDisplay() -> String {
        switch self {
            case .tokenAdded:
                return "Token Added"
            case .paid:
                return "Paid"
            case .price:
                return "Price"
        }
    }
}

struct SimplePaymentContract: PropertyLoadable {
    typealias ContractMethods = SimplePaymentMethods
    typealias ContractProperties = SimplePaymentProperties
}

// Ready: the item has been posted.
// Purchased: a buyer has purchased the item by transferring the fund into the smart contract.
// Transferred: transfer happens at the same time as Purchased because the token transfer is within the same method as Buy().
// Complete: the transaction is complete when the seller withdraws the fund in the smart contract.
enum SimplePaymentStatus: String {
    case ready, purchased, transferred, complete, aborted
    
    var toDisplay: String! {
        switch self {
            case .ready:
                return "Ready"
            case .purchased:
                return "Purchased"
            case .transferred:
                return "Transferred"
            case .complete:
                return "Completed"
            case .aborted:
                return "Aborted"
        }
    }
}

// MARK: - NFTrack Contract
enum NFTrackMethods: String, ContractMethodsEnum {
    case ownerOf
    case name
    case symbol
    case safeTransferFrom
}

enum NFTrackProperties: ContractPropertiesEnum {
    case address
    // Tuple since the property could be mapping that requires a key
    var value: (String, AnyObject?) {
        switch self {
            case .address:
                return ("address", nil)
        }
    }
    
    func toDisplay() -> String {
        switch self {
            case .address:
                return "Address"
        }
    }
}

struct NFTrackContract: PropertyLoadable {
    typealias ContractMethods = NFTrackMethods
    typealias ContractProperties = NFTrackProperties
}
