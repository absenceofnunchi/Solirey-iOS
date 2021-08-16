//
//  AuctionDetailViewController + Properties Parse.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-04.
//

import UIKit
import Combine
import web3swift
import BigInt

// starting bid
// current highest bid
// current highest bidder
// auction end time
extension AuctionDetailViewController {
    final func getAuctionInfo(
        transactionHash: String,
        executeReadTransaction: @escaping (_ propertyFetchModel: inout SmartContractProperty, _ promise: (Result<SmartContractProperty, PostingError>) -> Void) -> Void,
        contractAddress: EthereumAddress
    ) {
        //        guard let auctionHash = post.auctionHash else { return }
        
        let auctionInfoLoader = PropertyLoader<AuctionContract>(
            propertiesToLoad: self.propertiesToLoad,
            transactionHash: transactionHash,
            executeReadTransaction: executeReadTransaction,
            contractAddress: contractAddress,
            contractABI: auctionABI
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
                case AuctionContract.ContractProperties.startingBid.value.0:
                    if let startingBid = result["0"] as? BigUInt,
                       let bidInEth = Web3.Utils.formatToEthereumUnits(startingBid, toUnits: .eth, decimals: 9) {
                        // remove the unnecessary zeros in the decimal
                        let trimmed = self.transactionService.stripZeros(bidInEth)
                        propertyFetchModel.propertyDesc = "\(trimmed) ETH"
                    }
                case AuctionContract.ContractProperties.auctionEndTime.value.0:
                    if let auctionEndTime = result["0"] as? BigUInt {
                        let date = Date(timeIntervalSince1970: Double(auctionEndTime))
                        propertyFetchModel.propertyDesc = date
                    }
                case AuctionContract.ContractProperties.highestBid.value.0:
                    if let highestBid = result["0"] as? BigUInt {
                        if let converted = Web3.Utils.formatToEthereumUnits(highestBid, toUnits: .eth, decimals: 9) {
                            let trimmed = transactionService.stripZeros(converted)
                            propertyFetchModel.propertyDesc = "\(trimmed) ETH"
                        }
                    }
                case AuctionContract.ContractProperties.highestBidder.value.0:
                    if let propertyDesc = result["0"] as? EthereumAddress {
                        if propertyDesc.address == "0x0000000000000000000000000000000000000000" {
                            propertyFetchModel.propertyDesc = "No Bidder"
                        } else {
                            propertyFetchModel.propertyDesc = propertyDesc.address
                        }
                    }
                case AuctionContract.ContractProperties.ended.value.0:
                    if let ended = result["0"] as? Bool {
                        propertyFetchModel.propertyDesc = ended
                    }
                case AuctionContract.ContractProperties.pendingReturns(self.contractAddress).value.0:
                    if let pendingReturns = result["0"] as? BigUInt,
                       let converted = Web3.Utils.formatToEthereumUnits(pendingReturns, toUnits: .eth, decimals: 9) {
                        let trimmed = self.transactionService.stripZeros(converted.description)
                        propertyFetchModel.propertyDesc = trimmed
                    }
                case AuctionContract.ContractProperties.beneficiary.value.0:
                    if let propertyDesc = result["0"] as? EthereumAddress {
                        if propertyDesc.address == "0x0000000000000000000000000000000000000000" {
                            propertyFetchModel.propertyDesc = "N/A"
                        } else {
                            propertyFetchModel.propertyDesc = propertyDesc.address
                        }
                    }
                default:
                    break
            }
            
            promise(.success(propertyFetchModel))
        } catch {
            promise(.failure(.generalError(reason: "Could not read the properties from the blockchain.")))
        }
    }
    
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
        
        auctionSpecView.stackView.arrangedSubviews.enumerated().forEach { [weak self] (index, element) in
            guard let self = self else { return }
            let specDetail = propertyFetchModels[index]
            
            /// tag 1 refers to the property name such as "Highest Bid", this is only in case you want to modify the name. the property name is already provided in propertiesToLoad
            /// tag 2 refers to the property value such as "2 ether"
            for case let subview as UILabel in element.subviews where subview.tag == 2 {
                switch specDetail.propertyName {
                    // show the info button when the pending return value is 0
                    case AuctionContract.ContractProperties.pendingReturns(self.contractAddress).value.0 where specDetail.propertyDesc as? String == "0":
                        subview.text = specDetail.propertyDesc as? String
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
                            pendingReturnButton.centerYAnchor.constraint(equalTo: subview.centerYAnchor),
                            pendingReturnButton.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: 0),
                            pendingReturnButton.widthAnchor.constraint(equalToConstant: 40),
                        ])
                        
                        NSLayoutConstraint.activate(pendingReturnButtonConstraints)
                        
                        UIView.animate(withDuration: 0.5) { [weak self] in
                            self?.pendingReturnButton.alpha = 1
                        }
                        
                        print("1")
                        break
                    // show the pending return button when there is a non-zero value to be returned
                    case AuctionContract.ContractProperties.pendingReturns(self.contractAddress).value.0 where specDetail.propertyDesc as? String != "0":
                        subview.text = specDetail.propertyDesc as? String

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
                            pendingReturnButton.centerYAnchor.constraint(equalTo: subview.centerYAnchor),
                            pendingReturnButton.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: -12),
                            pendingReturnButton.widthAnchor.constraint(equalToConstant: 70),
                        ])
                        
                        NSLayoutConstraint.activate(pendingReturnButtonConstraints)
                                                
                        UIView.animate(withDuration: 0.5) { [weak self] in
                            self?.pendingReturnButton.alpha = 1
                        }
                        
                        print("2")
                        NotificationCenter.default.publisher(for: .auctionDidWithdraw)
                            .compactMap { $0.object as? Bool }
                            .sink { [weak self] (isWithdrawPending) in
                                if isWithdrawPending == true {
//                                    DispatchQueue.main.async {
//                                        self?.pendingReturnButton.isEnabled = false
//                                        self?.pendingReturnButton.isHidden = true
//                                    }

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
                                            self.pendingReturnActivityIndicatorView.centerYAnchor.constraint(equalTo: subview.centerYAnchor),
                                            self.pendingReturnActivityIndicatorView.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: 0),
                                            self.pendingReturnActivityIndicatorView.widthAnchor.constraint(equalToConstant: 40),
                                            self.pendingReturnActivityIndicatorView.heightAnchor.constraint(equalToConstant: 40),
                                        ])
                                    }
                                }
                            }
                            .store(in: &self.storage)
                        break
                    case AuctionContract.ContractProperties.highestBidder.value.0 where specDetail.propertyDesc is String:
                        guard let highestBidder = specDetail.propertyDesc as? String else { return }
                        auctionButtonController.highestBidder = highestBidder
                        
                        if highestBidder == self.contractAddress.address {
                            subview.text = "You"
                        } else {
                            subview.text = specDetail.propertyDesc as? String
                        }
                    case AuctionContract.ContractProperties.ended.value.0 where specDetail.propertyDesc is Bool:
                        guard let status = specDetail.propertyDesc as? Bool else { return }
                        subview.text = status == false ? "Active" : "Ended"
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
                            statusInfoButton.centerYAnchor.constraint(equalTo: subview.centerYAnchor),
                            statusInfoButton.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: 0),
                            statusInfoButton.widthAnchor.constraint(equalToConstant: 40),
                        ])
                        
                        UIView.animate(withDuration: 0.5) {
                            statusInfoButton.alpha = 1
                        }
                        break
                    case AuctionContract.ContractProperties.auctionEndTime.value.0 where specDetail.propertyDesc is Date:
                        guard let propDesc = specDetail.propertyDesc as? Date else { return }
                        auctionButtonController.auctionEndTime = propDesc
                        auctionButtonController.isAuctionEnded = propDesc < Date()
                        
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        formatter.dateStyle = .short
                        formatter.timeZone = .current
                        let formattedDate = formatter.string(from: propDesc)
                        subview.text = formattedDate
                    case AuctionContract.ContractProperties.beneficiary.value.0 where specDetail.propertyDesc is String:
                        guard let benficiary = specDetail.propertyDesc as? String else { return }
                        auctionButtonController.beneficiary = benficiary
                        if benficiary == self.contractAddress.address {
                            subview.text = "You"
                        } else {
                            subview.text = specDetail.propertyDesc as? String
                        }
                    default:
                        subview.text = specDetail.propertyDesc as? String
                        break
                }
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
                
                //                var filter = EventFilter()
                //                filter.fromBlock = .blockNumber(0)
                //                filter.toBlock = .latest
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
