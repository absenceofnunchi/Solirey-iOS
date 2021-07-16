//
//  HistoryViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//

import UIKit

class HistoryViewController: UITableViewController, PostParseDelegate {
    private let alert = Alerts()
    private var data = [Post]()
    var itemIdentifier: String! {
        didSet {
            guard let id = itemIdentifier else { return }
            FirebaseService.shared.db.collection("post")
                .whereField("itemIdentifier", isEqualTo: id)
                .getDocuments { [weak self] (querySnapshot, err) in
                    if let err = err {
                        self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self)
                    } else {
                        defer {
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                        
                        if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                            self?.data = data
                        }
                    }
                }
        }
    }
    private let CELL_HEIGHT: CGFloat = 100
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    final override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredSize()
    }
}

extension HistoryViewController {
    final func configureUI() {
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.identifier)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.rowHeight = CELL_HEIGHT
        tableView.estimatedRowHeight = CELL_HEIGHT
    }

    private func calculatePreferredSize() {
        //        let targetSize = CGSize(width: view.bounds.width,
        //                                height: UIView.layoutFittingCompressedSize.height)
        //        print("tableView.systemLayoutSizeFitting(targetSize)", tableView.systemLayoutSizeFitting(targetSize))
        
        let vcHeight: CGFloat = CGFloat(self.data.count) * CELL_HEIGHT
        let targetSize = CGSize(width: view.bounds.width, height: vcHeight)
        preferredContentSize = targetSize
    }
}

extension HistoryViewController {
    final override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.identifier, for: indexPath) as? HistoryCell else {
            fatalError("Table cell could not be loaded.")
        }
        cell.selectionStyle = .none
        let datum = data[indexPath.row]
        if let date = datum.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            let formattedDate = formatter.string(from: date)
            cell.dateLabel.text = formattedDate
        }
        cell.hashLabel.text = datum.sellerHash
        
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
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let datum = data[indexPath.row]
        let historyDetailVC = HistoryDetailViewController()
        historyDetailVC.post = datum
        self.navigationController?.pushViewController(historyDetailVC, animated: true)
    }
}

// following goes on the parent view controller
//    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
//        if let container = container as? HistoryViewController {
//            historyVCHeight = container.preferredContentSize.height
//            let adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 700 )
//            print("adjustedSize", adjustedSize)
//            self.scrollView.contentSize =  adjustedSize
//
//            NSLayoutConstraint.activate([
//                historyVC.view.topAnchor.constraint(equalTo: updateStatusButton.bottomAnchor, constant: 40),
//                historyVC.view.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
//                historyVC.view.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
//                historyVC.view.heightAnchor.constraint(equalToConstant: historyVCHeight),
//            ])
//
//        }
//    }

//var data: [String] {
//    var data = [String]()
//    for i in 1...50 {
//        data.append("\(i)")
//    }
//    return data
//}
