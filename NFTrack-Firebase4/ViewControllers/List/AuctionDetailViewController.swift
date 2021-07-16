//
//  AuctionDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-13.
//

import UIKit
import Combine
import web3swift
import BigInt

enum AuctionProperties: String, CaseIterable {
    case startingBid
    case highestBid
    case highestBidder
    case auctionEndTime
    
    static func allCasesString() -> [String] {
        return AuctionProperties.allCases.map { $0.rawValue }
    }
    
    func asFormattedString() -> String {
        switch self {
            case .startingBid:
                return "Starting Bid"
            case .highestBid:
                return "Highest Bid"
            case .highestBidder:
                return "Highest Bidder"
            case .auctionEndTime:
                return "Auction End Time"
        }
    }
}

class AuctionDetailViewController: ParentDetailViewController {    
    final var historyVC: HistoryViewController!
    lazy final var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    final var auctionDetailTitleLabel: UILabel!
    final var auctionDetailRefreshButton: UIButton!
    final var auctionSpecView: SpecDisplayView!
    final var storage = Set<AnyCancellable>()
    final var bidContainer: UIView!
    final var bidTextField: UITextField!
    final var auctionButton: UIButton!
    final var auctionContractAddress: EthereumAddress!
    final let LIST_DETAIL_MARGIN: CGFloat = 10
    final var propertiesToRead: [String]!
    lazy final var auctionDetailArr: [SpecDetailModel] = propertiesToRead.map { SpecDetailModel(propertyName: $0, propertyDesc: "loading...")}
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.propertiesToRead = AuctionProperties.allCasesString()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if let container = container as? HistoryViewController {
            // the height of the child VC's view has to be increased accordingly since it's set to be unscrollable.
            // this is so that the child VC's view doesn't scroll independently of the parent VC's view.
            historyVCHeightConstraint.constant = container.preferredContentSize.height
            
            var adjustedSize: CGSize!
            if let files = post.files, files.count > 0 {
                adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1500)
            } else {
                adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1250)
            }
            
            self.scrollView.contentSize =  adjustedSize
        }
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        getAuctionInfo()
    }
}

extension AuctionDetailViewController: UITextFieldDelegate {
    final override func configureUI() {
        super.configureUI()
        self.hideKeyboardWhenTappedAround()

        historyVC = HistoryViewController()
        historyVC.itemIdentifier = post.id
        addChild(historyVC)
        historyVC.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyVC.view)
        historyVC.didMove(toParent: self)
        
        auctionDetailTitleLabel = createTitleLabel(text: "Auction Detail")
        auctionDetailTitleLabel.isUserInteractionEnabled = true
        scrollView.addSubview(auctionDetailTitleLabel)
        
        guard let refreshImage = UIImage(systemName: "arrow.clockwise") else { return }
        auctionDetailRefreshButton = UIButton.systemButton(with: refreshImage, target: self, action: #selector(buttonPressed(_:)))
        auctionDetailRefreshButton.tag = 2
        auctionDetailRefreshButton.translatesAutoresizingMaskIntoConstraints = false
        auctionDetailTitleLabel.addSubview(auctionDetailRefreshButton)
        
        auctionSpecView = SpecDisplayView(listingDetailArr: auctionDetailArr)
        auctionSpecView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(auctionSpecView)
        
        bidContainer = UIView()
        bidContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(bidContainer)
        
        bidTextField = createTextField(placeHolder: "In ETH", delegate: self)
        bidTextField.keyboardType = .decimalPad
        bidContainer.addSubview(bidTextField)
        
        auctionButton = UIButton()
        auctionButton.backgroundColor = .black
        auctionButton.layer.cornerRadius = 5
        auctionButton.tag = 1
        auctionButton.setTitle("Bid Now", for: .normal)
        auctionButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        auctionButton.translatesAutoresizingMaskIntoConstraints = false
        bidContainer.addSubview(auctionButton)
    }
    
