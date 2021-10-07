//
//  PostViewController.swift + Resale
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-06.
//

import UIKit
import Combine
import web3swift

extension PostViewController {
    override func processResale(
        price: String?,
        itemTitle: String,
        desc: String,
        category: String,
        convertedId: String,
        tokensArr: Set<String>,
        userId: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String
    ) {
        guard let price = price, !price.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the price.", for: self)
            return
        }
        
        //        guard let convertedPrice = Double(price), convertedPrice > 0.01 else {
        //            self.alert.showDetail("Price Limist", with: "The price has to be greater than 0.01 ETH.", for: self)
        //            return
        //        }
        
        guard let shippingAddress = self.addressLabel.text, !shippingAddress.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please select the shipping restrictions.", for: self)
            return
        }
        
        guard let NFTrackAddress = NFTrackAddress else {
            self.alert.showDetail("Sorry", with: "There was an error loading the minting contract address.", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                titleString: "",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                titleString: "Transaction Options",
                body: [AlertModalDictionary.gasLimit: "", AlertModalDictionary.gasPrice: "", AlertModalDictionary.nonce: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner {
            DispatchQueue.main.async {
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let self = self else { return }
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                            return
                        } // password guard
                        
                        self.dismiss(animated: true, completion: {
                            self.progressModal = ProgressModalViewController(postType: .tangible)
                            self.progressModal.titleString = "Posting In Progress"
                            self.present(self.progressModal, animated: true, completion: {
                                Future<WriteTransaction, PostingError> { promise in
                                    self.transactionService.prepareTransactionForNewContract(
                                        contractABI: purchaseABI2,
                                        bytecode: purchaseBytecode2,
                                        value: price,
                                        promise: promise
                                    )
                                }
                            }) // self.present(self.progressModal
                        }) // dismiss
                    } // mainVC.buttonAction
                } // alertVC.action
            } // DispatchQueue
        }// self.hideSpinner
    } // processResale
}

