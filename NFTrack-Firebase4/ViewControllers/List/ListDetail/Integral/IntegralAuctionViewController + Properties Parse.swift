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
                        break
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
                    self?.createSocket(topics: [Topics.IntegralAuction.bid, Topics.IntegralAuction.auctionEnd])
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
            
            switch propertyFetchModel.propertyName {
                case IntegralAuctionContract.ContractProperties.getPendingReturn(self.solireyUid).value.0:
                    if let pendingReturns = result["0"] as? BigUInt,
                       let converted = Web3.Utils.formatToEthereumUnits(pendingReturns, toUnits: .eth, decimals: 17) {
                        let trimmed = self.transactionService.stripZeros(converted.description)
                        propertyFetchModel.propertyDesc = trimmed
                    }
                    break
                default:
                    guard let beneficiary = result[IntegralAuctionProperties.AuctionInfo.beneficiary.rawValue] as? EthereumAddress,
                          let auctionEndTime = result[IntegralAuctionProperties.AuctionInfo.auctionEndTime.rawValue] as? BigUInt,
                          let startingBid = result[IntegralAuctionProperties.AuctionInfo.startingBid.rawValue] as? BigUInt,
                          let startingBidInEth = Web3.Utils.formatToEthereumUnits(startingBid, toUnits: .eth, decimals: 17),
                          let tokenId = result[IntegralAuctionProperties.AuctionInfo.tokenId.rawValue] as? BigUInt,
                          let highestBidder = result[IntegralAuctionProperties.AuctionInfo.highestBidder.rawValue] as? EthereumAddress,
                          let highestBid = result[IntegralAuctionProperties.AuctionInfo.highestBid.rawValue] as? BigUInt,
                          let highestBidInEth = Web3.Utils.formatToEthereumUnits(highestBid, toUnits: .eth, decimals: 17),
                          let ended = result[IntegralAuctionProperties.AuctionInfo.ended.rawValue] as? Bool,
                          let transferred = result[IntegralAuctionProperties.AuctionInfo.transferred.rawValue] as? Bool else { return }
                    
                    let auctionEndDate = Date(timeIntervalSince1970: Double(auctionEndTime))
                    let convertedStartingBid = self.transactionService.stripZeros(startingBidInEth) // starting bid
                    let convertedHighestBid = self.transactionService.stripZeros(highestBidInEth) // highest bid
                    
                    var convertedHighestBidder: String!
                    if highestBidder.address == "0x0000000000000000000000000000000000000000" {
                        convertedHighestBidder = "No Bidder"
                    } else {
                        convertedHighestBidder = highestBidder.address
                    }
                    
                    let auctionInfo = AuctionInfo(
                        beneficiary: beneficiary.address,
                        auctionEndTime: auctionEndDate,
                        startingBid: "\(convertedStartingBid) ETH",
                        tokenId: tokenId,
                        highestBidder: convertedHighestBidder,
                        highestBid: "\(convertedHighestBid) ETH",
                        pendingReturns: nil,
                        ended: ended,
                        transferred: transferred
                    )
                    
                    propertyFetchModel.propertyDesc = auctionInfo
                    break
            }
            
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
        guard let propertyFetchModels = propertyFetchModels else { return }

        if pendingReturnButton != nil {
            pendingReturnButton.removeFromSuperview()
            NSLayoutConstraint.deactivate(pendingReturnButtonConstraints)
            pendingReturnButtonConstraints.removeAll()
        }

        if pendingReturnActivityIndicatorView != nil {
            pendingReturnActivityIndicatorView.removeFromSuperview()
        }
        
        guard let auctionInfo = propertyFetchModels[0].propertyDesc as? AuctionInfo,
              let pendingReturn = propertyFetchModels[1].propertyDesc as? String else { return }
        
