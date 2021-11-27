//
//  TransactionServicer.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

import Foundation
import web3swift
import BigInt
import Combine
import FirebaseFirestore

class TransactionService {
    let keysService = KeysService()
    let db = FirebaseService.shared.db!
    var userId: String? {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.userId) 
    }
    let localDatabase = LocalDatabase()
    var storage = Set<AnyCancellable>()
    
    final func requestGasPrice(onComplition:@escaping (Double?) -> Void) {
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
    final func stripZeros(_ string: String) -> String {
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
    final func prepareTransactionForSending(destinationAddressString: String?,
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
            options.value = amount
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            let web3 = Web3swiftService.web3instance
            guard let contract = web3.contract(Web3.Utils.coldWalletABI, at: destinationEthAddress, abiVersion: 2) else {
                DispatchQueue.main.async {
                    completion(nil, PostingError.contractLoadingError)
                }
                return
            }
            
            
//            contract.getIndexedEvents(eventName: <#T##String?#>, filter: .init(fromBlock: <#T##EventFilter.Block?#>, toBlock: <#T##EventFilter.Block?#>, addresses: <#T##[EthereumAddress]?#>, parameterFilters: [.]))
            
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
//    final func prepareTransactionForNewContract(value: String, completion: @escaping (WriteTransaction?, PostingError?) -> Void) {
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
    final func prepareTransactionForNewContract(
        contractABI: String,
        bytecode: String,
        value: String,
        parameters: [AnyObject]? = nil,
        completion: @escaping (WriteTransaction?, PostingError?) -> Void
    ) {
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
    
    final func prepareTransactionForNewContract(
        contractABI: String,
        bytecode: String,
        value: String,
        parameters: [AnyObject]? = nil,
        promise: @escaping (Result<WriteTransaction, PostingError>) -> Void
    ) {
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
    
    final func prepareTransactionForNewContractWithGasEstimate(
        contractABI: String,
        bytecode: String,
        value: String = "0",
        parameters: [AnyObject]? = nil,
        nonce: BigUInt? = nil,
        promise: @escaping (Result<TxPackage, PostingError>) -> Void
    ) {
        guard let currentAddress = Web3swiftService.currentAddress else {
            promise(.failure(PostingError.retrievingCurrentAddressError))
            return
        }
                
        var options = TransactionOptions.defaultOptions
        options.nonce = (nonce != nil) ? .manual(nonce!) : .pending
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

        guard let transaction = contract.deploy(
                bytecode: bytecodeHexData,
                parameters: parameters ?? [AnyObject](),
                extraData: Data(),
                transactionOptions: options
        ) else {
            promise(.failure(PostingError.createTransactionIssue))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let gasEstimate = try transaction.estimateGas()
                let txPackage = TxPackage(
                    transaction: transaction,
                    gasEstimate: gasEstimate,
                    price: value,
                    type: .deploy
                )
                promise(.success(txPackage))
            } catch {
                promise(.failure(.retrievingEstimatedGasError))
            }
        }
    }
    
    // MARK: - prepareTransactionForMinting
    final func prepareTransactionForMinting(completion: @escaping (WriteTransaction?, PostingError?) -> Void) {
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
    final func prepareTransactionForMinting(
        receiverAddress: EthereumAddress,
        nonce: BigUInt? = nil,
        promise: @escaping (Result<WriteTransaction, PostingError>) -> Void
    ) {
        guard let address = Web3swiftService.currentAddress else {
            promise(.failure(PostingError.retrievingCurrentAddressError))
            return
        }
        var options = TransactionOptions.defaultOptions
        options.nonce = (nonce != nil) ? .manual(nonce!) : .pending
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(mintContractABI, at: ContractAddresses.solireyMintContractAddress, abiVersion: 2) else {
            promise(.failure(PostingError.contractLoadingError))
            return
        }
        
        let parameters: [AnyObject] = [receiverAddress] as [AnyObject]
        guard let transaction = contract.write("mintNft", parameters: parameters, extraData: Data(), transactionOptions: options) else {
            promise(.failure(PostingError.createTransactionIssue))
            return
        }
                
        promise(.success(transaction))
    }
    
    // MARK: - prepareTransactionForReading
    final func prepareTransactionForReading(
        method: String,
        abi: String = purchaseABI2,
        contractAddress: EthereumAddress,
        completion: @escaping (ReadTransaction?, PostingError?) -> Void
    ) {
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
    
    final func prepareTransactionForReading(
        method: String,
        parameters: [AnyObject]? = nil,
        abi: String,
        contractAddress: EthereumAddress,
        promise: @escaping (Result<SmartContractProperty, PostingError>) -> Void
    ) {
        guard let fromAddress = Web3swiftService.currentAddress else {
            promise(.failure(.retrievingCurrentAddressError))
            return
        }
        var options = TransactionOptions.defaultOptions
        options.from = fromAddress
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
            promise(.failure(PostingError.contractLoadingError))
            return
        }
        
        DispatchQueue.global().async {
            guard let transaction = contract.read(
                method,
                parameters: parameters ?? [AnyObject](),
                extraData: Data(),
                transactionOptions: options
            ) else {
                promise(.failure(PostingError.createTransactionIssue))
                return
            }
            
            let propertyFetchModel = SmartContractProperty(propertyName: method, transaction: transaction)
            promise(.success(propertyFetchModel))
        }
    }
    
    final func prepareTransactionForWriting(
        method: String,
        abi: String,
        param: [AnyObject] = [AnyObject](),
        contractAddress: EthereumAddress,
        to: EthereumAddress? = nil,
        amountString: String?,
        completion: @escaping (WriteTransaction?, PostingError?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let web3 = Web3swiftService.web3instance
            guard let myAddress = Web3swiftService.currentAddress else {
                completion(nil, PostingError.retrievingCurrentAddressError)
                return
            }
            
            var options = TransactionOptions.defaultOptions
            
            if let amountString = amountString {
                guard !amountString.isEmpty else {
                    completion(nil, PostingError.emptyAmount)
                    return
                }
                
                guard let amount = Web3.Utils.parseToBigUInt(amountString, units: .eth) else {
                    completion(nil, PostingError.invalidAmountFormat)
                    return
                }
                          
                options.value = amount
            }
            
            if let to = to {
                options.to = to
            }
                 
            options.from = myAddress
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
                completion(nil, PostingError.contractLoadingError)
                return
            }
                        
            guard let transaction = contract.write(
                    method,
                    parameters: param,
                    extraData: Data(),
                    transactionOptions: options
            ) else {
                completion(nil, PostingError.createTransactionIssue)
                return
            }
            
            completion(transaction, nil)
        }
    }
    
    final func prepareTransactionForWritingWithGasEstimate(
        method: String,
        abi: String,
        param: [AnyObject] = [AnyObject](),
        contractAddress: EthereumAddress,
        amountString: String?,
        to: EthereumAddress? = nil,
        promise: @escaping (Result<TxPackage, PostingError>) -> Void
    ) {
        self.prepareTransactionForWriting(
            method: method,
            abi: abi,
            param: param,
            contractAddress: contractAddress,
            to: to,
            amountString: amountString
        ) { (transaction, error) in
            if let error = error {
                promise(.failure(error))
            }
            
            if let transaction = transaction {
                do {
                    let gasEstimate = try transaction.estimateGas()
                    let txPackage = TxPackage(
                        transaction: transaction,
                        gasEstimate: gasEstimate,
                        price: nil,
                        type: .mint
                    )
                    
                    promise(.success(txPackage))
                } catch {
                    promise(.failure(.retrievingEstimatedGasError))
                }
            }
        }
    }
    
    final func prepareTransactionForWriting(
        method: String,
        abi: String,
        param: [AnyObject] = [AnyObject](),
        contractAddress: EthereumAddress,
        amountString: String?,
        to: EthereumAddress? = nil,
        promise: @escaping (Result<WriteTransaction, PostingError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let web3 = Web3swiftService.web3instance
            guard let fromAddress = Web3swiftService.currentAddress else {
                promise(.failure(PostingError.generalError(reason: "Could not retrieve the wallet address.")))
                return
            }
                        
            var options = TransactionOptions.defaultOptions
            options.from = fromAddress
            
            if amountString != nil {
                guard let amount = Web3.Utils.parseToBigUInt(amountString!, units: .eth) else {
                    promise(.failure(PostingError.invalidAmountFormat))
                    return
                }
                
                options.value = amount
            }
            
//            options.to = to
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
                promise(.failure(PostingError.contractLoadingError))
                return
            }
            
            guard let transaction = contract.write(
                    method,
                    parameters: param,
                    extraData: Data(),
                    transactionOptions: options
            ) else {
                promise(.failure(PostingError.createTransactionIssue))
                return
            }
            
            promise(.success(transaction))
        }
    }
}

// MARK: - helper functions
extension TransactionService {
    final func prepareMintTransactionWithGasEstimate(_ promise: @escaping (Result<TxPackage, PostingError>) -> Void) {
        self.prepareTransactionForMinting { (transaction, error) in
            if let error = error {
                promise(.failure(error))
            }
            
            if let transaction = transaction {
                do {
                    let escrowGasEstimate = try transaction.estimateGas()
                    let txPackage = TxPackage(
                        transaction: transaction,
                        gasEstimate: escrowGasEstimate,
                        price: nil,
                        type: .mint
                    )
                                        
                    promise(.success(txPackage))
                } catch {
                    promise(.failure(.retrievingEstimatedGasError))
                }
            }
        }
    }
    
//    final func createWriteTransaction(method: String, abi: String, paramters: [AnyObject], contractAddress: EthereumAddress, promise: @escaping (Result<TxPackage, PostingError>) -> Void) {
//        self.prepareTransactionForWriting(method: method, abi: abi, param: paramters, contractAddress: contractAddress) { (transaction, error) in
//            if let error = error {
//                promise(.failure(.generalError(reason: error.localizedDescription)))
//            }
//            
//            if let transaction = transaction {
//                do {
//                    let transferGasEstimate = try transaction.estimateGas()
//                    let txPackage = TxPackage(transaction: transaction, gasEstimate: transferGasEstimate, price: nil, type: .mint)
//                    promise(.success(txPackage))
//                } catch {
//                    promise(.failure(.retrievingEstimatedGasError))
//                }
//            }
//        }
//    }
    
//    final func createReadTransaction(method: String, abi: String, contractAddress: EthereumAddress, property: String, promise: (Result<TxPackage, PostingError>) -> Void) {
//        self.prepareTransactionForReading(method: method, abi: abi, contractAddress: contractAddress, promise: promise)
//    }
    
    final func calculateTotalGasCost(
        with gasEstimates: [BigUInt],
        price: String,
        plus additionalGasUnits: BigUInt = 0,
        promise: @escaping (Result<Bool, PostingError>) -> Void
    ) {
        /// checks the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
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

            A. Total estimated gas for your transaction:
            \(totalGasUnits ?? 0) units

            B. Current gas price:
            \(currentGasPrice ?? 0) Wei

            C. Your current balance:
            \(balanceResult ?? 0) Wei

            Discrepancy:
            \(totalGasUnits * currentGasPrice - balanceResult) Wei
            """
            promise(.failure(PostingError.insufficientFund(msg)))
            return
        }
        
        promise(.success(true))
    }
    
    final func calculateTotalGasCost(
        with txPackages: [TxPackage],
        plus additionalGasUnits:
            BigUInt = 0,
        promise: @escaping (Result<[TxPackage], PostingError>) -> Void
    ) {
        /// checks the balance of the wallet against the deposit into the escrow + gas limit for two transactions: minting and deploying the contract
        guard let wallet = localDatabase.getWallet(), let walletAddress = EthereumAddress(wallet.address) else {
            promise(.failure(PostingError.generalError(reason: "There was an error retrieving your wallet.")))
            return
        }
        
        var balanceResult: BigUInt!
        do {
            balanceResult = try Web3swiftService.web3instance.eth.getBalance(address: walletAddress)
        } catch {
            promise(.failure(PostingError.generalError(reason: "An error retrieving the balance of your wallet. Please sign/re-sign into into your wallet.")))
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

                A. Total estimated gas for your transaction:
                \(totalGasUnits ?? 0) units

                B. Current gas price:
                \(currentGasPrice ?? 0) Gwei

                C. Your current balance:
                \(balanceResult ?? 0) Wei

                Discrepancy:
                \(totalGasUnits * currentGasPrice) Wei
                """
            promise(.failure(PostingError.insufficientFund(msg)))
            return
        }
        
        promise(.success(txPackages))
    }
    
    final func executeTransaction(transaction: WriteTransaction, password: String, type: TxType) -> Future<TxResult, PostingError> {
        return Future<TxResult, PostingError> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
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
                        promise(.failure(.generalError(reason: err.errorDescription)))
                    } else {
                        promise(.failure(.generalError(reason: error.localizedDescription)))
                    }
                }
            }
        }
    }
    
