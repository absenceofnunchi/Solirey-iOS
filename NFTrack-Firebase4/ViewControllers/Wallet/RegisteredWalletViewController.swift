//
//  RegisteredWalletViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit
import web3swift

class RegisteredWalletViewController: UIViewController {
    private var closeButton: UIButton!
    weak var delegate: WalletDelegate?
    private var lowerContainer: BackgroundView!
    private var upperContainer: UIView!
    private var balanceLabel: UILabel!
    private var sendButton: WalletButtonView!
    private var receiveButton: WalletButtonView!
    private var refreshButton: UIButton!
    private var stackView: UIStackView!
    private var historyButton: UIButton!
    private var deleteWalletButton: UIButton!
    private var privateKeyButton: UIButton!
    private var resetPassword: UIButton!
    private let localDatabase = LocalDatabase()
    private let keyService = KeysService()
    private let transactionService = TransactionService()
    private let alert = Alerts()
    private let buttonArr: [ButtonModel] = [
        ButtonModel(titleString: NSLocalizedString("Transaction History", comment: ""), imageName: "book.circle", tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 0),
        ButtonModel(titleString: NSLocalizedString("Reset Password", comment: ""), imageName: "lock.rotation", tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 1),
        ButtonModel(titleString: NSLocalizedString("Private Key", comment: ""), imageName: "lock.circle", tintColor: UIColor(red: 255/255, green: 160/255, blue: 160/255, alpha: 1), tag: 2),
        ButtonModel(titleString: NSLocalizedString("Delete Wallet", comment: ""), imageName: "trash.circle", tintColor: UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1), tag: 3)
    ]
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configureWallet()
        setConstraints()
    }
    
    private var presentingController: UIViewController?
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presentingController = presentingViewController
        loadingAnimation()
    }
    
    func loadingAnimation() {
        let totalCount = 7
        let duration = 1.0 / Double(totalCount) + 0.2
        
        let animation = UIViewPropertyAnimator(duration: 0.7, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration) {
                    self?.balanceLabel.transform = .identity
                    self?.balanceLabel.alpha = 1
                }
                
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.sendButton.transform = .identity
                    self?.sendButton.alpha = 1
                    
                    self?.receiveButton.transform = .identity
                    self?.receiveButton.alpha = 1
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.lowerContainer.transform = .identity
                    self?.lowerContainer.alpha = 1
                }
                
                guard let buttonCount = self?.buttonArr.count else { return }
                for i in 0...buttonCount - 1 {
                    UIView.addKeyframe(withRelativeStartTime: Double(i + 3) / Double(totalCount), relativeDuration: duration) {
                        self?.stackView.arrangedSubviews[i].transform = .identity
                        self?.stackView.arrangedSubviews[i].alpha = 1
                    }
                }
            })
        }
        
        animation.startAnimation()
    }
}

struct ButtonModel {
    let titleString: String
    let imageName: String
    let tintColor: UIColor
    let tag: Int
}

extension RegisteredWalletViewController: UITextFieldDelegate {
    // MARK: - configure
    func configure() {
//        view.backgroundColor = UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1)
//        view.backgroundColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
        let gradientBackgroundView = GradientBackgroundView(startingColor: UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1),
                                                            finishingColor: UIColor(red: 66/255, green: 110/255, blue: 148/255, alpha: 1))
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.fill()
        
