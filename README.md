# Solirey

Solirey demonstrates the use of Ethereum in creating a marketplace for buying and selling services and goods, including both the tangible and digital products. Mint your product on the blockchain and sell away! The use of the blockchain allows various payment forms like escrow and auction that are conducive to the the trust between a buyer and a seller. Users are also able to see the history of transactions on the blockchain, which means the sales history throughout the lifetime of an item can be traced transparently.

## App Store Installation

https://apps.apple.com/tm/app/solirey/id1598768391

## Structure

1. **Front end**: The app generates public/private keys internally, creates public signatures for transactions, and calls methods on smart contracts that have already been deployed. It’s also able to deploy new escrow or auction smart contracts. It queries smart contracts to show the current state of a sale or the history of an item. Finally, it creates and views the reviews of the past sales of a seller and a buyer via Firebase.

2. **Smart contracts**: [A collection of smart contracts](https://github.com/igibliss00/Solirey) involving a ERC721 preset for minting, escrow, auction, and a simplified payment deployed on Rinkeby testnet.

3. **Firebase**: Firebase is used to store offchain data such as the details of products for sale, reviews of buyers and sellers, as well as for the authentication process of a Solirey account for users.

## Payment Methods

### Escrow

An escrow payment method is a collaborative dance between a buyer and seller. When a seller posts an item for sale, a deposit is made into an escrow smart contract for the amount that matches the price of the item.  For example, if the cost of an item is 1 ETH, then the deposit is 1 ETH as well.  The deposit in the escrow is to incentivize the seller to represent the item as accurately as possible in the post as well as to ship the item expediently upon the purchase order. 

When a buyer pays for the item, the buyer also deposits an amount that matches the price of the item in the escrow smart contract.  This is to incentivize the buyer to truthfully confirm the receipt of the product as well as the condition of the product.  Only when the buyer confirms the receipt of the item in a satisfactory manner, the buyer receives the deposit back from the smart contract and the seller receives the deposit as well as the payment from the buyer.

The state of an escrow sale could be categorized into 6 phases. Each phase determines whether a post is displayed to the users, a buyer could put in a purchase order, whose turn it is to call a smart contract method, etc:

```swift
// MARK: - PostStatus
/// when the seller first posts: ready
/// when the seller aborts: aborted
/// when the buyer buys: pending
/// when the seller transfers the token: transferred
/// when the transaction is complete: complete
enum PostStatus: String {
    case ready, pending, aborted, complete, resold, transferred
    
    var toDisplay: String! {
        switch self {
            case .pending:
                return "Purchased"
            case .transferred:
                return "Transferred"
            case .complete:
                return "Received"
            default:
                return "Ready"
        }
    }
}
```

1. **Ready**: A seller creates a post regarding an item and updates the status to `createEscrow`.  A new ERC721 token is minted and the meta data of the item is stored in Firebase:
```swift
    func escrowIntegral(_ mintParameters: MintParameters, price: String, isResale: Bool = false) {
        /// Estimates the total cost of the gas, calculates the total amount of ETH required for the deposit, and compares them against the available ETH in the wallet
        /// The function is made generic and modular so that it can be used for other forms of payments like wallet-to-wallet or auction.
        self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
            guard let getIntegralEscrowEstimate = self?.getIntegralEscrowEstimate else {
                return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                    .eraseToAnyPublisher()
            }
            return getIntegralEscrowEstimate(.createEscrow, price, isResale)
            
        }) { [weak self] (estimates, txPackage, error) in
            if let error = error {
                self?.processFailure(error)
            }
            
            if let estimates = estimates,
               let txPackage = txPackage {
                
                /// Execute the transaction by minting a ERC721 token pertaining to the item as well as transferring the deposit into an escrow.
                /// If the transaction is for resale, the ERC721 token has to be carried over, not newly minted.
                if isResale == false {
                    self?.executeIntegralEscrow(
                        estimates: estimates,
                        mintParameters: mintParameters,
                        txPackage: txPackage
                    )
                } else {
                    self?.executeIntegralEscrowResale(
                        estimates: estimates,
                        mintParameters: mintParameters,
                        txPackage: txPackage
                    )
                }
            }
        }
    }
```

2. **Aborted**: The seller can choose to abort the sale and receive the deposit back given that no purchase order has been made by a buyer.
```swift
FirebaseService.shared.db.collection("post").document(documentId).updateData([
    "status": PostStatus.aborted.rawValue,
    "\(method.rawValue)Hash": txPackage.txResult.hash,
    "\(method.rawValue)Date": Date()
], completion: { (error) in
    successMsg = "You have aborted the sale. The deployed contract is now locked and your deposit will be sent back to your wallet."
    promise(.success(txPackage.txResult.hash))
    })
```

3. **Pending**: If the seller doesn't abort and proceeds with the sale process, a buyer is able to request to purchase the item. 
```swift
DispatchQueue.global().async { [weak self] in
    do {
        /// Fetch the current balance of the user's wallet
        let balance = try Web3swiftService.web3instance.eth.getBalance(address: address)
        guard let balanceString = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth, decimals: 17),
              let convertedBalance = Double(balanceString) else {
            return
        }
        
        DispatchQueue.main.async {
            /// Confirm that the balance is sufficient to cover the price of the item + deposit
            if convertedBalance > priceWithDeposit {
                self?.alert.showDetail(
                    "Deposit Required",
                    with: "The escrow requires paying a deposit equaling the price of the item, which will be reverted back to your wallet upon receiving the item. The deposits by both the seller and the buyer incentivize the transaction to completed in an efficient manner. \n\nWould you like to proceed?",
                    for: self,
                    alertStyle: .withCancelButton) {
                        /// Proceed with purchase by calling a smart contract method that transfers the deposit + price of the item and updates the status of the sale.
                        self?.confirmPurchase(finalPrice.stringValue)
                    } completion: {}
            } else {
                self?.alert.showDetail(
                    "Insufficient Balance",
                    with: "Escrow requires a deposit equaling the amount of the price: \n\nBalance: \(balanceString)\nPrice + Deposit: \(price) * 2",
                    for: self
                )
            }
        }
    } catch {
        self?.alert.showDetail("Error", with: "Unable to fetch the wallet balance.", for: self)
    }
}
```

4. **Transferred**: The transfer process happens in two parts.  First, the seller ships the item physically to the buyer.  Second, the seller transfers the ERC721 token to the buyer by calling the `transferFrom` method on the smart contract.  The order in which the two-step process happens is irrelevant. 
```swift
func transferToken(method: SolireyContract.ContractMethods) {
    self.transactionService.preLaunch (transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
        /// Estimate the total cost of the transaction and compare it to the balance in the wallet
        guard let getSolireyMethodEstimate = self?.transactionService.getSolireyMethodEstimate else {
            return Fail(error: PostingError.generalError(reason: "Unable to estimate gas."))
                .eraseToAnyPublisher()
        }
        
        /// Obtain the ERC721 token ID to be transferred
        guard let tokenId = self?.post.tokenID else {
            return Fail(error: PostingError.generalError(reason: "Unable to get the ID for the smart contract."))
                .eraseToAnyPublisher()
        }
        
        /// Obtain the address of the seller
        guard let currentAddress = Web3swiftService.currentAddress else {
            return Fail(error: PostingError.generalError(reason: "Unable to fetch the user's current wallet address."))
                .eraseToAnyPublisher()
        }
        
        /// Obtain the address of the buyer
        guard let buyerAddressString = self?.post.buyerHash,
              let buyerAddress = EthereumAddress(buyerAddressString) else {
            return Fail(error: PostingError.generalError(reason: "Unable to fetch the buyer's wallet address."))
                .eraseToAnyPublisher()
        }
        
        /// Convert the information into a proper transaction format
        let transactionParameters: [AnyObject] = [currentAddress, buyerAddress, tokenId] as [AnyObject]
        return getSolireyMethodEstimate(method, transactionParameters)
        
    }) { [weak self] (estimates, txPackage, error) in
        if let error = error {
            self?.processFailure(error)
        }
        
        if let estimates = estimates,
           let txPackage = txPackage {
            
            /// Execute the transfer by creating a transaction and sending it to blockchain
            self?.executeSolirey(
                estimates: estimates,
                txPackage: txPackage,
                method: method
            )
        }
    }
}
```

5. **Complete**: The final step is for the buyer to confirm the receipt of the item.  If the condition of the item is to the buyer's satisfaction, then the buyer calls the `confirmReceived` method on the escrow contract.  Each participant in this transaction gets their share of the payout and the transaction is deemed finalized. 
```solidity
function confirmReceived(uint id) external inState(State.Locked, id) {
    // Only the buyer is authorized to call this method
    require(msg.sender == _escrowInfo[id].buyer, "Unauthorized");
    
    // Send the event notifying the execution to any listeners 
    emit ItemReceived(id);
    // Convert the status of the sale as inactive
    _escrowInfo[id].state = State.Inactive;
    
    // Calculate the payments for each participant 
    uint value = _escrowInfo[id].value;
    uint fee = value * 2 / 100;
    uint payment = value * 3 - (fee * 2);
    
    // Transfer the residual payment to the original owner of the item in case this is a resale
    address artist = solirey._artist(_escrowInfo[id].tokenId);
    payable(artist).transfer(fee);
    
    // Transfer the payment to the admin, buyer, and the seller
    solirey.admin().transfer(fee);
    _escrowInfo[id].seller.transfer(payment);
    _escrowInfo[id].buyer.transfer(value);
}
```

### Auction 

Whereas escrow is only used for the sales of tangible (non-digital) items, auction is only used for digital items. Broadly speaking, this auction happens in a 4-step process: listing the item to be sold, bidding, transfer of the item, and the payout. 

```swift
enum AuctionStatus: String {
    case ready, aborted, bid, ended, transferred, resell
    
    var toDisplay: String! {
        switch self {
            case .bid:
                return "Bid"
            case .ended:
                return "Auction Ended"
            case .transferred:
                return "Transferred"
            case .aborted:
                return "Aborted"
            case .resell:
                return "Resell"
            default:
                return "ready"
        }
    }
}
```

1. **Ready**: A seller lists an item to be auctioned by minting an ERC721 token, setting the floor price and the auction expiry date, and transferring the token into a pre-existing auction smart contract.
```swift
self.transactionService.preLaunch(transactionToEstimate: { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
    /// Create transaction parameters involving the bidding expirty date and the starting bid
    let transactionParameters: [AnyObject] = [biddingTime, startingBid] as [AnyObject]
    
    /// Calculate the total cost of the transaction
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
        
        /// Execute the transaction by calling the minting function on a smart contract and transferring the token to a auction smart contract
        self?.executeIntegralAuction(
            estimates: estimates,
            mintParameters: mintParameters,
            txPackage: txPackage
        )
    }
}
```
In order to obtain the token ID of the newly minted item to be saved in Firebase, a web socket is created to listen to the event log.  Once the event log is captured, it is filtered by a transaction hash and parsed to extract the token ID from the JSON data.
```swift
/// Create a web socket for the auction contract address filtered by a topic
self?.socketDelegate = SocketDelegate(contractAddress: solireyContractAddress, topics: [Topics.Solirey.transfer])
self?.socketDelegate.didReceiveTopics = { webSocketMessage in
    /// Extract topics and the transaction hash from the event log emitted by the transfer method on the smart contract
    guard let topics = webSocketMessage["topics"] as? [String],
          let txHash = webSocketMessage["transactionHash"] as? String else { return }
    
    /// Extract the token ID located in one of the topics
    let paddedTokenId = topics[3]
    
    /// Eliminate the padded 0's from the topic
    guard let tokenId = Web3Utils.hexToBigUInt(paddedTokenId) else {
        promise(.failure(.generalError(reason: "Unable to parse the newly minted token ID.")))
        return
    }
    
    /// Filter by a desired transaction hash
    if txPackage.txResult.hash == txHash {
        promise(.success((txPackage: txPackage, tokenId: tokenId.description)))
    }
}
```

2. **Bid**: Given that the auction is not expired and the bid is higher than the minium price, a potential buyer bids on an item by creating transaction and calling the `bid` method on the auction smart contract.
```swift
if method == .bid {
    /// Convert the bidding amount to the proper format and confirm that it's higher than the required minimum bid amount.
    guard let amountString = amountString,
          let bidAmount = Double(amountString),
          let startingBid = Double(startingBidRetainer),
          bidAmount >= startingBid else {
        guard let startingBidRetainer = startingBidRetainer else { return }
        let stripped = self.transactionService.stripZeros(startingBidRetainer)
        self.alert.showDetail("Insufficient Bid Amount", with: "The minimum bid amount is \(stripped) ETH.", for: self)
        return
    }
}
/// Prepare the pertinent token ID for the item to bid on
let parameters: [AnyObject] = [post.solireyUid] as [AnyObject]
/// Estimate the total gas and create a transaction to call the bid method on the auction smart contract
self.transactionService.preLaunch { [weak self] () -> AnyPublisher<TxPackage, PostingError> in
    Future<TxPackage, PostingError> { promise in
        self?.transactionService.prepareTransactionForWritingWithGasEstimate(
            method: method.rawValue,
            abi: integralAuctionABI,
            param: parameters,
            contractAddress: integralAuctionAddress,
            amountString: amountString ?? "0",
            promise: promise
        )
    }
    .eraseToAnyPublisher()
} completionHandler: { [weak self] (estimates, txPackage, error) in
    if let error = error {
        self?.processFailure(error)
    }
    /// parse the result
}
```
The bidding information is broadcast to all the users who have previously bid on the item and update Firebase.
```swift
/// lets every user involved in the auction (who has previously bid before) know through the push notification that there's been a new bid
let fcmToken = UserDefaults.standard.string(forKey: UserDefaultKeys.fcmToken)
/// The bidding status update will be reflected on GUI
self?.db.collection("post").document(documentId).updateData([
    "bidderTokens": FieldValue.arrayUnion([fcmToken ?? ""]),
    "bidders": FieldValue.arrayUnion([userId]),
    "status": AuctionStatus.bid.rawValue,
    "bidDate": Date(),
    "bidderWalletAddress": [currentAddress: userId]
], completion: { (error) in
    if let error = error {
        print("firebase error", error)
    }
})
/// unsubscribe so that you don't get the push notification for your own update
/// but later resubscribe for the notification for the counterparty
/// firebase doesn't have a way to opt out of the notification directed at yourself
Messaging.messaging().unsubscribe(fromTopic: documentId) { error in
    print("unsubscribed to \(self?.post.documentId ?? "")")
}
return FirebaseService.shared.sendToTopics(
    title: "Auction Bid",
    content: "A new bid was made in your auction.",
    topic: documentId,
    docId: documentId
    )
```
3. **Transferred**: The official end of the auction happens after the expiry date when the `auctionEnd` method is called.
```solidity
function auctionEnd(uint id) external {
    AuctionInfo storage ai = _auctionInfo[id];
    /// confirm that the auction expiry date has passed.
    require(block.timestamp >= ai.auctionEndTime, "Auction has not yet ended");
    require(ai.ended == false, "Already ended");
    
    /// Mark the auction as ended
    _auctionInfo[id].ended = true;
    
    /// Transfer the token to the highest bidder. If none, then transfer the token back to the seller.
    if (ai.highestBidder != address(0)) {
        solirey.transferFrom(address(this), ai.highestBidder, ai.tokenId);
    } else {
        solirey.transferFrom(address(this), ai.beneficiary, ai.tokenId);
    }
    
    /// Emit the end event
    emit AuctionEnded(id);
}
```
The beneficiary, who is the seller, can withdraw the final bid amount by calling the `getTheHighestBid` method on the contract.

### Simple Payment

A wallet-to-wallet payment option is available for when a certain level of trust between a buyer and a seller already exists.

```swift
Deferred {
    Future<TxPackage, PostingError> { [weak self] promise in
        /// Prepare a transaction to estimate the cost of gas
        self?.transactionService.prepareTransactionForWritingWithGasEstimate(
            method: method.rawValue,
            abi: isDigital ? integralDigitalSimplePaymentABI : integralTangibleSimplePaymentABI,
            param: param,
            contractAddress: isDigital ? integralDigitalSimplePaymentAddress : integralTangibleSimplePaymentAddress,
            amountString: price,
            promise: promise
        )
    }
    .eraseToAnyPublisher()
}
.flatMap({ [weak self] (txPackage) -> AnyPublisher<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> in
    self?.txPackageRetainer = txPackage
    /// Estimate the total cost of gas for the transaction
    return Future<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> { promise in
        self?.transactionService.estimateGas(gasEstimate: txPackage.gasEstimate, promise: promise)
    }
    .eraseToAnyPublisher()
})
.sink {[weak self] (completion) in
    switch completion {
        case .failure(let error):
            self?.processFailure(error)
        default:
            break
    }
} receiveValue: { [weak self] (estimates) in
    self?.hideSpinner()
    /// Execute the wallet-to-wallet transfer including the token transfer
    self?.executeTransaction(estimates: estimates, method: method)
}
.store(in: &storage)
```

## Smart Contract Query

When working with the Ethereum blockchain, one of the tricky aspects is the asynchronous nature of the transactions.  From the moment a transaction is submitted, being selected by a miner in a mempool, the Ethash calculation, being added to a block, and all the way to the propagation, the lifecycle of a transaction takes an indeterminate amount of time.  

Moreover, certain features like notifying when a contract deployment has been completed is not natively provided.  There can also be a downright failure on the node’s part to respond to requests.  A common solution is to deal with contingencies from the front end.  

I came across instances where the receipt of a transaction is not delivered timely after the submission of a transaction.  Following is the solution I came up with using Combine.

```swift
/// Get the receipt from the hash of the transaction.
/// The receipt doesn't appear right away after the transaction which means repeatedly query until the receipt is ready.
/// Retry for 25 times with 5 seconds of delay in between
final func confirmReceipt( txHash: String) -> AnyPublisher<TransactionReceipt, PostingError> {
    Deferred {
        Future<TransactionReceipt, PostingError> { promise in
            Web3swiftService.getReceipt(hash: txHash, promise: promise)
        }
    }
    .retryIfWithDelay(
        retries: 25,
        delay: .seconds(5),
        scheduler: DispatchQueue.global()
    ) { (error) -> Bool in
        // the tx hash returns no receipt right after the transaction
        // retry if none returns, but with delay
        if case let PostingError.generalError(reason: msg) = error,
           msg == "Invalid value from Ethereum node" {
            return true
        }
        return false
    }
}
```

Created a modularized and generic object `PropertyLoader` for querying the properties of a smart contract.  It's modularized in the sense that a function to deal with the result of the fetched properties can be externally defined and passed into this object as a closure function.  The generic aspect of the object allows for it to be used for any smart contracts, such as the escrow or the auction contract.

```swift
final func getAuctionInfo(
    transactionHash: String,
    executeReadTransaction: @escaping (_ propertyFetchModel: inout SmartContractProperty, _ promise: (Result<SmartContractProperty, PostingError>) -> Void) -> Void,
    contractAddress: EthereumAddress
) {
    
    /// A generic class PropertyLoader is used with the IntegralAuctionContract type.
    /// The initializer parameters include the properties to query, the transaction hash if it's a newly deployed contract, an closure function to deal with the result of the fetched properties, and finally the address and the ABI of the contract looking to query.
    let auctionInfoLoader = PropertyLoader<IntegralAuctionContract>(
        propertiesToLoad: self.propertiesToLoad,
        transactionHash: transactionHash,
        executeReadTransaction: executeReadTransaction,
        contractAddress: contractAddress,
        contractABI: integralAuctionABI
    )
    
    /// Toggle the isPending property to activate the activity indicator while querying
    isPending = true
    
    /// Create a read transaction and send it to a node.
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
            /// fetched properties
        }
        .store(in: &self.storage)
    }
}
```

## Asynchronous Data Fetch For Table View

Created optimal data fetching for table views. Images are fetched from a remote server, namely Firestore in this case, by the `prefetchRowAt` method.  The fetch requests are added to `Operation` and executed sequentially in the background thread.  Until the images arrive, a placeholder image is shown in place.  When the images do arrive, they are stored in a dictionary form with the indexPath of a cell as the key and the image as the value.

Within the `willDisplay` method, a cell at a particular indexPath first examines the content of NSCache to verify whether an image for this cell exists or not.  If it doesn’t, access the image from the fetched image from the dictionary and update the UI.  Finally, store the image in NSCache.

The view controller is generic so that it can be subclassed and used for different purposes like displaying items for sale or images in a chat.  

```swift
func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let cell = cell as? ParentTableCell<T> else { return }
    
    let updateCellClosure: (UIImage?) -> () = { [weak self] (image) in
        cell.updateAppearanceFor(.fetched(image))
        guard let self = self else { return }
        self.loadingOperations.removeValue(forKey: indexPath)
    }
    
    // Check the cache for an existing image
    if let cachedImage: UIImage = cache[indexPath.row as NSNumber] as? UIImage {
        cell.updateAppearanceFor(.fetched(cachedImage))
        loadingOperations.removeValue(forKey: indexPath)
    } else {
        // No cached image exists so try to find an existing data loader
        if let dataLoader = loadingOperations[indexPath] {
            // Has the data already been loaded?
            if let image = dataLoader.image {
                cell.updateAppearanceFor(.fetched(image))
                loadingOperations.removeValue(forKey: indexPath)
                cache[indexPath.row as NSNumber] = image
            } else {
                // No data loaded yet, so add the completion closure to update the cell once the data arrives
                dataLoader.loadingCompleteHandler = updateCellClosure
            }
        } else {
            // Need to create a data loaded for this index path
            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
                // Provide the completion closure, and kick off the loading operation
                dataLoader.loadingCompleteHandler = updateCellClosure
                loadingQueue.addOperation(dataLoader)
                loadingOperations[indexPath] = dataLoader
            }
        }
    }
}

// 1. The entire data is loaded to the data store
// 2. For every cell, prefetch the Operation that pertains to indexPath.row
// 3. Add the operation to the loading queue (addOperation)
// 4. Add the opertaion to the loadingOperation dictionary
// 5. If the data has been loaded already, delete it form the loadingOperations queue
func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
        if let _ = loadingOperations[indexPath] { return }
        if let dataLoader = dataStore.loadImage(at: indexPath.row) {
            loadingQueue.addOperation(dataLoader)
            loadingOperations[indexPath] = dataLoader
        }
    }
}
```

The `Operation` can be initalized with a URL (or a string URL) and distinguishes between fetching a PDF file or an image file. PDF images will be presented by a placeholder even after downloaded until a user decides to tap on the PDF itself.  This is because the miniaturized PDF doesn’t convey the content as well as the regular images.

```swift
class DataLoadOperation: Operation {
    final var image: UIImage?
    final var loadingCompleteHandler: ((UIImage?) -> ())?
    private var _imageString: String!
    private var _imageURL: URL!
    private var _index: Int!
    
    init(_ imageString: String, at index: Int) {
        _imageString = imageString
        _index = index
    }
    
    init(_ imageURL: URL, at index: Int) {
        _imageURL = imageURL
        _index = index
    }
    
    override func main() {
        if isCancelled { return }
        
        var url: URL!
        if let imageString = _imageString {
            url = URL(string: imageString)
        } else {
            url = _imageURL
        }
        
        if url.pathExtension == "pdf" {
            guard let _image = UIImage(systemName: "doc.circle") else { return }
            let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .light, scale: .small)
            let configuredImage = _image.withTintColor(.lightGray, renderingMode: .alwaysOriginal).withConfiguration(configuration)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isCancelled { return }
                self.image = configuredImage
                self.loadingCompleteHandler?(self.image)
                guard let index = self._index else { return }
                CacheManager.shared[index] = configuredImage
            }
        } else {
            downloadImageFrom(url) { (image) in
                DispatchQueue.main.async() { [weak self] in
                    guard let self = self, !self.isCancelled else { return }
                    self.image = image
                    self.loadingCompleteHandler?(self.image)
                    guard let image = image, let index = self._index else { return }
                    CacheService.shared[index as NSNumber] = image
                }
            }
        }
    }
}
```

## Chat

### Table view

In order to display the new messages from the bottom up, the table view is flipped upside down.

```swift
tableView = UITableView()
tableView.allowsSelection = false
tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
tableView.register(ImageMessageCell.self, forCellReuseIdentifier: ImageMessageCell.identifier)
tableView.rowHeight = UITableView.automaticDimension
tableView.estimatedRowHeight = UITableView.automaticDimension
tableView.prefetchDataSource = self
tableView.delegate = self
tableView.dataSource = self
tableView.separatorStyle = .none
tableView.keyboardDismissMode = .onDrag
tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
tableView.frame = CGRect(origin: .zero, size: view.bounds.size)
tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
view.addSubview(tableView)
```

### Chat status

The chat incorporates the "last seen" and the online status indicators. The `lastSeen` indicator allows the chat to display whether the recipient of a message has been read or not. The online status indicator is determined by whether the user has pushed the chat view controller to the forefront and/or the app is backgrounded.

```swift
class OnlineStatus {
    var lastSeen = [String: Date]()
    var isOnline: [String: Bool]!
    
    convenience init(querySnapshot: DocumentSnapshot) {
        self.init()
        self.isOnline = querySnapshot.get("isOnline") as? [String: Bool]
        if let lastSeenBuffer = querySnapshot.get("lastSeen") as? [String: Timestamp] {
            for (key, value) in lastSeenBuffer {
                lastSeen.updateValue(value.dateValue(), forKey: key)
            }
        }
    }
}
```

## Screetshots

1. Progress view when listing an item on blockchain.

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/1.png)

2. Main catogories for listings.

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/2.png)

3. Item listing detail displaying the description, price, user detail, user listing history, user review, payment method, delivery method, etc. 

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/3.png)

4. Account settings

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/4.png)

5. Wallet interface

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/5.png)

6. Chat between a buyer and seller. Shows the received status indicator as well as the online/offline indicator

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/6.png)

7. Chat inbox interface. Trailing swipe shortcuts to recipient, post, report, delete, etc.

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/7.png)

8. Quick Unique Identifier check provides the ability to check the existence of an identifier in Firestore without going through the listing process.

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/8.png)

9. A seller is able to specify the shipping availability by location or distance

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/9.png)

10. The auction detail of a listed item shows the relevant information needed for a bidder

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/10.png)

11. A visual indicator of the status of a sale.  The circles are filled out as the stage progresses.

![](https://github.com/igibliss00/Solirey-iOS/blob/master/ReadmeAssets/11.png)

