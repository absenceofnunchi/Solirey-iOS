//
//  ListDetailViewController + History.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//

import UIKit

extension ListDetailViewController {
    // MARK: - getHistory
    func getHistory() {
        FirebaseService.sharedInstance.db.collection("post")
            .whereField("itemIdentifier", isEqualTo: post.id)
            .getDocuments { [weak self] (querySnapshot, err) in
                if let err = err {
                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self!)
                } else {
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.historicData = data
                        DispatchQueue.main.async {
                            self?.historyTableViewHeight = CGFloat(self!.historicData.count) * self!.CELL_HEIGHT
                            NSLayoutConstraint.activate([
                                self!.historyTableView.heightAnchor.constraint(equalToConstant: self!.historyTableViewHeight),
                            ])
                            self?.historyTableView.reloadData()
                        }
                    }
                }
            }
    }
}

extension ListDetailViewController {
    func setHistoryVC() {
        historyTableView = UITableView()
        historyTableView.translatesAutoresizingMaskIntoConstraints = false
        historyTableView.register(HistoryCell.self, forCellReuseIdentifier: Cell.historyCell)
        historyTableView.isScrollEnabled = false
        historyTableView.rowHeight = CELL_HEIGHT
        historyTableView.estimatedRowHeight = CELL_HEIGHT
        historyTableView.dataSource = self
        historyTableView.delegate = self
        historyTableView.separatorStyle = .none
        scrollView.addSubview(historyTableView)

        NSLayoutConstraint.activate([
            historyTableView.topAnchor.constraint(equalTo: updateStatusButton.bottomAnchor, constant: 40),
            historyTableView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyTableView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}


extension ListDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historicData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.historyCell, for: indexPath) as! HistoryCell
        cell.selectionStyle = .none
        let data = historicData[indexPath.row]
        let date = data.date
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let formattedDate = formatter.string(from: date)
        cell.dateLabel.text = formattedDate
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
        let historyDetailVC = HistoryDetailViewController()
        self.navigationController?.pushViewController(historyDetailVC, animated: true)
    }
}