        upperContainer = UIView()
        upperContainer.isUserInteractionEnabled = true
        upperContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upperContainer)
        
        // refresh button
        guard let refreshImage = UIImage(systemName: "arrow.clockwise")?.withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
        refreshButton = UIButton.systemButton(with: refreshImage, target: self, action: #selector(buttonHandler))
        refreshButton.tag = 4
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        upperContainer.addSubview(refreshButton)
        
        guard let closeButtonImage = UIImage(systemName: "multiply") else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        closeButton = UIButton.systemButton(with: closeButtonImage, target: self, action: #selector(buttonHandler))
        closeButton.tag = 5
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .white
        upperContainer.addSubview(closeButton)
        
        // balance label
        balanceLabel = UILabel()
        balanceLabel.textAlignment = .center
        balanceLabel.text = "0 ETH"
        balanceLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        balanceLabel.alpha = 0
        balanceLabel.textColor = .white
        balanceLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        balanceLabel.sizeToFit()
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        upperContainer.addSubview(balanceLabel)
        
        // send button
        sendButton = WalletButtonView(imageName: "arrow.up.to.line", labelName: "Send", bgColor: UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1), labelTextColor: .white, imageTintColor: .white)
        sendButton.transform = CGAffineTransform(translationX: 0, y: 40)
        sendButton.alpha = 0
        sendButton.buttonAction = { [weak self] in
            let sendVC = SendViewController()
            sendVC.modalPresentationStyle = .fullScreen
            self?.present(sendVC, animated: true, completion: nil)
        }
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        upperContainer.addSubview(sendButton)
        
        // receive button
        receiveButton = WalletButtonView(imageName: "arrow.down.to.line", labelName: "Receive", bgColor: UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1), labelTextColor: .white, imageTintColor: .white)
        receiveButton.transform = CGAffineTransform(translationX: 0, y: 40)
        receiveButton.alpha = 0
        receiveButton.buttonAction = { [weak self] in
            let receiveVC = ReceiveViewController()
            let address = self?.localDatabase.getWallet()?.address
            receiveVC.address = address
            receiveVC.modalPresentationStyle = .fullScreen
            self?.present(receiveVC, animated: true, completion: nil)
        }
        receiveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(receiveButton)
        
        lowerContainer = BackgroundView()
        lowerContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        lowerContainer.alpha = 0
        lowerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lowerContainer)
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        buttonArr.forEach { (buttonModel) in
            guard let buttonView = createButton(
                    titleString: buttonModel.titleString,
                    imageName: buttonModel.imageName,
                    tintColor: buttonModel.tintColor,
                    tag: buttonModel.tag
            ) else { return }
            
            stackView.addArrangedSubview(buttonView)
        }
    }
    
    func createButton(
        titleString: String,
        imageName: String,
        tintColor: UIColor,
        tag: Int
    ) -> UIView? {
        let containerView = UIView()
        containerView.tag = tag
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 10
        containerView.transform = CGAffineTransform(translationX: 0, y: 40)
        containerView.alpha = 0
        containerView.dropShadow()
        
        guard let image = UIImage(systemName: imageName)?
                .withTintColor(tintColor, renderingMode: .alwaysOriginal) else { return nil }
        
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        let titleLabel = UILabel()
        titleLabel.textAlignment = .left
        titleLabel.text = titleString
        titleLabel.textColor = .lightGray
        titleLabel.font = UIFont.rounded(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        containerView.addGestureRecognizer(tap)
        return containerView
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        guard let v = sender.view else { return }
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch v.tag {
            case 0:
                guard let walletAddress = Web3swiftService.currentAddressString else {
                    self.alert.showDetail("Error", with: "Could not retrieve the wallet address.", for: self)
                    return
                }
                
                let webVC = WebViewController()
                let hashType = "address"
                webVC.urlString = "https://rinkeby.etherscan.io/\(hashType)/\(walletAddress)"
                self.present(webVC, animated: true, completion: nil)
            case 1:
                // reset your password
                let prVC = PasswordResetViewController()
                prVC.titleString = "Reset your password"
                prVC.buttonAction = { [weak self]vc in
                    self?.dismiss(animated: true, completion: {
                        let prVC = vc as! PasswordResetViewController
                        guard let oldPassword = prVC.currentPasswordTextField.text,
                              let newPassword = prVC.passwordTextField.text else { return }
                        
                        self?.keyService.resetPassword(oldPassword: oldPassword, newPassword: newPassword) { [weak self](wallet, error) in
                            if let error = error {
                                switch error {
                                    case .failureToFetchOldPassword:
                                        self?.alert.showDetail("Error", with: "Sorry, the old password couldn't be fetched", alignment: .center, for: self)
                                    case .failureToRegeneratePassword:
                                        self?.alert.showDetail("Error", with: "Sorry, a new password couldn't be generated", alignment: .left, for: self)
                                }
                            }
                            
                            if let wallet = wallet {
                                self?.localDatabase.saveWallet(isRegistered: false, wallet: wallet) { (error) in
                                    if let _ = error {
                                        self?.alert.showDetail("Error", with: "Sorry, there was an error generating a new password. Check to see if you're using the correct password.", alignment: .left, for: self)
                                    }
                                    
                                    self?.alert.showDetail("Success", with: "A new password has been generated!", alignment: .center, for: self)
                                }
                            }
                        }
                    })
                }
                present(prVC, animated: true, completion: nil)
            case 2:
                // show private key
                let content = [
                    StandardAlertContent(
                        titleString: "",
                        body: [AlertModalDictionary.passwordSubtitle: ""],
                        isEditable: true,
                        fieldViewHeight: 40,
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton
                    ),
                ]
                
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    mainVC.buttonAction = { _ in
                        guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                              !password.isEmpty else {
                            self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                            return
                        }
                        
                        self?.dismiss(animated: true, completion: {
                            do {
                                let privateKey = try self?.keyService.getWalletPrivateKey(password: password)
                                let receiveVC = ReceiveViewController()
                                receiveVC.address = privateKey
                                receiveVC.modalPresentationStyle = .fullScreen
                                self?.present(receiveVC, animated: true, completion: nil)
                            } catch {
                                self?.alert.showDetail("Error", with: "Wrong password", alignment: .center, for: self)
                            }
                        })
                    }
                }
                present(alertVC, animated: true, completion: nil)
            case 3:
                // delete
                let content = [
                    StandardAlertContent(
                        titleString: "Delete Wallet",
                        body: ["": "Are you sure you want to delete your wallet from your local storage?"],
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton,
                        buttonAction: { [weak self](_) in
                            self?.dismiss(animated: true, completion: nil)
                            self?.localDatabase.deleteWallet { (error) in
                                if let error = error {
                                    self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                                }
                                self?.delegate?.didProcessWallet()
                            }
                        })
                ]
                let alertVC = AlertViewController(height: 300, standardAlertContent: content)
                self.present(alertVC, animated: true, completion: nil)
            default:
                break
        }
    }
    
    @objc func configureWallet() {
        guard let address = Web3swiftService.currentAddress else {
            let content = [
                StandardAlertContent(titleString: "Error", body: ["": "There was an error getting the wallet address."], messageTextAlignment: .left, buttonAction: { [weak self](_) in
                    self?.dismiss(animated: true, completion: nil)
                })
            ]
            let alertVC = AlertViewController(height: 300, standardAlertContent: content)
            self.present(alertVC, animated: true, completion: nil)
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            do {
                let balance = try Web3swiftService.web3instance.eth.getBalance(address: address)
                if let balanceString = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth, decimals: 5) {
                    DispatchQueue.main.async {
                        self.balanceLabel.text = "\(self.transactionService.stripZeros(balanceString)) ETH"
                    }
                }
            } catch {
                let content = [
                    StandardAlertContent(titleString: "Error", body: ["": "There was an error getting the wallet address."], messageTextAlignment: .left, buttonAction: { [weak self](_) in
                        self?.dismiss(animated: true, completion: nil)
                    })
                ]
                
                let alertVC = AlertViewController(height: 300, standardAlertContent: content)
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - setConstraints
    func setConstraints() {
        NSLayoutConstraint.activate([
            // uppper container
            upperContainer.topAnchor.constraint(equalTo: view.topAnchor),
            upperContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            upperContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            upperContainer.bottomAnchor.constraint(equalTo: lowerContainer.topAnchor),
            
            refreshButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 0),
            refreshButton.trailingAnchor.constraint(equalTo: upperContainer.layoutMarginsGuide.trailingAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 60),
            refreshButton.heightAnchor.constraint(equalToConstant: 60),
            
            // close button
            closeButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 60),
            
            // balance label
            balanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            balanceLabel.centerYAnchor.constraint(equalTo: upperContainer.centerYAnchor, constant: -20),
            balanceLabel.heightAnchor.constraint(equalToConstant: 50),
            balanceLabel.widthAnchor.constraint(equalToConstant: 300),
            
            // send button
            sendButton.centerYAnchor.constraint(equalTo: upperContainer.centerYAnchor, constant: 80),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -80),
            sendButton.widthAnchor.constraint(equalToConstant: 100),
            sendButton.heightAnchor.constraint(equalToConstant: 100),
            
            // receive button
            receiveButton.centerYAnchor.constraint(equalTo: upperContainer.centerYAnchor, constant: 80),
            receiveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 80),
            receiveButton.widthAnchor.constraint(equalToConstant: 100),
            receiveButton.heightAnchor.constraint(equalToConstant: 100),
            
            // lower container
            lowerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lowerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lowerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            lowerContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // stack view
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: lowerContainer.centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: lowerContainer.heightAnchor, multiplier: 0.6),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
            // reset wallet password button
