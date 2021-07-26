//
//  SocketDelegate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-29.
//

import UIKit
import web3swift

class SocketDelegate: Web3SocketDelegate {
    final var socketProvider: InfuraWebsocketProvider? = nil
    final weak var delegate: SocketMessageDelegate?
    final var didReceiveTopics: (([String]) -> Void)?
    final var promise: ((Result<[String], PostingError>) -> Void)!
    
    init(contractAddress: EthereumAddress, topics: [String]? = nil) {
        connectSocket(contractAddress: contractAddress, topics: topics)
    }
        
    deinit {
        if socketProvider != nil {
            print("websocket disconnected")
            socketProvider!.disconnectSocket()
        }
    }
    
    func connectSocket(contractAddress: EthereumAddress, topics: [String]? = nil) {
        self.socketProvider = InfuraWebsocketProvider("wss://rinkeby.infura.io/ws/v3/d011663e021f45e1b07ef4603e28ba90", delegate: self)
        self.socketProvider?.connectSocket()
        
        if self.socketProvider != nil {
            do {
                try self.socketProvider!.subscribeOnLogs(addresses: [contractAddress], topics: topics)
            } catch {
                if let promise = promise {
                    promise(.failure(.generalError(reason: error.localizedDescription)))
                }
            }
        }
    }
    
    func disconnectSocket() {
        if socketProvider != nil {
            print("websocket disconnected")
            socketProvider!.disconnectSocket()
        }
    }
    
    // Protocol method, here will be messages, received from WebSocket server
    func received(message: Any) {
        print("message", message)
        if let dict = message as? [String: Any],
           let topics = dict["topics"] as? [String],
           let promise = promise {
            
            promise(.success(topics))
        }
    }
    
    //    func received(message: Any) {
    //        if let dict = message as? [String: Any], let topics = dict["topics"] as? [String] {
    //            delegate?.didReceiveMessage(topics: topics)
    //            if let didReceiveTopics = didReceiveTopics {
    //                didReceiveTopics(topics)
    //            }
    //        }
    //    }
    
    func gotError(error: Error) {
        print("socket error", error)
        if case PostingError.web3Error(let err) = error {
            promise(.failure(.generalError(reason: err.errorDescription)))
        } else {
            promise(.failure(.generalError(reason: error.localizedDescription)))
        }
    }
}
