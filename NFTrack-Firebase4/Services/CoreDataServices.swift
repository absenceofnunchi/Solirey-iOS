//
//  CoreDataServices.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import Foundation
import CoreData

class LocalDatabase {
    lazy var container: NSPersistentCloudKitContainer = NSPersistentCloudKitContainer(name: "CoreDataModel")
    private lazy var mainContext = self.container.viewContext
    
    init() {
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
    }
    
    func getWallet() -> KeyWalletModel? {
        let requestWallet: NSFetchRequest<KeyWallet> = KeyWallet.fetchRequest()
        
        do {
            let results = try mainContext.fetch(requestWallet)
            guard let result = results.first else { return nil }
            return KeyWalletModel.fromCoreData(crModel: result)
        } catch {
            print(error)
            return nil
        }
    }
    
    func saveWallet(isRegistered: Bool, wallet: KeyWalletModel, completion: @escaping (WalletSavingError?) -> Void) {
        container.performBackgroundTask { [weak self](context) in
            
            self?.deleteWallet { (error) in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
                
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: "KeyWallet", into: context) as? KeyWallet else { return }
                entity.address = wallet.address
                entity.data = wallet.data
                
                do {
                    try context.save()
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(WalletSavingError.couldNotSaveTheWallet)
                    }
                }
            }
        }
    }
    
    func deleteWallet(completion: @escaping (WalletSavingError?) -> Void) {
        let requestWallet: NSFetchRequest<KeyWallet> = KeyWallet.fetchRequest()
        
        do {
            let result = try mainContext.fetch(requestWallet)
            print("result", result)
            for item in result {
                mainContext.delete(item)
            }
            
            try mainContext.save()
            completion(nil)
        } catch {
            DispatchQueue.main.async {
                completion(WalletSavingError.couldNotDeleteTheWallet)
            }
        }
    }
    
//    func getAllTransactionHashes() -> [TxModel]? {
//        let requestTransaction: NSFetchRequest<TransactionModel> = TransactionModel.fetchRequest()
//
//        do {
//            let results = try mainContext.fetch(requestTransaction)
//
//            let tx = results.map { result in
//                return TxModel.fromCoreData(crModel: result)
//            }
//            return tx
//        } catch {
//            print(error)
//            return nil
//        }
//    }
//
//    func getAllTransactionHashes(walletAddress: String) -> [TxModel]? {
//        let requestTransaction: NSFetchRequest<TransactionModel> = TransactionModel.fetchRequest()
//        requestTransaction.predicate = NSPredicate(format: "walletAddress == %@", walletAddress)
//        let sort = NSSortDescriptor(key: "date", ascending: true)
//        requestTransaction.sortDescriptors = [sort]
//
//        do {
//            let results = try mainContext.fetch(requestTransaction)
//
//            let tx = results.map { result in
//                return TxModel.fromCoreData(crModel: result)
//            }
//            return tx
//        } catch {
//            print(error)
//            return nil
//        }
//    }
//
//    func getAllTransactionHashes(walletAddress: String, predicateName: String, predicate: String) -> [TxModel]? {
//        let requestTransaction: NSFetchRequest<TransactionModel> = TransactionModel.fetchRequest()
//        let walletAddressPredicate =  NSPredicate(format: "walletAddress == %@", walletAddress)
//        let additionalPredicate = NSPredicate(format: "\(predicateName) == %@", predicate)
//        requestTransaction.predicate = NSCompoundPredicate(type: .and, subpredicates: [walletAddressPredicate, additionalPredicate])
//        let sort = NSSortDescriptor(key: "date", ascending: true)
//        requestTransaction.sortDescriptors = [sort]
//
//        do {
//            let results = try mainContext.fetch(requestTransaction)
//
//            let tx = results.map { result in
//                return TxModel.fromCoreData(crModel: result)
//            }
//            return tx
//        } catch {
//            print(error)
//            return nil
//        }
//    }
//
//    func getTransactionHash(fileHash: String) -> TxModel? {
//        let requestTransaction: NSFetchRequest<TransactionModel> = TransactionModel.fetchRequest()
//        requestTransaction.predicate = NSPredicate(format: "fileHash == %@", fileHash)
//        let sort = NSSortDescriptor(key: "date", ascending: true)
//        requestTransaction.sortDescriptors = [sort]
//
//        do {
//            let results = try mainContext.fetch(requestTransaction)
//            guard let result = results.first else { print("no data"); return nil }
//            return TxModel.fromCoreData(crModel: result)
//        } catch {
//            print(error)
//            return nil
//        }
//    }
    
    // for sending ether from the wallet
    //    func saveTransactionDetail(result: TxModel, completion: @escaping (Error?) -> Void) {
    //        container.performBackgroundTask { (context) in
    //            guard let entity = NSEntityDescription.insertNewObject(forEntityName: "TransactionModel", into: context) as? TransactionModel else { return }
    //            entity.gasPrice = result.gasPrice
    //            entity.gasLimit = result.gasLimit
    //            entity.toAddress = result.toAddress
    //            entity.value = result.value
    //            entity.date = result.date
    //            entity.nonce = result.nonce
    //
    //            do {
    //                try context.save()
    //                DispatchQueue.main.async {
    //                    completion(nil)
    //                }
    //            } catch {
    //                DispatchQueue.main.async {
    //                    completion(error)
    //                }
    //            }
    //        }
    //    }
    
    // for uploading files
//    func saveTransactionDetail(walletAddress: String, txHash: String, fileHash: String? = nil, date: Date, txType: TransactionType) {
//        container.performBackgroundTask { (context) in
//            guard let entity = NSEntityDescription.insertNewObject(forEntityName: "TransactionModel", into: context) as? TransactionModel else { return }
//            entity.walletAddress = walletAddress
//            entity.transactionHash = txHash
//            entity.fileHash = fileHash
//            entity.date = date
//            entity.transactionType = txType.rawValue
//
//            do {
//                try context.save()
//            } catch {
//                print("error saving the upload detail")
//            }
//        }
//    }
}