//            resetPassword.bottomAnchor.constraint(equalTo: privateKeyButton.topAnchor, constant: -30),
//            resetPassword.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
//            resetPassword.heightAnchor.constraint(equalToConstant: 60),
//            resetPassword.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            // private key
//            privateKeyButton.centerYAnchor.constraint(equalTo: lowerContainer.centerYAnchor),
//            privateKeyButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
//            privateKeyButton.heightAnchor.constraint(equalToConstant: 60),
//            privateKeyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            // create wallet button
//            deleteWalletButton.topAnchor.constraint(equalTo: privateKeyButton.bottomAnchor, constant: 30),
//            deleteWalletButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
//            deleteWalletButton.heightAnchor.constraint(equalToConstant: 60),
//            deleteWalletButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    // MARK: - buttonHandler
    @objc func buttonHandler(_ sender: UIButton!) {
        switch sender.tag {
            case 1:
                // delete
                let content = [
                    StandardAlertContent(
                        titleString: "Delete Wallet",
                        body: ["": "Are you sure you want to delete your wallet from your local storage?"],
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton,
                        buttonAction: { [weak self](_) in
                        self?.dismiss(animated: true, completion: nil)
                        self?.localDatabase.deleteWallet { (error) in
                            if let error = error {
                                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                            }
                            self?.delegate?.didProcessWallet()
                        }
                    })
                ]
                let alertVC = AlertViewController(height: 300, standardAlertContent: content)
                self.present(alertVC, animated: true, completion: nil)
            case 2:
                // show private key
                let ac = UIAlertController(title: "Enter the password", message: nil, preferredStyle: .alert)
                ac.addTextField { (textField: UITextField!) in
                    textField.delegate = self
                }
                
                let enterAction = UIAlertAction(title: "Enter", style: .default) { [unowned ac, weak self](_) in
                    guard let textField = ac.textFields?.first, let text = textField.text else { return }
 
                    do {
                        let privateKey = try self?.keyService.getWalletPrivateKey(password: text)
                        self?.alert.showDetail("Private Key", with: privateKey, height: 350, for: self, buttonAction:  { [weak self] in
                            self?.alert.fading(controller: self, toBePasted: privateKey ?? "Not available")
                        })
                    } catch {
                        self?.alert.showDetail("Error", with: "Wrong password", alignment: .center, for: self)
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                ac.addAction(enterAction)
                ac.addAction(cancelAction)
                self.present(ac, animated: true, completion: nil)
            case 3:
                // reset your password
                let prVC = PasswordResetViewController()
                prVC.titleString = "Reset your password"
                prVC.buttonAction = { [weak self]vc in
                    self?.dismiss(animated: true, completion: {
                        let prVC = vc as! PasswordResetViewController
                        guard let oldPassword = prVC.currentPasswordTextField.text,
                              let newPassword = prVC.passwordTextField.text else { return }

                        self?.keyService.resetPassword(oldPassword: oldPassword, newPassword: newPassword) { [weak self](wallet, error) in
                            if let error = error {
                                switch error {
                                    case .failureToFetchOldPassword:
                                        self?.alert.showDetail("Error", with: "Sorry, the old password couldn't be fetched", alignment: .center, for: self)
                                    case .failureToRegeneratePassword:
                                        self?.alert.showDetail("Error", with: "Sorry, a new password couldn't be generated", alignment: .left, for: self)
                                }
                            }

                            if let wallet = wallet {
                                self?.localDatabase.saveWallet(isRegistered: false, wallet: wallet) { (error) in
                                    if let _ = error {
                                        self?.alert.showDetail("Error", with: "Sorry, there was an error generating a new password. Check to see if you're using the correct password.", alignment: .left, for: self)
                                    }

                                    self?.alert.showDetail("Success", with: "A new password has been generated!", alignment: .center, for: self)
                                }
                            }
                        }
                    })
                }
                present(prVC, animated: true, completion: nil)
            case 4:
                configureWallet()
            case 5:
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            case 6:
                guard let walletAddress = Web3swiftService.currentAddressString else {
                    self.alert.showDetail("Error", with: "Could not retrieve the wallet address.", for: self)
                    return
                }
                
                let webVC = WebViewController()
                let hashType = "address"
                webVC.urlString = "https://rinkeby.etherscan.io/\(hashType)/\(walletAddress)"
                self.present(webVC, animated: true, completion: nil)
            default:
                break
        }
    }
}

// 2
// 123456@email.com (mclovin)
// 123456
// a9420edb3ac5a4eaece8dfa7c5fdd37b0358d7a7d51b1579b5ae94be9cce0842

// posting
// 10
// 99@email.com (tasmanian)
// 111111
// 650ab63c9923856efde6471bb1249df2e5b0995e7a84826f4374feb7ad605079

// test@email.com (N/A)
// 123456
// a3bf8a54341153d2890ece27123ec51438b1a5fe014ea71da7ee2422567c74b6

// 100@email.com (Tom Cruise)
// 123456

// 1004@email.com (Hari Sheldon)
// 111111
