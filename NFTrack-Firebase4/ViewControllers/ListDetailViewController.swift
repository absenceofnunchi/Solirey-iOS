//
//  ListDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit
import FirebaseFirestore
import web3swift

class ListDetailViewController: UIViewController {
    var scrollView: UIScrollView!
    var post: Post!
    var pvc: UIPageViewController!
    var galleries = [String]()
    var dateLabel: UILabel!
    var underLineView: UnderlineView!
    var priceTitleLabel: UILabel!
    var priceLabel: UILabel!
    var descTitleLabel: UILabel!
    var descLabel: UILabelPadding!
    var txDetailButton: UIButton!
//    var db: Firestore!
    var contractAddress: EthereumAddress!
    
    let alert = Alerts()
    let transactionService = TransactionService()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
//        configureFirebase()
        configureData()
        configureUI()
        setConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("descLabel height", descLabel.bounds.size.height)
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 2000)
    }
}

extension ListDetailViewController {
    // MARK: - configureBackground
    func configureBackground() {
        title = post.title
        view.backgroundColor = .white
        scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.backgroundColor = .white
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
    }
    
//    // MARK: - configureFirebase
//    func configureFirebase() {
//        let settings = FirestoreSettings()
//        Firestore.firestore().settings = settings
//        db = Firestore.firestore()
//    }
    
