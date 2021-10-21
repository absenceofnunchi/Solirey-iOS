//
//  ProgressModalViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-19.
//

import UIKit

enum PostProgress: Int, CaseIterable {
    case estimatGas
    case deployingEscrow
    case deployingAuction
    case minting
    case images
    case initializeAuction
    
    func asString() -> String {
        switch self {
            case .estimatGas:
                return "Estimating the total gas"
            case .deployingEscrow:
                return "Deploying the escrow contract"
            case .deployingAuction:
                return "Deplying the auction contract"
            case .minting:
                return "Minting your item on the blockchain"
            case .images:
                return "Checking for images to upload"
            case .initializeAuction:
                return "Initializing the auction contract"
        }
    }
}

struct PostProgressData {
    var phases: [PostProgress]
    
    init(paymentMethod: PaymentMethod) {
        switch paymentMethod {
            case .escrow:
                phases = [.estimatGas, .deployingEscrow, .minting, .images]
            case .directTransfer:
                phases = [.estimatGas, .minting, .images]
            case .auctionBeneficiary:
                phases = [.estimatGas, .images, .deployingAuction, .minting, .initializeAuction]
        }
    }
    
    func asString(i: Int) -> String {
        return phases[i].asString()
    }
}

//struct PostProgressData1 {
//    var phases: [PostProgress]
//    
//    init(postType: PostType) {
//        switch postType {
//            case .tangible:
//                phases = [.estimatGas, .deployingEscrow, .minting, .images]
//            case .digital(.onlineDirect):
//                phases = [.estimatGas, .images, .deployingEscrow, .minting]
//            case .digital(.openAuction):
//                phases = [.estimatGas, .images, .deployingAuction, .minting, .initializeAuction]
//        }
//    }
//    
//    func asString(i: Int) -> String {
//        return phases[i].asString()
//    }
//}

class ProgressModalViewController: UIViewController {
    private var titleLabel: UILabel!
    var titleString: String?
    var timerLabel: UILabel!
    var timer: Timer!
    private var height: CGFloat!
    private lazy var customTransitioningDelegate = TransitioningDelegate(height: height)
    private var stackView: UIStackView!
    private var completionCount: Int = 0
    private var doneButton: UIButton!
    var progressView: UIProgressView!
    var progressLabel: UILabel!
    var postProgressData: PostProgressData!
    
    init(height: CGFloat = 350, paymentMethod: PaymentMethod) {
        super.init(nibName: nil, bundle: nil)
        self.height = height
        self.postProgressData = PostProgressData(paymentMethod: paymentMethod)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = customTransitioningDelegate
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .didUpdateProgress, object: nil)
        NotificationCenter.default.removeObserver(self, name: .willDismiss, object: nil)
        
        if let timer = timer {
            timer.invalidate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateProgress), name: .didUpdateProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWillDismiss), name: .willDismiss, object: nil)
    }

//    @objc func onDidUpdateProgress(_ notification: Notification) {
//        if let update = notification.userInfo?["update"] as? PostProgress,
//           let postProgress = PostProgress(rawValue: update.rawValue) {
//            DispatchQueue.main.async { [weak self] in
//                if let sv = self?.stackView.arrangedSubviews[postProgress.rawValue],
//                   let containerView = sv.viewWithTag(100) {
//                    for case let imageView as UIImageView in containerView.subviews {
//                        guard let checkImage = UIImage(systemName: "checkmark") else { return }
//                        let configuration = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold, scale: .small)
//                        let finalImage = checkImage.withConfiguration(configuration).withTintColor(UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1), renderingMode: .alwaysOriginal)
//                        imageView.image = finalImage
//
//                        self?.completionCount += 1
//                        if self?.completionCount == PostProgress.allCases.count {
//                            self?.doneButton.isHidden = false
//                            self?.doneButton.isEnabled = true
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    @objc func onDidUpdateProgress(_ notification: Notification) {
        if let update = notification.userInfo?["update"] as? PostProgress,
           let postProgressIndex = postProgressData.phases.firstIndex(of: update) {
            DispatchQueue.main.async { [weak self] in
                if let sv = self?.stackView.arrangedSubviews[postProgressIndex],
                   let containerView = sv.viewWithTag(100) {
                    for case let imageView as UIImageView in containerView.subviews {
                        guard let checkImage = UIImage(systemName: "checkmark") else { return }
                        let configuration = UIImage.SymbolConfiguration(pointSize: 8, weight: .light, scale: .small)
                        let finalImage = checkImage.withConfiguration(configuration).withTintColor(UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1), renderingMode: .alwaysOriginal)
                        imageView.image = finalImage
                        
                        self?.completionCount += 1
                        if self?.completionCount == self?.postProgressData.phases.count {
                            self?.doneButton.isHidden = false
                            self?.doneButton.isEnabled = true
                            
                            if let timer = self?.timer {
                                timer.invalidate()
                            }
                            
                            self?.timerLabel.text = ""
                        }
                    }
                }
            }
        }
    }
    
    @objc func onWillDismiss(_ notification: Notification) {
        self.dismiss(animated: true, completion: nil)
    }
}

