//
//  SinglePageViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit

class SinglePageViewController: UIViewController {
    var gallery: String!
    var containerView: BlurEffectContainerView!
    var textFields = [UITextField]()
    private let keyService = KeysService()
    private let localDatabase = LocalDatabase()
    private let alert = Alerts()
    weak var delegate: WalletDelegate?
    var mode: WalletCreationType = .createKey
    private let walletController = WalletGenerationController()
    
    // createWallet
    var passwordTextField: UITextField!
    var repeatPasswordTextField: UITextField!
    var createButton: UIButton!
    var passwordsDontMatch: UILabel!
    
    // importWallet
    var closeButton: UIButton!
    var importButton: UIButton!
    var enterPrivateKeyTextField: UITextField!
    
    init(gallery: String) {
        self.gallery = gallery
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        
        if gallery == "1" {
            configureCreateWallet()
            setCreateWalletConstraints()
        } else {
            configureImportWallet()
            setImportWalletConstraints()
        }
    }
}

extension SinglePageViewController {
    func configure() {
        self.hideKeyboardWhenTappedAround()

        containerView = BlurEffectContainerView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        containerView.fill(inset: 30)
    }

    func configureCreateWallet() {
        // passwords don't match label
        passwordsDontMatch = UILabel()
        passwordsDontMatch.textColor = .red
        passwordsDontMatch.textAlignment = .center
        passwordsDontMatch.translatesAutoresizingMaskIntoConstraints = false
        passwordsDontMatch.isHidden = true
        containerView.addSubview(passwordsDontMatch)
        
        // password text field
        passwordTextField = UITextField()
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.gray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.placeholder = "Create a new password"
        textFields.append(passwordTextField)
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.delegate = self
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(passwordTextField)
        
        // repeat password text field
        repeatPasswordTextField = UITextField()
        repeatPasswordTextField.isSecureTextEntry = true
        repeatPasswordTextField.layer.borderWidth = 1
        repeatPasswordTextField.layer.borderColor = UIColor.gray.cgColor
        repeatPasswordTextField.layer.cornerRadius = 10
        repeatPasswordTextField.placeholder = "Enter your password again"
        textFields.append(repeatPasswordTextField)
        repeatPasswordTextField.setLeftPaddingPoints(10)
        repeatPasswordTextField.delegate = self
        repeatPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(repeatPasswordTextField)
        
        // create wallet button
        createButton = UIButton()
        createButton.setTitle("Create Wallet", for: .normal)
        createButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        createButton.tag = 1
        createButton.backgroundColor = .black
        createButton.layer.cornerRadius = 10
        createButton.isEnabled = false
        createButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(createButton)
    }
    
    func setCreateWalletConstraints() {
        NSLayoutConstraint.activate([
            // paswords don't match label
            passwordsDontMatch.topAnchor.constraint(equalTo: repeatPasswordTextField.bottomAnchor, constant: 3),
            passwordsDontMatch.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordsDontMatch.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            passwordsDontMatch.heightAnchor.constraint(equalToConstant: 50),
            
            // password text field
            passwordTextField.bottomAnchor.constraint(equalTo: repeatPasswordTextField.topAnchor, constant: -50),
            passwordTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // repeat password text field
            repeatPasswordTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            repeatPasswordTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            repeatPasswordTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            repeatPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // create wallet button
            createButton.topAnchor.constraint(equalTo: repeatPasswordTextField.bottomAnchor, constant: 50),
            createButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])
    }
    
    func configureImportWallet() {
        // passwords don't match label
        passwordsDontMatch = UILabel()
        passwordsDontMatch.textColor = .red
        passwordsDontMatch.textAlignment = .center
        passwordsDontMatch.translatesAutoresizingMaskIntoConstraints = false
        passwordsDontMatch.isHidden = true
        containerView.addSubview(passwordsDontMatch)
        
        // repeat password text field
        passwordTextField = UITextField()
        passwordTextField.delegate = self
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.gray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.placeholder = "Enter your password"
        textFields.append(passwordTextField)
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(passwordTextField)
        
        // enter private key
        enterPrivateKeyTextField = UITextField()
        enterPrivateKeyTextField.delegate = self
        enterPrivateKeyTextField.layer.borderWidth = 1
        enterPrivateKeyTextField.layer.cornerRadius = 10
        enterPrivateKeyTextField.placeholder = "Enter your private key"
        enterPrivateKeyTextField.layer.borderColor = UIColor.lightGray.cgColor
        enterPrivateKeyTextField.setLeftPaddingPoints(10)
        textFields.append(enterPrivateKeyTextField)
        enterPrivateKeyTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(enterPrivateKeyTextField)
        
        // create wallet button
        importButton = UIButton()
        importButton.setTitle("Import Wallet", for: .normal)
        importButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        importButton.backgroundColor = .black
        importButton.layer.cornerRadius = 10
        importButton.isEnabled = false
        importButton.tag = 2
        importButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(importButton)
    }
    
