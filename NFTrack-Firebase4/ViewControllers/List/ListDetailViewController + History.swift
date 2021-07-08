//
//  ListDetailViewController + History.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//

import UIKit

extension ListDetailViewController: TableViewConfigurable {
    // MARK: - getHistory
    func getHistory() {
        FirebaseService.shared.db.collection("post")
            .whereField("itemIdentifier", isEqualTo: post.id!)
            .getDocuments { [weak self] (querySnapshot, err) in
                if let err = err {
                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self)
                } else {
                    defer {
                        DispatchQueue.main.async {
                            self?.historyTableViewHeight = CGFloat(self!.historicData.count) * self!.CELL_HEIGHT
                            NSLayoutConstraint.activate([
                                self!.historyTableView.heightAnchor.constraint(equalToConstant: self!.historyTableViewHeight),
                            ])
                            self?.historyTableView.reloadData()
                        }
                    }
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        print("history data", data)
                        self?.historicData = data
                    }
                }
            }
    }
    
    func setHistoryVC() {
//        historyTableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: HistoryCell.self, identifier: HistoryCell.identifier)
        historyTableView.separatorStyle = .none
        historyTableView.isScrollEnabled = false
        scrollView.addSubview(historyTableView)

        NSLayoutConstraint.activate([
            historyTableView.topAnchor.constraint(equalTo: updateStatusButton.bottomAnchor, constant: 40),
            historyTableView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyTableView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
        ])
    }
    
    func fetchUserData(id: String, completion: @escaping (UserInfo?) -> Void) {
        showSpinner {
            let docRef = FirebaseService.shared.db.collection("user").document(id)
            docRef.getDocument { [weak self] (document, error) in
                if let document = document, document.exists {
                    if let data = document.data() {
                        let displayName = data[UserDefaultKeys.displayName] as? String
                        let photoURL = data[UserDefaultKeys.photoURL] as? String
                        let userInfo = UserInfo(email: nil, displayName: displayName!, photoURL: photoURL, uid: nil)
                        self?.hideSpinner {
                            completion(userInfo)
                        }
                    }
                } else {
                    self?.hideSpinner {
                        completion(nil)
                    }
                }
            }
        }
    }
}


extension ListDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historicData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.identifier, for: indexPath) as! HistoryCell
        cell.selectionStyle = .none
        let data = historicData[indexPath.row]
        if let date = data.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            let formattedDate = formatter.string(from: date)
            cell.dateLabel.text = formattedDate
        }
        cell.hashLabel.text = data.sellerHash

        switch indexPath.row {
            case 0:
                cell.cellPosition = .first
            case self.tableView(tableView, numberOfRowsInSection: 0) - 1:
                cell.cellPosition = .last
            default:
                cell.cellPosition = .middle
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = historicData[indexPath.row]
        let historyDetailVC = HistoryDetailViewController()
        historyDetailVC.post = data
//        historyDetailVC.userInfo = userInfo
        self.navigationController?.pushViewController(historyDetailVC, animated: true)
        
//        fetchUserData(id: data.sellerUserId) { [weak self] (userInfo) in
//            if let userInfo = userInfo {
//
//            } else {
//                self?.alert.showDetail("Sorry", with: "Unable to retrieve data. Please try again", for: self)
//            }
//        }
    }
}
