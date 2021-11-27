//
//  DigitalAssetViewController + Auction.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-05.
//

import UIKit
import Combine
import web3swift

extension DigitalAssetViewController {
    // MARK: - auction mint
    final override func processAuction(_ mintParameters: MintParameters) {
//    final func test100() {
//        let mintParameters = MintParameters(price: nil, itemTitle: "Test", desc: "Test", category: "Electronics", convertedId: "dsddfgg", tokensArr: [], userId: "343fdf", deliveryMethod: "online", saleFormat: "Auction", paymentMethod: "Auction", contractFormat: "Auction", postType: "Digital", saleConfigValue: .digitalNewSaleAuctionBeneficiaryIndividual)
        
        guard let auctionDuration = auctionDurationLabel.text,
              !auctionDuration.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the auction duration.", for: self)
            return
        }
        guard let auctionStartingPrice = auctionStartingPriceTextField.text,
              !auctionStartingPrice.isEmpty else {
            self.alert.showDetail("Incomplete", with: "Please specify the starting price for your auction.", for: self)
            return
        }

        guard let index = auctionDuration.firstIndex(of: "d") else { return }

        let newIndex = auctionDuration.index(before: index)
        let newStr = auctionDuration[..<newIndex]

        guard let numOfDays = NumberFormatter().number(from: String(newStr)) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction duration into a proper format. Please try again.", for: self)
            return
        }

        guard let startingBidInWei = Web3.Utils.parseToBigUInt(auctionStartingPrice, units: .eth),
              let startingBid = NumberFormatter().number(from: startingBidInWei.description) else {
            self.alert.showDetail("Sorry", with: "Could not convert the auction starting price into a proper format. Pleas try again.", for: self)
            return
        }
        
//        let startingBid = 100 as NSNumber
        
