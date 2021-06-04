//
//  AppProtocols.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import Foundation

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

protocol TableViewRefreshDelegate: AnyObject {
    func didRefreshTableView()
}