    // MARK: - configureData
    func configureData() {
        // image
        if let images = post.images, images.count > 0 {
            self.galleries.append(contentsOf: images)
            configurePageVC(gallery: galleries[0])
            
            guard let pv = pvc.view else { return }
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: pv.bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            scrollView.fill()
        }
        
        FirebaseService.sharedInstance.db.collection("escrow").whereField("userId", isEqualTo: post.userId)
            .getDocuments() { [weak self](querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        guard let txHash = data["transactionHash"] as? String else { return }
                        DispatchQueue.global().async {
                            do {
                                let receipt = try Web3swiftService.web3instance.eth.getTransactionReceipt(txHash)
                                self?.contractAddress = receipt.contractAddress
                                self?.transactionService.prepareTransactionForReading(method: "state", contractAddress: receipt.contractAddress!, completion: { (transaction, error) in
                                    if let error = error {
                                        switch error {
                                            case .contractLoadingError:
                                                self?.alert.showDetail("Error", with: "Contract Loading Error", for: self!)
                                            case .createTransactionIssue:
                                                self?.alert.showDetail("Error", with: "Contract Transaction Issue", for: self!)
                                            default:
                                                self?.alert.showDetail("Error", with: "There was an error minting your token.", for: self!)
                                        }
                                    }
                                    
                                    if let transaction = transaction {
                                        DispatchQueue.global().async {
                                            do {
                                                let result = try transaction.call()
                                                print("result", result)
                                            } catch {
                                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                                            }
                                        }
                                    }
                                })
                            } catch {
                                self?.alert.showDetail("Error", with: error.localizedDescription, for: self!)
                            }
                        }
                    }
                }
            }
    }
    
    // MARK: - configurePageVC
    func configurePageVC(gallery: String) {
        let singlePageVC = ImagePageViewController(gallery: gallery)
        pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        pvc.dataSource = self
        pvc.delegate = self
        addChild(pvc)
        view.addSubview(pvc.view)
        pvc.didMove(toParent: self)
        pvc.view.layer.zPosition = 100
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
        pageControl.currentPageIndicatorTintColor = .gray
        pageControl.backgroundColor = .white
        
        guard let pv = pvc.view else { return }
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: view.topAnchor),
            pv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pv.heightAnchor.constraint(equalToConstant: 250),
        ])
    }
    
    // MARK: - configureUI
    func configureUI() {
        dateLabel = UILabel()
        dateLabel.textAlignment = .right
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let formattedDate = formatter.string(from: post.date)
        dateLabel.text = formattedDate
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(dateLabel)
        
        underLineView = UnderlineView()
        underLineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(underLineView)
        
        priceTitleLabel = UILabel()
        priceTitleLabel.text = "Price"
        priceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(priceTitleLabel)
        
        priceLabel = UILabel()
        priceLabel.textAlignment = .center
        priceLabel.text = post.price
        priceLabel.layer.borderColor = UIColor.lightGray.cgColor
        priceLabel.layer.borderWidth = 0.5
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(priceLabel)
        
        descTitleLabel = UILabel()
        descTitleLabel.text = "Description"
        descTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descTitleLabel)
        
        descLabel = UILabelPadding()
        descLabel.lineBreakMode = .byClipping
        descLabel.text = """
            Bundle ID in 'GoogleService-Info.plist', or the Bundle ID in the options if you are using a customized options. To ensure that everything can be configured correctly, you may need to make the Bundle IDs consistent. To continue with this plist file, you may change your app's bundle identifier to 'com.ovis.NFTrack'. Or you can download a new configuration file that matches your bundle identifier from https://console.firebase.google.com/ and replace the current one.
        2021-05-17 21:44:56.289497-0400 NFTrack-Firebase4[7443:8988532] [] nw_protocol_get_quic_image_block_invoke dlopen libquic failed
        2021-05-17 21:44:56.308206-0400 NFTrack-Firebase4[7443:8988524] 7.8.0 - [Firebase/Analytics][I-ACS023007] Analytics v.7.8.0 started
        2021-05-17 21:44:56.309573-0400 NFTrack-Firebase4[7443:8988524] 7.8.0 - [Firebase/Analytics][I-ACS023008] To enable debug logging set the following application argument: -FIRAnalyticsDebugEnabled (see http://goo.gl/RfcP7r)
        2021-05-17 21:44:56.991641-0400 NFTrack-Firebase4[7443:8988524] 7.8.0 - [Firebase/Analytics][I-ACS800023] No pending snapshot to activate. SDK name: app_measurement
        2021-05-17 21:44:57.106485-0400 NFTrack-Firebase4[7443:8988524] 7.8.0 - [Firebase/Analytics][I-ACS023012] Analytics collection enabled
        2021-05-17 21:44:57.133068-0400 NFTrack-Firebase4[7443:8988524] 7.8.0 - [Firebase/Analytics][I-ACS023220] Analytics screen reporting is enabled. Call +[FIRAnalytics logEventWithName:FIREventScreenView parameters:] to log a screen view event. To disable automatic screen reporting, set the flag FirebaseAutomaticScreenReportingEnabled to NO (boolean) in the Info.plist
        gallery in imageVC https://firebasestorage.googleapis.com/v0/b/nftrack-69488.appspot.com/o/DpUgBbZzpQhHKnvKURZbyp3jeOA3%2FDD422D51-C41F-4FB5-B7F7-970DF6236A2C?alt=media&token=f4dec0ef-d76a-4876-865a-f98170009c8c
        urlAddress Optional("https://firebasestorage.googleapis.com/v0/b/nftrack-69488.appspot.com/o/DpUgBbZzpQhHKnvKURZbyp3jeOA3%2FDD422D51-C41F-4FB5-B7F7-970DF6236A2C?alt=media&token=f4dec0ef-d76a-4876-865a-f98170009c8c")
        url https://firebasestorage.googleapis.com/v0/b/nftrack-69488.appspot.com/o/DpUgBbZzpQhHKnvKURZbyp3jeOA3%2FDD422D51-C41F-4FB5-B7F7-970DF6236A2C?alt=media&token=f4dec0ef-d76a-4876-865a-f98170009c8c
        imageView Optional(<UIImageView: 0x7fae7a808710; frame = (0 0; 0 0); userInteractionEnabled = NO; layer = <CALayer: 0x600001a698a0>>)
        data 2049960 bytes
        """
        descLabel.numberOfLines = 0
        descLabel.sizeToFit()
        descLabel.layer.borderWidth = 0.5
        descLabel.layer.borderColor = UIColor.lightGray.cgColor
        descLabel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descLabel)
        
        txDetailButton = UIButton(type: .infoDark)
        txDetailButton.setTitle("Transaction Detail", for: .normal)
        txDetailButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        txDetailButton.tag = 1
        txDetailButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(txDetailButton)
    }
    
    // MARK: - setConstraints
    func setConstraints() {
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
            dateLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            dateLabel.heightAnchor.constraint(equalToConstant: 50),
            dateLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.4),
            
            underLineView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor),
            underLineView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            underLineView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            underLineView.heightAnchor.constraint(equalToConstant: 0.5),
            
            priceTitleLabel.topAnchor.constraint(equalTo: underLineView.bottomAnchor, constant: 50),
            priceTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            priceTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            priceTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            priceLabel.topAnchor.constraint(equalTo: priceTitleLabel.bottomAnchor, constant: 0),
            priceLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            priceLabel.heightAnchor.constraint(equalToConstant: 50),
            
            descTitleLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 50),
            descTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            descTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: descTitleLabel.bottomAnchor, constant: 10),
            descLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            
            txDetailButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            txDetailButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            txDetailButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            txDetailButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton!) {
        txDetailButton.tag = 1
        switch sender.tag {
            case 1:
                let txDetailVC = TxDetailViewController()
                txDetailVC.txHash = post.txHash
                txDetailVC.nonce = post.nonce
                self.navigationController?.pushViewController(txDetailVC, animated: true)
            default:
                break
        }
    }
}

extension ListDetailViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index -= 1
        if index < 0 {
            return nil
        }

        return ImagePageViewController(gallery: galleries[index])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index += 1
        if index >= galleries.count {
            return nil
        }

        return ImagePageViewController(gallery: galleries[index])
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.galleries.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let page = pageViewController.viewControllers![0] as! ImagePageViewController
        
        if let gallery = page.gallery {
            return self.galleries.firstIndex(of: gallery)!
        } else {
            return 0
        }
    }
}
