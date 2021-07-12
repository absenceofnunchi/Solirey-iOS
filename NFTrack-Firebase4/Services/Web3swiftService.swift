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
    
    static func getReceipt(hash: String, promise: @escaping (Result<TransactionReceipt, PostingError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let receipt = try web3instance.eth.getTransactionReceipt(hash)
                promise(.success(receipt))
            } catch {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            }
        }
    }
}

