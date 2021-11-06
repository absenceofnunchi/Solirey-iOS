//
//  IntegralAuctionViewController + Properties Parse.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-04.
//

import UIKit
import web3swift
import Combine
import BigInt

extension IntegralAuctionViewController {
    final func getAuctionInfo(
        transactionHash: String,
        executeReadTransaction: @escaping (_ propertyFetchModel: inout SmartContractProperty, _ promise: (Result<SmartContractProperty, PostingError>) -> Void) -> Void,
        contractAddress: EthereumAddress
    ) {
        let auctionInfoLoader = PropertyLoader<IntegralAuctionContract>(
            propertiesToLoad: self.propertiesToLoad,
            transactionHash: transactionHash,
            executeReadTransaction: executeReadTransaction,
            contractAddress: contractAddress,
            contractABI: integralAuctionABI
        )
        
        isPending = true
        auctionInfoLoader.initiateLoadSequence()
            .sink { [weak self] (completion) in
                self?.isPending = false
                switch completion {
                    case .failure(.retrievingCurrentAddressError):
                        self?.alert.showDetail("Contract Address Error", with: "Unable to retrieve the current address of your wallet", for: self)
                    case .failure(.contractLoadingError):
                        self?.alert.showDetail("Contract Address Error", with: "Unable to load the current address of your wallet", for: self)
                    case .failure(.createTransactionIssue):
                        self?.alert.showDetail("Transaction Error", with: "Unable to create the transaction.", for: self)
                    case .failure(.generalError(reason: let msg)):
                        self?.alert.showDetail("Auction Info Retrieval Error", with: msg, for: self)
                    case .finished:
                        print("get auction info finished")
                    default:
                        self?.alert.showDetail("Auction Info Retrieval Error", with: "Unable to fetch the auction contract information.", for: self)
                }
            } receiveValue: { [weak self] (propertyFetchModels: [SmartContractProperty]) in
                self?.isPending = false
                
                DispatchQueue.main.async {
                    // if the count is different, then the arrangedSubview in the stack view of auctionSpecView will go out of bound
                    if self?.propertiesToLoad.count == propertyFetchModels.count  {
                        DispatchQueue.main.async {
                            self?.parseFetchResultToDisplay(propertyFetchModels: propertyFetchModels)
                        }
                    }
                    
                    // socket to receive topics so that the auction specs could be re-updated
                    // whenever the current user or anybody else calls the method on the auction contract
                    // the socket will respond
                    // needs to be in the main thread, otherwise won't work
                    // only connect if the socket has timed out or disconnected
                    self?.createSocket()
                }
                
                // receives the publisher events from AuctionButtonController
                // depending on the logic provided by AuctionButtonController,
                // the status will determine what the "big button" should display
                guard let self = self else { return }
                NotificationCenter.default.publisher(for: .auctionButtonDidUpdate)
                    .compactMap { $0.object as? AuctionContract.ContractMethods }
                    .sink { (status) in
                        self.setButtonStatus(as: status)
                    }
                    .store(in: &self.storage)
            }
            .store(in: &self.storage)
    }
    