//        let biddingTime = numOfDays.intValue * 60 * 60 * 24
        let biddingTime = 150

        mintParameters.biddingTime = biddingTime
        mintParameters.startingBid = startingBid
        
        self.hideSpinner {
            switch mintParameters.saleConfigValue {
                case .digitalNewSaleAuctionBeneficiaryIntegral:
                    self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                        
                        guard let getIntegralAuctionEstimate = self?.getIntegralAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIntegralAuctionEstimate(.createAuction, transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        if let error = error {
                            self?.processFailure(error)
                        }
                                                
                        if let estimates = estimates,
                           let txPackage = txPackage {

                            self?.executeIntegralAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage
                            )
                        }
                    }
                    break
                case .digitalNewSaleAuctionBeneficiaryIndividual:
                    guard let adminAddress = EthereumAddress("0x0b6fcFEc0133E77DcE6021Ff79BeFAd4b3af7564") else {
                        self.alert.showDetail("Error", with: "Unable to get the admin address.", for: self)
                        return
                    }
                    
                    self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid, adminAddress] as [AnyObject]
                        
                        guard let getIndividualAuctionEstimate = self?.getIndividualAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIndividualAuctionEstimate(transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        
                        if let error = error {
                            self?.processFailure(error)
                        }
                        
                        if let estimates = estimates,
                           let txPackage = txPackage {
                            self?.executeIndividualAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage,
                                completion: { (receipt, password, mintParameters) in
                                    self?.mintAndTransfer(txReceipt: receipt, password: password, mintParameters: mintParameters)
                                }
                            )
                        }
                    }
                    break
                case .digitalResaleAuctionBeneficiaryIntegral:
                    self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        guard let tokenId = self?.post?.tokenID else {
                            return Fail(error: PostingError.generalError(reason: "Unable to get the token ID."))
                                .eraseToAnyPublisher()
                        }
                        
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid, tokenId] as [AnyObject]
                        
                        guard let getIntegralAuctionEstimate = self?.getIntegralAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIntegralAuctionEstimate(.resell, transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        if let error = error {
                            self?.processFailure(error)
                        }
                        
                        if let estimates = estimates,
                           let txPackage = txPackage {
                            
                            self?.executeIntegralAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage
                            )
                        }
                    }
                    break
                case .digitalResaleAuctionBeneficiaryIndividual:
                    self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
                        let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
                        
                        guard let getIndividualAuctionEstimate = self?.getIndividualAuctionEstimate else {
                            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                                .eraseToAnyPublisher()
                        }
                        return getIndividualAuctionEstimate(transactionParameters)
                        
                    }) { [weak self] (estimates, txPackage, error) in
                        
                        if let error = error {
                            self?.processFailure(error)
                        }
                        
                        if let estimates = estimates,
                           let txPackage = txPackage {
                            
                            self?.executeIndividualAuction(
                                estimates: estimates,
                                mintParameters: mintParameters,
                                txPackage: txPackage,
                                completion: { (receipt, password, mintParameters) in
                                    self?.transferToken(txReceipt: receipt, password: password, mintParameters: mintParameters)
                                }
                            )
                        }
                    }
                    break
                default:
                    break
            }
        } // hideSpinner
    }
    
    func updateFirestore(
        txInfo: (txPackage: TxResult2, tokenId: String, id: String),
        mintParameters: MintParameters
    ) {
        let update: [String: PostProgress] = ["update": .minting]
        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        
        guard let previewDataArr = self.previewDataArr, previewDataArr.count == 1 else {
            alert.showDetail("Error", with: "A single digital asset is required.", for: self)
            return
        }
        
        var fileURLs: [AnyPublisher<String?, PostingError>]!
        
        // Use the existing file path if this is reselling. No need to upload to the Storage.
        // Since the remote image's url is used to display the digital image during the resale (not the local directory URL)
        // the attempt to use uploadFileWithPromise will result in no image found.
        if let post = self.post,
           let files = post.files,
           let filePath = files.first {
            
            let resellURLPromise = Future<String?, PostingError> { promise in
                promise(.success(filePath))
            }
            .eraseToAnyPublisher()
            
            fileURLs = [resellURLPromise]
        } else {
            fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                return Future<String?, PostingError> { promise in
                    self.uploadFileWithPromise(
                        fileURL: previewData.filePath,
                        userId: mintParameters.userId,
                        promise: promise
                    )
                }.eraseToAnyPublisher()
            }
        }
        
        Publishers.MergeMany(fileURLs)
            .collect()
            .eraseToAnyPublisher()
            // upload the details to Firestore
            .flatMap { [weak self] (urlStrings) -> AnyPublisher<Bool, PostingError> in
                let update: [String: PostProgress] = ["update": .images]
                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                
                guard let self = self,
                      let currentAddressString = Web3swiftService.currentAddressString else {
                    return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
                        .eraseToAnyPublisher()
                }
                
                return Future<Bool, PostingError> { promise in
                    self.transactionService.createFireStoreEntryRevised(
                        documentId: &self.documentId,
                        senderAddress: currentAddressString,
                        escrowHash: "N/A",
                        auctionHash: txInfo.txPackage.txResult.hash,
                        mintHash: "N/A",
                        itemTitle: mintParameters.itemTitle,
                        desc: mintParameters.desc,
                        price: mintParameters.price ?? "N/A",
                        category: mintParameters.category,
                        tokensArr: mintParameters.tokensArr,
                        convertedId: mintParameters.convertedId,
                        type: mintParameters.postType,
                        deliveryMethod: mintParameters.deliveryMethod,
                        saleFormat: mintParameters.saleFormat,
                        paymentMethod: mintParameters.paymentMethod,
                        tokenId: txInfo.tokenId,
                        urlStrings: urlStrings,
                        ipfsURLStrings: [],
                        shippingInfo: self.shippingInfo,
                        isWithdrawn: false,
                        isAdminWithdrawn: false,
                        solireyUid: txInfo.id,
                        contractFormat: mintParameters.contractFormat,
                        bidders: [self.userId],
                        promise: promise
                    )
                }
                .eraseToAnyPublisher()
            }
            .sink { [weak self] (completion) in
                if self?.socketDelegate != nil {
                    self?.socketDelegate.disconnectSocket()
                }
                
                switch completion {
                    case .failure(let error):
                        self?.processFailure(error)
                    case .finished:
                        self?.afterPostReset()
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.saleMethodContainerConstraintHeight.constant = 50
                            self?.priceTextFieldConstraintHeight.constant = 50
                            self?.priceTextField.alpha = 1
                            self?.priceLabelConstraintHeight.constant = 50
                            self?.priceLabel.alpha = 1
                            self?.auctionDurationTitleLabel.alpha = 0
                            self?.auctionDurationLabel.alpha = 0
                            self?.auctionDurationLabel.text = nil
                            self?.auctionStartingPriceTitleLabel.alpha = 0
                            self?.auctionStartingPriceTextField.alpha = 0
                            self?.auctionStartingPriceTextField.text = nil
                            self?.saleMethodLabel.text = nil
                            self?.deliveryMethodLabel.text = DeliveryMethod.onlineTransfer.rawValue
                            self?.pickerLabel.text = Category.digital.asString()
                            
                            UIView.animate(withDuration: 0.5) {
                                self?.view.layoutIfNeeded()
                            }
                            
                            guard let `self` = self else { return }
                            self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
                        }
                        
                        guard let documentId = self?.documentId else { return }
                        FirebaseService.shared.sendToTopicsVoid(
                            title: "New item has been listed on \(mintParameters.category)",
                            content: mintParameters.itemTitle,
                            topic: mintParameters.category,
                            docId: documentId
                        )
                        
                        self?.storage.removeAll()
                    //  register spotlight?
                }
            } receiveValue: { (_) in
            }
            .store(in: &self.storage)
    }
}
