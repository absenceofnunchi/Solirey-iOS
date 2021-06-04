//
//  HistoryViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//

import UIKit

class HistoryViewController: UITableViewController {
    
    var data: [String] {
        var data = [String]()
        for i in 1...50 {
            data.append("\(i)")
        }
        return data
    }
    let CELL_HEIGHT: CGFloat = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredSize()
    }
}

extension HistoryViewController {
    func configureUI() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Cell.historyCell)
//        tableView.isScrollEnabled = false
        tableView.rowHeight = CELL_HEIGHT
        tableView.estimatedRowHeight = CELL_HEIGHT
    }
    
    func setConstraints() {
        
    }
    
    private func calculatePreferredSize() {
        //        let targetSize = CGSize(width: view.bounds.width,
        //                                height: UIView.layoutFittingCompressedSize.height)
        //        print("tableView.systemLayoutSizeFitting(targetSize)", tableView.systemLayoutSizeFitting(targetSize))
        
        let vcHeight: CGFloat = CGFloat(self.data.count) * CELL_HEIGHT
        print("vcHeight", vcHeight)
        let targetSize = CGSize(width: view.bounds.width, height: vcHeight)
        print("targetSize", targetSize)
        preferredContentSize = targetSize
    }
}

extension HistoryViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.historyCell, for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        return cell
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