private extension ProgressModalViewController {
    private func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        titleLabel = UILabel()
        titleLabel.text = titleString
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        timerLabel = UILabel()
        timerLabel.textColor = .lightGray
        timerLabel.sizeToFit()
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)
        
        var estimatedDuration = 120
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (Timer) in
            if let converted = self?.secondsToHoursMinutesSeconds(seconds: estimatedDuration) {
                if estimatedDuration >= 0 {
                    var min, sec: String!
                    
                    if converted.1 < 10 {
                        min = "0\(converted.1)"
                    } else {
                        min = "\(converted.1)"
                    }
                    
                    if converted.2 < 10 {
                        sec = "0\(converted.2)"
                    } else {
                        sec = "\(converted.2)"
                    }
                    
                    let countdown = "Estimated Duration: \(min ?? "00"):\(sec ?? "00")"
                    self?.timerLabel.text = countdown
                    
                    estimatedDuration -= 1
                } else {
                    Timer.invalidate()
                    self?.timerLabel.text = "Estimated Duration: 00:00"
                }
            }
        }
        
        let oneDotImage = createProgressImage(dotCount: .one)
        let twoDotImage = createProgressImage(dotCount: .two)
        let threeDotImage = createProgressImage(dotCount: .three)
        let images = [oneDotImage, twoDotImage, threeDotImage]
        let animation = UIImage.animatedImage(with: images, duration: 1.5)
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for i in 0..<postProgressData.phases.count {
            let containerView = UIView()
            containerView.tag = 100
            let dotsImageView = UIImageView()
            dotsImageView.contentMode = .scaleAspectFit
            dotsImageView.animationRepeatCount = .max
            dotsImageView.image = animation
            dotsImageView.startAnimating()
            dotsImageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(dotsImageView)
            
            let progressLabel = createTitleLabel(text: postProgressData.asString(i: i), fontSize: 13, weight: .medium)
            containerView.addSubview(progressLabel)
            
            NSLayoutConstraint.activate([
                dotsImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                dotsImageView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
                dotsImageView.widthAnchor.constraint(equalToConstant: 35),
                
                progressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                progressLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor),
                progressLabel.trailingAnchor.constraint(equalTo: dotsImageView.leadingAnchor)
            ])
            
            stackView.addArrangedSubview(containerView)
        }
        view.addSubview(stackView)
        
        doneButton = UIButton()
        doneButton.setTitle("Success!", for: .normal)
        doneButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        doneButton.backgroundColor = .black
        doneButton.layer.cornerRadius = 8
        doneButton.isHidden = true
        doneButton.isEnabled = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)
        
        progressView = UIProgressView()
        progressView.isHidden = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        progressLabel = UILabel()
        progressView.isHidden = true
        progressLabel.textAlignment = .right
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressLabel)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            timerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.heightAnchor.constraint(equalToConstant: 50),
            
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.50),
            
            doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            doneButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            doneButton.heightAnchor.constraint(equalToConstant: 40),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            progressView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            progressView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            progressView.heightAnchor.constraint(equalToConstant: 10),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            progressLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            progressLabel.heightAnchor.constraint(equalToConstant: 20),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    enum DotCount {
        case one, two, three
    }
    
    private func createProgressImage(dotCount: DotCount) -> UIImage {
        let imageBounds = CGRect(origin: .zero, size: CGSize(width: 35, height: 25))
        let renderer = UIGraphicsImageRenderer(bounds: imageBounds)
        var image: UIImage!
        let radius = (min(imageBounds.width, imageBounds.height)) / 20
        
        switch dotCount {
            case .one:
                image = renderer.image { (_) in
                    let center = CGPoint(x: imageBounds.minX + radius, y: imageBounds.midY)
                    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.gray.setFill()
                    path.fill()
                }
            case .two:
                image = renderer.image { (_) in
                    let center = CGPoint(x: imageBounds.minX + radius, y: imageBounds.midY)
                    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path.fill()
                    
                    let center2 = CGPoint(x: imageBounds.midX, y: imageBounds.midY)
                    let path2 = UIBezierPath(arcCenter: center2, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path2.fill()
                }
            case .three:
                image = renderer.image { (_) in
                    let center = CGPoint(x: imageBounds.minX + radius, y: imageBounds.midY)
                    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path.fill()
                    
                    let center2 = CGPoint(x: imageBounds.midX, y: imageBounds.midY)
                    let path2 = UIBezierPath(arcCenter: center2, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path2.fill()
                    
                    let center3 = CGPoint(x: imageBounds.maxX - radius, y: imageBounds.midY)
                    let path3 = UIBezierPath(arcCenter: center3, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path3.fill()
                }
        }

        return image
    }
    
    @objc func buttonPressed(_ sender: UIButton!) {
        dismiss(animated: true, completion: nil)
    }
}


