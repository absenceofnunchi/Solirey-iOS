//
//  SignUpViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-05.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    var titleLabel: UILabel!
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    var repeatPasswordTextField: UITextField!
    var createButton: UIButton!
    var passwordsDontMatch: UILabel!
    var textFields = [UITextField]()
    var containerView: BlurEffectContainerView!
    var additionalContainer: UIView!
    var additionalLabel: UILabel!
    var toggleButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setConstraints()
        passwordTextField.delegate = self
        repeatPasswordTextField.delegate = self
    }
}

extension SignUpViewController {
    // MARK: - ConfigureUI
    func configureUI() {
        
        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
        
        // title label
        titleLabel = UILabel()
        titleLabel.text = "Welcome Back"
        titleLabel.font = .rounded(ofSize: 25, weight: .bold)
        titleLabel.textColor = .gray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // container view
        containerView = BlurEffectContainerView()
//        containerView.transform = CGAffineTransform(translationX: 0, y: 80)
//        containerView.alpha = 0
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // email text field
        emailTextField = UITextField()
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor.gray.cgColor
        emailTextField.layer.cornerRadius = 10
        emailTextField.placeholder = "Enter your email"
            emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        textFields.append(emailTextField)
        emailTextField.setLeftPaddingPoints(10)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emailTextField)
        
        // passwords don't match label
        passwordsDontMatch = UILabel()
        passwordsDontMatch.translatesAutoresizingMaskIntoConstraints = false
        passwordsDontMatch.isHidden = true
        view.addSubview(passwordsDontMatch)
        
        // password text field
        passwordTextField = UITextField()
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.gray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.placeholder = "Create a new password"
        textFields.append(passwordTextField)
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(passwordTextField)
        
        // repeat password text field
        repeatPasswordTextField = UITextField()
        repeatPasswordTextField.layer.borderWidth = 1
        repeatPasswordTextField.layer.borderColor = UIColor.gray.cgColor
        repeatPasswordTextField.layer.cornerRadius = 10
        repeatPasswordTextField.placeholder = "Enter your password again"
        textFields.append(repeatPasswordTextField)
        repeatPasswordTextField.setLeftPaddingPoints(10)
        repeatPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(repeatPasswordTextField)
        
        // create wallet button
        createButton = UIButton()
        createButton.setTitle("Signup", for: .normal)
        createButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        createButton.tag = 2
        createButton.backgroundColor = .black
        createButton.layer.cornerRadius = 10
//        createButton.isEnabled = false
        createButton.isEnabled = true
        createButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(createButton)
        
        additionalContainer = UIView()
        additionalContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(additionalContainer)
        
        additionalLabel = UILabel()
        additionalLabel.font = UIFont.systemFont(ofSize: 16)
        additionalLabel.text = "Have an account?"
        additionalLabel.textColor = .lightGray
        additionalLabel.translatesAutoresizingMaskIntoConstraints = false
        additionalContainer.addSubview(additionalLabel)
        
