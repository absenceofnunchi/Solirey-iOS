//
//  MainDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import FirebaseFirestore
import web3swift
import Combine

class MainDetailViewController: ParentListViewController<Post>, PostParseDelegate {
    var storage = Set<AnyCancellable>()
    var category: String! {
        didSet {
            guard let category = category,
                  let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) else { return }
            
            title = category
            FirebaseService.shared.db.collection("post")
                .whereField("category", isEqualTo: category as String)
                .whereField("status", isEqualTo: "ready")
                .whereField("bidders", notIn: [userId])
                .order(by: "bidders")
                .order(by: "date", descending: true)
                .getDocuments() { [weak self](querySnapshot, err) in
                    if let err = err {
                        print(err)
                        self?.alert.showDetail("Error fetching data", with: err.localizedDescription, for: self)
                    } else {
                        defer {
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                        
                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.postArr = data
                            self?.dataStore = PostImageDataStore(posts: data)
                        }
                    }
                }
        }
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    // MARK: - didRefreshTableView
    override func didRefreshTableView(index: Int) {
        
    }
    
    override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: 330, cellType: CardCell.self, identifier: CardCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.identifier) as? CardCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        
        guard let saleFormat = SaleFormat(rawValue: post.saleFormat) else {
            self.alert.showDetail("Error", with: "There was an error accessing the item data.", for: self)
            return
        }
        
        switch saleFormat {
            case .onlineDirect:
                let listDetailVC = ListDetailViewController()
                listDetailVC.post = post
                // refreshes the MainDetailVC table when the user updates the status
                listDetailVC.tableViewRefreshDelegate = self
                self.navigationController?.pushViewController(listDetailVC, animated: true)
            case .openAuction:
                guard let auctionHash = post.auctionHash else { return }
                print("auctionHash", auctionHash)

                Future<TransactionReceipt, PostingError> { promise in
                    Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
                }
                .sink { [weak self] (completion) in
                    switch completion {
                        case .failure(let error):
                            self?.alert.showDetail("Contract Address Loading Error", with: error.localizedDescription, for: self)
                        case .finished:
                            break
                    }
                } receiveValue: { [weak self] (receipt) in
                    guard let contractAddress = receipt.contractAddress,
                          let currentAddress = Web3swiftService.currentAddress else {
                        self?.alert.showDetail("Wallet Addres Loading Error", with: "Please ensure that you're logged into your wallet.", for: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
                        auctionDetailVC.post = post
                        self?.navigationController?.pushViewController(auctionDetailVC, animated: true)
                    }
                }
                .store(in: &storage)
        }
    }
}

//guard let myContractAddress = Web3swiftService.currentAddress else {
//    self.alert.showDetail("Wallet Not Logged In.", with: "You have to be logged into your wallet to continue.", for: self, buttonAction: {
//
//    }, completion:  {
//
//    })
//    return
//}