//        auctionButtonController = AuctionButtonController(
//            isAuctionEnded: auctionInfo.ended,
//            isAuctionOfficiallyEnded: auctionInfo.auctionEndTime < Date(),
//            highestBidder: auctionInfo.highestBidder,
//            beneficiary: auctionInfo.beneficiary
//        )
        
        auctionSpecView.stackView.arrangedSubviews.forEach { [weak self] (element) in
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
                    break
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
                case IntegralAuctionProperties.AuctionInfo.startingBid.value:
                    descLabel.text = auctionInfo.startingBid
                    break
                case IntegralAuctionProperties.AuctionInfo.highestBid.value:
                    descLabel.text = auctionInfo.highestBid
                    break
                case IntegralAuctionProperties.AuctionInfo.pendingReturns.value where pendingReturn == "0":
                    descLabel.text = pendingReturn
                    
                    pendingReturnButton = UIButton()
                    pendingReturnButton.alpha = 0
                    
                    let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .light, scale: .medium)
                    guard let infoImage = UIImage(systemName: "info.circle")?.withConfiguration(configuration) else { return }
                    pendingReturnButton.setImage(infoImage, for: .normal)
                    pendingReturnButton.tag = 61
                    pendingReturnButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
                    pendingReturnButton.translatesAutoresizingMaskIntoConstraints = false
                    element.addSubview(pendingReturnButton)
                    
                    pendingReturnButtonConstraints.append(contentsOf: [
                        pendingReturnButton.centerYAnchor.constraint(equalTo: element.centerYAnchor),
                        pendingReturnButton.trailingAnchor.constraint(equalTo: element.trailingAnchor, constant: 0),
                        pendingReturnButton.widthAnchor.constraint(equalToConstant: 40),
                    ])
                    
                    NSLayoutConstraint.activate(pendingReturnButtonConstraints)
                    
                    UIView.animate(withDuration: 0.5) { [weak self] in
                        self?.pendingReturnButton.alpha = 1
                    }
                    break
                case IntegralAuctionProperties.AuctionInfo.pendingReturns.value where pendingReturn != "0":
                    descLabel.text = pendingReturn

                    pendingReturnButton = UIButton()
                    pendingReturnButton.backgroundColor = .black
                    pendingReturnButton.setTitle("Withdraw", for: .normal)
                    pendingReturnButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    pendingReturnButton.layer.cornerRadius = 5
                    pendingReturnButton.tag = 60
                    pendingReturnButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                    pendingReturnButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
                    pendingReturnButton.translatesAutoresizingMaskIntoConstraints = false
                    element.addSubview(pendingReturnButton)
                    
                    pendingReturnButtonConstraints.append(contentsOf: [
                        pendingReturnButton.centerYAnchor.constraint(equalTo: element.centerYAnchor),
                        pendingReturnButton.trailingAnchor.constraint(equalTo: element.trailingAnchor, constant: -12),
                        pendingReturnButton.widthAnchor.constraint(equalToConstant: 70),
                    ])
                    
                    NSLayoutConstraint.activate(pendingReturnButtonConstraints)
                    
                    UIView.animate(withDuration: 0.5) { [weak self] in
                        self?.pendingReturnButton.alpha = 1
                    }
                    
                    NotificationCenter.default.publisher(for: .auctionDidWithdraw)
                        .compactMap { $0.object as? Bool }
                        .sink { [weak self] (isWithdrawPending) in
                            if isWithdrawPending == true {
                                DispatchQueue.main.async {
                                    guard let self = self else { return }
                                    self.pendingReturnButton.removeFromSuperview()
                                    NSLayoutConstraint.deactivate(self.pendingReturnButtonConstraints)
                                    self.pendingReturnButtonConstraints.removeAll()
                                    
                                    self.pendingReturnActivityIndicatorView = UIActivityIndicatorView()
                                    self.pendingReturnActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
                                    element.addSubview(self.pendingReturnActivityIndicatorView)
                                    self.pendingReturnActivityIndicatorView.startAnimating()
                                    
                                    NSLayoutConstraint.activate([
                                        self.pendingReturnActivityIndicatorView.centerYAnchor.constraint(equalTo: element.centerYAnchor),
                                        self.pendingReturnActivityIndicatorView.trailingAnchor.constraint(equalTo: element.trailingAnchor, constant: 0),
                                        self.pendingReturnActivityIndicatorView.widthAnchor.constraint(equalToConstant: 40),
                                        self.pendingReturnActivityIndicatorView.heightAnchor.constraint(equalToConstant: 40),
                                    ])
                                }
                            }
                        }
                        .store(in: &self.storage)
                    break
                default:
                    break
            }
        }
    }

    func createSocket(topics: [String]? = nil) {
        var txHash: String!
        
        guard socketDelegate == nil else { return }
        
        socketDelegate = SocketDelegate(
            contractAddress: auctionContractAddress,
            topics: topics,
            passThroughSubject: PassthroughSubject<[String: Any], PostingError>()
        )
        
        socketDelegate.passThroughSubject
            .flatMap({ (WebSocketMessage) -> AnyPublisher<TransactionReceipt, PostingError> in
                Future<TransactionReceipt, PostingError> { promise in
                    guard let _txHash = WebSocketMessage["transactionHash"] as? String else {
                        promise(.failure(.generalError(reason: "Unable to parse the socket data from the blockchain.")))
                        return
                    }
                    
                    txHash = _txHash
                     
                    print("run")
                    DispatchQueue.global().async {
                        return Web3swiftService.getReceipt(hash: txHash, promise: promise)
                    }
                }
                .eraseToAnyPublisher() 
            })
            .flatMap({ (receipt) -> AnyPublisher<String, PostingError> in
                Future<String, PostingError> { promise in
                    let web3 = Web3swiftService.web3instance
                    guard let contract = web3.contract(integralAuctionABI, at: ContractAddresses.integralAuctionAddress, abiVersion: 2) else {
                        promise(.failure(.generalError(reason: "Unable to get the instance of the auction contract to parse data.")))
                        return
                    }
                    
                    for i in 0..<receipt.logs.count {
                        let parsedEvent = contract.parseEvent(receipt.logs[i])
                     
                        switch parsedEvent.eventName {
                            case "HighestBidIncreased", "AuctionEnded":
                                if let parsedData = parsedEvent.eventData,
                                   let id = parsedData["id"] as? BigUInt {
                                    promise(.success(id.description))
                                } else {
                                    promise(.failure(.emptyResult))
                                }
                                break
                            default:
                                break
                        }
                    }
                    
                    promise(.failure(.emptyResult))
                }
                .eraseToAnyPublisher()
            })
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                    case .failure(let error):
                        switch error {
                            case .generalError(reason: let err):
                                self?.alert.showDetail("Auction Detail Fetch Error", with: err, for: self)
                            case .emptyResult:
                                break
                            default:
                                break
                        }
                    case .finished:
                        break
                }
            }, receiveValue: { [weak self] (id) in
                
                guard let solireyUid = self?.post.solireyUid,
                      let auctionContractAddress = self?.auctionContractAddress,
                      let executeReadTransaction = self?.executeReadTransaction else { return }
                
                // Only refetch data if the Solirey ID pertains the user's own.
                if solireyUid == id {
                    self?.isPending = true
                    self?.getAuctionInfo(
                        transactionHash: txHash,
                        executeReadTransaction: executeReadTransaction,
                        contractAddress: auctionContractAddress
                    )
                }
            })
            .store(in: &storage)
    }
    
    func split(text: String, length: Int) -> [Substring] {
        return stride(from: 0, to: text.count, by: length)
            .map { text[text.index(text.startIndex, offsetBy: $0)..<text.index(text.startIndex, offsetBy: min($0 + length, text.count))] }
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
                
                let contract = web3.contract(individualAuctionABI, at: auctionContractAddress, abiVersion: 2)
                
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

//[
//    "removed": 0,
//    "transactionHash": 0x4387794afb2ee291c800687fddb6198a8993879f7a9e843e254cdba377bb5ef7,
//    "transactionIndex": 0x23,
//    "blockHash": 0xaff20f36e2397659f019449e97e69a83c62c894cde3bbca64319685c3becf779,
//    "address": 0x6d23ebe8d9ff75fe79fc0f4ae4b75b811cad2daa,
//    "topics": <__NSSingleObjectArrayI 0x600001d46190>(0xda0a18da71d8ebd145966339a728fc0d8ccc07c22870d561890d823c515dda6b),
//    "blockNumber": 0x92a28e,
//    "data": 0x00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000b6fcfec0133e77dce6021ff79befad4b3af756400000000000000000000000000000000000000000000000000000012a05f2000,
//    "logIndex": 0x53
//]

//Deferred {
//    Future<TransactionReceipt, PostingError> { promise in
//        Web3swiftService.getReceipt(hash: "0xeabec6558553ca1736efd6269932173b9242493f7f6d82904cca6ac65eaa2951", promise: promise)
//    }
//}
//.sink { (completion) in
//    print(completion)
//} receiveValue: { (receipt) in
//    print("receipt", receipt)
//    let logs = receipt.logs
//    print("logs", logs)
//    
//    let web3 = Web3swiftService.web3instance
//    guard let contract = web3.contract(integralAuctionABI, at: ContractAddresses.integralAuctionAddress, abiVersion: 2) else {
//        return
//    }
//    
//    // Two events will be emitted (AuctionCreated, Transfer).
//    // Following determines which event in the logs array is which so that the order shouldn't matter. i.e. logs[0] could be either AuctionCreated or Transfer.
//    let parsedEvent1 = contract.parseEvent(receipt.logs[0])
//    print("parsedEvent1.eventName", parsedEvent1.eventName)
//    if parsedEvent1.eventName == "HighestBidIncreased" {
//        guard let eventData1 = parsedEvent1.eventData,
//              let id = eventData1["id"] as? BigUInt else {
//            return
//        }
//        
//        print("id", id)
//    }
//}
