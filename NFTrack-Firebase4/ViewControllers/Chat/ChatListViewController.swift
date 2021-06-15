//
//  ChatListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit
import Firebase

class ChatListViewController: ParentListViewController<ChatListModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar(vc: self)
        fetchChatList()
    }
    
    override func setDataStore(postArr: [ChatListModel]) {
        dataStore = ChatImageDataStore(posts: postArr, userId: userId)
    }
    
    override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: 120, cellType: MainDetailCell.self, identifier: MainDetailCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainDetailCell.identifier) as? MainDetailCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        cell.userId = userId
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? MainDetailCell else { return }
        
        // How should the operation update the cell once the data has been loaded?
        let updateCellClosure: (UIImage?) -> () = { [unowned self] (image) in
            cell.updateAppearanceFor(.fetched(image))
            self.loadingOperations.removeValue(forKey: indexPath)
        }
        
        // Try to find an existing data loader
        if let dataLoader = loadingOperations[indexPath] {
            // Has the data already been loaded?
            if let image = dataLoader.image {
                cell.updateAppearanceFor(.fetched(image))
                loadingOperations.removeValue(forKey: indexPath)
            } else {
                // No data loaded yet, so add the completion closure to update the cell once the data arrives
                dataLoader.loadingCompleteHandler = updateCellClosure
            }
        } else {
            // Need to create a data loaded for this index path
            if let dataLoader = dataStore.loadImage(at: indexPath.row) {
                // Provide the completion closure, and kick off the loading operation
                dataLoader.loadingCompleteHandler = updateCellClosure
                loadingQueue.addOperation(dataLoader)
                loadingOperations[indexPath] = dataLoader
            } else {
                //                cell.updateAppearanceFor(.none(post))
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let post = postArr[indexPath.row]
//        let listDetailVC = ListDetailViewController()
//        listDetailVC.post = post
//        listDetailVC.tableViewRefreshDelegate = self
//        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
}

extension ChatListViewController {
    func fetchChatList() {
        let docRef = FirebaseService.shared.db.collection("chatrooms")
        docRef.getDocuments { [weak self] (document, error) in
            if let document = document,
               !document.isEmpty {
                for doc in document.documents {
                    let data = doc.data()
                    var buyerDisplayName, sellerDisplayName, docId, latestMessage, date, buyerPhotoURL, sellerPhotoURL, sellerId: String!
                    data.forEach { (item) in
                        switch item.key {
                            case "buyerDisplayName":
                                buyerDisplayName = item.value as? String
                            case "buyerPhotoURL":
                                buyerPhotoURL = item.value as? String
                            case "docId":
                                docId = item.value as? String
                            case "latestMessage":
                                latestMessage = item.value as? String
                            case "sellerDisplayName":
                                sellerDisplayName = item.value as? String
                            case "sellerPhotoURL":
                                sellerPhotoURL = item.value as? String
                            case "sentAt":
                                let timeStamp = item.value as? Timestamp
                                if let dateValue = timeStamp?.dateValue() {
                                    let formatter = DateFormatter()
                                    formatter.dateStyle = .long
                                    date = formatter.string(from: dateValue)
                                } else {
                                    date = "N/A"
                                }
                            case "sellerId":
                                sellerId = item.value as? String
                            default:
                                break
                        }
                    }
                    let chatListModel = ChatListModel(docId: docId, latestMessage: latestMessage, date: date, buyerDisplayName: buyerDisplayName, buyerPhotoURL: buyerPhotoURL, sellerDisplayName: sellerDisplayName, sellerPhotoURL: sellerPhotoURL, sellerId: sellerId)
                    self?.postArr.append(chatListModel)
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } else {
                print("no data")
            }
        }
    }
}