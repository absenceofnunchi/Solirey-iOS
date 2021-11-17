//
//  DigitalAssetViewController + Individual Auction Resale.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-15.
//

import UIKit
import Combine
import web3swift

// temp
import BigInt

extension DigitalAssetViewController {
    final func transferToken(
        txReceipt: TransactionReceipt,
        password: String,
        mintParameters: MintParameters
    ) {
        let update: [String: PostProgress] = ["update": .deployingAuction]
        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        
        guard let fromAddress = Web3swiftService.currentAddress else {
            self.alert.showDetail("Error", with: "Could not get your wallet address.", for: self)
            return
        }
        
        guard let receivingContractAddress = txReceipt.contractAddress else {
            self.alert.showDetail("Error", with: "Unable to get the address of the receiving contract.", for: self)
            return
        }
        
        guard let solireyMintContractAddress = ContractAddresses.solireyMintContractAddress else {
            self.alert.showDetail("Error", with: "Unable to get the address of the transferring contract.", for: self)
            return
        }
        
        guard let tokenId = self.post?.tokenID else {
            self.alert.showDetail("Error", with: "Unable to get the token ID to transfer.", for: self)
            return
        }
        
        let param: [AnyObject] = [fromAddress, receivingContractAddress, tokenId] as [AnyObject]
        
        // mint a token and transfer it to the address of the newly deployed auction contract
        Deferred {
            Future<WriteTransaction, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForWriting(
                    method: SolireyContract.ContractMethods.safeTransferFrom.rawValue,
                    abi: mintContractABI,
                    param: param,
                    contractAddress: solireyMintContractAddress,
                    amountString: nil,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        }
        // execute the mint transaction
        .flatMap { [weak self] (transaction) -> AnyPublisher<[TxResult2], PostingError> in
            guard let txService = self?.transactionService else {
                return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                    .eraseToAnyPublisher()
            }
            
            let results = txService.executeTransaction2(
                transaction: transaction,
                password: password,
                type: .mint
            )
            
            return Publishers.MergeMany(results)
                .collect()
                .eraseToAnyPublisher()
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .failure(let error):
                    self?.processFailure(error)
                case .finished:
                    break
            }
        } receiveValue: { [weak self] (txResults) in
            self?.txResultArr.append(contentsOf: txResults)
            
            // Get the token ID by parsing the receipt from the minting transaction
            guard let receipt = txResults.first?.txResult.hash,
                  let self = self else {
                return
            }
            
            self.transactionService.confirmReceipt(txHash: receipt)
                .flatMap { (receipt) -> AnyPublisher<String, PostingError> in
                    Future<String, PostingError> { promise in
//                        guard let solireyMintContractAddress = ContractAddresses.solireyMintContractAddress else {
//                            return
//                        }
                        
                        let web3 = Web3swiftService.web3instance
                        guard let contract = web3.contract(mintContractABI, at: solireyMintContractAddress, abiVersion: 2) else {
                            self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                            return
                        }
                        
                        let parsedEvent = contract.parseEvent(receipt.logs[0])
                        guard let eventData = parsedEvent.eventData,
                              let tokenId = eventData["tokenId"] as? BigUInt else {
                            self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                            return
                        }
                        
                        promise(.success(tokenId.description))
                    }
                    .eraseToAnyPublisher()
                }
                .flatMap { [weak self] (tokenId) -> AnyPublisher<[String?], PostingError> in
                    let update: [String: PostProgress] = ["update": .transferToken]
                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                    self?.tokenIdRetainer = tokenId
                    
                    // upload images/files to the Firebase Storage and get the array of URLs
                    if let previewDataArr = self?.previewDataArr, previewDataArr.count > 0 {
                        let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                            return Future<String?, PostingError> { promise in
                                self?.uploadFileWithPromise(
                                    fileURL: previewData.filePath,
                                    userId: mintParameters.userId,
                                    promise: promise
                                )
                            }.eraseToAnyPublisher()
                        }
                        return Publishers.MergeMany(fileURLs)
                            .collect()
                            .eraseToAnyPublisher()
                    } else {
                        // if there are none to upload, return an empty array
                        return Result.Publisher([] as [String]).eraseToAnyPublisher()
                    }
                }
                .flatMap { [weak self] (urlStrings) -> AnyPublisher<Bool, PostingError> in
                    let update: [String: PostProgress] = ["update": .initializeAuction]
                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                    
                    guard let self = self,
                          let tokenId = self.tokenIdRetainer,
                          let currentAddressString = Web3swiftService.currentAddressString else {
                        return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
                            .eraseToAnyPublisher()
                    }
                    
                    var mintHash, auctionHash: String!
                    
                    for txResult in self.txResultArr {
                        if txResult.txType == .auctionContract {
                            auctionHash = txResult.txResult.hash
                        } else if txResult.txType == .mint {
                            mintHash = txResult.txResult.hash
                        }
                    }
                    
                    return Future<Bool, PostingError> { promise in
                        self.transactionService.createFireStoreEntryRevised(
                            documentId: &self.documentId,
                            senderAddress: currentAddressString,
                            escrowHash: "N/A",
                            auctionHash: auctionHash,
                            mintHash: mintHash,
                            itemTitle: mintParameters.itemTitle,
                            desc: mintParameters.desc,
                            price: mintParameters.price ?? "0",
                            category: mintParameters.category,
                            tokensArr: mintParameters.tokensArr,
                            convertedId: mintParameters.convertedId,
                            type: mintParameters.postType,
                            deliveryMethod: mintParameters.deliveryMethod,
                            saleFormat: mintParameters.saleFormat,
                            paymentMethod: mintParameters.paymentMethod,
                            tokenId: tokenId,
                            urlStrings: urlStrings,
                            ipfsURLStrings: [],
                            shippingInfo: self.shippingInfo,
                            solireyUid: "N/A",
                            contractFormat: mintParameters.contractFormat,
                            promise: promise
                        )
                    }
                    .eraseToAnyPublisher()
                }
                .sink { [weak self] (completion) in
                    switch completion {
                        case .failure(let error):
                            self?.processFailure(error)
                        case .finished:
                            self?.alert.showDetail(
                                "Success!",
                                with: "You have successfully posted your item.",
                                for: self,
                                buttonAction: {
                                    self?.dismiss(animated: true, completion: {
                                        self?.navigationController?.popToRootViewController(animated: true)
                                    })
                                }
                            )
                            
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
        .store(in: &self.storage)
    }
}