    // MARK: - executeReadTransaction
    final func executeReadTransaction(
        propertyFetchModel: inout SmartContractProperty,
        promise: (Result<SmartContractProperty, PostingError>) -> Void
    ) {
        
        do {
            guard let transaction = propertyFetchModel.transaction else {
                promise(.failure(.generalError(reason: "Unable to create a transaction.")))
                return
            }

            let result: [String: Any] = try transaction.call()

            guard let beneficiary = result[IntegralAuctionProperties.AuctionInfo.beneficiary.rawValue] as? EthereumAddress,
                  let auctionEndTime = result[IntegralAuctionProperties.AuctionInfo.auctionEndTime.rawValue] as? BigUInt,
                  let startingBid = result[IntegralAuctionProperties.AuctionInfo.startingBid.rawValue] as? BigUInt,
                  let tokenId = result[IntegralAuctionProperties.AuctionInfo.tokenId.rawValue] as? BigUInt,
                  let highestBidder = result[IntegralAuctionProperties.AuctionInfo.highestBidder.rawValue] as? EthereumAddress,
                  let highestBid = result[IntegralAuctionProperties.AuctionInfo.highestBid.rawValue] as? BigUInt,
                  let convertedHighestBid = Web3.Utils.formatToEthereumUnits(highestBid, toUnits: .eth, decimals: 17), // highest bid
                  let bidInEth = Web3.Utils.formatToEthereumUnits(startingBid, toUnits: .eth, decimals: 17),
                  let ended = result[IntegralAuctionProperties.AuctionInfo.ended.rawValue] as? Bool,
                  let transferred = result[IntegralAuctionProperties.AuctionInfo.transferred.rawValue] as? Bool else { return }

            let auctionEndDate = Date(timeIntervalSince1970: Double(auctionEndTime))
            let convertedStartingBid = self.transactionService.stripZeros(bidInEth) // starting bid

            var convertedHighestBidder: String!
            if highestBidder.address == "0x0000000000000000000000000000000000000000" {
                convertedHighestBidder = "No Bidder"
            } else {
                convertedHighestBidder = highestBidder.address
            }
 
            let auctionInfo = AuctionInfo(
                beneficiary: beneficiary.address,
                auctionEndTime: auctionEndDate,
                startingBid: convertedStartingBid,
                tokenId: tokenId,
                highestBidder: convertedHighestBidder,
                highestBid: convertedHighestBid,
                pendingReturns: nil,
                ended: ended,
                transferred: transferred
            )
            
            propertyFetchModel.propertyDesc = auctionInfo
            promise(.success(propertyFetchModel))
        } catch {
            promise(.failure(.generalError(reason: "Could not read the properties from the blockchain.")))
        }
    }
    
    func getLabelWithTag(views: [UIView], tag: Int) -> UILabel? {
        guard let label = views.filter ({ $0.tag == tag }).first as? UILabel else { return nil }
        return label
    }
    
