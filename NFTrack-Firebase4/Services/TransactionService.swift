//
//  TransactionServicer.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

import Foundation
import web3swift
import BigInt
//import PromiseKit
import Combine

class TransactionService {
    let keysService = KeysService()
    let db = FirebaseService.shared.db!
    let alert = Alerts()
    var userId: String? {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId) 
    }
    
    func requestGasPrice(onComplition:@escaping (Double?) -> Void) {
        let path = "https://ethgasstation.info/json/ethgasAPI.json"
        guard let url = URL(string: path) else {
            DispatchQueue.main.async {
                onComplition(nil)
            }
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    onComplition(nil)
                }
                return
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
                    let gasPrice = json?["average"] as? Double
                    DispatchQueue.main.async {
                        onComplition(gasPrice)
                    }
                }catch {
                    DispatchQueue.main.async {
                        onComplition(nil)
                    }
                }
            }
        }
        dataTask.resume()
    }
    
    // MARK: - stripZeros
    func stripZeros(_ string: String) -> String {
        if !string.contains(".") {return string}
        var end = string.index(string.endIndex, offsetBy: -1)
        
        while string[end] == "0" {
            end = string.index(before: end)
        }
        
        if string[end] == "." {
            if string[string.index(before: end)] == "0" {
                return "0.0"
            } else {
                return string[...end] + "0"
            }
        }
        return String(string[...end])
    }
}

extension TransactionService {
    //MARK: - prepareTransactionForSending
    func prepareTransactionForSending(destinationAddressString: String?,
                                      amountString: String?,
                                      gasLimit: UInt = 21000,
                                      completion:  @escaping (WriteTransaction?, PostingError?) -> Void) {
        var balance: BigUInt!
        
        DispatchQueue.global().async {
            guard let currentAddress = Web3swiftService.currentAddress else {
                completion(nil, PostingError.retrievingCurrentAddressError)
                return
            }
            
            balance = try? Web3swiftService.web3instance.eth.getBalance(address: currentAddress)
            
            guard let destinationAddressString = destinationAddressString, !destinationAddressString.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.emptyDestinationAddress)
                }
                return
            }
            
            guard let amountString = amountString, !amountString.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.emptyAmount)
                }
                return
            }
            
            guard let destinationEthAddress = EthereumAddress(destinationAddressString) else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.invalidDestinationAddress)
                }
                return
            }
            
            guard let amount = Web3.Utils.parseToBigUInt(amountString, units: .wei) else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.invalidAmountFormat)
                }
                return
            }
            
            guard amount > 0 else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.zeroAmount)
                }
                return
            }
            
            guard amount <= (balance ?? 0) else {
                DispatchQueue.main.async {
                    let msg = "Insufficient fund in your wallet"
                    completion(nil, PostingError.insufficientFund(msg))
                }
                return
            }
            
            var options = TransactionOptions.defaultOptions
            options.from = currentAddress
            options.value = BigUInt(amount)
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            let web3 = Web3swiftService.web3instance
            guard let contract = web3.contract(Web3.Utils.coldWalletABI, at: destinationEthAddress, abiVersion: 2) else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.contractLoadingError)
                }
                return
            }
            
            guard let transaction = contract.write("fallback", parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.createTransactionIssue)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(transaction, nil)
            }
        }
    }
    
