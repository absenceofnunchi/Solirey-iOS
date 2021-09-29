//
//  ReceiveViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

import UIKit

class ReceiveViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
//    private var localDatabase: LocalDatabase!
//    private var wallet: KeyWalletModel!
    var address: String!
    private var backgroundView: BackgroundView3!
    private var copyButton: WalletButtonView!
    private var shareButton: WalletButtonView!
    private var stackView: UIStackView!
    private var qrCodeImageView: UIImageView!
    private var qrCodeImage: UIImage!
    private var addressLabel: EdgeInsetLabel!
    private let alert = Alerts()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCloseButton()
        setButtonConstraints()
//        configureWallet()
        configureUI()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let totalCount = 5
        let duration = 1.0 / Double(totalCount)
        
        let animation = UIViewPropertyAnimator(duration: 0.8, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.qrCodeImageView.alpha = 1
                    self?.qrCodeImageView.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.addressLabel.alpha = 1
                    self?.addressLabel.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 3 / Double(totalCount), relativeDuration: duration) {
                    self?.stackView.alpha = 1
                    self?.stackView.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 4 / Double(totalCount), relativeDuration: duration) {
                    self?.backgroundView.alpha = 1
                    self?.backgroundView.transform = .identity
                }
            })
        }
        
        animation.startAnimation()
    }
}

extension ReceiveViewController {
//    func configureWallet() {
//        localDatabase = LocalDatabase()
//        wallet = localDatabase.getWallet()
//        address = wallet.address
//    }
    
    func configureUI() {
        view.backgroundColor = .white
        
        backgroundView = BackgroundView3()
        backgroundView.transform = CGAffineTransform(translationX: 0, y: 40)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.alpha = 0
        view.addSubview(backgroundView)
        
        qrCodeImage = generateQRCode(from: address)
        qrCodeImageView = UIImageView(image: qrCodeImage)
        //        let origin = CGPoint(x: view.frame.size.width / 2 - 100, y: view.frame.size.height / 2 - 300)
        //        qrCodeImageView.frame = CGRect(origin: origin, size: CGSize(width: 200, height: 200))
        qrCodeImageView.transform = CGAffineTransform(translationX: 0, y: 40)
        qrCodeImageView.alpha = 0
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCodeImageView)
        
        addressLabel = EdgeInsetLabel()
        addressLabel.textInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        BorderStyle.customShadowBorder(for: addressLabel)
        addressLabel.numberOfLines = 0
        addressLabel.alpha = 0
        addressLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        addressLabel.text = address
        addressLabel.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addressLabel)
        
        copyButton = WalletButtonView(imageName: "square.on.square", labelName: "Copy")
        copyButton.buttonAction = { [weak self] in
            //            let pasteboard = UIPasteboard.general
            //            pasteboard.string = self?.address ?? ""
            DispatchQueue.main.async {
                self?.alert.fading(controller: self!, toBePasted: self?.address ?? "")
            }
        }
        
        shareButton = WalletButtonView(imageName: "square.and.arrow.up", labelName: "Share")
        shareButton.buttonAction = { [weak self] in
            let shareSheetVC = UIActivityViewController(activityItems: [self?.address ?? "", self?.qrCodeImage as Any], applicationActivities: nil)
            self?.present(shareSheetVC, animated: true, completion: nil)
            if let pop = shareSheetVC.popoverPresentationController {
                pop.sourceView = self?.view
                //                pop.sourceRect = CGRect(x: self?.view.bounds.midX, y: self?.view.bounds.height, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
        }
        
        stackView = UIStackView(arrangedSubviews: [copyButton, shareButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.transform = CGAffineTransform(translationX: 0, y: 40)
        stackView.alpha = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            // background view
            backgroundView.widthAnchor.constraint(equalTo: view.widthAnchor),
            backgroundView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 3/5),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // qr
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeImageView.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            
            // address label
            addressLabel.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 50),
            addressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addressLabel.widthAnchor.constraint(equalToConstant: 200),
            addressLabel.heightAnchor.constraint(equalToConstant: 90),
            
            // copy button
            copyButton.heightAnchor.constraint(equalToConstant: 100),
            
            // stack view
            stackView.widthAnchor.constraint(equalToConstant: 260),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 50),
            stackView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 5.5, y: 5.5)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
}


class EdgeInsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}
