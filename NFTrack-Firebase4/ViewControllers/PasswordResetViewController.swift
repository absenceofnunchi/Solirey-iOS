//
//  PasswordResetViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

/*
 Abstract: Password reset for RegisteredWalletViewController
 */

import UIKit

class PasswordResetViewController: UIViewController {
    var titleString: String?
    var titleLabel: UILabel!
    var messageLabel: UILabel!
    var height: CGFloat!
    var buttonAction: ((UIViewController)->Void)?
    var buttonPanel: UIView!
    var closeButton: UIButton!
    var cancelButton: UIButton!
    var currentPasswordTextField: UITextField!
    var passwordTextField: UITextField!
    var repeatPasswordTextField: UITextField!
    var passwordsDontMatch: UILabel!
    var textFields = [UITextField]()
    
    private lazy var customTransitioningDelegate = TransitioningDelegate(height: height)
    
    init(height: CGFloat = 450, buttonTitle: String = "OK", messageTextAlignment: NSTextAlignment = .center) {
        super.init(nibName: nil, bundle: nil)
        
        self.height = height
        
        self.closeButton = UIButton()
        self.closeButton.setTitle(buttonTitle, for: .normal)
        
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("fatal error")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setConstraints()
    }
}

private extension PasswordResetViewController {
    func configure() {
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        transitioningDelegate = customTransitioningDelegate
    }
    
    func configureUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        // passwords don't match label
        passwordsDontMatch = UILabel()
        passwordsDontMatch.textColor = .red
        passwordsDontMatch.translatesAutoresizingMaskIntoConstraints = false
        passwordsDontMatch.isHidden = true
        view.addSubview(passwordsDontMatch)
        
        titleLabel = UILabel()
        titleLabel.textColor = .lightGray
        titleLabel.text = titleString
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        messageLabel = UILabel()
        messageLabel.textColor = .lightGray
        messageLabel.text = "Minimum 6 characters"
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        
        // current password
        currentPasswordTextField = UITextField()
        currentPasswordTextField.isSecureTextEntry = true
        currentPasswordTextField.placeholder = "Current Password"
        currentPasswordTextField.autocapitalizationType = .none
        currentPasswordTextField.setLeftPaddingPoints(10)
        currentPasswordTextField.layer.borderWidth = 0.7
        currentPasswordTextField.layer.cornerRadius = 5
        currentPasswordTextField.layer.borderColor = UIColor.lightGray.cgColor
        textFields.append(currentPasswordTextField)
        currentPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentPasswordTextField)
        
        // new password
        passwordTextField = UITextField()
        passwordTextField.isSecureTextEntry = true
        passwordTextField.delegate = self
        passwordTextField.placeholder = "New Password"
        passwordTextField.autocapitalizationType = .none
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.layer.borderWidth = 0.7
        passwordTextField.layer.cornerRadius = 5
        passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        textFields.append(passwordTextField)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordTextField)
        
        repeatPasswordTextField = UITextField()
        repeatPasswordTextField.isSecureTextEntry = true
        repeatPasswordTextField.delegate = self
        repeatPasswordTextField.placeholder = "New password again"
        repeatPasswordTextField.autocapitalizationType = .none
        repeatPasswordTextField.setLeftPaddingPoints(10)
        repeatPasswordTextField.layer.borderWidth = 0.7
        repeatPasswordTextField.layer.cornerRadius = 5
        repeatPasswordTextField.layer.borderColor = UIColor.lightGray.cgColor
        textFields.append(repeatPasswordTextField)
        repeatPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(repeatPasswordTextField)
        
        buttonPanel = UIView()
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonPanel)
        
        closeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        closeButton.isEnabled = false
        closeButton.backgroundColor = .black
        closeButton.layer.cornerRadius = 10
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(closeButton)
        
        cancelButton = UIButton()
        cancelButton.backgroundColor = .red
        cancelButton.layer.cornerRadius = 10
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelHandler), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(cancelButton)
    }
    
    func setConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(contentsOf: [
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageLabel.heightAnchor.constraint(equalToConstant: 50),
            
            currentPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            currentPasswordTextField.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant: -20),
            currentPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            repeatPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            repeatPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            repeatPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            repeatPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordsDontMatch.topAnchor.constraint(equalTo: repeatPasswordTextField.bottomAnchor, constant: 5),
            passwordsDontMatch.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordsDontMatch.widthAnchor.constraint(equalToConstant: 200),
            passwordsDontMatch.heightAnchor.constraint(equalToConstant: 50),
            
            buttonPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            buttonPanel.heightAnchor.constraint(equalToConstant: 50),
            
            closeButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            closeButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
            
            cancelButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            cancelButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func tapped() {
        if let buttonAction = self.buttonAction {
            buttonAction(self)
        }
    }
    
    @objc func cancelHandler() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PasswordResetViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.returnKeyType = closeButton.isEnabled ? UIReturnKeyType.done : .next
        textField.textColor = UIColor.orange
        if textField == passwordTextField || textField == repeatPasswordTextField {
            passwordsDontMatch.isHidden = true
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text ?? "") as NSString
        let futureString = currentText.replacingCharacters(in: range, with: string) as String
        closeButton.isEnabled = false

        switch textField {
//            case currentPasswordTextField:
//                if !(currentPasswordTextField.text?.isEmpty ?? true) &&
//                    !futureString.isEmpty && (passwordTextField.text == repeatPasswordTextField.text) {
//                    closeButton.isEnabled = true
//                }
            case passwordTextField:
                if !futureString.isEmpty &&
                    futureString == repeatPasswordTextField.text &&
                    repeatPasswordTextField.text?.isEmpty == false &&
                    currentPasswordTextField.text?.isEmpty == false {
                    if ((passwordTextField.text?.count)! < 5) {
                        passwordsDontMatch.isHidden = false
                        closeButton.isEnabled = false
                    } else {
                        passwordsDontMatch.isHidden = true
                        closeButton.isEnabled = true
                    }
                    passwordsDontMatch.isHidden = true
                    closeButton.isEnabled = true
                } else {
                    passwordsDontMatch.isHidden = false
                    closeButton.isEnabled = false
                }
            case repeatPasswordTextField:
                if !futureString.isEmpty &&
                    futureString == passwordTextField.text &&
                    currentPasswordTextField.text?.isEmpty == false {
                    if ((repeatPasswordTextField.text?.count)! < 5) {
                        passwordsDontMatch.isHidden = false
                        closeButton.isEnabled = false
                    } else {
                        passwordsDontMatch.isHidden = true
                        closeButton.isEnabled = true
                    }
                } else {
                    passwordsDontMatch.isHidden = false
                    closeButton.isEnabled = false
                }
            default:
                closeButton.isEnabled = false
                passwordsDontMatch.isHidden = false
        }

        closeButton.alpha = closeButton.isEnabled ? 1.0 : 0.5
        textField.returnKeyType = closeButton.isEnabled ? UIReturnKeyType.done : .next

        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
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

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done && closeButton.isEnabled && ((passwordTextField.text?.count)! > 4) {
            print("account created")
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
