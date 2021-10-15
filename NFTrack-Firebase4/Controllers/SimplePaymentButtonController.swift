//
//  SimplePaymentButtonController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-13.
//

import Foundation

class SimplePaymentButtonController {
    final var tokenAdded: Bool!
    private var paid: Bool!
    private var price: String!
    private var status: SimplePaymentContract.ContractMethods!
    private var post: Post!
    private var userId: String!
    
    init(
        post: Post,
        userId: String,
        tokenAdded: Bool,
        paid: Bool,
        price: String
    ) {
        self.post = post
        self.userId = userId
        self.tokenAdded = tokenAdded
        self.paid = paid
        self.price = price
    }
    
    final func configure() -> SimplePaymentContract.ContractMethods? {
        // Before any payment
        if paid == false {
            // The token has been properly transferred into the contract and the user is not the seller.
            if post.sellerUserId != userId {
                status = .pay
            } else if post.sellerUserId == userId {
                // Abort. The token has been added and the user is the seller, but the pay has not occured.
                status = .abort
            }
        } else {
            // After a payment
            if Web3swiftService.currentAddress == adminAddress {
                status = .withdrawFee
            } else if post.sellerUserId == userId {
                status = .withdraw
            } else if post.buyerUserId == userId {
                status = .none
            }
        }
        
        return status
    }
}
