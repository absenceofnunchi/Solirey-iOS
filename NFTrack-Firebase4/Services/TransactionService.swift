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
        
        DispatchQueue.global().async {
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
            
            DispatchQueue.main.async {
                completion(transaction, nil)
            }
        }
    }
    
    // MARK: - prepareTransactionForMinting
    func prepareTransactionForMinting(completion: @escaping (WriteTransaction?, SendEthErrors?) -> Void) {
        DispatchQueue.global().async {
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
    }
    
    // MARK: - prepareTransactionForReading
    func prepareTransactionForReading(method: String, abi: String = purchaseABI2, contractAddress: EthereumAddress, completion: @escaping (ReadTransaction?, SendEthErrors?) -> Void) {
        guard let address = Web3swiftService.currentAddress else { return }
        var options = TransactionOptions.defaultOptions
        options.from = address
        options.gasLimit = TransactionOptions.GasLimitPolicy.automatic
        options.gasPrice = TransactionOptions.GasPricePolicy.automatic
        
        DispatchQueue.global().async {
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
    }
    
    func prepareTransactionForWriting(method: String, abi: String = purchaseABI2, param: [AnyObject] = [AnyObject](), contractAddress: EthereumAddress, amountString: String = "0", completion: @escaping (WriteTransaction?, SendEthErrors?) -> Void) {
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
            
            guard let transaction = contract.write(method, parameters: param, extraData: Data(), transactionOptions: options) else {
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

//TransactionSendingResult(transaction: Transaction
//                         Nonce: 99
//                         Gas price: 1000000000
//                         Gas limit: 57289
//                         To: 0x656f9BF02FA8EfF800f383E5678e699ce2788C5C
//                         Value: 0
//                         Data: 0xe9c2e14b0000000000000000000000009ce24c07aab108283b3518c6801c6e757b0c514c
//                         v: 43
//                         r: 2280159737137638003207476698716749457091804291606456927160914703478058179025
//                         s: 1626766791259019315163922223723536520307630036486086251261618980737456711270
//                         Intrinsic chainID: Optional(4)
//                         Infered chainID: Optional(4)
//                         sender: Optional("0x9Ce24C07AaB108283b3518c6801c6E757b0C514C")
//                         hash: Optional("0x0cd134994977be4e5294d9c95b2b05a30240398495c68ab739699418bf8c0225")
//                         , hash: "0x0cd134994977be4e5294d9c95b2b05a30240398495c68ab739699418bf8c0225")

//TransactionSendingResult(transaction: Transaction
//                         Nonce: 80
//                         Gas price: 1000000000
//                         Gas limit: 57289
//                         To: 0x656f9BF02FA8EfF800f383E5678e699ce2788C5C
//                         Value: 0
//                         Data: 0xe9c2e14b0000000000000000000000006879f0a123056b5bb56c7e787cf64a67f3a16a71
//                         v: 43
//                         r: 68050701568546023666251596280823648350722752180838243890427235514308429619001
//                         s: 4250613332262705056579686434897004420380205267553040033091827715143850010970
//                         Intrinsic chainID: Optional(4)
//                         Infered chainID: Optional(4)
//                         sender: Optional("0x6879f0A123056B5Bb56c7E787cF64A67f3a16a71")
//                         hash: Optional("0x83c91bfdbe0fba135d447c84d7c93c242e09e7415c02517e343247d7107781ed")
//                         , hash: "0x83c91bfdbe0fba135d447c84d7c93c242e09e7415c02517e343247d7107781ed")

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