    final override func setConstraints() {
        super.setConstraints()
        NSLayoutConstraint.activate([
            auctionDetailTitleLabel.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            auctionDetailTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            auctionDetailTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            auctionDetailRefreshButton.trailingAnchor.constraint(equalTo: auctionDetailTitleLabel.trailingAnchor),
            auctionDetailRefreshButton.heightAnchor.constraint(equalToConstant: 40),
            auctionDetailRefreshButton.topAnchor.constraint(equalTo: auctionDetailTitleLabel.topAnchor, constant: -10),
            
            auctionSpecView.topAnchor.constraint(equalTo: auctionDetailTitleLabel.bottomAnchor, constant: 10),
            auctionSpecView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            auctionSpecView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            auctionSpecView.heightAnchor.constraint(equalToConstant: CGFloat(auctionDetailArr.count) * LIST_DETAIL_HEIGHT + LIST_DETAIL_MARGIN),
            
            bidContainer.topAnchor.constraint(equalTo: auctionSpecView.bottomAnchor, constant: 40),
            bidContainer.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            bidContainer.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            bidContainer.heightAnchor.constraint(equalToConstant: 50),
            
            bidTextField.leadingAnchor.constraint(equalTo: bidContainer.leadingAnchor),
            bidTextField.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 0.45),
            bidTextField.heightAnchor.constraint(equalTo: bidContainer.heightAnchor),
            
            auctionButton.trailingAnchor.constraint(equalTo: bidContainer.trailingAnchor),
            auctionButton.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 0.45),
            auctionButton.heightAnchor.constraint(equalTo: bidContainer.heightAnchor),
            
            historyVC.view.topAnchor.constraint(equalTo: auctionButton.bottomAnchor, constant: 40),
            historyVC.view.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyVC.view.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            historyVCHeightConstraint,
        ])
    }
    
    @objc final func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 1:
                bid()
                break
            case 2:
                // refresh auction detail
                print("refresh")
                break
            default:
                break
        }
    }
    
    final func bid() {
        guard let bidAmount = bidTextField.text, !bidAmount.isEmpty else {
            self.alert.showDetail("Bid Amount Error", with: "The bid amount cannot be empty.", for: self)
            return
        }
        
        guard Double(bidAmount) != nil else {
            self.alert.showDetail("Bid Format Error", with: "The bid amount has to be in a numeric form", for: self)
            return
        }
        
        guard let bidAmountNumber = NumberFormatter().number(from: bidAmount), bidAmountNumber.doubleValue > 0 else {
            self.alert.showDetail("Bid Amount Error", with: "The bid amount has to be greater than zero.", for: self)
            return
        }
        
        let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
        detailVC.titleString = "Enter your passcode"
        detailVC.buttonAction = { [weak self] vc in
            guard let `self` = self else { return }
            if let dvc = vc as? DetailViewController, let password = dvc.textField.text {
                self.dismiss(animated: true, completion: {
                    guard let auctionContractAddress = self.auctionContractAddress else {
                        self.alert.showDetail("Error", with: "Unable to retrieve the address for the auction contract.", for: self)
                        return
                    }
                    
//                    self.transactionService.prepareTransactionForWriting(method: "bid", abi: auctionABI, contractAddress: auctionContractAddress, amountString: bidAmount) { (transaction, error) in
//                        if let error = error {
//                            self.alert.showDetail("Error", with: error.localizedDescription, for: self)
//                        }
//                        
//                        if let transaction = transaction {
//                            DispatchQueue.global(qos: .utility).async {
//                                do {
//                                    let result = try transaction.send(password: password, transactionOptions: nil)
//                                    print("result", result)
//                                } catch {
//                                    self.alert.showDetail("Transaction Error", with: error.localizedDescription, for: self)
//                                }
//                            }
//                        }
//                    }
                    Future<WriteTransaction, PostingError> { promise in
                        self.transactionService.prepareTransactionForWriting(method: "bid", abi: auctionABI, contractAddress: auctionContractAddress, amountString: bidAmount, promise: promise)
                    }
                    .eraseToAnyPublisher()
                    .flatMap { (transaction) -> Future<TxResult, PostingError> in
                        self.transactionService.executeTransaction(transaction: transaction, password: password, type: .deploy)
                    }
                    .sink { (completion) in
                        switch completion {
                            case .failure(let error):
                                print("error", error)
                                switch error {
                                    case .generalError(reason: let msg):
                                        self.alert.showDetail("Error", with: msg, for: self)
                                    default:
                                        break
                                }
                                break
                            case .finished:
                                print("finished")
                                break
                        }
                    } receiveValue: { (txResult) in
                        print("txResult", txResult)
                    }
                    .store(in: &self.storage)
                })
            }
        }
        self.present(detailVC, animated: true, completion: nil)
    }
}

