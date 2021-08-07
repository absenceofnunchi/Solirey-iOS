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
    }
}

extension RegisteredWalletViewController: UITextFieldDelegate {
    // MARK: - configure
    func configure() {
        view.backgroundColor = UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1)
        
        upperContainer = UIView()
        upperContainer.isUserInteractionEnabled = true
        upperContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upperContainer)
        
        // refresh button
        let refreshImage = UIImage(systemName: "arrow.clockwise")!.withTintColor(.white, renderingMode: .alwaysOriginal)
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
        balanceLabel.textColor = .white
        balanceLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        balanceLabel.sizeToFit()
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        upperContainer.addSubview(balanceLabel)
        
        // send button
        sendButton = WalletButtonView(imageName: "arrow.up.to.line", labelName: "Send", bgColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), labelTextColor: .white, imageTintColor: .white)
        sendButton.buttonAction = { [weak self] in
            let sendVC = SendViewController()
            sendVC.modalPresentationStyle = .fullScreen
            self?.present(sendVC, animated: true, completion: nil)
        }
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        upperContainer.addSubview(sendButton)
        
        // receive button
        receiveButton = WalletButtonView(imageName: "arrow.down.to.line", labelName: "Receive", bgColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), labelTextColor: .white, imageTintColor: .white)
        receiveButton.buttonAction = { [weak self] in
            let receiveVC = ReceiveViewController()
            receiveVC.modalPresentationStyle = .fullScreen
            self?.present(receiveVC, animated: true, completion: nil)
        }
        receiveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(receiveButton)
        
        lowerContainer = BackgroundView()
        lowerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lowerContainer)
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        historyButton = UIButton()
        historyButton.dropShadow()
        historyButton.setTitle("Transaction History", for: .normal)
        historyButton.setTitleColor(.black, for: .normal)
        historyButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        historyButton.backgroundColor = .white
        historyButton.layer.cornerRadius = 10
        historyButton.tag = 6
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(historyButton)
        
        resetPassword = UIButton()
        resetPassword.dropShadow()
        resetPassword.setTitle("Reset Password", for: .normal)
        resetPassword.setTitleColor(.black, for: .normal)
        resetPassword.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        resetPassword.backgroundColor = .white
        resetPassword.layer.cornerRadius = 10
        resetPassword.tag = 3
        resetPassword.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(resetPassword)
        
        privateKeyButton = UIButton()
        privateKeyButton.dropShadow()
        privateKeyButton.setTitle("Private Key", for: .normal)
        privateKeyButton.setTitleColor(.black, for: .normal)
        privateKeyButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        privateKeyButton.backgroundColor = .white
        privateKeyButton.layer.cornerRadius = 10
        privateKeyButton.tag = 2
        privateKeyButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(privateKeyButton)
        
        deleteWalletButton = UIButton()
        deleteWalletButton.dropShadow()
        deleteWalletButton.setTitle("Delete Wallet", for: .normal)
        deleteWalletButton.setTitleColor(.black, for: .normal)
        deleteWalletButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        deleteWalletButton.backgroundColor = .white
        deleteWalletButton.layer.cornerRadius = 10
        deleteWalletButton.tag = 1
        deleteWalletButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(deleteWalletButton)
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
                if let balanceString = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth, decimals: 4) {
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
    
//    override func configureCloseButton() {
//        super.configureCloseButton()
//
//        closeButtonImage.withTintColor(.white, renderingMode: .alwaysOriginal)
//    }
    
    // MARK: - setConstraints
    func setConstraints() {
        NSLayoutConstraint.activate([
            // uppper container
            upperContainer.topAnchor.constraint(equalTo: view.topAnchor),
            upperContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            upperContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            upperContainer.bottomAnchor.constraint(equalTo: lowerContainer.topAnchor),
            
            refreshButton.topAnchor.constraint(equalTo: upperContainer.layoutMarginsGuide.topAnchor, constant: 0),
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
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            
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
                    StandardAlertContent(titleString: "Delete Wallet", body: ["": "Are you sure you want to delete your wallet from your local storage?"], messageTextAlignment: .left, alertStyle: .withCancelButton, buttonAction: { [weak self](_) in
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
