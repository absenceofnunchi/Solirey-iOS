//
//  AuctionDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-13.
//

import UIKit

class AuctionDetailViewController: ParentDetailViewController {
    var historyVC: HistoryViewController!
    lazy var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        var contentHeight: CGFloat!
//        if let files = post.files, files.count > 0 {
//            contentHeight = descLabel.bounds.size.height + 800 + historyTableViewHeight + 250
//        } else {
//            contentHeight = descLabel.bounds.size.height + 800 + historyTableViewHeight
//        }
//
//        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: contentHeight)
//    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if let container = container as? HistoryViewController {
            historyVCHeightConstraint.constant = container.preferredContentSize.height
            let adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 700 )
            print("adjustedSize", adjustedSize)
            self.scrollView.contentSize =  adjustedSize
        }
    }
}

extension AuctionDetailViewController {
    override func configureUI() {
        super.configureUI()
        
        historyVC = HistoryViewController()
        addChild(historyVC)
        historyVC.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyVC.view)
        historyVC.didMove(toParent: self)
    }
    
    override func setConstraints() {
        super.setConstraints()
        NSLayoutConstraint.activate([
            historyVC.view.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 40),
            historyVC.view.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyVC.view.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            historyVCHeightConstraint,
        ])
    }
}