// starting bid
// current highest bid
// current highest bidder
// auction end time
// bid button
extension AuctionDetailViewController {
    final func getAuctionInfo() {
        guard let auctionHash = post.auctionHash else {
            self.alert.showDetail("Error", with: "Could not load the transaction hash for the auction contract deployment.", for: self)
            return
        }
        
        Future<TransactionReceipt, PostingError> { promise in
            Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
        }
        .receive(on: DispatchQueue.global(qos: .utility))
        .eraseToAnyPublisher()
        .flatMap { [weak self] (receipt) -> AnyPublisher<[PropertyFetchModel], PostingError>  in
            guard let contractAddress = receipt.contractAddress else {
                return Fail(error: PostingError.generalError(reason: "Could not obtain the auction contract."))
                    .eraseToAnyPublisher()
            }

            guard let `self` = self else {
                return Fail(error: PostingError.generalError(reason: "Error"))
                    .eraseToAnyPublisher()
            }
                
            self.auctionContractAddress = contractAddress
            guard let propertiesToRead = self.propertiesToRead else {
                return Fail(error: PostingError.generalError(reason: "Unable to load the properties to read"))
                    .eraseToAnyPublisher()
            }
            
            let listOfPrepPublishers = propertiesToRead.map { (propertyToRead) in
                return Future<PropertyFetchModel, PostingError> { promise in
                    self.transactionService.prepareTransactionForReading(method: propertyToRead, abi: auctionABI, contractAddress: contractAddress, promise: promise)
                }
                .receive(on: DispatchQueue.global(qos: .utility))
            }
            return Publishers.MergeMany(listOfPrepPublishers)
                .collect()
                .eraseToAnyPublisher()
        }
        .flatMap { [weak self] (propertyFetchModels) -> AnyPublisher<[PropertyFetchModel], PostingError> in
            let listOfReadPublishers = propertyFetchModels.map { (propertyFetchModel) in
                return Future<PropertyFetchModel, PostingError> { promise in
                    var mutableModel = propertyFetchModel
                    self?.executeReadTransaction(propertyFetchModel: &mutableModel, promise: promise)
                }
                .receive(on: DispatchQueue.global(qos: .utility))
                .eraseToAnyPublisher()
            }
            return Publishers.MergeMany(listOfReadPublishers)
                .collect()
                .eraseToAnyPublisher()
        }
        .tryMap ({ [weak self] (propertyFetchModels) -> [PropertyFetchModel] in
            print("self?.propertiesToRead.count", self?.propertiesToRead.count as Any)
            print("propertyFetchModels.count", propertyFetchModels.count)
            if propertyFetchModels.count != self?.propertiesToRead.count {
                throw PostingError.generalError(reason: "Couldn't fetch the auction properties.")
            } else {
                return propertyFetchModels
            }
        })
        .retryWithDelay(retries: 5, delay: 1, scheduler: DispatchQueue.global())
        .sink { (completion) in
            switch completion {
                case .failure(let error):
                    print("error", error)
                    break
                case .finished:
                    print("finished")
                    break
            }
        } receiveValue: { [weak self] (propertyFetchModels) in
            DispatchQueue.main.async {
                if self?.propertiesToRead.count == propertyFetchModels.count  {
                    self?.auctionSpecView.fetchedDataArr = propertyFetchModels
                }
            }
        }
        .store(in: &storage)
    }

    final func executeReadTransaction(propertyFetchModel: inout PropertyFetchModel, promise: (Result<PropertyFetchModel, PostingError>) -> Void) {
        do {
            let result: [String: Any] = try propertyFetchModel.transaction.call()
            switch AuctionProperties(rawValue: propertyFetchModel.propertyName) {
                case .startingBid:
                    if let startingBid = result["0"] as? BigUInt,
                       var bidInEth = Web3.Utils.formatToEthereumUnits(startingBid, toUnits: .eth, decimals: 8) {

                        var index = bidInEth.index(before: bidInEth.endIndex)
                        while bidInEth[index] == "0" {
                            bidInEth.removeLast()
                            index = bidInEth.index(before: bidInEth.endIndex)
                        }
                                                
                        propertyFetchModel.propertyDesc = "\(bidInEth.description) ETH"
                    }
                case .auctionEndTime:
                    if let auctionEndTime = result["0"] as? BigUInt {
                        
                        let date = Date(timeIntervalSince1970: Double(auctionEndTime))
                        
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        formatter.dateStyle = .short
                        formatter.timeZone = .current
                        let formattedDate = formatter.string(from: date)
                        propertyFetchModel.propertyDesc = formattedDate
                    }
                case .highestBid:
                    if let startingBid = result["0"] as? BigUInt,
                       let bidInEth = Web3.Utils.parseToBigUInt(startingBid.description, units: .eth) {
                        
                        propertyFetchModel.propertyDesc = "\(bidInEth.description) ETH"
                    }
                case .highestBidder:
                    if let propertyDesc = result["0"] as? EthereumAddress {
                        propertyFetchModel.propertyDesc = propertyDesc.address
                    }
                default:
                    break
            }
            
            promise(.success(propertyFetchModel))
        } catch {
            promise(.failure(.generalError(reason: "Could not read the properties from the blockchain.")))
        }
    }
}

extension Publisher {
    func retryWithDelay<S>(
        retries: Int,
        delay: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        self
            .delayIfFailure(for: delay, scheduler: scheduler)
            .retry(retries)
            .eraseToAnyPublisher()
    }
    
    private func delayIfFailure<S>(
        for delay: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        self.catch { error in
            Future { completion in
                scheduler.schedule(after: scheduler.now.advanced(by: delay)) {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