        toggleButton = UIButton()
        toggleButton.setTitle("Sign in", for: .normal)
        toggleButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        toggleButton.tag = 1
        toggleButton.setTitleColor(.gray, for: .normal)
        toggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        additionalContainer.addSubview(toggleButton)
    }
    
    func setConstraints() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                // container view
                containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
                containerView.heightAnchor.constraint(equalToConstant: 350),
            ])
        }else{
            NSLayoutConstraint.activate([
                // container view
                containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
                containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.3),
            ])
        }
        
        NSLayoutConstraint.activate([
            // paswords don't match label
            passwordsDontMatch.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            passwordsDontMatch.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordsDontMatch.widthAnchor.constraint(equalToConstant: 200),
            passwordsDontMatch.heightAnchor.constraint(equalToConstant: 50),
            
            // title label
            titleLabel.topAnchor.constraint(equalTo: passwordsDontMatch.bottomAnchor, constant: 20),
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // email text field
            emailTextField.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant:  -30),
            emailTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emailTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // password text field
            passwordTextField.bottomAnchor.constraint(equalTo: repeatPasswordTextField.topAnchor, constant: -30),
            passwordTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // repeat password text field
            repeatPasswordTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 30),
            repeatPasswordTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            repeatPasswordTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            repeatPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // create wallet button
            createButton.topAnchor.constraint(equalTo: repeatPasswordTextField.bottomAnchor, constant: 30),
            createButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            additionalContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            additionalContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            additionalContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            additionalContainer.heightAnchor.constraint(equalToConstant: 40),
            
            additionalLabel.centerYAnchor.constraint(equalTo: additionalContainer.centerYAnchor),
            additionalLabel.leadingAnchor.constraint(equalTo: additionalContainer.leadingAnchor),
            additionalLabel.widthAnchor.constraint(equalTo: additionalContainer.widthAnchor, multiplier: 0.8),
            additionalLabel.heightAnchor.constraint(equalToConstant: 40),
            
            toggleButton.centerYAnchor.constraint(equalTo: additionalContainer.centerYAnchor),
            toggleButton.trailingAnchor.constraint(equalTo: additionalContainer.trailingAnchor),
            toggleButton.widthAnchor.constraint(equalTo: additionalContainer.widthAnchor, multiplier: 0.2),
            toggleButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Button Handler
    
    @objc func buttonHandler(_ sender: UIButton!) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 1:
                self.dismiss(animated: true, completion: nil)
            case 2:
                didCreateAccount()
                print("sign up")
                break
            default:
                break
        }
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.returnKeyType = createButton.isEnabled ? UIReturnKeyType.done : .next
        textField.textColor = UIColor.orange
        if textField == passwordTextField || textField == repeatPasswordTextField {
            passwordsDontMatch.isHidden = true
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text ?? "") as NSString
        let futureString = currentText.replacingCharacters(in: range, with: string) as String
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
//                    createButton.isEnabled = (mode == .createKey)
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
        
        createButton.isEnabled = true
        
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
        if textField.returnKeyType == .done && createButton.isEnabled && ((passwordTextField.text?.count)! > 4) {
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

extension SignUpViewController {
    // MARK: - didCreateAccount
    func didCreateAccount() {
        guard let email = emailTextField.text, !email.isEmpty else {
            let detailVC = DetailViewController(height: 250)
            detailVC.titleString = "Sorry!"
            detailVC.message = "Email can't be empty"
            detailVC.buttonAction = { [weak self]vc in
                self?.dismiss(animated: true, completion: nil)
            }
            present(detailVC, animated: true, completion: nil)
            return
        }
                
        guard let password = passwordTextField.text, !password.isEmpty else {
            let detailVC = DetailViewController(height: 250)
            detailVC.titleString = "Sorry!"
            detailVC.message = "Password can't be empty"
            detailVC.buttonAction = { [weak self]vc in
                self?.dismiss(animated: true, completion: nil)
            }
            present(detailVC, animated: true, completion: nil)
            return
        }
                
        showSpinner {
            // [START create_user]
            Auth.auth().createUser(withEmail: email, password: password) { [weak self](authResult, error) in
                // [START_EXCLUDE]
                self?.hideSpinner {
                    guard let user = authResult?.user, error == nil else {
//                        strongSelf.showMessagePrompt(error!.localizedDescription)
                        let detailVC = DetailViewController(height: 250)
                        detailVC.titleString = "Sorry!"
                        detailVC.message = error!.localizedDescription
                        detailVC.buttonAction = { vc in
                            self?.dismiss(animated: true, completion: nil)
                        }
                        self?.present(detailVC, animated: true, completion: nil)
                        return
                    }
                    print("\(user.email!) created")
                    self?.navigationController?.popViewController(animated: true)
                }
                // [END_EXCLUDE]
            }
            // [END create_user]
        }
    }
}
