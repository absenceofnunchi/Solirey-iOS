//
//  ParentPostViewController + Mint.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-19.
//

import UIKit

extension ParentPostViewController {
    // MARK:- Mint
    @objc func mint() {
        self.showSpinner { [weak self] in
            guard let itemTitle = self?.titleTextField.text, !itemTitle.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please fill in the title field.", for: self)
                return
            }
            
            guard let desc = self?.descTextView.text, !desc.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please fill in the description field.", for: self)
                return
            }
            
            guard let deliveryMethod = self?.deliveryMethodLabel.text,
                  !deliveryMethod.isEmpty,
                  let deliveryMethodEnum = DeliveryMethod(rawValue: deliveryMethod) else {
                self?.alert.showDetail("Incomplete", with: "Please select the delivery method.", for: self)
                return
            }
            
            guard let saleFormat = self?.saleMethodLabel.text,
                  !saleFormat.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please select the sale method.", for: self)
                return
            }
            
            guard let paymentMethod = self?.paymentMethodLabel.text,
                  !paymentMethod.isEmpty,
                  let paymentMethodEnum = PaymentMethod(rawValue: paymentMethod) else {
                self?.alert.showDetail("Incomplete", with: "Please select the payment method.", for: self)
                return
            }
            
            guard let contractFormat = self?.smartContractFormatLabel.text,
                  !contractFormat.isEmpty,
                  let contractFormatEnum = ContractFormat(rawValue: contractFormat) else {
                self?.alert.showDetail("Incomplete", with: "Please select the smart contract format.", for: self)
                return
            }
            
            guard let category = self?.pickerLabel.text,
                  !category.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please choose the category.", for: self)
                return
            }
            
            guard let id = self?.idTextField.text,
                  !id.isEmpty else {
                self?.alert.showDetail("Incomplete", with: "Please select the digital asset.", for: self)
                return
            }
            
            // process id
            let whitespaceCharacterSet = CharacterSet.whitespaces
            let convertedId = id.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
            
            let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
            guard convertedId.rangeOfCharacter(from: characterset.inverted) == nil else {
                self?.alert.showDetail("Invalid Characters", with: "The unique identifier cannot contain any space or special characters.", for: self)
                return
            }
            
            guard let tagTextField = self?.tagTextField, tagTextField.tokens.count > 0 else {
                self?.alert.showDetail("Missing Tags", with: "Please add the tags using the plus sign.", for: self)
                return
            }
            
            guard tagTextField.tokens.count < 6 else {
                self?.alert.showDetail("Tag Limit", with: "You can add up to 5 tags.", for: self)
                return
            }
            
            // add both the tokens and the title to the tokens field
            var tokensArr = Set<String>()
            let strippedString = itemTitle.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
            let searchItems = strippedString.components(separatedBy: " ") as [String]
            searchItems.forEach { (item) in
                tokensArr.insert(item)
            }
            
            for token in tagTextField.tokens {
                if let retrievedToken = token.representedObject as? String {
                    tokensArr.insert(retrievedToken.lowercased())
                }
            }
            
            // Determine whether the current postType is tangible or digital
            //            guard let type = self?.post?.type,
            //                  let postType = PostType(rawValue: type) else {
            //                self?.alert.showDetail("Error", with: "Unable to determine between a new sale and a resale.", for: self)
            //                return
            //            }
            guard let postType = self?.postType else {
                self?.alert.showDetail("Error", with: "Unable to determine between a new sale and a resale.", for: self)
                return
            }
            
            guard let userId = self?.userId else {
                self?.alert.showDetail("Error", with: "Unable to retrieve your user ID. Please ensure that you're logged in.", for: self)
                return
            }
            
            // The four configuration are the pivotal elements in determining what contract to deploy.
            let saleConfig = SaleConfig.hybridMethod(
                postType: postType,
                saleType: (self?.post != nil) ? .resale : .newSale,
                delivery: deliveryMethodEnum,
                payment: paymentMethodEnum,
                contractFormat: contractFormatEnum
            )
            
            let mintParameters = MintParameters(
                price: self?.priceTextField.text,
                itemTitle: itemTitle,
                desc: desc,
                category: category,
                convertedId: convertedId,
                tokensArr: tokensArr,
                userId: userId,
                deliveryMethod: deliveryMethod,
                saleFormat: saleFormat,
                paymentMethod: paymentMethod,
                contractFormat: contractFormat,
                postType: postType.asString(),
                saleConfigValue: saleConfig.value
            )
            
            switch saleConfig.value {
                case .tangibleNewSaleInPersonEscrowIntegral:
                    break
                case .tangibleNewSaleInPersonEscrowIndividual:
                    self?.checkExistingId(id: convertedId) { (isDuplicate, err) in
                        if let _ = err {
                            self?.alert.showDetail("Error", with: "There was an error checking for the Unique Identifier duplicates.", for: self)
                            return
                        }
                        
                        if let isDuplicate = isDuplicate, isDuplicate == true {
                            self?.alert.showDetail("Duplicate", with: "The item has already been registered. Please transfer the ownership instead of re-posting it.", height: 350, for: self)
                        } else {
                            self?.processEscrow(mintParameters)
                        } // not duplicate
                    } // end of checkExistingId
                    break
                 case .tangibleNewSaleInPersonDirectPaymentIntegral:
                    break
                case .tangibleNewSaleInPersonDirectPaymentIndividual:
                    // The direct transfer option for in-person pickup doesn't require any contracts to be deployed
                    self?.processDirectSaleRevised(mintParameters, isAddressRequired: true, postType: .tangible)
                    break
                case .tangibleNewSaleShippingEscrowIntegral:
                    break
                case .tangibleNewSaleShippingEscrowIndividual:
                    self?.checkExistingId(id: convertedId) { (isDuplicate, err) in
                        if let _ = err {
                            self?.alert.showDetail("Error", with: "There was an error checking for the Unique Identifier duplicates.", for: self)
                            return
                        }
                        
                        if let isDuplicate = isDuplicate, isDuplicate == true {
                            self?.alert.showDetail("Duplicate", with: "The item has already been registered. Please transfer the ownership instead of re-posting it.", height: 350, for: self)
                        } else {
                            self?.processEscrow(mintParameters)
                        } // not duplicate
                    } // end of checkExistingId
                    break
                case .tangibleResaleInPersonEscrowIntegral:
                    break
                case .tangibleResaleInPersonEscrowIndividual:
                    self?.processEscrowResale(mintParameters)
                    break
                case .tangibleResaleInPersonDirectPaymentIntegral:
                    break
                case .tangibleResaleInPersonDirectPaymentIndividual:
                    self?.processDirectResaleRevised(mintParameters, isAddressRequired: true, postType: .tangible)
                    break
                case .tangibleResaleShippingEscrowIntegral:
                    break
                case .tangibleResaleShippingEscrowIndividual:
                    self?.processEscrowResale(mintParameters)
                    break
                case .digitalNewSaleOnlineDirectPaymentIntegral:
                    break
                case .digitalNewSaleOnlineDirectPaymentIndividual:
                    self?.processDirectSaleRevised(mintParameters, isAddressRequired: false, postType: .digital)
                    break
                case .digitalNewSaleAuctionBeneficiaryIntegral:
                    self?.processAuction(mintParameters)
                    break
                case .digitalNewSaleAuctionBeneficiaryIndividual:
                    self?.processAuction(mintParameters)
                    break
                case .digitalResaleOnlineDirectPaymentIntegral:
                    break
                case .digitalResaleOnlineDirectPaymentIndividual:
                    self?.processDirectResaleRevised(mintParameters, isAddressRequired: false, postType: .digital)
                    break
                case .digitalResaleAuctionBeneficiaryIntegral:
                    break
                case .digitalResaleAuctionBeneficiaryIndividual:
                    break
                default:
                    print("no sale config exists")
                    break
            }
        }
    }
        