//    // MARK: - prepareTransactionForNewContract
//    func prepareTransactionForNewContract(value: String, completion: @escaping (WriteTransaction?, PostingError?) -> Void) {
//        let web3 = Web3swiftService.web3instance
//        let localDatabase = LocalDatabase()
//        if let wallet = localDatabase.getWallet() {
//            let walletAddress = EthereumAddress(wallet.address)! // Address which balance we want to know
//            let balanceResult = try! web3.eth.getBalance(address: walletAddress)
//            let balanceString = Web3.Utils.formatToEthereumUnits(balanceResult, toUnits: .eth, decimals: 3)!
//            print("balanceResult", balanceResult)
//            print("balanceString", balanceString)
//        }
//
//
//        DispatchQueue.global().async {
//            guard let address = Web3swiftService.currentAddress else { return }
//            var options = TransactionOptions.defaultOptions
//            options.from = address
//            options.gasLimit = TransactionOptions.GasLimitPolicy.manual(BigUInt(5129290000000000000))
//            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
//
//            let bytecode = Data(hex: purchaseBytecode2)
//            var estimatedGasResult: BigUInt!
//            do {
//                estimatedGasResult = try web3.contract(purchaseABI2)?.deploy(bytecode: bytecode)?.estimateGas(transactionOptions: nil)
//                print("estimatedGasResult", estimatedGasResult as Any)
//                print("BigUint", BigUInt(estimatedGasResult))
////                options.gasLimit = BigUInt(512929)
//            } catch {
//                print("gas result", error)
//            }
//
//            guard let amount = Web3.Utils.parseToBigUInt(value, units: .eth) else {
//                DispatchQueue.main.async {
//                    completion(nil, PostingError.invalidAmountFormat)
//                }
//                return
//            }
//            options.value = BigUInt(amount)
//
////            let web3 = Web3swiftService.web3instance
//            guard let contract = web3.contract(purchaseABI2) else {
//                DispatchQueue.main.async {
//                    completion(nil, PostingError.contractLoadingError)
//                }
//                return
//            }
//
//            guard let transaction = contract.deploy(bytecode: bytecode, parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
//                DispatchQueue.main.async {
//                    completion(nil, PostingError.createTransactionIssue)
//                }
//                return
//            }
//
//
//
//            DispatchQueue.main.async {
//                completion(nil, nil)
//            }
////            DispatchQueue.main.async {
////                completion(transaction, nil)
////            }
//        }
//    }

    // purchaseABI2
    // MARK: - prepareTransactionForNewContract
    func prepareTransactionForNewContract(contractABI: String, bytecode: String, value: String, parameters: [AnyObject]? = nil, completion: @escaping (WriteTransaction?, PostingError?) -> Void) {
        guard let currentAddress = Web3swiftService.currentAddress else {
            completion(nil, PostingError.retrievingCurrentAddressError)
            return
        }
        
        var options = TransactionOptions.defaultOptions
        options.from = currentAddress
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic

        guard let amount = Web3.Utils.parseToBigUInt(value, units: .eth) else {
            DispatchQueue.main.async {
                completion(nil, PostingError.invalidAmountFormat)
            }
            return
        }
        options.value = BigUInt(amount)

        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(contractABI) else {
            DispatchQueue.main.async {
                completion(nil, PostingError.contractLoadingError)
            }
            return
        }

        let bytecodeHexData = Data(hex: bytecode)
        guard let transaction = contract.deploy(bytecode: bytecodeHexData, parameters: parameters ?? [AnyObject](), extraData: Data(), transactionOptions: options) else {
            DispatchQueue.main.async {
                completion(nil, PostingError.createTransactionIssue)
            }
            return
        }

        completion(transaction, nil)
    }
    
    func prepareTransactionForNewContract(contractABI: String, bytecode: String, value: String, parameters: [AnyObject]? = nil, promise: @escaping (Result<WriteTransaction, PostingError>) -> Void) {
        guard let currentAddress = Web3swiftService.currentAddress else {
            promise(.failure(PostingError.retrievingCurrentAddressError))
            return
        }
        
        var options = TransactionOptions.defaultOptions
        options.from = currentAddress
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        guard let amount = Web3.Utils.parseToBigUInt(value, units: .eth) else {
            promise(.failure(PostingError.invalidAmountFormat))
            return
        }
        options.value = BigUInt(amount)
        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(contractABI) else {
            promise(.failure(PostingError.contractLoadingError))
            return
        }
        
        let bytecodeHexData = Data(hex: bytecode)
        guard let transaction = contract.deploy(bytecode: bytecodeHexData, parameters: parameters ?? [AnyObject](), extraData: Data(), transactionOptions: options) else {
            promise(.failure(PostingError.createTransactionIssue))
            return
        }
        
        promise(.success(transaction))
    }
    
    // MARK: - prepareTransactionForMinting
    func prepareTransactionForMinting(completion: @escaping (WriteTransaction?, PostingError?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let address = Web3swiftService.currentAddress else { return }
            var options = TransactionOptions.defaultOptions
            options.from = address
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            let web3 = Web3swiftService.web3instance
            guard let contract = web3.contract(NFTrackABI, at: NFTrackAddress, abiVersion: 2) else {
                completion(nil, PostingError.contractLoadingError)
                return
            }
            
            guard let currentAddress = Web3swiftService.currentAddressString else {
                completion(nil, PostingError.retrievingCurrentAddressError)
                return
            }
            
            let parameters: [AnyObject] = [currentAddress] as [AnyObject]
            guard let transaction = contract.write("mintNft", parameters: parameters, extraData: Data(), transactionOptions: options) else {
                completion(nil, PostingError.createTransactionIssue)
                return
            }
            
            completion(transaction, nil)
        }
    }
    
    // MARK: - prepareTransactionForMinting
    func prepareTransactionForMinting(promise: @escaping (Result<WriteTransaction, PostingError>) -> Void) {
        guard let address = Web3swiftService.currentAddress else { return }
        var options = TransactionOptions.defaultOptions
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(NFTrackABI, at: NFTrackAddress, abiVersion: 2) else {
            promise(.failure(PostingError.contractLoadingError))
            return
        }
        
        guard let currentAddress = Web3swiftService.currentAddressString else {
            promise(.failure(PostingError.retrievingCurrentAddressError))
            return
        }
        
        let parameters: [AnyObject] = [currentAddress] as [AnyObject]
        guard let transaction = contract.write("mintNft", parameters: parameters, extraData: Data(), transactionOptions: options) else {
            promise(.failure(PostingError.createTransactionIssue))
            return
        }
        
        promise(.success(transaction))
    }
    
    // MARK: - prepareTransactionForReading
    func prepareTransactionForReading(method: String, abi: String = purchaseABI2, contractAddress: EthereumAddress, completion: @escaping (ReadTransaction?, PostingError?) -> Void) {
        guard let address = Web3swiftService.currentAddress else { return }
        var options = TransactionOptions.defaultOptions
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        DispatchQueue.global().async {
            let web3 = Web3swiftService.web3instance
            guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.contractLoadingError)
                }
                return
            }
            
            guard let transaction = contract.read(method, parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.createTransactionIssue)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(transaction, nil)
            }
        }
    }
    
    func prepareTransactionForReading(method: String, abi: String, contractAddress: EthereumAddress, promise: @escaping (Result<PropertyFetchModel, PostingError>) -> Void) {
        guard let address = Web3swiftService.currentAddress else {
            promise(.failure(.retrievingCurrentAddressError))
            return
        }
        var options = TransactionOptions.defaultOptions
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
            promise(.failure(PostingError.contractLoadingError))
            return
        }
        
        guard let transaction = contract.read(method, parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
            promise(.failure(PostingError.createTransactionIssue))
            return
        }
        
        let propertyFetchModel = PropertyFetchModel(propertyName: method, propertyDesc: nil, transaction: transaction)
        promise(.success(propertyFetchModel))
    }
    
    func prepareTransactionForWriting(method: String, abi: String, param: [AnyObject] = [AnyObject](), contractAddress: EthereumAddress, amountString: String = "0", completion: @escaping (WriteTransaction?, PostingError?) -> Void) {
        let web3 = Web3swiftService.web3instance
        guard let myAddress = Web3swiftService.currentAddress else { return }
//        let balance = try? web3.eth.getBalance(address: myAddress)
        
        guard !amountString.isEmpty else {
            completion(nil, PostingError.emptyAmount)
            return
        }
        
        guard let amount = Web3.Utils.parseToBigUInt(amountString, units: .eth) else {
            completion(nil, PostingError.invalidAmountFormat)
            return
        }
        
//        guard amount >= 0 else {
//            completion(nil, PostingError.zeroAmount)
//            return
//        }
//
//        guard amount <= (balance ?? 0) else {
//            completion(nil, PostingError.insufficientFund)
//            return
//        }
        
        var options = TransactionOptions.defaultOptions
        options.from = myAddress
        options.value = amount
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
            completion(nil, PostingError.contractLoadingError)
            return
        }
        
        guard let transaction = contract.write(method, parameters: param, extraData: Data(), transactionOptions: options) else {
            completion(nil, PostingError.createTransactionIssue)
            return
        }
        
        completion(transaction, nil)
    }
    
    func prepareTransactionForWriting(method: String, abi: String, param: [AnyObject] = [AnyObject](), contractAddress: EthereumAddress, amountString: String = "0", promise: @escaping (Result<WriteTransaction, PostingError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let web3 = Web3swiftService.web3instance
            guard let myAddress = Web3swiftService.currentAddress else {
                promise(.failure(PostingError.generalError(reason: "Could not retrieve the wallet address.")))
                return
            }
            
            guard !amountString.isEmpty else {
                promise(.failure(PostingError.emptyAmount))
                return
            }
            
            guard let amount = Web3.Utils.parseToBigUInt(amountString, units: .eth) else {
                promise(.failure(PostingError.invalidAmountFormat))
                return
            }
            
            print("amount", amount)
            
            var options = TransactionOptions.defaultOptions
            options.callOnBlock = .pending
            options.nonce = .pending
            options.from = myAddress
            options.value = amount
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
                promise(.failure(PostingError.contractLoadingError))
                return
            }
            
            guard let transaction = contract.write(method) else {
                promise(.failure(PostingError.createTransactionIssue))
                return
            }
            
            transaction.transactionOptions.from = myAddress
            transaction.transactionOptions.value = amount
//            guard let transaction = contract.write(method, parameters: param, extraData: Data(), transactionOptions: options) else {
//                promise(.failure(PostingError.createTransactionIssue))
//                return
//            }
            
            promise(.success(transaction))
        }
    }
}

