////
////  AuctionDeploymentTests.swift
////  NFTrack-Firebase4Tests
////
////  Created by J C on 2021-08-01.
////
//
//import XCTest
//import Firebase
//import Combine
//import web3swift
//import BigInt
//@testable import NFTrack_Firebase4
//
//class AuctionDeploymentTests: XCTestCase {
//    var digitalAssetVC: DigitalAssetViewController!
//    var storage = Set<AnyCancellable>()
//    var transactionService = TransactionService()
//    var socketDelegate: SocketDelegate!
//    var previewDataArr: [PreviewData]!
//    var documentId: String!
//    var auctionDetailVC: AuctionDetailViewController!
//    var auctionHashBefore: String!
//    var auctionHashAfter: String!
//    
//    override func setUp() {
//        super.setUp()
//        digitalAssetVC = DigitalAssetViewController()
//        previewDataArr = []
//    }
//
//    override func tearDown() {
//        digitalAssetVC = nil
////        transactionService = nil
//        previewDataArr = nil
//        documentId = nil
//        
//        FirebaseService.shared.db
//            .collection("post")
//            .whereField("convertedId", isEqualTo: "random_unique_identifier")
//            .getDocuments { (querySnapshot, error) in
//                if let error = error {
//                    print("Error fetching query snapshot", error)
//                } else {
//                    guard let querySnapshot = querySnapshot else { return }
//                    for document in querySnapshot.documents {
//                        document.reference.delete { (error) in
//                            if let error = error {
//                                print("Error in deleting", error)
//                            } else {
//                                print("Delete success!")
//                            }
//                        }
//                    }
//                }
//            }
//        
//        super.tearDown()
//    }
//    
//    func test_auction_deployed_properly() {
//        let expectation = self.expectation(description: "Auction deployed and the properties fetched")
//        let itemTitle = "Test Title"
//        let desc = "Test description"
//        let category = Category.digital.asString()
//        let convertedId = "random_unique_identifier"
//        let tokensArr = ["30"] as Set<String>
//        let userId = "firebase_user_id"
//        let deliveryMethod = "Online Transfer"
//        let saleFormat = SaleFormat.openAuction.rawValue
//        let paymentMethod = PaymentMethod.auctionBeneficiary.rawValue
//        let auctionDuration = "500"
//        let auctionStartingPrice = "200"
//        let parameters: [AnyObject] = [auctionDuration, auctionStartingPrice] as [AnyObject]
//        // to be used for getting the contract address so that the token can be transferred
//        var auctionHash: String!
//        var txPackageArr = [TxPackage]()
//        var txResultArr: [TxResult2]!
//        var topicsRetainer: [String]!
//        
//        socketDelegate = SocketDelegate(contractAddress: NFTrackAddress!)
//        print("STEP 1")
//        // prepare the deployment transaction of the auction contract
//        Future<TxPackage, PostingError> { promise in
//            self.transactionService.prepareTransactionForNewContractWithGasEstimate(
//                contractABI: auctionABI,
//                bytecode: auctionBytcode,
//                parameters: parameters,
//                promise: promise
//            )
//        }
//        .flatMap { (txPackage) -> AnyPublisher<[TxPackage], PostingError> in
//            // TxPackage array is needed because calculateTotalGasCost can calculate multiple transactions' gas.
//            // In this case, there is only one transaction to be calculated.
//            // The minting transaction can't be calculated because it requires the auction contract's address.
//            txPackageArr.append(txPackage)
//            return Future<[TxPackage], PostingError> { promise in
//                print("STEP 2")
//                let gasEstimateToMintAndTransferAToken: BigUInt = 80000
//                self.transactionService.calculateTotalGasCost(
//                    with: txPackageArr,
//                    plus: gasEstimateToMintAndTransferAToken,
//                    promise: promise
//                )
//                let update: [String: PostProgress] = ["update": .estimatGas]
//                NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//            }
//            .eraseToAnyPublisher()
//        }
//        // execute the deployment transaction and get the receipts in an array
//        .flatMap { (txPackages) -> AnyPublisher<[TxResult2], PostingError> in
//            let update: [String: PostProgress] = ["update": .images]
//            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//            
//            print("STEP 3")
//            let results = txPackages.map { self.transactionService.executeTransaction2(
//                transaction: $0.transaction,
//                password: "111111",
//                type: $0.type
//            )}
//            return Publishers.MergeMany(results)
//                .collect()
//                .eraseToAnyPublisher()
//        }
//        // confirm that the block has been added to the chain
//        .flatMap({ (txResults) -> AnyPublisher<[TransactionReceipt], PostingError> in
//            txResultArr = txResults
//            guard let txResult = txResults.first else {
//                return Fail(error: PostingError.generalError(reason: "Parsing the transaction result error."))
//                    .eraseToAnyPublisher()
//            }
//            print("STEP 4")
//            return self.transactionService.confirmEtherTransactionsNoDelay(txHash: txResult.txResult.hash)
//        })
//        .eraseToAnyPublisher()
//        // mint a token and transfer it to the address of the newly deployed auction contract
//        .flatMap({ (txReceipts) -> AnyPublisher<WriteTransaction, PostingError> in
//            print("STEP 5")
//            
//            let update: [String: PostProgress] = ["update": .deployingAuction]
//            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//            
//            guard let txReceipt = txReceipts.first else {
//                return Fail(error: PostingError.generalError(reason: "Parsing the transaction result error."))
//                    .eraseToAnyPublisher()
//            }
//            
//            guard let auctionContractAddress = txReceipt.contractAddress else {
//                return Fail(error: PostingError.generalError(reason: "Failed to obtain the auction contract address."))
//                    .eraseToAnyPublisher()
//            }
//            
//            // prepare the transaction to mint and transfer the token
//            return Future<WriteTransaction, PostingError> { promise in
//                self.transactionService.prepareTransactionForMinting(
//                    receiverAddress: auctionContractAddress,
//                    promise: promise
//                )
//            }
//            .eraseToAnyPublisher()
//        })
//        // execute the mint transaction
//        .flatMap { (transaction) -> AnyPublisher<[TxResult2], PostingError> in
//            print("STEP 6")
//            
//            let results = self.transactionService.executeTransaction2(
//                transaction: transaction,
//                password: "111111",
//                type: .mint
//            )
//            
//            return Publishers.MergeMany(results)
//                .collect()
//                .eraseToAnyPublisher()
//        }
//        // get the topics from the socket delegate
//        .flatMap { (txResult) -> AnyPublisher<[String: Any], PostingError> in
//            // retain the mint transaction details for FireStore
//            txResultArr.append(contentsOf: txResult)
//            return Future<[String: Any], PostingError> { promise in
//                print("STEP 7")
//                self.socketDelegate.promise = promise
//            }
//            .eraseToAnyPublisher()
//        }
//        // instantiate the socket, parse the receipts, and create the firebase entry as soon as the socket delegate receives the data
//        // createFiresStoreEntry ends with sending a HTTP request to the Cloud Functions for the token ID
//        .flatMap({ (webSocketMessage) -> AnyPublisher<[String?], PostingError> in
//            let update: [String: PostProgress] = ["update": .minting]
//            NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//            
//            if let topics = webSocketMessage["topics"] as? [String] {
//                topicsRetainer = topics
//            }
//            
//            // upload images/files to the Firebase Storage and get the array of URLs
//            if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
//                let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
//                    return Future<String?, PostingError> { promise in
//                        self.uploadFileWithPromise(
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
//        .flatMap { [self] (urlStrings) -> AnyPublisher<Int, PostingError> in
//            var mintHash: String!
//            var senderAddress: String!
//            for txResult in txResultArr {
//                if txResult.txType == .deploy {
//                    auctionHash = txResult.txResult.hash
//                    self.auctionHashBefore = txResult.txResult.hash
//                } else {
//                    mintHash = txResult.txResult.hash
//                }
//                senderAddress = txResult.senderAddress
//            }
//            print("STEP 8")
//            
//            return Future<Int, PostingError> { promise in
//                self.transactionService.createFireStoreEntry(
//                    documentId: &self.documentId,
//                    senderAddress: senderAddress,
//                    escrowHash: "N/A",
//                    auctionHash: auctionHash,
//                    mintHash: mintHash,
//                    itemTitle: itemTitle,
//                    desc: desc,
//                    price: "N/A",
//                    category: category,
//                    tokensArr: tokensArr,
//                    convertedId: convertedId,
//                    type: "digital",
//                    deliveryMethod: deliveryMethod,
//                    saleFormat: saleFormat,
//                    paymentMethod: paymentMethod,
//                    topics: topicsRetainer,
//                    urlStrings: urlStrings,
//                    promise: promise
//                )
//            }
//            .eraseToAnyPublisher()
//        }
//        .sink { (completion) in
//            switch completion {
//                case .failure(let error):
//                    print("Error", error)
//                    XCTFail(error.localizedDescription)
//                case .finished:
//                    let update: [String: PostProgress] = ["update": .initializeAuction]
//                    NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//            }
//        } receiveValue: { [weak self] (receivedValue) in
//            XCTAssertTrue(receivedValue > 0)
//            
//            
//            DispatchQueue.main.async {
//                expectation.fulfill()
//            }
//            
//            
//            if self?.socketDelegate != nil {
//                self?.socketDelegate.disconnectSocket()
//            }
//            
//            
//            Future<TransactionReceipt, PostingError> { promise in
//                Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
//            }
//            .sink { (completion) in
//                switch completion {
//                    case .finished:
//                        print("getReceipt finished")
//                    case .failure(let error):
//                        XCTFail(error.localizedDescription)
//                }
//            } receiveValue: { (receipt: TransactionReceipt) in
//                guard let contractAddress = receipt.contractAddress else { return }
//                
//                DispatchQueue.main.async {
//                    self?.getAuctionProperties(auctionContractAddress: contractAddress)
//                }
//            }
//            .store(in: &self!.storage)
//        }
//        .store(in: &self.storage)
//        waitForExpectations(timeout: 200, handler: nil)
//    }
//    
//func getAuctionProperties(auctionContractAddress: EthereumAddress) {
//        var expectation: XCTestExpectation!
//        DispatchQueue.main.async {
//            expectation = self.expectation(description: "Auction deployed and the properties fetched")
//        }
//
//        guard let contractAddress = Web3swiftService.currentAddress else { return }
//        let propertiesToLoad = [
//            AuctionContract.ContractProperties.startingBid,
//            AuctionContract.ContractProperties.highestBid,
//            AuctionContract.ContractProperties.highestBidder,
//            AuctionContract.ContractProperties.auctionEndTime,
//            AuctionContract.ContractProperties.ended,
//            AuctionContract.ContractProperties.pendingReturns(contractAddress)
//        ]
//        
//        
//        let auctionInfoLoader = PropertyLoader(
//            propertiesToLoad: propertiesToLoad,
//            transactionHash: auctionContractAddress.address,
//            contractAddress: contractAddress
//        )
//        
//        auctionInfoLoader.initiateLoadSequence()
//            .sink { (completion) in
//                switch completion {
//                    case .finished:
//                        print("get auction info finished")
//                    case .failure(let error):
//                        XCTFail(error.localizedDescription)
//                }
//            } receiveValue: { (propertyFetchModels: [SmartContractProperty]) in
//                XCTAssertEqual(propertyFetchModels.count, 6)
//                
//                print("propertyFetchModels", propertyFetchModels)
//                propertyFetchModels.forEach { (model) in
//                    if model.propertyDesc is String {
//                        switch model.propertyDesc as? String {
//                            case AuctionContract.AuctionProperties.pendingReturns(contractAddress).value.0:
//                                print("pending returns", model.propertyDesc as Any)
//                            case AuctionContract.AuctionProperties.highestBidder.value.0:
//                                print("highest bidder", model.propertyDesc as Any)
//                            case AuctionContract.AuctionProperties.highestBid.value.0:
//                                print("highest bid", model.propertyDesc as Any)
//                            case AuctionContract.AuctionProperties.startingBid.value.0:
//                                print("starting bid", model.propertyDesc as Any)
//                            default:
//                                break
//                        }
//                    } else if model.propertyDesc is Bool {
//                        print("auction ended", model.propertyDesc as Any)
//                    } else if model.propertyDesc is Date {
//                        print("auction end date", model.propertyDesc as Any)
//                    } else {
//                        XCTFail("Wrong property format fetched")
//                    }
//                }
//                
//                DispatchQueue.main.async {
//                    expectation.fulfill()
//                    self.waitForExpectations(timeout: 100, handler: nil)
//                }
//                
//            }
//            .store(in: &self.storage)
//    }
//    
//    func uploadFileWithPromise(fileURL: URL, userId: String, promise: @escaping (Result<String?, PostingError>) -> Void) {
//        FirebaseService.shared.uploadFile(fileURL: fileURL, userId: userId) { (uploadTask, fileUploadError) in
//            if let error = fileUploadError {
//                switch error {
//                    case .fileNotAvailable:
//                        promise(.failure(PostingError.fileUploadError(.fileNotAvailable)))
//                        break
//                    default:
//                        promise(.failure(.generalError(reason: "Image Uploading Error.")))
//                }
//            }
//            
//            if let uploadTask = uploadTask {
//                uploadTask.observe(.progress) { snapshot in
//                    // Upload reported progress
//                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
//                        / Double(snapshot.progress!.totalUnitCount)
//                    print("percent Complete", percentComplete)
//                }
//                
//                uploadTask.observe(.success) { snapshot in
//                    // Upload completed successfully
//                    snapshot.reference.downloadURL {(url, error) in
//                        if let error = error {
//                            promise(.failure(.generalError(reason: error.localizedDescription)))
//                        }
//                        
//                        if let url = url {
//                            promise(.success("\(url)"))
//                        }
//                    }
//                }
//                
//                uploadTask.observe(.failure) { snapshot in
//                    if let error = snapshot.error as NSError? {
//                        switch (StorageErrorCode(rawValue: error.code)!) {
//                            case .objectNotFound:
//                                // File doesn't exist
//                                print("object not found")
//                                break
//                            case .unauthorized:
//                                // User doesn't have permission to access file
//                                print("unauthorized")
//                                break
//                            case .cancelled:
//                                // User canceled the upload
//                                print("cancelled")
//                                break
//                                
//                            /* ... */
//                            
//                            case .unknown:
//                                // Unknown error occurred, inspect the server response
//                                print("unknown")
//                                break
//                            default:
//                                // A separate error occurred. This is a good place to retry the upload.
//                                print("reload?")
//                                break
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
////    func test_auction_post_fetch_from_firebase() {
////        print("self.documentId", self.documentId as Any)
////        let hashRef = FirebaseService.shared.db
////            .collection("post")
////            .document(self.documentId)
////
////        hashRef.getDocument { (snapShot, error) in
////            if let error = error {
////                XCTFail(error.localizedDescription)
////            }
////
////            guard let snapShot = snapShot,
////                  let document = snapShot.data(),
////                  !document.isEmpty else {
////                XCTFail("snapshot error or is empty")
////                return
////            }
////
////            document.forEach { (item) in
////                print("item", item as Any)
////                switch item.key {
////                    case "auctionHash":
////                        print("item.value as? String", item.value as? String as Any)
////                        self.auctionHashAfter = item.value as? String
////                    default:
////                        break
////                }
////
////                XCTAssertEqual(self.auctionHashBefore, self.auctionHashAfter)
////            }
////        }
////    }
//}
//
////        digitalAssetVC.auction(
////            price: "0",
////            itemTitle: "Test Title",
////            desc: "Test description",
////            category: Category.digital.asString(),
////            convertedId: "random_unique_identifier",
////            tokensArr: ["30"], userId: "firebase_user_id",
////            deliveryMethod: "Online Transfer",
////            saleFormat: SaleFormat.openAuction.rawValue,
////            paymentMethod: PaymentMethod.auctionBeneficiary.rawValue,
////            auctionDuration: "500",
////            auctionStartingPrice: "0.000000002"
////        )
