//
//  AuctionButtonTest.swift
//  NFTrack-Firebase4Tests
//
//  Created by J C on 2021-08-04.
//

import XCTest
import Combine
@testable import NFTrack_Firebase4

class AuctionButtonTest: XCTestCase {
    var auctionButtonController: AuctionButtonController!
    var storage = Set<AnyCancellable>()
    override func setUp() {
        super.setUp()
        auctionButtonController = AuctionButtonController()
    }
    
    override func tearDown() {
        auctionButtonController = nil
        super.tearDown()
    }
    
    func test_auction_button_default() {
        auctionButtonController.isAuctionEnded = false
        auctionButtonController.isAuctionOfficiallyEnded = false
        NotificationCenter.default.publisher(for: .auctionButtonDidUpdate)
            .compactMap { $0.object as? AuctionContract.AuctionMethods }
            .sink { (status) in
                XCTAssertEqual(status, .bid)
            }
            .store(in: &self.storage)
    }
    
    func test_auction_button_auction_ended() {
        auctionButtonController.isAuctionEnded = true
        auctionButtonController.isAuctionOfficiallyEnded = false
        NotificationCenter.default.publisher(for: .auctionButtonDidUpdate)
            .compactMap { $0.object as? AuctionContract.AuctionMethods }
            .sink { (status) in
                XCTAssertEqual(status, .auctionEnd)
            }
            .store(in: &self.storage)
    }
    
    func test_auction_button_auction_officially_ended_beneficiary() {
        guard let currentAddress = Web3swiftService.currentAddress else { return }
        
        auctionButtonController.isAuctionEnded = true
        auctionButtonController.isAuctionOfficiallyEnded = true
        auctionButtonController.beneficiary = currentAddress.address
        
        NotificationCenter.default.publisher(for: .auctionButtonDidUpdate)
            .compactMap { $0.object as? AuctionContract.AuctionMethods }
            .sink { (status) in
                XCTAssertEqual(status, .getTheHighestBid)
            }
            .store(in: &self.storage)
    }
    
    func test_auction_button_auction_officially_ended_highest_bidder() {
        guard let currentAddress = Web3swiftService.currentAddress else { return }
        
        auctionButtonController.isAuctionEnded = true
        auctionButtonController.isAuctionOfficiallyEnded = true
        auctionButtonController.highestBidder = currentAddress.address
        
        NotificationCenter.default.publisher(for: .auctionButtonDidUpdate)
            .compactMap { $0.object as? AuctionContract.AuctionMethods }
            .sink { (status) in
                XCTAssertEqual(status, .transferToken)
            }
            .store(in: &self.storage)
    }
}
