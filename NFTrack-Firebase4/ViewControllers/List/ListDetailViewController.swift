//
//  ListDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import Combine
import FirebaseFirestore
import web3swift

class ListDetailViewController: ParentDetailViewController {
    final override var post: Post! {
        didSet {
            self.getStatus()
        }
    }
    private var statusTitleLabel: UILabel!
    final var statusLabel: UILabelPadding!
    final var updateStatusButton = UIButton()
    final var activityIndicatorView: UIActivityIndicatorView!
    final var historyVC: HistoryViewController!
    lazy var historyVCHeightConstraint: NSLayoutConstraint = historyVC.view.heightAnchor.constraint(equalToConstant: 100)
    final var observation: NSKeyValueObservation?
    private var socketDelegate: SocketDelegate!
    private var pendingIndicatorView: PendingIndicatorView!
    // indicator to show whether the transaction is pending or not
    // toggled when any events like purchase confirm or abort is emitted
    lazy var isPending: Bool = false {
        didSet {
            guard let pendingIndicatorView = self.pendingIndicatorView else { return }
            if isPending == true {
                DispatchQueue.main.async {
                    pendingIndicatorView.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    pendingIndicatorView.isHidden = true
                }
            }
        }
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if observation != nil {
            observation?.invalidate()
        }
    }
    
    final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if observation != nil {
            observation?.invalidate()
        }
        
        if socketDelegate != nil {
            socketDelegate.disconnectSocket()
        }
    }
    
//    final override func viewDidLayoutSubviews() {
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
    
    final override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if let container = container as? HistoryViewController {
            historyVCHeightConstraint.constant = container.preferredContentSize.height            
            if let files = post.files, files.count > 0 {
                let adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1000 + 250 )
                self.scrollView.contentSize =  adjustedSize
            } else {
                let adjustedSize = CGSize(width: container.preferredContentSize.width, height: container.preferredContentSize.height + descLabel.bounds.size.height + 1000 )
                self.scrollView.contentSize =  adjustedSize
            }
        }
    }
    
    final override func userInfoDidSet() {
        super.userInfoDidSet()
        
        guard let status = post.status,
              status != PostStatus.complete.rawValue else { return }
        
        if userInfo.uid != userId {
            configureBuyerNavigationBar()
            fetchSavedPostData()
        } else if post.sellerUserId == userId {
            configureSellerNavigationBar()
        }
    }
}

extension ListDetailViewController {
    final override func configureUI() {
        super.configureUI()
        title = post.title
        
        statusTitleLabel = createTitleLabel(text: "Status")
        statusTitleLabel.sizeToFit()
        scrollView.addSubview(statusTitleLabel)
        
        pendingIndicatorView = PendingIndicatorView()
        pendingIndicatorView.isHidden = true
        pendingIndicatorView.buttonAction = { _ in
            let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Pending Transaction", detail: InfoText.pendingEscrow)])
            self.present(infoVC, animated: true, completion: nil)
        }
        pendingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pendingIndicatorView)
        
        statusLabel = UILabelPadding()
        statusLabel.layer.borderColor = UIColor.lightGray.cgColor
        statusLabel.layer.borderWidth = 0.5
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(statusLabel)
        
        updateStatusButton.backgroundColor = .black
        updateStatusButton.isEnabled = false
        updateStatusButton.layer.cornerRadius = 5
        updateStatusButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        updateStatusButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(updateStatusButton)
        
        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        updateStatusButton.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        historyVC = HistoryViewController()
        historyVC.itemIdentifier = post.id
        addChild(historyVC)
        historyVC.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyVC.view)
        historyVC.didMove(toParent: self)
    }
    
    final override func setConstraints() {
        super.setConstraints()
        NSLayoutConstraint.activate([
            statusTitleLabel.topAnchor.constraint(equalTo: listingSpecView.bottomAnchor, constant: 40),
            statusTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            
            pendingIndicatorView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -10),
            pendingIndicatorView.leadingAnchor.constraint(equalTo: statusTitleLabel.trailingAnchor, constant: 20),
            pendingIndicatorView.heightAnchor.constraint(equalToConstant: 28),
            pendingIndicatorView.widthAnchor.constraint(equalToConstant: 100),
            
            statusLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 15),
            statusLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 50),
            
            updateStatusButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            updateStatusButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            updateStatusButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            updateStatusButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicatorView.centerYAnchor.constraint(equalTo: updateStatusButton.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: updateStatusButton.centerXAnchor),
            
            historyVC.view.topAnchor.constraint(equalTo: updateStatusButton.bottomAnchor, constant: 40),
            historyVC.view.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyVC.view.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            historyVCHeightConstraint,
        ])
    }
}

