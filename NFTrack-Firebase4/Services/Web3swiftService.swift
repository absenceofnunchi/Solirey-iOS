//
//  Web3swiftService.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import Foundation
import web3swift
import BigInt
import Combine

class Web3swiftService {
    static let keyservice = KeysService()
    
    static var web3instance: web3 {
        let web3Rinkeby = Web3.InfuraRinkebyWeb3()
        web3Rinkeby.addKeystoreManager(self.keyservice.keystoreManager())
        return web3Rinkeby
    }
    
    //    static var web3instance: web3 {
    //        let web3Ropsten = Web3.InfuraRopstenWeb3()
    //        web3Ropsten.addKeystoreManager(self.keyservice.keystoreManager())
    //        return web3Ropsten
    //    }
    
    static var currentAddress: EthereumAddress? {
        let wallet = self.keyservice.selectedWallet()
        guard let address = wallet?.address else {
            return nil
        }
        let ethAddressFrom =  EthereumAddress(address)
        return ethAddressFrom
    }
    
    static var currentAddressString: String? {
        let wallet = self.keyservice.selectedWallet()
        guard let address = wallet?.address else {
            return nil
        }
        return address
    }
    
    func isEthAddressValid(address: String) -> Bool {
        if EthereumAddress(address) != nil {
            return true
        }
        
        return false
    }
    
    // uses the transaction hash to get the contract address
    // ex) uses the auction contract deployment transaction hash to get the contract address of the auction contract
    static func getReceipt(hash: String, promise: @escaping (Result<TransactionReceipt, PostingError>) -> Void) {
        do {
            let receipt = try web3instance.eth.getTransactionReceipt(hash)
            promise(.success(receipt))
        } catch {
            if let err = error as? Web3Error {
                print("getReceipt error1", error)
                promise(.failure(.generalError(reason: err.errorDescription)))
            } else {
                print("getReceipt error2", error)
                promise(.failure(.generalError(reason: error.localizedDescription)))
            }
        }
        
//        DispatchQueue.global(qos: .userInitiated).async {
//
//        }
    }
    
    static func getBlock(_ promise: @escaping (Result<BigUInt, PostingError>) -> Void) {
        do {
            let currentBlock = try Web3swiftService.web3instance.eth.getBlockNumber()
            promise(.success(currentBlock))
            //            return receipt.blockNumber == nil ? 0 : currentBlock.number - receipt.blockNumber
        } catch {
            promise(.failure(PostingError.generalError(reason: "Unable to get the current block.")))
        }
    }
}