// MARK: - helper functions
extension TransactionService {
    final func createDeploymentTransaction(contractABI: String, bytecode: String, price: String, parameters: [AnyObject] = [AnyObject](), promise: @escaping (Result<TxPackage, PostingError>) -> Void) {
        self.prepareTransactionForNewContract(contractABI: contractABI, bytecode: bytecode, value: price, parameters: parameters, completion: { (transaction, error) in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            }
            
            if let transaction = transaction {
                do {
                    let escrowGasEstimate = try transaction.estimateGas()
                    let txPackage = TxPackage(transaction: transaction, gasEstimate: escrowGasEstimate, price: price, type: .deploy)
                    promise(.success(txPackage))
                } catch {
                    promise(.failure(.retrievingEstimatedGasError))
                }
            }
        })
    }
    
    final func createMintTransaction(_ promise: @escaping (Result<TxPackage, PostingError>) -> Void) {
        self.prepareTransactionForMinting { (transaction, error) in
            if let error = error {
                promise(.failure(error))
            }
            
            if let transaction = transaction {
                do {
                    let escrowGasEstimate = try transaction.estimateGas()
                    let txPackage = TxPackage(transaction: transaction, gasEstimate: escrowGasEstimate, price: nil, type: .mint)
                    promise(.success(txPackage))
                } catch {
                    promise(.failure(.retrievingEstimatedGasError))
                }
            }
        }
    }
    
    final func createWriteTransaction(method: String, abi: String, paramters: [AnyObject], contractAddress: EthereumAddress, promise: @escaping (Result<TxPackage, PostingError>) -> Void) {
        self.prepareTransactionForWriting(method: method, abi: abi, param: paramters, contractAddress: contractAddress) { (transaction, error) in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            }
            
            if let transaction = transaction {
                do {
                    let transferGasEstimate = try transaction.estimateGas()
                    let txPackage = TxPackage(transaction: transaction, gasEstimate: transferGasEstimate, price: nil, type: .mint)
                    promise(.success(txPackage))
                } catch {
                    promise(.failure(.retrievingEstimatedGasError))
                }
            }
        }
    }
    