//    final func executeTransaction(transaction: WriteTransaction, password: String, promise: (Result<TxResult, PostingError>) -> Void) {
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                let result = try transaction.send(password: password, transactionOptions: nil)
//                print("executeTransaction", result)
//                guard let sender = result.transaction.sender else {
//                    promise(.failure(.generalError(reason: "Unable to parse the transaction receipt.")))
//                    return
//                }
//                
//                let txResult = TxResult(senderAddress: sender.address, txHash: result.hash, txType: type)
//                promise(.success(txResult))
//            } catch {
//                if let err = error as? Web3Error {
//                    print("execute error", err)
//                    promise(.failure(.generalError(reason: err.errorDescription)))
//                } else {
//                    print("execute error2", error)
//                    promise(.failure(.generalError(reason: error.localizedDescription)))
//                }
//            }
//        }
//    }
    
    final func executeTransaction2(transaction: WriteTransaction, password: String, type: TxType) -> Future<TxResult2, PostingError> {
        return Future<TxResult2, PostingError> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try transaction.send(password: password, transactionOptions: nil)
                    guard let sender = result.transaction.sender?.address else {
                        promise(.failure(.generalError(reason: "Unable to parse the transaction receipt.")))
                        return
                    }
                    
                    let txResult = TxResult2(
                        senderAddress: sender,
                        txResult: result,
                        txType: type
                    )
                    promise(.success(txResult))
                } catch {
                    if let err = error as? Web3Error {
                        promise(.failure(.generalError(reason: err.errorDescription)))
                    } else {
                        promise(.failure(.generalError(reason: error.localizedDescription)))
                    }
                }
            }
        }
    }
    
    final func transferToken(transaction: WriteTransaction, type: TxType = .transferToken) {
        DispatchQueue.global(qos: .userInitiated).async {
            var result: [String: Any]!
            do {
                result = try transaction.call()
                print("result", result as Any)
            } catch {
                if let err = error as? Web3Error {
                    print("execute error", err)
                } else {
                    print("execute error2", error)
                }
            }
        }
    }
   
    // With the token ID parsing to the Google Functions
    // This function soon to be deprecated since the token ID parsing is now done in the front end.
    final func createFireStoreEntry(
        documentId: inout String?,
        senderAddress: String,
        escrowHash: String,
        auctionHash: String,
        mintHash: String,
        itemTitle: String,
        desc: String,
        price: String,
        category: String,
        tokensArr: Set<String>,
        convertedId: String,
        type: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String,
        topics: [String],
        urlStrings: [String?],
        ipfsURLStrings: [String?],
        shippingInfo: ShippingInfo? = nil,
        isWithdrawn: Bool = true,
        isAdminWithdrawn: Bool = true,
        promise: @escaping (Result<Int, PostingError>) -> Void
    ) {
        let ref = self.db.collection("post")
        let id = ref.document().documentID
        // for deleting photos afterwards
        documentId = id
                
        let shippingInfoData: [String: Any] = [
            "scope": shippingInfo?.scope.stringValue ?? "NA" as String,
            "addresses": shippingInfo?.addresses ?? [] as [String],
            "radius": shippingInfo?.radius ?? 0,
            "longitude": shippingInfo?.longitude ?? 0,
            "latitude": shippingInfo?.latitude ?? 0
        ]
        
        let postData: [String: Any] = [
            "sellerUserId": userId as Any,
            "senderAddress": senderAddress,
            "escrowHash": escrowHash,
            "auctionHash": auctionHash,
            "mintHash": mintHash,
            "date": Date(),
            "title": itemTitle,
            "description": desc,
            "price": price,
            "category": category,
            "status": "ready",
            "tags": Array(tokensArr),
            "itemIdentifier": convertedId,
            "isReviewed": false,
            "type": type,
            "deliveryMethod": deliveryMethod,
            "saleFormat": saleFormat,
            "files": urlStrings,
            "IPFS": ipfsURLStrings,
            "paymentMethod": paymentMethod,
            "bidderTokens": [],
            "bidders": [],
            "shippingInfo": shippingInfoData,
            "saleType": SaleType.newSale.rawValue,
            "isWithdrawn": isWithdrawn, // There are contracts like Auction or SimplePayment that requires the bidders that have been outbid or the seller whose item has been purchased, respectively, that require the user to withdraw their funds manually
            "isAdminWithdrawn": isAdminWithdrawn // The fee collected by the admin
        ]
        
        // txHash is either minting or transferring the ownership
        ref.document(id).setData(postData) { (error) in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            } else {
                return FirebaseService.shared.getTokenId1(topics: topics, documentId: id, promise: promise)
            }
        }
    }
    
    final func createFireStoreEntryRevised(
        documentId: inout String?,
        senderAddress: String,
        escrowHash: String,
        auctionHash: String,
        mintHash: String,
        itemTitle: String,
        desc: String,
        price: String,
        category: String,
        tokensArr: Set<String>,
        convertedId: String,
        type: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String,
        tokenId: String,
        urlStrings: [String?],
        ipfsURLStrings: [String?],
        shippingInfo: ShippingInfo? = nil,
        isWithdrawn: Bool = true,
        isAdminWithdrawn: Bool = true,
        solireyUid: String,
        contractFormat: String,
        bidders: [String] = [],
        promise: @escaping (Result<Bool, PostingError>) -> Void
    ) {
        let ref = self.db.collection("post")
        let id = ref.document().documentID
        // for deleting photos afterwards
        documentId = id
        
        let shippingInfoData: [String: Any] = [
            "scope": shippingInfo?.scope.stringValue ?? "NA" as String,
            "addresses": shippingInfo?.addresses ?? [] as [String],
            "radius": shippingInfo?.radius ?? 0,
            "longitude": shippingInfo?.longitude ?? 0,
            "latitude": shippingInfo?.latitude ?? 0
        ]
        
        let postData: [String: Any] = [
            "sellerUserId": userId as Any,
            "senderAddress": senderAddress,
            "escrowHash": escrowHash,
            "auctionHash": auctionHash,
            "mintHash": mintHash,
            "date": Date(),
            "title": itemTitle,
            "description": desc,
            "price": price,
            "category": category,
            "status": "ready",
            "tags": Array(tokensArr),
            "itemIdentifier": convertedId,
            "isReviewed": false,
            "type": type,
            "deliveryMethod": deliveryMethod,
            "saleFormat": saleFormat,
            "files": urlStrings,
            "IPFS": ipfsURLStrings,
            "paymentMethod": paymentMethod,
            "bidderTokens": [],
            "bidders": bidders,
            "shippingInfo": shippingInfoData,
            "saleType": SaleType.newSale.rawValue,
            "isWithdrawn": isWithdrawn, // There are contracts like Auction or SimplePayment that requires the bidders that have been outbid or the seller whose item has been purchased, respectively, that require the user to withdraw their funds manually
            "isAdminWithdrawn": isAdminWithdrawn, // The fee collected by the admin
            "tokenId": tokenId,
            "solireyUid": solireyUid, // Solirey unique ID that's required for each posting on the integral contracts (i.e. mapping's key)
            "contractFormat": contractFormat,
            "isOutbidWithdrawn": false
        ]
        
        // txHash is either minting or transferring the ownership
        ref.document(id).setData(postData) { (error) in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            } else {
                promise(.success(true))
            }
        }
    }
    
    // Resale doesn't need the topics to be converted to the token ID
    final func createFireStoreEntryForResale(
        documentId: inout String?,
        senderAddress: String,
        escrowHash: String,
        auctionHash: String,
        mintHash: String,
        itemTitle: String,
        desc: String,
        price: String,
        category: String,
        tokensArr: Set<String>,
        convertedId: String,
        type: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String,
        tokenId: String,
        urlStrings: [String?],
        ipfsURLStrings: [String?],
        shippingInfo: ShippingInfo? = nil,
        isWithdrawn: Bool = true,
        isAdminWithdrawn: Bool = true,
        promise: @escaping (Result<Bool, PostingError>) -> Void
    ) {
        let ref = self.db.collection("post")
        let id = ref.document().documentID
        // for deleting photos afterwards
        documentId = id
        
        let shippingInfoData: [String: Any] = [
            "scope": shippingInfo?.scope.stringValue ?? "NA" as String,
            "addresses": shippingInfo?.addresses ?? [] as [String],
            "radius": shippingInfo?.radius ?? 0,
            "longitude": shippingInfo?.longitude ?? 0,
            "latitude": shippingInfo?.latitude ?? 0
        ]
        
        let postData: [String: Any] = [
            "sellerUserId": userId as Any,
            "senderAddress": senderAddress,
            "escrowHash": escrowHash,
            "auctionHash": auctionHash,
            "mintHash": mintHash,
            "date": Date(),
            "title": itemTitle,
            "description": desc,
            "price": price,
            "category": category,
            "status": "ready",
            "tags": Array(tokensArr),
            "itemIdentifier": convertedId,
            "isReviewed": false,
            "type": type,
            "deliveryMethod": deliveryMethod,
            "saleFormat": saleFormat,
            "files": urlStrings,
            "IPFS": ipfsURLStrings,
            "paymentMethod": paymentMethod,
            "bidderTokens": [],
            "bidders": [],
            "shippingInfo": shippingInfoData,
            "saleType": SaleType.newSale.rawValue,
            "isWithdrawn": isWithdrawn, // There are contracts like Auction or SimplePayment that requires the bidders that have been outbid or the seller whose item has been purchased, respectively, that require the user to withdraw their funds manually
            "isAdminWithdrawn": isAdminWithdrawn, // The fee collected by the admin
            "tokenId": tokenId
        ]
        
        // txHash is either minting or transferring the ownership
        ref.document(id).setData(postData) { (error) in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            } else {
                promise(.success(true))
            }
        }
    }
    
    // Instead of passing the reference of documentId to be modified,
    // pass let ref = self.db.collection("post") since the documentId sometimes need to be used for other things than the firestore update (i.e. sending messages or calling NFTrack minting method).
    final func createFireStoreEntry(
        senderAddress: String,
        escrowHash: String,
        auctionHash: String,
        solireyUid: String = "N/A",
        mintHash: String,
        itemTitle: String,
        desc: String,
        price: String,
        category: String,
        tokensArr: Set<String>,
        convertedId: String,
        type: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String,
        topics: [String],
        urlStrings: [String?],
        ipfsURLStrings: [String?],
        shippingInfo: ShippingInfo? = nil,
        isWithdrawn: Bool = true,
        isAdminWithdrawn: Bool = true,
        promise: @escaping (Result<Int, PostingError>) -> Void
    ) {
        let ref = self.db.collection("post")
        let id = ref.document().documentID
        
        let shippingInfoData: [String: Any] = [
            "scope": shippingInfo?.scope.stringValue ?? "NA" as String,
            "addresses": shippingInfo?.addresses ?? [] as [String],
            "radius": shippingInfo?.radius ?? 0,
            "longitude": shippingInfo?.longitude ?? 0,
            "latitude": shippingInfo?.latitude ?? 0
        ]
        
        let postData: [String: Any] = [
            "sellerUserId": userId as Any,
            "senderAddress": senderAddress,
            "escrowHash": escrowHash,
            "auctionHash": auctionHash,
            "solireyUid": solireyUid,
            "mintHash": mintHash,
            "date": Date(),
            "title": itemTitle,
            "description": desc,
            "price": price,
            "category": category,
            "status": "ready",
            "tags": Array(tokensArr),
            "itemIdentifier": convertedId,
            "isReviewed": false,
            "type": type,
            "deliveryMethod": deliveryMethod,
            "saleFormat": saleFormat,
            "files": urlStrings,
            "IPFS": ipfsURLStrings,
            "paymentMethod": paymentMethod,
            "bidderTokens": [],
            "bidders": [],
            "shippingInfo": shippingInfoData,
            "saleType": SaleType.newSale.rawValue,
            "isWithdrawn": isWithdrawn, // There are contracts like Auction or SimplePayment that requires the bidders that have been outbid or the seller whose item has been purchased, respectively, that require the user to withdraw their funds manually
            "isAdminWithdrawn": isAdminWithdrawn // The fee collected by the admin
        ]
        
        // txHash is either minting or transferring the ownership
        ref.document(id).setData(postData) { (error) in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            } else {
                return FirebaseService.shared.getTokenId1(topics: topics, documentId: id, promise: promise)
            }
        }
    }

    final func confirmEtherTransactionsNoDelay(
        txHash: String,
        confirmations: Int = 3
    ) -> AnyPublisher<[TransactionReceipt], PostingError> {
        var receiptRetainer: TransactionReceipt!
        var cycleCount: Int = 0
        let hashPublisher = CurrentValueSubject<String, Never>(txHash)
        return hashPublisher
            .setFailureType(to: PostingError.self)
            .flatMap { (txHash) -> AnyPublisher<TransactionReceipt, PostingError> in
                return Future<TransactionReceipt, PostingError> { promise in
                    DispatchQueue.global().async {
                        Web3swiftService.getReceipt(hash: txHash, promise: promise)
                    }
                }
                .eraseToAnyPublisher()
            }
            .retryIfWithDelay(
                retries: 5,
                delay: .seconds(10),
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
            .flatMap { (receipt) -> AnyPublisher<BigUInt, PostingError> in
                receiptRetainer = receipt
                return Future<BigUInt, PostingError> { promise in
                    Web3swiftService.getBlock(promise)
                }
                .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] (currentBlock) in
                let txConfirmations = currentBlock - receiptRetainer.blockNumber
                print("txConfirmations", txConfirmations)
                if txConfirmations >= confirmations {
                    print("Transaction with hash \(txHash) has been successfully confirmed.")
                    hashPublisher.send(completion: .finished)
                } else {
                    cycleCount += 1
                    print("cycle count: ", cycleCount)
                    self?.delay(10) {
                        hashPublisher.send(txHash)
                    }
                }
            })
            .map { (value) -> TransactionReceipt in
                return receiptRetainer
            }
            .collect()
            .eraseToAnyPublisher()
    }
    
    // Get the receipt from the hash of the transaction.
    // The receipt doesn't appear right away after the transaction which means repeatedly query until the receipt is ready.
    // This transaction has been included and will be reflected in a short while.
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
    
    // Confirms that a block has been added to the blockchain by counting the number of confirmations.
    final func confirmTransactions(_ receipt: TransactionReceipt, confirmations: Int = 3) -> AnyPublisher<TransactionReceipt, PostingError> {
        Deferred {
            Future<BigUInt, PostingError> { promise in
                Web3swiftService.getBlock(promise)
            }
            .eraseToAnyPublisher()
        }
        .flatMap { (currentBlock) -> AnyPublisher<TransactionReceipt, PostingError> in
            let txConfirmations = currentBlock - receipt.blockNumber
            return Future<TransactionReceipt, PostingError> { promise in
                print("txConfirmations", txConfirmations)
                if txConfirmations >= confirmations {
                    promise(.success(receipt))
                } else {
//                    if let txConfirmsNumber = Int(txConfirmations.description) {
//                        let update: [String: Int] = ["update": txConfirmsNumber]
//                        NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update)
//                    }
                    
                    promise(.failure(.generalError(reason: "pending")))
                }
            }
            .eraseToAnyPublisher()
        }
        .retryIfWithDelay(
            retries: 20,
            delay: .seconds(5),
            scheduler: DispatchQueue.global()
        ) { (error) -> Bool in
            // the tx hash returns no receipt right after the transaction
            // retry if none returns, but with delay
            if case let PostingError.generalError(reason: msg) = error,
               msg == "pending" {
                return true
            }
            return false
        }
    }
        
    final func estimateGas(gasEstimate: BigUInt, completion: @escaping ((totalGasCost: String, balance: String, gasPriceInGwei: String)?, PostingError?) -> Void)  {
        var gasPrice: BigUInt!
        do {
            gasPrice = try Web3swiftService.web3instance.eth.getGasPrice()
        } catch {
            completion(nil, .generalError(reason: "Unable to fetch the current gas price. Please try again later."))
            return
        }
        
        let totalGasCost = gasEstimate * gasPrice
        
        guard let convertedTotalGasCost = Web3.Utils.formatToEthereumUnits(totalGasCost, toUnits: .eth) else {
            completion(nil, .generalError(reason: "Unable to convert the unit of the gas cost. Please try restarting the app."))
            return
        }
        
        var balance: BigUInt!
        do {
            balance = try Web3swiftService.web3instance.eth.getBalance(address: Web3swiftService.currentAddress!)
        } catch {
            completion(nil, .generalError(reason:  "Unable to retrieve the balance of your wallet. Please try restarting the app."))
            return
        }
        
        guard let convertedBalance = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth) else {
            completion(nil, .generalError(reason:  "Unable to convert the unit of your wallet balance. Please try restarting the app."))
            return
        }
        
        guard let gasPriceInGwei = Web3.Utils.formatToEthereumUnits(gasPrice, toUnits: .Gwei) else {
            completion(nil, .generalError(reason:  "Unable to convert the unit of the gas price. Please try restarting the app."))
            return
        }
        
        completion((convertedTotalGasCost, convertedBalance, gasPriceInGwei), nil)
    }
    
    final func estimateGas(
        gasEstimate: BigUInt,
        promise: @escaping (Result<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError>) -> Void
    )  {
        var gasPrice: BigUInt!
        do {
            gasPrice = try Web3swiftService.web3instance.eth.getGasPrice()
        } catch {
            promise(.failure(.generalError(reason: "Unable to fetch the current gas price. Please try again later.")))
            return
        }
        
        let totalGasCost = gasEstimate * gasPrice
        
        guard let convertedTotalGasCost = Web3.Utils.formatToEthereumUnits(totalGasCost, toUnits: .eth, decimals: 9) else {
            promise(.failure(.generalError(reason: "Unable to convert the unit of the gas cost. Please try restarting the app.")))
            return
        }
        
        let trimmedTotalGasCost = stripZeros(convertedTotalGasCost)
        
        var balance: BigUInt!
        do {
            balance = try Web3swiftService.web3instance.eth.getBalance(address: Web3swiftService.currentAddress!)
        } catch {
            promise(.failure(.generalError(reason:  "Unable to retrieve the balance of your wallet. Please try restarting the app.")))
            return
        }
        
        guard let convertedBalance = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth) else {
            promise(.failure(.generalError(reason:  "Unable to convert the unit of your wallet balance. Please try restarting the app.")))
            return
        }
        
        guard let gasPriceInGwei = Web3.Utils.formatToEthereumUnits(gasPrice, toUnits: .Gwei) else {
            promise(.failure(.generalError(reason:  "Unable to convert the unit of the gas price. Please try restarting the app.")))
            return
        }
        
        promise(.success((trimmedTotalGasCost, convertedBalance, gasPriceInGwei)))
    }

    final func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    // MARK: - prelaunch
    /// The purposes of prelaunch are two folds:
    ///     1. Checking for the duplicate on firestore (eventually eliminate the checkExistingId method if prelaunch is universalized)
    ///     2. Estimate the total gas fee in the format that the execution completion handler can understand with the transaction of any kind provided as a parameter
    final func preLaunch(
//        mintParameters: MintParameters,
        transactionToEstimate: @escaping () -> AnyPublisher<TxPackage, PostingError>,
        completionHandler: @escaping ((totalGasCost: String, balance: String, gasPriceInGwei: String)?, TxPackage?, PostingError?) -> Void
    ) {
        
        var txPackageRetainer: TxPackage!

        transactionToEstimate()
        .flatMap({ [weak self] (txPackage) -> AnyPublisher<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> in
            txPackageRetainer = txPackage
            return Future<(totalGasCost: String, balance: String, gasPriceInGwei: String), PostingError> { promise in
                self?.estimateGas(
                    gasEstimate: txPackage.gasEstimate,
                    promise: promise
                )
            }
            .eraseToAnyPublisher()
        })
        .sink { (completion) in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    completionHandler(nil, nil, error)
                    break
            }
        } receiveValue: { (estimates) in
            completionHandler(estimates, txPackageRetainer, nil)
        }
        .store(in: &self.storage)
    }
}
