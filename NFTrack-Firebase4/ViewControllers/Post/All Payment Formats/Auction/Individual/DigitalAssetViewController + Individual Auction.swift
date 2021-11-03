//
//  DigitalAssetViewController + Individual Auction.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-03.
//

import UIKit
import Combine
import web3swift

extension DigitalAssetViewController {
    final func executeIndividualAuction(
        estimates: (totalGasCost: String, balance: String, gasPriceInGwei: String),
        mintParameters: MintParameters
    ) {
        //        var txResultRetainer: TransactionSendingResult!
        //        // To be used for the event topics from the socket
        //        var postUid: String!
        //        var tokenId: String!
        //        // To retain the above information for Firestore
        //        var topicsInfoRetainer: (uid: String, tokenId: String)!
        
        guard let integralAuctionAddress = ContractAddresses.integralAuctionAddress,
              let txPackageRetainer = self.txPackageArr.first else {
            return
        }
        
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
                    "Total Gas Units": txPackageRetainer.gasEstimate.description,
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
                        let progressModal = ProgressModalViewController(paymentMethod: .auctionBeneficiary)
                        progressModal.titleString = "Posting In Progress"
                        self?.present(progressModal, animated: true, completion: {
                            self?.socketDelegate = SocketDelegate(
                                contractAddress: integralAuctionAddress,
                                topics: [Topics.IntegralAuction.auctionCreated, Topics.IntegralAuction.transfer]
                            )
                            
                            guard let txPackageArr = self?.txPackageArr,
                                  let transaction = txPackageArr.first?.transaction,
                                  let transactionService = self?.transactionService,
                                  let self = self else {
                                return
                            }
                            
                            Deferred {
                                transactionService.executeTransaction2(
                                    transaction: transaction,
                                    password: password,
                                    type: .auctionContract
                                )
                            }
                            .sink { (completion) in
                                switch completion {
                                    case .failure(let error):
                                        self.processFailure(error)
                                    default:
                                        break
                                }
                            } receiveValue: { (txResult) in
                                // confirm that the receipt of the transaction is obtained
                                self.transactionService.confirmReceipt(txHash: txResult.txResult.hash)
                                    .sink { (completion) in
                                        switch completion {
                                            case .failure(let error):
                                                self.processFailure(error)
                                            default:
                                                break
                                        }
                                    } receiveValue: { (receipt) in
                                        print("receipt", receipt)
                                        // confirm that the block is added to the chain
                                        self.transactionService.confirmTransactions(receipt)
                                            .sink(receiveCompletion: { (completion) in
                                                switch completion {
                                                    case .failure(let error):
                                                        self.processFailure(error)
                                                    default:
                                                        break
                                                }
                                            }, receiveValue: { (receipt) in
                                                self.mintAndTransfer(
                                                    txReceipt: receipt,
                                                    password: password,
                                                    mintParameters: mintParameters
                                                )
                                            })
                                            .store(in: &self.storage)
                                    }
                                    .store(in: &self.storage)
                            }
                            .store(in: &self.storage)
                            
                        }) // self?.present
                    }) // self?.dismiss
                } // mainVC
            } // alertVC
            self?.present(alertVC, animated: true, completion: nil)
        } // dispatch
    }
    
    // First time sale for SimplePayment
    final func mintAndTransfer(
        txReceipt: TransactionReceipt,
        password: String,
        mintParameters: MintParameters
    ) {
        let update: [String: PostProgress] = ["update": .deployingAuction]
        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        
        guard let contractAddress = txReceipt.contractAddress,
              let solireyMintContractAddress = ContractAddresses.solireyMintContractAddress else {
            return
        }
        
        
        print("txReceipt", txReceipt as Any)
        self.socketDelegate = SocketDelegate(contractAddress: solireyMintContractAddress, topics: [Topics.IndividualAuction.mint])
        
        // mint a token and transfer it to the address of the newly deployed auction contract
        Deferred {
            Future<WriteTransaction, PostingError> { [weak self] promise in
                self?.transactionService.prepareTransactionForMinting(
                    receiverAddress: contractAddress,
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
        .sink(receiveCompletion: { [weak self](completion) in
            switch completion {
                case .failure(let error):
                    self?.processFailure(error)
                case .finished:
                    break
            }
        }, receiveValue: { (txResult) in
            print("txResult", txResult)
            
        })
        .store(in: &self.storage)
        //        // get the topics from the socket delegate
        //        .flatMap { [weak self] (txResult) -> AnyPublisher<[String: Any], PostingError> in
        //            let update: [String: PostProgress] = ["update": .minting]
        //            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        //
        //            // retain the mint transaction details for FireStore
        //            self?.txResultArr.append(contentsOf: txResult)
        //
        //            return Future<String, PostingError> { promise in
        //                self?.socketDelegate.didReceiveTopics = { webSocketMessage in
        //                    guard let topics = webSocketMessage["topics"] as? [String] else { return }
        //
        //                    let fromAddress = topics[2]
        //                    let paddedTokenId = topics[3]
        //
        //                    guard let tokenId = Web3Utils.hexToBigUInt(paddedTokenId) else {
        //                        promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
        //                        return
        //                    }
        //
        //                    let data = Data(hex: fromAddress)
        //                    guard let decodedFromAddress = ABIDecoder.decode(types: [.address], data:data)?.first as? EthereumAddress else {
        //                        promise(.failure(.generalError(reason: "Unable to decode the contract address.")))
        //                        return
        //                    }
        //
        //                    if decodedFromAddress == Web3swiftService.currentAddress {
        //                        promise(.success(tokenId.description))
        //                    }
        //                }
        //            }
        //            .eraseToAnyPublisher()
        //        }
        
        //        // instantiate the socket, parse the topics, and create the firebase entry as soon as the socket delegate receives the data
        //        // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
        //        .flatMap({ [weak self] (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
        //            let update: [String: PostProgress] = ["update": .minting]
        //            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        //
        //            if let topics = webSocketMessage["topics"] as? [String] {
        //                self?.topicsRetainer = topics
        //            }
        //
        //            guard let userId = self?.userId else {
        //                return Fail(error: PostingError.generalError(reason: "Unable to fetch the user ID."))
        //                    .eraseToAnyPublisher()
        //            }
        //
        //            // upload images/files to the Firebase Storage and get the array of URLs
        //            if let previewDataArr = self?.previewDataArr, previewDataArr.count > 0 {
        //                let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
        //                    return Future<String?, PostingError> { promise in
        //                        self?.uploadFileWithPromise(
        //                            fileURL: previewData.filePath,
        //                            userId: userId,
        //                            promise: promise
        //                        )
        //                    }.eraseToAnyPublisher()
        //                }
        //                return Publishers.MergeMany(fileURLs)
        //                    .collect()
        //                    .eraseToAnyPublisher()
        //            } else {
        //                // if there are none to upload, return an empty array
        //                return Result.Publisher([] as [String]).eraseToAnyPublisher()
        //            }
        //        })
        //        // upload the details to Firestore
        //        .flatMap { [weak self] (urlStrings) -> AnyPublisher<Int, PostingError> in
        //            let update: [String: PostProgress] = ["update": .images]
        //            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
        //
        //            guard let price = mintParameters.price,
        //                  let topics = self?.topicsRetainer,
        //                  let txResults = self?.txResultArr else {
        //                return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
        //                    .eraseToAnyPublisher()
        //            }
        //
        //            var mintHash: String!
        //            var senderAddress: String!
        //            var escrowHash: String!
        //            for txResult in txResults {
        //                if txResult.txType == .deploy {
        //                    escrowHash = txResult.txResult.hash
        //                } else {
        //                    mintHash = txResult.txResult.hash
        //                }
        //                senderAddress = txResult.senderAddress
        //            }
        //
        //            guard let self = self else {
        //                return Fail(error: PostingError.generalError(reason: "Unable to prepare data for the database update."))
        //                    .eraseToAnyPublisher()
        //            }
        //            return Future<Int, PostingError> { promise in
        //                self.transactionService.createFireStoreEntry(
        //                    documentId: &self.documentId,
        //                    senderAddress: senderAddress,
        //                    escrowHash: escrowHash,
        //                    auctionHash: "N/A",
        //                    mintHash: mintHash,
        //                    itemTitle: mintParameters.itemTitle,
        //                    desc: mintParameters.desc,
        //                    price: price,
        //                    category: mintParameters.category,
        //                    tokensArr: mintParameters.tokensArr,
        //                    convertedId: mintParameters.convertedId,
        //                    type: "tangible",
        //                    deliveryMethod: mintParameters.deliveryMethod,
        //                    saleFormat: mintParameters.saleFormat,
        //                    paymentMethod: mintParameters.paymentMethod,
        //                    topics: topics,
        //                    urlStrings: urlStrings,
        //                    ipfsURLStrings: [],
        //                    isWithdrawn: false,
        //                    isAdminWithdrawn: false,
        //                    promise: promise
        //                )
        //            }
        //            .eraseToAnyPublisher()
        //        }
        //        .sink { [weak self] (completion) in
        //            switch completion {
        //                case .failure(let error):
        //                    self?.processFailure(error)
        //                case .finished:
        //                    // index Core Spotlight
        //                    self?.indexSpotlight(
        //                        itemTitle: mintParameters.itemTitle,
        //                        desc: mintParameters.desc,
        //                        tokensArr: mintParameters.tokensArr,
        //                        convertedId: mintParameters.convertedId
        //                    )
        //
        //                    self?.afterPostReset()
        //            }
        //        } receiveValue: { (receivedValue) in
        //            if self.socketDelegate != nil {
        //                self.socketDelegate.disconnectSocket()
        //            }
        //        }
        //        .store(in: &self.storage)
    }
}
