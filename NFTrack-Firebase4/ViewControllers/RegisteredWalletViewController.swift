//
//  RegisteredWalletViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit
import web3swift

class RegisteredWalletViewController: UIViewController {
    var deleteWalletButton: UIButton!
    var privateKeyButton: UIButton!
    var resetPassword: UIButton!
    weak var delegate: WalletDelegate?
    var lowerContainer: BackgroundView!
    var upperContainer: UIView!
    var balanceLabel: UILabel!
    var sendButton: WalletButtonView!
    var receiveButton: WalletButtonView!
    var refreshButton: UIButton!
    
    let localDatabase = LocalDatabase()
    let keyService = KeysService()
    let transactionService = TransactionService()
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configureWallet()
        setConstraints()
    }
}

extension RegisteredWalletViewController: UITextFieldDelegate {
    // MARK: - configure
    func configure() {
        view.backgroundColor = UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1)
        
        upperContainer = UIView()
        upperContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upperContainer)
        
        // refresh button
        let refreshImage = UIImage(systemName: "arrow.clockwise")!.withTintColor(.white, renderingMode: .alwaysOriginal)
        refreshButton = UIButton.systemButton(with: refreshImage, target: self, action: #selector(buttonHandler))
        refreshButton.tag = 4
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        upperContainer.addSubview(refreshButton)
        
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
        
        resetPassword = UIButton()
        resetPassword.dropShadow()
        resetPassword.setTitle("Reset Password", for: .normal)
        resetPassword.setTitleColor(.black, for: .normal)
        resetPassword.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        resetPassword.backgroundColor = .white
        resetPassword.layer.cornerRadius = 10
        resetPassword.tag = 3
        resetPassword.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetPassword)
        
        privateKeyButton = UIButton()
        privateKeyButton.dropShadow()
        privateKeyButton.setTitle("Private Key", for: .normal)
        privateKeyButton.setTitleColor(.black, for: .normal)
        privateKeyButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        privateKeyButton.backgroundColor = .white
        privateKeyButton.layer.cornerRadius = 10
        privateKeyButton.tag = 2
        privateKeyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(privateKeyButton)
        
        deleteWalletButton = UIButton()
        deleteWalletButton.dropShadow()
        deleteWalletButton.setTitle("Delete Wallet", for: .normal)
        deleteWalletButton.setTitleColor(.black, for: .normal)
        deleteWalletButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        deleteWalletButton.backgroundColor = .white
        deleteWalletButton.layer.cornerRadius = 10
        deleteWalletButton.tag = 1
        deleteWalletButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteWalletButton)
    }
    
    @objc func configureWallet() {
        guard let address = Web3swiftService.currentAddress else {
            let detailVC = DetailViewController(height: 250)
            detailVC.titleString = "Error"
            detailVC.message = "There was an error obtaining the wallet address"
            detailVC.buttonAction = { [weak self]vc in
                self?.dismiss(animated: true, completion: nil)
            }
            present(detailVC, animated: true, completion: nil)
            return
        }
        
        DispatchQueue.global().async {
            do {
                let balance = try Web3swiftService.web3instance.eth.getBalance(address: address)
                if let balanceString = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth, decimals: 4) {
                    DispatchQueue.main.async {
                        self.balanceLabel.text = "\(self.transactionService.stripZeros(balanceString)) ETH"
                    }
                }
            } catch {
                let detailVC = DetailViewController(height: 250)
                detailVC.titleString = "Error"
                detailVC.message = "Sorry, there was an error retrieving your balance."
                detailVC.buttonAction = { [weak self]vc in
                    self?.dismiss(animated: true, completion: nil)
                }
                self.present(detailVC, animated: true, completion: nil)
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
            
            refreshButton.topAnchor.constraint(equalTo: upperContainer.layoutMarginsGuide.topAnchor, constant: 0),
            refreshButton.trailingAnchor.constraint(equalTo: upperContainer.trailingAnchor, constant: -10),
            refreshButton.widthAnchor.constraint(equalToConstant: 50),
            refreshButton.heightAnchor.constraint(equalToConstant: 50),
            
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
            
            // reset wallet password button
            resetPassword.bottomAnchor.constraint(equalTo: privateKeyButton.topAnchor, constant: -30),
            resetPassword.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            resetPassword.heightAnchor.constraint(equalToConstant: 60),
            resetPassword.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // private key
            privateKeyButton.centerYAnchor.constraint(equalTo: lowerContainer.centerYAnchor),
            privateKeyButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            privateKeyButton.heightAnchor.constraint(equalToConstant: 60),
            privateKeyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // create wallet button
            deleteWalletButton.topAnchor.constraint(equalTo: privateKeyButton.bottomAnchor, constant: 30),
            deleteWalletButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            deleteWalletButton.heightAnchor.constraint(equalToConstant: 60),
            deleteWalletButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    // MARK: - buttonHandler
    @objc func buttonHandler(_ sender: UIButton!) {
        switch sender.tag {
            case 1:
                // delete
                let ac = UIAlertController(title: "Delete Wallet", message: "Are you sure you want to delete your wallet?", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self](_) in
                    self?.localDatabase.deleteWallet { [weak self](error) in
                        if let error = error {
                            switch error {
                                case .couldNotDeleteTheWallet:
                                    let detailVC = DetailViewController(height: 250)
                                    detailVC.titleString = "Error"
                                    detailVC.message = "Could not delete the wallet."
                                    detailVC.buttonAction = { [weak self]vc in
                                        self?.dismiss(animated: true, completion: nil)
                                    }
                                    self?.present(detailVC, animated: true, completion: nil)
                                default:
                                    break
                            }
                        }
                        self?.delegate?.didProcessWallet()

                    }
                }))
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(ac, animated: true, completion: nil)
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
                        let detailVC = DetailViewController(height: 250)
                        detailVC.titleString = "Private Key"
                        detailVC.message = privateKey
                        detailVC.buttonAction = { _ in
                            if privateKey != nil {
                                let pasteboard = UIPasteboard.general
                                pasteboard.string = privateKey
                            }
                            
                            self?.dismiss(animated: true, completion: nil)
                        }
                        self?.present(detailVC, animated: true, completion: nil)
                    } catch {
                        let detailVC = DetailViewController(height: 250)
                        detailVC.titleString = "Error"
                        detailVC.message = "Wrong password."
                        detailVC.buttonAction = { [weak self]vc in
                            self?.dismiss(animated: true, completion: nil)
                        }
                        self?.present(detailVC, animated: true, completion: nil)
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
                                        let detailVC = DetailViewController(height: 250)
                                        detailVC.titleString = "Error"
                                        detailVC.message = "Sorry, the old password couldn't be fetched"
                                        detailVC.buttonAction = { [weak self]vc in
                                            self?.dismiss(animated: true, completion: nil)
                                        }
                                        self?.present(detailVC, animated: true, completion: nil)
                                    case .failureToRegeneratePassword:
                                        let detailVC = DetailViewController(height: 250)
                                        detailVC.titleString = "Error"
                                        detailVC.message = "Sorry, a new password couldn't be generated"
                                        detailVC.buttonAction = { [weak self]vc in
                                            self?.dismiss(animated: true, completion: nil)
                                        }
                                        self?.present(detailVC, animated: true, completion: nil)
                                }
                            }

                            if let wallet = wallet {
                                self?.localDatabase.saveWallet(isRegistered: false, wallet: wallet) { (error) in
                                    if let _ = error {
                                        let detailVC = DetailViewController(height: 250)
                                        detailVC.titleString = "Error"
                                        detailVC.message = "Sorry, there was an error generating a new password. Check to see if you're using the correct password."
                                        detailVC.buttonAction = { [weak self]vc in
                                            self?.dismiss(animated: true, completion: nil)
                                        }
                                        self?.present(detailVC, animated: true, completion: nil)
                                    }

                                    let detailVC = DetailViewController(height: 250)
                                    detailVC.titleString = "Success"
                                    detailVC.message = "A new password has been generated!"
                                    detailVC.buttonAction = { [weak self]vc in
                                        self?.dismiss(animated: true, completion: nil)
                                    }
                                    self?.present(detailVC, animated: true, completion: nil)
                                }
                            }
                        }
                    })
                }
                present(prVC, animated: true, completion: nil)
            case 4:
                configureWallet()
            default:
                break
        }
    }
}

// private key
// a9420edb3ac5a4eaece8dfa7c5fdd37b0358d7a7d51b1579b5ae94be9cce0842
// 650ab63c9923856efde6471bb1249df2e5b0995e7a84826f4374feb7ad605079