extension ListDetailViewController {
    // MARK: - buttonPressed
    @objc final override func buttonPressed(_ sender: UIButton) {
        super.buttonPressed(sender)
        
        switch sender.tag {
            case 1:
                // abort by the seller
                updateState(method: PurchaseMethods.abort.methodName, status: .aborted)
            case 2:
                // confirm purchase or "buy"
                updateState(method: PurchaseMethods.confirmPurchase.methodName, price: String(post.price), status: .pending)
            case 3:
                // confirm received
                updateState(method: PurchaseMethods.confirmReceived.methodName, status: .complete)
            case 4:
                // sell
                let resellVC = ResellViewController()
                resellVC.modalPresentationStyle = .fullScreen
                resellVC.post = post
                self.present(resellVC, animated: true, completion: nil)
            case 5:
                // transfer ownership
                guard let post = post else { return }
                transferToken(post: post)
            case 8:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.transferPending)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 9:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.receiptPending)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 10:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Status", detail: InfoText.transferCompleted)])
                self.present(infoVC, animated: true, completion: nil)
                break
            case 11:
                let listEditVC = TangibleListEditViewController()
                listEditVC.post = post
                listEditVC.userId = userId
                self.navigationController?.pushViewController(listEditVC, animated: true)
                break
            default:
                break
        }
    }
    
    // MARK: - configureStatusButton
    final func configureStatusButton(buttonTitle: String = "Buy", tag: Int = 2) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusButton.tag = tag
            self?.updateStatusButton.isEnabled = true
            self?.updateStatusButton.setTitle(buttonTitle, for: .normal)
        }
    }
}

extension ListDetailViewController {
    func createSocket(contractAddress: EthereumAddress, topics: [String]? = nil) {
        guard socketDelegate == nil else { return }
        socketDelegate = SocketDelegate(
            contractAddress: contractAddress,
            topics: topics,
            passThroughSubject: PassthroughSubject<[String: Any], PostingError>()
        )
        
        socketDelegate.passThroughSubject
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                    case .failure(let err):
                        self?.alert.showDetail("Auction Detail Fetch Error", with: err.localizedDescription, for: self)
                    case .finished:
                        print("")
                        break
                }
            }, receiveValue: { [weak self] (webSocketMessage) in
                self?.isPending = true
                
                print("webSocketMessage", webSocketMessage)
                guard let topics = webSocketMessage["topics"] as? [String],
                      let txHash = webSocketMessage["transactionHash"] as? String else { return }
                
                switch topics {
                    case _ where topics.contains(Topics.Transfer) || topics.contains(Topics.Transfer2):
                        self?.getStatus()
//                        self?.isPending = true
//                        guard let executeReadTransaction = self?.executeReadTransaction else { return }
//                        self?.getAuctionInfo(
//                            transactionHash: txHash,
//                            executeReadTransaction: executeReadTransaction,
//                            contractAddress: contractAddress
//                        )
                        print("trasnfer event")
                        break
                    case _ where topics.contains(Topics.PurchaseConfirmed):
                        self?.getStatus()
                        print("PurchaseConfirmed event")
                        break
                    case _ where topics.contains(Topics.ItemReceived):
                        self?.getStatus()
                        print("ItemReceived event")
                        break
                    case _ where topics.contains(Topics.Aborted):
                        self?.getStatus()
                        print("Aborted event")
                        break
                    default:
                        print("other events")
                }
            })
            .store(in: &storage)
    }
}
