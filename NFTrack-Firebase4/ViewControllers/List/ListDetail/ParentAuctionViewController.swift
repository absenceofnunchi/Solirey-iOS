//
//  ParentAuctionViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-11-15.
//

import UIKit

class ParentAuctionViewController: ParentDetailViewController {
    final var historyVC: HistoryViewController!
    lazy final var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    final var auctionDetailTitleLabel: UILabel!
    final var moreDetailsButton: UIButton!
    final var auctionSpecView: SpecDisplayView!
    final var bidContainer: UIView!
    final var bidTextField: UITextField!
    final var auctionButton: UIButton!
    final let LIST_DETAIL_MARGIN: CGFloat = 10
    final var propertiesToLoad: [IntegralAuctionContract.ContractProperties]!
    lazy final var auctionDetailArr: [SmartContractProperty] = IntegralAuctionProperties.AuctionInfo.getAll().map { SmartContractProperty(propertyName: $0, propertyDesc: "loading...") }
    lazy final var auctionButtonNarrowConstraint: NSLayoutConstraint! = auctionButton.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 0.45)
    lazy final var auctionButtonWideConstraint: NSLayoutConstraint! = auctionButton.widthAnchor.constraint(equalTo: bidContainer.widthAnchor, multiplier: 1)
    final var auctionContractAddress: EthereumAddress!
    final var socketDelegate: SocketDelegate!
    // indicator to show whether the transaction is pending or not
    // it means the current highest bidder/bidding price will likely change
    final lazy var isPending: Bool = false {
        didSet {
            if isPending == true {
                DispatchQueue.main.async { [weak self] in
                    self?.pendingIndicatorView.isHidden = false
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.pendingIndicatorView.isHidden = true
                }
            }
        }
    }
    
    final var pendingIndicatorView: PendingIndicatorView!
    final var pendingReturnButton: UIButton!
    final var txResult: TxResult!
    final var auctionButtonController: AuctionButtonController!
    final var pendingReturnButtonConstraints = [NSLayoutConstraint]()
    final var pendingReturnActivityIndicatorView: UIActivityIndicatorView!
    final var db: Firestore! {
        return FirebaseService.shared.db
    }
    final var solireyUid: BigUInt!
    
}