    func setImportWalletConstraints() {
        NSLayoutConstraint.activate([
            // paswords don't match label
            passwordsDontMatch.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            passwordsDontMatch.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordsDontMatch.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            passwordsDontMatch.heightAnchor.constraint(equalToConstant: 50),
            
            // password text field
            passwordTextField.bottomAnchor.constraint(equalTo: enterPrivateKeyTextField.topAnchor, constant: -50),
            passwordTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // enterPrivateKeyTextField text field
            enterPrivateKeyTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            enterPrivateKeyTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            enterPrivateKeyTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            enterPrivateKeyTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // import wallet button
            importButton.topAnchor.constraint(equalTo: enterPrivateKeyTextField.bottomAnchor, constant: 50),
            importButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            importButton.heightAnchor.constraint(equalToConstant: 50),
            importButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])
    }
    
    @objc func buttonHandler(_ sender: UIButton!) {
        switch sender.tag {
            case 1:
                createWallet()
            case 2:
                importWallet()
            default:
                break
        }
    }
}

extension SinglePageViewController: UITextFieldDelegate {
    // MARK: - textFieldDidBeginEditing
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if gallery == "1" {
            textField.returnKeyType = createButton.isEnabled ? UIReturnKeyType.done : .next
            textField.textColor = UIColor.orange
            if textField == passwordTextField || textField == repeatPasswordTextField {
                passwordsDontMatch.isHidden = true
            }
        } else {
            textField.returnKeyType = importButton.isEnabled ? UIReturnKeyType.done : .next
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text ?? "") as NSString
        let futureString = currentText.replacingCharacters(in: range, with: string) as String

        if gallery == "1" {
            createButton.isEnabled = false

            switch textField {
                //            case enterPrivateKeyTextField:
                //                if passwordTextField.text == repeatPasswordTextField.text &&
                //                    !(passwordTextField.text?.isEmpty ?? true) &&
                //                    !futureString.isEmpty && ((passwordTextField.text?.count)! > 4) {
                //                    createButton.isEnabled = true
                //                }
                case passwordTextField:
                    if !futureString.isEmpty &&
                        futureString == repeatPasswordTextField.text ||
                        repeatPasswordTextField.text?.isEmpty == true {
                        passwordsDontMatch.isHidden = true
                        createButton.isEnabled = true
                        //                    createButton.isEnabled = (!(enterPrivateKeyTextField.text?.isEmpty ?? true) || mode == .createKey)
                    } else {
                        passwordsDontMatch.isHidden = false
                        createButton.isEnabled = false
                    }
                case repeatPasswordTextField:
                    if !futureString.isEmpty &&
                        futureString == passwordTextField.text {
                        passwordsDontMatch.isHidden = true
                        createButton.isEnabled = true
                        //                    createButton.isEnabled = (mode == .createKey)
                    } else {
                        passwordsDontMatch.isHidden = false
                        createButton.isEnabled = false
                    }
                default:
                    createButton.isEnabled = false
                    passwordsDontMatch.isHidden = false
            }

            createButton.alpha = createButton.isEnabled ? 1.0 : 0.5
            textField.returnKeyType = createButton.isEnabled ? UIReturnKeyType.done : .next
        } else {
            importButton.isEnabled = false

            switch textField {
                case passwordTextField:
                    if !futureString.isEmpty {
                        passwordsDontMatch.isHidden = true
                        importButton.isEnabled = !(enterPrivateKeyTextField.text?.isEmpty ?? true)
                    } else {
                        passwordsDontMatch.isHidden = false
                        importButton.isEnabled = false
                    }
                case enterPrivateKeyTextField:
                    if  !futureString.isEmpty {
                        importButton.isEnabled = !(passwordTextField.text?.isEmpty ?? true)
                    } else {
                        passwordsDontMatch.isHidden = false
                        importButton.isEnabled = false
                    }
                default:
                    importButton.isEnabled = false
                    passwordsDontMatch.isHidden = false
            }

            importButton.alpha = importButton.isEnabled ? 1.0 : 0.5
            textField.returnKeyType = importButton.isEnabled ? UIReturnKeyType.done : .next
        }

