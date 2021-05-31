//
//  SocketDelegate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-29.
//

import UIKit
import web3swift

class SocketDelegate: Web3SocketDelegate {
    var socketProvider: InfuraWebsocketProvider? = nil
    
    init() {
        configure()
    }
    
    deinit {
        if socketProvider != nil {
            socketProvider!.disconnectSocket()
        }
    }
    
    // Protocol method, here will be messages, received from WebSocket server
    func received(message: Any) {
        // Make something with message
        print("received message", message)
    }
    
    func gotError(error: Error) {
        print("error", error)
    }
    
    func configure() {
        //        socketProvider = WebsocketProvider.connectToSocket("wss://rinkeby.infura.io/ws/v3/MY_PROJ_ID", delegate: self)
        self.socketProvider = InfuraWebsocketProvider("wss://rinkeby.infura.io/ws/v3/d011663e021f45e1b07ef4603e28ba90", delegate: self)
        self.socketProvider?.connectSocket()
        
        do {
            try self.socketProvider!.subscribeOnLogs(addresses: [EthereumAddress("0x17c0aa2edbd1cf355fef9543f6705ccdc63cdbb0")!], topics: [])
        } catch {
            print("socket error", error)
        }
    }
}




//    func configureFirebase() {
//        let settings = FirestoreSettings()
//        Firestore.firestore().settings = settings
//        db = Firestore.firestore()
//    }
