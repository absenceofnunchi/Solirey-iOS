//
//  TransactionServicer.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

import Foundation
import web3swift
import BigInt
import PromiseKit

class TransactionService {
    let keysService = KeysService()
    
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
                                      completion:  @escaping (WriteTransaction?, SendEthErrors?) -> Void) {
        guard let address = Web3swiftService.currentAddress else { return }
        var balance: BigUInt!
        
        DispatchQueue.global().async {
            balance = try? Web3swiftService.web3instance.eth.getBalance(address: address)
            
            guard let destinationAddressString = destinationAddressString, !destinationAddressString.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.emptyDestinationAddress)
                }
                return
            }
            
            guard let amountString = amountString, !amountString.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.emptyAmount)
                }
                return
            }
            
            guard let destinationEthAddress = EthereumAddress(destinationAddressString) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.invalidDestinationAddress)
                }
                return
            }
            
            guard let amount = Web3.Utils.parseToBigUInt(amountString, units: .eth) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.invalidAmountFormat)
                }
                return
            }
            
            guard amount > 0 else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.zeroAmount)
                }
                return
            }
            
            guard amount <= (balance ?? 0) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.insufficientFund)
                }
                return
            }
            
            var options = TransactionOptions.defaultOptions
            options.from = address
            options.value = BigUInt(amount)
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            let web3 = Web3swiftService.web3instance
            guard let contract = web3.contract(Web3.Utils.coldWalletABI, at: destinationEthAddress, abiVersion: 2) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.contractLoadingError)
                }
                return
            }
            
            guard let transaction = contract.write("fallback", parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.createTransactionIssue)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(transaction, nil)
            }
        }
    }
    
    // MARK: - prepareTransactionForNewContract
    func prepareTransactionForNewContract(value: String, completion: @escaping (WriteTransaction?, SendEthErrors?) -> Void) {
        guard let address = Web3swiftService.currentAddress else { return }
        var options = TransactionOptions.defaultOptions
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        guard let amount = Web3.Utils.parseToBigUInt(value, units: .eth) else {
            DispatchQueue.main.async {
                completion(nil, SendEthErrors.invalidAmountFormat)
            }
            return
        }
        options.value = BigUInt(amount)
        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(purchaseABI2) else {
            DispatchQueue.main.async {
                completion(nil, SendEthErrors.contractLoadingError)
            }
            return
        }
        
        let bytecode = Data(hex: purchaseBytecode2)
        guard let transaction = contract.deploy(bytecode: bytecode, parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
            DispatchQueue.main.async {
                completion(nil, SendEthErrors.createTransactionIssue)
            }
            return
        }
        
        completion(transaction, nil)
    }
    
    // MARK: - prepareTransactionForMinting
    func prepareTransactionForMinting(completion: @escaping (WriteTransaction?, SendEthErrors?) -> Void) {
        guard let address = Web3swiftService.currentAddress else { return }
        var options = TransactionOptions.defaultOptions
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic

        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(NFTrackABI, at: NFTrackAddress, abiVersion: 2) else {
            DispatchQueue.main.async {
                completion(nil, SendEthErrors.contractLoadingError)
            }
            return
        }
        
        let parameters: [AnyObject] = [Web3swiftService.currentAddressString!] as [AnyObject]
        guard let transaction = contract.write("mintNft", parameters: parameters, extraData: Data(), transactionOptions: options) else {
            DispatchQueue.main.async {
                completion(nil, SendEthErrors.createTransactionIssue)
            }
            return
        }
        
        DispatchQueue.main.async {
            completion(transaction, nil)
        }
    }
    
    // MARK: - prepareTransactionForReading
    func prepareTransactionForReading(method: String, abi: String = someABI, contractAddress: EthereumAddress, completion: @escaping (ReadTransaction?, SendEthErrors?) -> Void) {
        guard let address = Web3swiftService.currentAddress else { return }
        var options = TransactionOptions.defaultOptions
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        let web3 = Web3swiftService.web3instance
        guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
            DispatchQueue.main.async {
                completion(nil, SendEthErrors.contractLoadingError)
            }
            return
        }
        
        guard let transaction = contract.read(method, parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
            DispatchQueue.main.async {
                completion(nil, SendEthErrors.createTransactionIssue)
            }
            return
        }

        DispatchQueue.main.async {
            completion(transaction, nil)
        }
    }
    
    func prepareTransactionForWriting(method: String, abi: String = someABI, contractAddress: EthereumAddress, amountString: String = "0", completion: @escaping (WriteTransaction?, SendEthErrors?) -> Void) {
        let web3 = Web3swiftService.web3instance
        guard let myAddress = Web3swiftService.currentAddress else { return }
        var balance: BigUInt!
        DispatchQueue.global().async {
            balance = try? web3.eth.getBalance(address: myAddress)
            
            guard !amountString.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.emptyAmount)
                }
                return
            }
            
            guard let amount = Web3.Utils.parseToBigUInt(amountString, units: .eth) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.invalidAmountFormat)
                }
                return
            }
            
            guard amount >= 0 else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.zeroAmount)
                }
                return
            }
            
            guard amount <= (balance ?? 0) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.insufficientFund)
                }
                return
            }
            
            var options = TransactionOptions.defaultOptions
            options.from = myAddress
            options.value = amount
            options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
            options.gasPrice = TransactionOptions.GasPricePolicy.automatic
            
            guard let contract = web3.contract(abi, at: contractAddress, abiVersion: 2) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.contractLoadingError)
                }
                return
            }
            
            guard let transaction = contract.write(method, parameters: [AnyObject](), extraData: Data(), transactionOptions: options) else {
                DispatchQueue.main.async {
                    completion(nil, SendEthErrors.createTransactionIssue)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(transaction, nil)
            }
        }
    }
}

//        options.gasPrice = .manual(BigUInt(gasPrice))
//        options.gasLimit = .manual(BigUInt(gasLimit))
//if let gasPrice = gasPrice,
//   let wei = Web3.Utils.parseToBigUInt(gasPrice, units: .eth) {
//    options.gasLimit = .manual(defaultGasLimitForTokenTransfer)
//    options.gasPrice = .manual(wei)
//}

