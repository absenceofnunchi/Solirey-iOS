//
//  AppProtocols.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit
import FirebaseFirestore

// WalletViewController
protocol WalletDelegate: AnyObject {
    func didProcessWallet()
}

// MARK: - PreviewDelegate
/// PostViewController
protocol PreviewDelegate: AnyObject {
    func didDeleteImage(imageName: String)
}

// MARK: - MessageDelegate
/// PostViewController
protocol MessageDelegate: AnyObject {
    func didReceiveMessage(topics: [String])
}

// MARK: - TableViewRefreshDelegate
protocol TableViewRefreshDelegate: AnyObject {
    func didRefreshTableView()
}

// MARK: - TableViewConfigurable
protocol TableViewConfigurable {
    func configureTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource, height: CGFloat, cellType: UITableViewCell.Type, identifier: String) -> UITableView
}

extension TableViewConfigurable where Self: UITableViewDataSource {
    func configureTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource, height: CGFloat, cellType: UITableViewCell.Type, identifier: String) -> UITableView {
        let tableView = UITableView()
        tableView.register(cellType, forCellReuseIdentifier: identifier)
        tableView.estimatedRowHeight = height
        tableView.rowHeight = height
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
}