        return true
    }
    
    // MARK: - textFieldShouldEndEditing
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if gallery == "1" {
            textField.textColor = UIColor.darkGray
            guard textField == repeatPasswordTextField ||
                    textField == passwordTextField else {
                return true
            }
            if (!(passwordTextField.text?.isEmpty ?? true) ||
                    !(repeatPasswordTextField.text?.isEmpty ?? true)) &&
                passwordTextField.text != repeatPasswordTextField.text {
                passwordsDontMatch.isHidden = false
                passwordsDontMatch.text = "Passwords don't match"
                repeatPasswordTextField.textColor = UIColor.red
                passwordTextField.textColor = UIColor.red
            } else if (!(passwordTextField.text?.isEmpty ?? true) ||
                        !(repeatPasswordTextField.text?.isEmpty ?? true)) &&
                        ((passwordTextField.text?.count)! < 5) {
                passwordsDontMatch.isHidden = false
                passwordsDontMatch.text = "Password is too short"
                repeatPasswordTextField.textColor = UIColor.red
                passwordTextField.textColor = UIColor.red
            } else {
                repeatPasswordTextField.textColor = UIColor.darkGray
                passwordTextField.textColor = UIColor.darkGray
            }
        } else {
            if textField.returnKeyType == .done && importButton.isEnabled {
                importWallet()
            } else if textField.returnKeyType == .next {
                let index = textFields.firstIndex(of: textField) ?? 0
                let nextIndex = (index == textFields.count - 1) ? 0 : index + 1
                textFields[nextIndex].becomeFirstResponder()
            } else {
                view.endEditing(true)
            }
        }
        return true
    }
    
    // MARK: - textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let createButton = createButton else {
            alert.fading(text: "Unable to log in.", controller: self, toBePasted: nil)
            return false
        }
        
        if textField.returnKeyType == .done && createButton.isEnabled && ((passwordTextField.text?.count)! > 4) {
            createWallet()
        } else if textField.returnKeyType == .next {
            let index = textFields.firstIndex(of: textField) ?? 0
            let nextIndex = (index == textFields.count - 1) ? 0 : index + 1
            textFields[nextIndex].becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
        return true
    }
}

extension SinglePageViewController {
    // MARK: - createWallet
    func createWallet() {
        guard let password = passwordTextField.text, !password.isEmpty else {
            self.alert.fading(text: "The password cannot be empty.", controller: self, toBePasted: nil, width: 250)
            return
        }
        
        guard let repeatPassword = repeatPasswordTextField.text, !repeatPassword.isEmpty else {
            self.alert.fading(text: "The repeat password cannot be empty.", controller: self, toBePasted: nil, width: 250)
            return
        }
        
        guard password == repeatPassword else {
            passwordsDontMatch.isHidden = false
            return
        }
        
        passwordsDontMatch.isHidden = true
        
        walletController.createWallet(with: mode, password: passwordTextField.text, key: nil) { [weak self](error) in
            guard error == nil else {
                self?.alert.fading(text: "Unable to create a wallet.", controller: self, toBePasted: nil, width: 250)
                return
            }

//            self.isWalletCreated = true
            self?.delegate?.didProcessWallet()
        }
    }
    
    // MARK: - importWallet
    func importWallet() {
        guard let password = passwordTextField.text, !password.isEmpty else {
            self.alert.fading(text: "The password cannot be empty.", controller: self, toBePasted: nil, width: 250)
            return
        }
        
        guard let privateKey = enterPrivateKeyTextField.text, !privateKey.isEmpty else {
            self.alert.fading(text: "The private key cannot be empty.", controller: self, toBePasted: nil, width: 300)
            return
        }

        keyService.addNewWalletWithPrivateKey(key: privateKey, password: password) { [weak self](wallet, error) in
            if let error = error {
                switch error {
                    case .couldNotSaveTheWallet, .couldNotCreateTheWallet:
                        self?.alert.fading(text: "Could not import the wallet.", controller: self, toBePasted: nil, width: 250)
                        break
                    case .couldNotGetAddress:
                        self?.alert.fading(text: "Could not get the wallet address.", controller: self, toBePasted: nil, width: 300)
                        break
                    default:
                        break
                }
                return
            }

            guard let wallet = wallet else { return }
            self?.localDatabase.saveWallet(isRegistered: true, wallet: wallet) { (error) in
                if let _ = error {
                    self?.alert.fading(text: "Could not save the wallet", controller: self, toBePasted: nil, width: 250)
                    return
                }

                self?.delegate?.didProcessWallet()
            }
        }
    }
}
