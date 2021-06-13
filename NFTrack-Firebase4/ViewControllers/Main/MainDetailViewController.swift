//
//  MainDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit
import FirebaseFirestore

class MainDetailViewController: ParentListViewController {
    var category: String! {
        didSet {
            title = category!
            FirebaseService.sharedInstance.db.collection("post")
                .whereField("category", isEqualTo: category! as String)
                .whereField("status", isEqualTo: "ready")
                .getDocuments() { [weak self](querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.postArr = data
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    }
                }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
}

extension MainDetailViewController {
    // MARK: - didRefreshTableView
    override func didRefreshTableView() {
        
    }
    
    override func configureUI() {
        super.configureUI()
        
        tableView = configureTableView(delegate: self, dataSource: self, height: 100, cellType: MainDetailCell.self, identifier: MainDetailCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
}

extension MainDetailViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainDetailCell.identifier) as? MainDetailCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
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
}

