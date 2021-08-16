//
//  ListDetailTest.swift
//  NFTrack-Firebase4Tests
//
//  Created by J C on 2021-08-15.
//

import XCTest
import BigInt

@testable import NFTrack_Firebase4

class ListDetailTest: XCTestCase {
    var propertyFetchModelsTest = [SmartContractProperty]()
    var buttonTitle: String!
    var buttonTag: Int!
    let currentUserId = "CurrentUser"
    lazy var userId: String = currentUserId
    var sellerUserId: String!
    var buyerUserId: String!
    var transferHash: String!
    var statusLabelString: String!
    var result: (String, Int)!
    
    // when the post is first created
    // status: created
    // 1. you're the seller
    // 2. you're the potential buyer who hasn't bought the item yet
    func test_button_and_status_created() {
        propertyFetchModelsTest.append(
            SmartContractProperty(
                propertyName: PurchaseContract.ContractProperties.state.value.0,
                propertyDesc: 0 as BigUInt
            )
        )
        
        propertyFetchModelsTest.forEach { (model) in
            if model.propertyName == PurchaseContract.ContractProperties.state.value.0 {
                guard let status = model.propertyDesc as? BigUInt else { return }

                if let purchaseStatus = PurchaseStatus(rawValue: Int(status)) {
                    statusLabelString = purchaseStatus.rawValue
                    XCTAssertEqual(statusLabelString, PurchaseStatus.created.rawValue)
                }
                
                result = parseStatus(status)
                XCTAssertEqual(result.0, PurchaseMethods.confirmPurchase.rawValue)
                XCTAssertEqual(result.1, 2)
                
                sellerUserId = currentUserId
                result = parseStatus(status)
                XCTAssertEqual(result.0, PurchaseMethods.abort.rawValue)
                XCTAssertEqual(result.1, 1)
            }
        }
    }
    
    // when the item has been purchased
    // status: Locked
    // - Before the item has been transferred
    // 1. when you're the seller
    // 2. when you're the buyer
    // - After the item has been transferred
    // 1. when you're the seller
    // 2. when you're the buyer
    func test_button_and_status_locked() {
        propertyFetchModelsTest.append(
            SmartContractProperty(
                propertyName: PurchaseContract.ContractProperties.state.value.0,
                propertyDesc: 1 as BigUInt
            )
        )
        
        propertyFetchModelsTest.forEach { (model) in
            if model.propertyName == PurchaseContract.ContractProperties.state.value.0 {
                guard let status = model.propertyDesc as? BigUInt else { return }

                if let purchaseStatus = PurchaseStatus(rawValue: Int(status)) {
                    statusLabelString = purchaseStatus.rawValue
                    XCTAssertEqual(statusLabelString, PurchaseStatus.locked.rawValue)
                }
                
                // before the transfer
                // buyer
                sellerUserId = nil
                buyerUserId = currentUserId
                result = parseStatus(status)
                XCTAssertEqual(result.0, "Transfer Pending")
                XCTAssertEqual(result.1, 8)
                
                // seller
                sellerUserId = currentUserId
                buyerUserId = nil
                result = parseStatus(status)
                XCTAssertEqual(result.0, "Transfer Ownership")
                XCTAssertEqual(result.1, 5)
                
                // after the transfer
                // seller
                transferHash = "transferHash"
                result = parseStatus(status)
                XCTAssertEqual(result.0, "Receipt Pending")
                XCTAssertEqual(result.1, 50)
                
                // buyer
                buyerUserId = currentUserId
                sellerUserId = nil

                result = parseStatus(status)
                XCTAssertEqual(result.0, PurchaseMethods.confirmReceived.rawValue)
                XCTAssertEqual(result.1, 3)
            }
        }
    }
    
    // when the item has been purchased
    // status: Inactive
    // 1. when you're the seller
    // 2. when you're the buyer
    func test_button_and_status_inactive() {
        propertyFetchModelsTest.append(
            SmartContractProperty(
                propertyName: PurchaseContract.ContractProperties.state.value.0,
                propertyDesc: 2 as BigUInt
            )
        )
        
        propertyFetchModelsTest.forEach { (model) in
            if model.propertyName == PurchaseContract.ContractProperties.state.value.0 {
                guard let status = model.propertyDesc as? BigUInt else { return }
                
                if let purchaseStatus = PurchaseStatus(rawValue: Int(status)) {
                    statusLabelString = purchaseStatus.rawValue
                    XCTAssertEqual(statusLabelString, PurchaseStatus.inactive.rawValue)
                }
                                
                sellerUserId = nil
                buyerUserId = currentUserId
                result = parseStatus(status)
                XCTAssertEqual(result.0, "Sell")
                XCTAssertEqual(result.1, 4)
                
                sellerUserId = currentUserId
                buyerUserId = nil
                result = parseStatus(status)
                XCTAssertEqual(result.0, "Transfer Completed")
                XCTAssertEqual(result.1, 50)
            }
        }
    }
    
    func parseStatus(_ status: BigUInt) -> (String, Int) {
        switch "\(status)" {
            case "0":
                if sellerUserId == userId {
                    buttonTitle = PurchaseMethods.abort.rawValue
                    buttonTag = 1
                } else {
                    buttonTitle = PurchaseMethods.confirmPurchase.rawValue
                    buttonTag = 2
                }
                break
            case "1":
                if transferHash != nil {
                    if sellerUserId == userId {
                        buttonTitle = "Receipt Pending"
                        buttonTag = 50
                    } else if buyerUserId == userId {
                        buttonTitle = PurchaseMethods.confirmReceived.rawValue
                        buttonTag = 3
                    }
                } else {
                    if sellerUserId == userId {
                        buttonTitle = "Transfer Ownership"
                        buttonTag = 5
                    } else if buyerUserId == userId {
                        buttonTitle = "Transfer Pending"
                        buttonTag = 8
                    }
                }
                break
            case "2":
                if sellerUserId == userId {
                    buttonTitle = "Transfer Completed"
                    buttonTag = 50
                } else if buyerUserId == userId {
                    buttonTitle = "Sell"
                    buttonTag = 4
                }
                break
            default:
                break
        }
        
        return (buttonTitle, buttonTag)
    }
}