    // MARK: - parseFetchResultToDisplay
    // parsing the result here and not inside AuctionSpecView to make AuctionSpecView modular
    // AuctonSpecView can display info from Firebase as well as from the blockchain
    func parseFetchResultToDisplay(propertyFetchModels: [SmartContractProperty]?) {
        guard let propertyFetchModels = propertyFetchModels,
              let specDetail = propertyFetchModels.first,
              let auctionInfo = specDetail.propertyDesc as? AuctionInfo else { return }

        if pendingReturnButton != nil {
            pendingReturnButton.removeFromSuperview()
            NSLayoutConstraint.deactivate(pendingReturnButtonConstraints)
            pendingReturnButtonConstraints.removeAll()
        }

        if pendingReturnActivityIndicatorView != nil {
            pendingReturnActivityIndicatorView.removeFromSuperview()
        }

        auctionSpecView.stackView.arrangedSubviews.forEach { [weak self] (element) in
//            guard let titleLabel = element.subviews.filter ({ $0.tag == 1 }).first as? UILabel else { return }
            
            guard let self = self,
                  let titleLabel = getLabelWithTag(views: element.subviews, tag: 1),
                  let descLabel = getLabelWithTag(views: element.subviews, tag: 2) else { return }
            
            switch titleLabel.text {
                case IntegralAuctionProperties.AuctionInfo.highestBidder.value:
                    let highestBidder = auctionInfo.highestBidder
                    auctionButtonController.highestBidder = highestBidder
                    
                    if highestBidder == self.contractAddress.address {
                        descLabel.text = "You"
                    } else {
                        descLabel.text = highestBidder
                    }
                case IntegralAuctionProperties.AuctionInfo.ended.value:
                    let status = auctionInfo.ended
                    descLabel.text = status == false ? "Active" : "Ended"
                    auctionButtonController.isAuctionOfficiallyEnded = status
                    
                    let statusInfoButton = UIButton()
                    statusInfoButton.alpha = 0
                    let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .light, scale: .medium)
                    guard let infoImage = UIImage(systemName: "info.circle")?.withConfiguration(configuration) else { return }
                    statusInfoButton.setImage(infoImage, for: .normal)
                    statusInfoButton.tag = 62
                    statusInfoButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
                    statusInfoButton.translatesAutoresizingMaskIntoConstraints = false
                    element.addSubview(statusInfoButton)
                    
                    NSLayoutConstraint.activate([
                        statusInfoButton.centerYAnchor.constraint(equalTo: descLabel.centerYAnchor),
                        statusInfoButton.trailingAnchor.constraint(equalTo: descLabel.trailingAnchor, constant: 0),
                        statusInfoButton.widthAnchor.constraint(equalToConstant: 40),
                    ])
                    
                    UIView.animate(withDuration: 0.5) {
                        statusInfoButton.alpha = 1
                    }
                    break
                case IntegralAuctionProperties.AuctionInfo.auctionEndTime.value:
                    let auctionEndTime = auctionInfo.auctionEndTime
                    auctionButtonController.auctionEndTime = auctionEndTime
                    auctionButtonController.isAuctionEnded = auctionEndTime < Date()
                    
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    formatter.dateStyle = .short
                    formatter.timeZone = .current
                    let formattedDate = formatter.string(from: auctionEndTime)
                    descLabel.text = formattedDate
                    break
                case IntegralAuctionProperties.AuctionInfo.beneficiary.value:
                    let beneficiary = auctionInfo.beneficiary
                    auctionButtonController.beneficiary = beneficiary
                    if beneficiary == self.contractAddress.address {
                        descLabel.text = "You"
                    } else {
                        descLabel.text = beneficiary
                    }
                    break
                case IntegralAuctionProperties.AuctionInfo.startingBid.value,
                     IntegralAuctionProperties.AuctionInfo.highestBid.value:
                    descLabel.text = auctionInfo.startingBid
                default:
                    break
            }
        }
    }

    func createSocket(topics: [String]? = nil) {
        guard socketDelegate == nil else { return }
        socketDelegate = SocketDelegate(
            contractAddress: self.auctionContractAddress,
            topics: topics,
            passThroughSubject: PassthroughSubject<[String: Any], PostingError>()
        )
        
        socketDelegate.passThroughSubject
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                    case .failure(let err):
                        self?.alert.showDetail("Auction Detail Fetch Error", with: err.localizedDescription, for: self)
                    case .finished:
                        print("")
                        break
                }
            }, receiveValue: { [weak self] (WebSocketMessage) in
                guard let topics = WebSocketMessage["topics"] as? [String],
                      let txHash = WebSocketMessage["transactionHash"] as? String,
                      let auctionContractAddress = self?.auctionContractAddress else { return }
                
                switch topics {
                    case _ where topics.contains(Topics.HighestBidIncreased):
                        self?.isPending = true
                        guard let executeReadTransaction = self?.executeReadTransaction else { return }
                        self?.getAuctionInfo(
                            transactionHash: txHash,
                            executeReadTransaction: executeReadTransaction,
                            contractAddress: auctionContractAddress
                        )
                    default:
                        print("other events")
                }
            })
            .store(in: &storage)
    }
    
    func createEventListener() {
        guard let auctionHash = post.auctionHash else { return }
        Future<TransactionReceipt, PostingError> { promise in
            Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
        }
        .flatMap({ (receipt) -> AnyPublisher<[EventParserResultProtocol], PostingError> in
            return Future<[EventParserResultProtocol], PostingError> { promise in
                let web3 = Web3swiftService.web3instance
                guard let auctionContractAddress = receipt.contractAddress else {
                    return promise(.failure(.generalError(reason: "Unable to retrieve the auction contract")))
                }
                
                let contract = web3.contract(auctionABI, at: auctionContractAddress, abiVersion: 2)
                
                var filter = EventFilter()
//                filter.
//                EventFilterable
                filter.fromBlock = .blockNumber(0)
                filter.toBlock = .latest
                let eventParser = contract?.createEventParser("HighestBidIncreased", filter: nil)
                
                var blockNumber: BigUInt!
                do {
                    blockNumber = try web3.eth.getBlockNumber()
                } catch {
                    promise(.failure(.generalError(reason: "Unable to get the block number.")))
                }
                
                do {
                    if let event = try eventParser?.parseBlockByNumber(UInt64(blockNumber)) {
                        print("event parser", event)
                        promise(.success(event))
                    } else {
                        promise(.failure(.generalError(reason: "No event.")))
                    }
                } catch {
                    promise(.failure(.generalError(reason: "Unable to parse event.")))
                }
            }
            .eraseToAnyPublisher()
        })
        .sink { (completion) in
            switch completion {
                case .finished:
                    break
                case .failure(let err):
                    print(err)
            }
        } receiveValue: { (event) in
            print("final event", event)
        }
        .store(in: &storage)
    }
}