//    final func createReadTransaction(method: String, abi: String, contractAddress: EthereumAddress, property: String, promise: (Result<TxPackage, PostingError>) -> Void) {
//        self.prepareTransactionForReading(method: method, abi: abi, contractAddress: contractAddress, promise: promise)
//    }
    
    final func calculateTotalGasCost(with gasEstimates: [BigUInt], price: String, plus additionalGasUnits: BigUInt = 0, promise: @escaping (Result<Bool, PostingError>) -> Void) {
        /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
        let localDatabase = LocalDatabase()
        guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
            promise(.failure(PostingError.generalError(reason: "There was an error retrieving your wallet.")))
            return
        }
        
        var balanceResult: BigUInt!
        do {
            balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
        } catch {
            promise(.failure(PostingError.generalError(reason: "An error retrieving the balance of your wallet.")))
        }
        
        var currentGasPrice: BigUInt!
        do {
            currentGasPrice = try Web3swiftService.web3instance.eth.getGasPrice()
        } catch {
            promise(.failure(PostingError.retrievingGasPriceError))
        }
        
        var totalGasUnits: BigUInt! = 0
        for estimate in gasEstimates {
            totalGasUnits += estimate
        }
        
        // Auction needs an additional gas allowance for transferring the token
        totalGasUnits += additionalGasUnits
        
        guard let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth),
              (totalGasUnits * currentGasPrice + priceInWei) < balanceResult else {
            let msg = """
            Insufficient funds in your wallet to cover the gas fee for deploying the auction contract and minting a token.

            A. Total estimated gas for your transaction: \(totalGasUnits ?? 0) units
            B. Current gas price: \(currentGasPrice ?? 0) Gwei
            C. Your current balance: \(balanceResult ?? 0) Wei

            A * B = \(totalGasUnits * currentGasPrice) Wei
            """
            promise(.failure(PostingError.insufficientFund(msg)))
            return
        }
        
        promise(.success(true))
    }
    
    final func calculateTotalGasCost(with txPackages: [TxPackage], plus additionalGasUnits: BigUInt = 0, promise: @escaping (Result<[TxPackage], PostingError>) -> Void) {
        /// check the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
        let localDatabase = LocalDatabase()
        guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
            promise(.failure(PostingError.generalError(reason: "There was an error retrieving your wallet.")))
            return
        }
        
        var balanceResult: BigUInt!
        do {
            balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
        } catch {
            promise(.failure(PostingError.generalError(reason: "An error retrieving the balance of your wallet.")))
        }
        
        var currentGasPrice: BigUInt!
        do {
            currentGasPrice = try Web3swiftService.web3instance.eth.getGasPrice()
        } catch {
            promise(.failure(PostingError.retrievingGasPriceError))
        }
        
        var totalGasUnits: BigUInt! = 0
        var price: String!
        for txPackage in txPackages {
            totalGasUnits += txPackage.gasEstimate
            // only one of the transactions will have price
            if price != nil { continue }
            price = txPackage.price
        }
        
        totalGasUnits += additionalGasUnits
        
        guard let priceInWei = Web3.Utils.parseToBigUInt(price, units: .eth),
              (totalGasUnits * currentGasPrice + priceInWei) < balanceResult else {
            let msg = """
            Insufficient funds in your wallet to cover the gas fee for deploying the auction contract and minting a token.

            A. Total estimated gas for your transaction: \(totalGasUnits ?? 0) units
            B. Current gas price: \(currentGasPrice ?? 0) Gwei
            C. Your current balance: \(balanceResult ?? 0) Wei

            A * B = \(totalGasUnits * currentGasPrice) Wei
            """
            promise(.failure(PostingError.insufficientFund(msg)))
            return
        }
        
        promise(.success(txPackages))
    }
    
    final func executeTransaction(transaction: WriteTransaction, password: String, type: TxType) -> Future<TxResult, PostingError> {
        return Future<TxResult, PostingError> { promise in
            do {
                let result = try transaction.send(password: password, transactionOptions: nil)
                print("executeTransaction", result)
                guard let sender = result.transaction.sender else {
                    promise(.failure(.generalError(reason: "Unable to parse the transaction receipt.")))
                    return
                }
                let txResult = TxResult(senderAddress: sender.address, txHash: result.hash, txType: type)
                promise(.success(txResult))
            } catch {
                if let err = error as? Web3Error {
                    print("execute error", err)
                    promise(.failure(.generalError(reason: err.errorDescription)))
                } else {
                    print("execute error2", error)
                    promise(.failure(.generalError(reason: error.localizedDescription)))
                }
            }
        }
    }
    
    final func createFireStoreEntry(documentId: inout String?, senderAddress: String, escrowHash: String, auctionHash: String, mintHash: String, itemTitle: String, desc: String, price: String, category: String, tokensArr: Set<String>, convertedId: String, deliveryMethod: String, saleFormat: String, paymentMethod: String, topics: [String], urlStrings: [String?], promise: @escaping (Result<Int, PostingError>) -> Void) {
        let ref = self.db.collection("post")
        let id = ref.document().documentID
        // for deleting photos afterwards
        documentId = id
        
        // txHash is either minting or transferring the ownership
        self.db.collection("post").document(id).setData([
            "sellerUserId": userId,
            "senderAddress": senderAddress,
            "escrowHash": escrowHash,
            "auctionHash": auctionHash,
            "mintHash": mintHash,
            "date": Date(),
            "title": itemTitle,
            "description": desc,
            "price": price,
            "category": category,
            "status": PostStatus.ready.rawValue,
            "tags": Array(tokensArr),
            "itemIdentifier": convertedId,
            "isReviewed": false,
            "type": "digital",
            "deliveryMethod": deliveryMethod,
            "saleFormat": saleFormat,
            "files": urlStrings,
            "paymentMethod": paymentMethod
        ]) { (error) in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            } else {
                return FirebaseService.shared.getTokenId1(topics: topics, documentId: id, promise: promise)
            }
        }
    }
}

struct PropertyFetchModel: SpecDetail {
    var propertyName: String
    var propertyDesc: String?
    let transaction: ReadTransaction
}

// subscription
//address = 0x656f9BF02FA8EfF800f383E5678e699ce2788C5C;
//blockHash = 0x545365244348926581806b2e144679cfbfc48692a349a9ab0ad023bc42b62c82;
//blockNumber = 0x849e11;
//data = 0x;
//logIndex = 0x5;
//removed = 0;
//topics =     (
//0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
//0x0000000000000000000000000000000000000000000000000000000000000000,
//0x0000000000000000000000006879f0a123056b5bb56c7e787cf64a67f3a16a71,
//0x0000000000000000000000000000000000000000000000000000000000000030
//);
//transactionHash = 0x60d5a11effe213fd143ca40133880d29819b3eff37580ed29ba0918f87b7c3c5;
//transactionIndex = 0x4;
