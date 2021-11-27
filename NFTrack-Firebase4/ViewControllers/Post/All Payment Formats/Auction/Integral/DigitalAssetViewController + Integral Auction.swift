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
        return Future<TxPackage, PostingError> { [weak self] promise in
            guard let solireyContractAddress = ContractAddresses.solireyContractAddress else {
                promise(.failure(PostingError.generalError(reason: "Unable to get the contract address of the auction.")))
                return
            }
            self?.socketDelegate = SocketDelegate(contractAddress: solireyContractAddress, topics: [Topics.Solirey.transfer])

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
                            Deferred { [weak self] () -> AnyPublisher<TxResult2, PostingError> in
                                guard let transactionService = self?.transactionService else {
                                    return Fail(error: PostingError.generalError(reason: "Unable to execute the transaction."))
                                        .eraseToAnyPublisher()
                                }
                                
                                return transactionService.executeTransaction2(transaction: txPackage.transaction, password: password, type: .auctionContract)
                                    .eraseToAnyPublisher()
                            }
                            .flatMap({ [weak self] (txPackage) -> AnyPublisher<(txPackage: TxResult2, tokenId: String), PostingError> in
                                // Listen to the Transfer even emitted from the mint method of Solirey in order to get the tokenId
                                return Future<(txPackage: TxResult2, tokenId: String), PostingError> { promise in
                                    self?.socketDelegate.didReceiveTopics = { webSocketMessage in
                                        guard let topics = webSocketMessage["topics"] as? [String],
                                              let txHash = webSocketMessage["transactionHash"] as? String else { return }
                                        
                                        let paddedTokenId = topics[3]
                                        
                                        guard let tokenId = Web3Utils.hexToBigUInt(paddedTokenId) else {
                                            promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
                                            return
                                        }
                                        
//                                        let data = Data(hex: fromAddress)
//                                        guard let decodedFromAddress = ABIDecoder.decode(types: [.address], data:data)?.first as? EthereumAddress else {
//                                            promise(.failure(.generalError(reason: "Unable to decode the contract address.")))
//                                            return
//                                        }
                                        
                                        if txPackage.txResult.hash == txHash {
                                            promise(.success((txPackage: txPackage, tokenId: tokenId.description)))
                                        }
                                    }
                                }
                                .eraseToAnyPublisher()
                            })
                            .sink(receiveCompletion: { (completion) in
                                switch completion {
                                    case .failure(let error):
                                        self?.processFailure(error)
                                    case .finished:
                                        break
                                }
                            }, receiveValue: { (returnedValue) in
                                let update: [String: PostProgress] = ["update": .estimatGas]
                                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                                txResultRetainer = returnedValue.txPackage.txResult

                                // Get the token ID by parsing the receipt from the minting transaction
                                guard let self = self else { return }

                                self.transactionService.confirmReceipt(txHash: returnedValue.txPackage.txResult.hash)
                                    .flatMap { (receipt) -> AnyPublisher<(txPackage: TxResult2, tokenId: String, id: String), PostingError> in
                                        Future<(txPackage: TxResult2, tokenId: String, id: String), PostingError> { promise in
                                            // There are two events that are being emitted:
                                            // 1. AuctionCreated: From the Auction contract. The Id from the AuctionCreated has to be captured.
                                            // 2. Transfer: From the Solirey contract. The tokenId from the Transfer event which is emitted from the mint method has to be captured.
                                            let web3 = Web3swiftService.web3instance
                                            guard let contract = web3.contract(integralAuctionABI, at: ContractAddresses.integralAuctionAddress, abiVersion: 2) else {
                                                self.alert.showDetail("Error", with: "Unable to parse the transaction.", for: self)
                                                return
                                            }
                                            
                                            for i in 0..<receipt.logs.count {
                                                let parsedEvent = contract.parseEvent(receipt.logs[i])
                                                switch parsedEvent.eventName {
                                                    case "AuctionCreated":
                                                        if let parsedData = parsedEvent.eventData,
                                                           let id = parsedData["id"] as? BigUInt {
                                                            if let seller = parsedData["seller"] as? EthereumAddress,
                                                               seller == Web3swiftService.currentAddress {
                                                                print("id.description", id.description)
                                                                promise(.success((txPackage: returnedValue.txPackage, tokenId: returnedValue.tokenId, id: id.description)))
                                                            }
                                                        } else {
                                                            promise(.failure(.emptyResult))
                                                        }
                                                        break
                                                    default:
                                                        break
                                                }
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
                                    } receiveValue: { [weak self] (txInfo) in
                                        self?.updateFirestore(
                                            txInfo: txInfo,
                                            mintParameters: mintParameters
                                        )
                                    }
                                    .store(in: &self.storage)
                                
//                                    .flatMap({ [weak self] (receipt) -> AnyPublisher<String, PostingError> in
//                                        print("receipt", receipt as Any)
//                                        // Listen to the Transfer even emitted from the mint method of Solirey in order to get the tokenId
//                                        return Future<String, PostingError> { promise in
//                                            self?.socketDelegate.didReceiveTopics = { webSocketMessage in
//                                                print("webSocketMessage", webSocketMessage)
//                                                guard let topics = webSocketMessage["topics"] as? [String] else { return }
//                                                print("topics", topics)
//
//                                                let fromAddress = topics[2]
//                                                let paddedTokenId = topics[3]
//                                                print("fromAddress", fromAddress)
//                                                guard let tokenId = Web3Utils.hexToBigUInt(paddedTokenId) else {
//                                                    promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
//                                                    return
//                                                }
//
//                                                let data = Data(hex: fromAddress)
//                                                guard let decodedFromAddress = ABIDecoder.decode(types: [.address], data:data)?.first as? EthereumAddress else {
//                                                    promise(.failure(.generalError(reason: "Unable to decode the contract address.")))
//                                                    return
//                                                }
//
//                                                if decodedFromAddress == Web3swiftService.currentAddress {
//                                                    promise(.success(tokenId.description))
//                                                }
//                                            }
//                                        }
//                                        .eraseToAnyPublisher()
//                                    })
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
