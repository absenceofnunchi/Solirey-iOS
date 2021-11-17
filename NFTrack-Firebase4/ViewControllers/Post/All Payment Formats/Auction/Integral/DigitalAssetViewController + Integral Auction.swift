//
//  DigitalAssetViewController + Integral Auction.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-04.
//

import UIKit
import Combine
import web3swift
import BigInt

extension DigitalAssetViewController {
    final func getIntegralAuctionEstimate(
        method: IntegralAuctionContract.ContractMethods,
        transactionParameters: [AnyObject]
    ) -> AnyPublisher<TxPackage, PostingError> {
        Future<TxPackage, PostingError> { [weak self] promise in
            guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress else {
                promise(.failure(PostingError.generalError(reason: "Unable to prepare the contract address.")))
                return
            }
            
            self?.transactionService.prepareTransactionForWritingWithGasEstimate(
                method: method.rawValue,
                abi: integralAuctionABI,
                param: transactionParameters,
                contractAddress: integralAuctionAddress,
                amountString: nil,
                promise: promise
            )
        }
        .eraseToAnyPublisher()
    }
    
    func executeIntegralAuction(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters,
        txPackage: TxPackage
    ) {
        var txResultRetainer: TransactionSendingResult!
        
        let content = [
            StandardAlertContent(
                titleString: "Enter Your Password",
                body: [AlertModalDictionary.walletPasswordRequired: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
            StandardAlertContent(
                index: 1,
                titleString: "Gas Estimate",
                titleColor: UIColor.white,
                body: [
                    "Total Gas Units": txPackage.gasEstimate.description,
                    "Gas Price": "\(estimates.gasPriceInGwei) Gwei",
                    "Total Gas Cost": "\(estimates.totalGasCost) Ether",
                    "Your Current Balance": "\(estimates.balance) Ether"
                ],
                isEditable: false,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .noButton
            )
        ]
        
        self.hideSpinner()
        
        DispatchQueue.main.async { [weak self] in
            let alertVC = AlertViewController(height: 350, standardAlertContent: content)
            alertVC.action = { [weak self] (modal, mainVC) in
                mainVC.buttonAction = { _ in
                    guard let password = modal.dataDict[AlertModalDictionary.walletPasswordRequired],
                          !password.isEmpty else {
                        self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                        return
                    }
                    
                    self?.dismiss(animated: true, completion: {
                        let progressModal = ProgressModalViewController(paymentMethod: .integralAuction)
                        progressModal.titleString = "Posting In Progress"
                        self?.present(progressModal, animated: true, completion: {
//                            self?.socketDelegate = SocketDelegate(
//                                contractAddress: integralAuctionAddress,
//                                topics: [Topics.IntegralAuction.auctionCreated, Topics.IntegralAuction.transfer]
//                            )
                            
                            Deferred { [weak self] () -> AnyPublisher<TxResult2, PostingError> in
                                guard let transactionService = self?.transactionService else {
                                    return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                                        .eraseToAnyPublisher()
                                }
                                
                                return transactionService.executeTransaction2(transaction: txPackage.transaction, password: password, type: .auctionContract)
                                    .eraseToAnyPublisher()
                            }
                            .sink(receiveCompletion: { (completion) in
                                switch completion {
                                    case .failure(let error):
                                        self?.processFailure(error)
                                    case .finished:
                                        break
                                }
                            }, receiveValue: { (txResult) in
                                let update: [String: PostProgress] = ["update": .estimatGas]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
                                txResultRetainer = txResult.txResult
                                
                                // Get the token ID by parsing the receipt from the minting transaction
                                guard let self = self else { return }
                                
                                self.transactionService.confirmReceipt(txHash: txResult.txResult.hash)
                                    .flatMap { (receipt) -> AnyPublisher<(id: String, tokenId: String), PostingError> in
                                        Future<(id: String, tokenId: String), PostingError> { promise in
                                            
                                            let web3 = Web3swiftService.web3instance
                                            guard let contract = web3.contract(integralAuctionABI, at: ContractAddresses.integralAuctionAddress, abiVersion: 2) else {
                                                self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                                                return
                                            }
                                            
                                            // Two events will be emitted (AuctionCreated, Transfer).
                                            // Following determines which event in the logs array is which so that the order shouldn't matter. i.e. logs[0] could be either AuctionCreated or Transfer.
                                            let parsedEvent1 = contract.parseEvent(receipt.logs[0])
                                            let parsedEvent2 = contract.parseEvent(receipt.logs[1])
                                            
                                            if parsedEvent1.eventName == "AuctionCreated" {
                                                guard let eventData1 = parsedEvent1.eventData,
                                                      let id = eventData1["id"] as? BigUInt,
                                                      let eventData2 = parsedEvent2.eventData,
                                                      let tokenId = eventData2["tokenId"] as? BigUInt else {
                                                    self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                                                    return
                                                }

                                                promise(.success((id: id.description, tokenId: tokenId.description)))
                                            } else {
                                                guard let eventData1 = parsedEvent1.eventData,
                                                      let id = eventData1["tokenId"] as? BigUInt,
                                                      let eventData2 = parsedEvent2.eventData,
                                                      let tokenId = eventData2["id"] as? BigUInt else {
                                                    self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                                                    return
                                                }
                                                
                                                promise(.success((id: id.description, tokenId: tokenId.description)))
                                            }
                                        }
                                        .eraseToAnyPublisher()
                                    }
                                    .sink { [weak self] (completion) in
                                        switch completion {
                                            case .failure(let error):
                                                self?.processFailure(error)
                                            case .finished:
                                                break
                                        }
                                    } receiveValue: { [weak self] (topicsInfo) in
                                        
                                        self?.updateFirestore(
                                            topicsInfo: topicsInfo,
                                            mintParameters: mintParameters,
                                            txResultRetainer: txResultRetainer
                                        )
                                    }
                                    .store(in: &self.storage)
                            })
                            .store(in: &self!.storage)
                        })
                    })
                } // mainVC
            } // alertVC.action
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
}