//        func getSaleConfigValue() -> DeliveryAndPaymentMethod? {
//            guard let postTypeValue = PostType(rawValue: postType),
//                  let deliveryMethodValue = DeliveryMethod(rawValue: deliveryMethod),
//                  let paymentMethodValue = PaymentMethod(rawValue: paymentMethod),
//                  let contractFormatValue = ContractFormat(rawValue: contractFormat) else { return nil }
//
//            let saleConfig = SaleConfig.hybridMethod(
//                postType: postTypeValue,
//                saleType: (self.post != nil) ? .resale : .newSale,
//                delivery: deliveryMethodValue,
//                payment: paymentMethodValue,
//                contractFormat: contractFormatValue
//            )
//        }
//    }
    
    @objc dynamic func processEscrow(_ mintParameters: MintParameters) {}
    
    @objc dynamic func processEscrowResale(_ mintParameters: MintParameters) {}
    
    // SimplePayment contract payment method
    @objc dynamic func processDirectSale(_ mintParameters: MintParameters) {}
    
    @objc dynamic func processDirectResale(_ mintParameters: MintParameters) {}
     
    @objc dynamic func processAuction(_ mintParameters: MintParameters) {}
    
    @objc dynamic func configureProgress() {}
}

extension ParentPostViewController {
    @objc func mint1() {
        for i in 0...10 {
            FirebaseService.shared.db
                .collection("post")
                .document("\(i)")
                .updateData([
                    "sellerUserId": "vcHixrcSsLMpLiafMYrAmCvnlLU2",
                    "senderAddress": "\(i)",
                    "escrowHash": "\(i)",
                    "auctionHash": "\(i)",
                    "mintHash": "\(i)",
                    "date": Date(),
                    "title": "\(i)",
                    "description": "\(i)",
                    "price": "\(i)",
                    "category": Category.realEstate.asString(),
                    "status": AuctionStatus.ready.rawValue,
                    "tags": ["example"],
                    "itemIdentifier": "\(i)",
                    "isReviewed": false,
                    "type": "tangible",
                    "deliveryMethod": "Shipping",
                    "saleFormat": "Online Direct",
                    "files": ["https://firebasestorage.googleapis.com/v0/b/nftrack-69488.appspot.com/o/vcHixrcSsLMpLiafMYrAmCvnlLU2%2FE366991C-B770-4A68-9CC7-862B793455CB.jpeg?alt=media&token=bbe4a96a-c5ea-4a77-8291-4357a7fc6963"],
                    "IPFS": "NA",
                    "paymentMethod": "Escrow",
                    "bidderTokens": [],
                    "bidders": []
                ])
        }
    }
}


