//
//  AuctionButtonController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-04.
//

/*
 Abstract:
 Gathers the inputs from parseFetchResultToDisplay() in AuctionDetailViewController to know whether the auction has been ended/ officially ended, etc
 Outputs what the auction button should show, whether it's bid, transfer bid, retrieve the final bid, or end auction.
 
 Following are the ways that the auction status can be changed:
 1. The time has expired. The isAuctionEnded will be set to true.
    A. This can be done by parsing after the property loader when it first fetches the properties and the current date is greater than the auction end time. It's done in "parseFetchResultToDisplay" to be specific
    B. It can also be done by the timer if the user is on the screen at the time when the auction end time expires.
 2. The auctionEnd method is called. The isAuctionOfficiallyEnded will be set to true.
    A. This can be done at the time someone pressed the End Auction Button. The auctionEnd method emits an event, which means the socket will pick up the topics, triggering the properly loader to re-fetch the properties. When the properties are being parsed "parseFetchResultToDisplay" will also set isAuctionOfficiallyEnded to true/false.
    B. If the auction has been officially ended already, the parsing by "parseFetchResultToDisplay" would set isAuctionOfficiallyEnded to true upon "viewDidLoad".
 */

import Foundation
import Combine
import web3swift

class AuctionButtonController {
    private var currentAddress: EthereumAddress!
    final var isAuctionEnded: Bool! = false {
        didSet{
            configure()
        }
    }
    
    final var isAuctionOfficiallyEnded: Bool! = false {
        didSet {
            configure()
        }
    }
    
    final var auctionEndTime: Date! {
        didSet {
            configure()
        }
    }
    
    final var highestBidder: String! {
        didSet {
            configure()
        }
    }
    
    final var beneficiary: String! {
        didSet {
            configure()
        }
    }
    
    final var timer: Timer!
    final var status: AuctionContract.ContractMethods!
    
    init() {
        self.currentAddress = Web3swiftService.currentAddress
        self.status = .bid
    }
    
    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }
}

extension AuctionButtonController {
    func configure() {
        DispatchQueue.main.async { [weak self] in
            guard let isAuctionOfficiallyEnded = self?.isAuctionOfficiallyEnded,
                  let isAuctionEnded = self?.isAuctionEnded else { return }
            // the auction end time has expired && someone has ended it officially by pressing the end button
            if isAuctionOfficiallyEnded == true && isAuctionEnded == true {
                if self?.beneficiary == self?.currentAddress.address {
                    self?.status = .getTheHighestBid
                }
                
                if self?.highestBidder == self?.currentAddress.address {
                    self?.status = .transferToken
                }
            // the auction end time has expired, but no one has officially ended the auction by pressing the end button
            } else if isAuctionOfficiallyEnded == false && isAuctionEnded == true {
                guard let self = self else { return }
                self.status = .auctionEnd
            // the auction is still ongoing
            } else if isAuctionOfficiallyEnded == false && isAuctionEnded == false {
                self?.status = .bid
                guard var differenceInSeconds = self?.auctionEndTime.timeIntervalSince(Date()) else { return }
                self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (Timer) in
                    if differenceInSeconds > 0 {
                        //                         print ("\(differenceInSeconds) seconds")
                        differenceInSeconds -= 1
                    } else {
                        self?.isAuctionEnded = true
                        Timer.invalidate()
                        self?.status = .auctionEnd
                    }
                }
            }
            
            NotificationCenter.default.post(name: .auctionButtonDidUpdate, object: self?.status)
        }
    }
}
