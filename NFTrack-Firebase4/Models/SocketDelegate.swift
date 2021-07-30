//
//  SocketDelegate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-29.
//

import UIKit
import web3swift
import Combine

class SocketDelegate: Web3SocketDelegate {
    final var socketProvider: InfuraWebsocketProvider? = nil
    final weak var delegate: SocketMessageDelegate?
    final var didReceiveTopics: (([String]) -> Void)?
    final var promise: ((Result<[String: Any], PostingError>) -> Void)!
    final var passThroughSubject: PassthroughSubject<[String: Any], PostingError>!
    
    init(
        contractAddress: EthereumAddress,
        topics: [String]? = nil,
        promise: ((Result<[String: Any], PostingError>) -> Void)?  = nil,
        passThroughSubject: PassthroughSubject<[String: Any], PostingError>? = nil
    ) {
        self.promise = promise
        self.passThroughSubject = passThroughSubject
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
        if let dict = message as? [String: Any] {
            // if the socket is needed multiple times to send the messages
            // like the auction specs everytime someone bids
            // then use the subject
            if let passThroughSubject = passThroughSubject {
                passThroughSubject.send(dict)
            }
            
            // if the socket is needed only once
            // like when you're posting an item
            // then use the promise for the Future publisher
            if let promise = promise {
                promise(.success(dict))
            }
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
