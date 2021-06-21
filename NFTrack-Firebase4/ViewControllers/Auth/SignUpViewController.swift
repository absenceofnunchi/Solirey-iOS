//
//  SignUpViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-05.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    private var titleLabel: UILabel!
    private var emailTextField: UITextField!
    private var displayNameTextField: UITextField!
    private var passwordTextField: UITextField!
    private var repeatPasswordTextField: UITextField!
    private var createButton: UIButton!
    private var passwordsDontMatch: UILabel!
    private var textFields = [UITextField]()
    private var containerView: BlurEffectContainerView!
    private var additionalContainer: UIView!
    private var additionalLabel: UILabel!
    private var toggleButton: UIButton!
    private let alert = Alerts()
    
    lazy var ipadNoKeyboard: [NSLayoutConstraint] = [
        containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        containerView.heightAnchor.constraint(equalToConstant: 380),
    ]
    
    lazy var mobileNoKeyboard: [NSLayoutConstraint] = [
        containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.5),
    ]
    
    lazy var withKeyboard: [NSLayoutConstraint] = [
        containerView.topAnchor.constraint(equalTo: passwordsDontMatch.bottomAnchor, constant: 10),
        containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.3),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setConstraints()
        passwordTextField.delegate = self
        repeatPasswordTextField.delegate = self
    }
    
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addKeyboardObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeKeyboardObserver()
    }
}

extension SignUpViewController {
    // MARK: - ConfigureUI
    func configureUI() {
        
        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
        
        // title label
        titleLabel = UILabel()
        titleLabel.text = "Create Account"
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
        
        displayNameTextField = UITextField()
        displayNameTextField.layer.borderWidth = 1
        displayNameTextField.layer.borderColor = UIColor.gray.cgColor
        displayNameTextField.layer.cornerRadius = 10
        displayNameTextField.placeholder = "Enter your display name"
        displayNameTextField.autocapitalizationType = .none
        displayNameTextField.autocorrectionType = .no
        textFields.append(displayNameTextField)
        displayNameTextField.setLeftPaddingPoints(10)
        displayNameTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(displayNameTextField)
        
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
        createButton.isEnabled = false
//        createButton.isEnabled = true
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
            NSLayoutConstraint.activate(ipadNoKeyboard)
        }else{
            NSLayoutConstraint.activate(mobileNoKeyboard)
        }
        
        NSLayoutConstraint.activate([
            // paswords don't match label
            passwordsDontMatch.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            passwordsDontMatch.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordsDontMatch.widthAnchor.constraint(equalToConstant: 200),
            passwordsDontMatch.heightAnchor.constraint(equalToConstant: 50),
            
            // title label
            titleLabel.topAnchor.constraint(equalTo: passwordsDontMatch.bottomAnchor, constant: 10),
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // email text field
            emailTextField.bottomAnchor.constraint(equalTo: displayNameTextField.topAnchor, constant:  -30),
            emailTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emailTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // email text field
            displayNameTextField.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant:  -30),
            displayNameTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            displayNameTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            displayNameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // password text field
            passwordTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            passwordTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // repeat password text field
            repeatPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
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
                } else {
                    passwordsDontMatch.isHidden = false
                    createButton.isEnabled = false
                }
            case repeatPasswordTextField:
                if !futureString.isEmpty &&
                    futureString == passwordTextField.text {
                    passwordsDontMatch.isHidden = true
                    createButton.isEnabled = true
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
            alert.showDetail("Sorry", with: "Email cannot be empty", for: self)
            return
        }
        
        guard let displayName = displayNameTextField.text, !displayName.isEmpty else {
            alert.showDetail("Sorry", with: "Display name cannot be empty", for: self)
            return
        }
                
        guard let password = passwordTextField.text, !password.isEmpty else {
            alert.showDetail("Sorry", with: "Password cannot be empty", for: self)
            return
        }
                
        showSpinner {
            // [START create_user]
            Auth.auth().createUser(withEmail: email, password: password) { [weak self](authResult, error) in
                // [START_EXCLUDE]
                self?.hideSpinner {
                    guard let user = authResult?.user, error == nil else {
                        self?.alert.showDetail("Sorry", with: error!.localizedDescription, for: self)
                        return
                    }
                    
                    let createRequest = user.createProfileChangeRequest()
                    createRequest.displayName = displayName
                    createRequest.commitChanges { (error) in
                        if let error = error {
                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                        } else {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }
                // [END_EXCLUDE]
            }
            // [END create_user]
        }
    }
}

extension SignUpViewController {
    // MARK: - addKeyboardObserver
    func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
                                                       name: UIResponder.keyboardWillChangeFrameNotification,
                                                       object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: - keyboardNotifications
    // This method will notify when keyboard appears/ dissapears
    @objc func keyboardNotifications(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            // here we will get frame of keyBoard (i.e. x, y, width, height)
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyBoardFrameY = keyBoardFrame!.origin.y

            //Check keyboards Y position and according to that move view up and down
            if keyBoardFrameY >= UIScreen.main.bounds.size.height {
                NSLayoutConstraint.deactivate(withKeyboard)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    NSLayoutConstraint.activate(ipadNoKeyboard)
                } else {
                    NSLayoutConstraint.activate(mobileNoKeyboard)
                }
            } else {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    NSLayoutConstraint.deactivate(ipadNoKeyboard)
                } else {
                    NSLayoutConstraint.deactivate(mobileNoKeyboard)
                }
                
                NSLayoutConstraint.activate(withKeyboard)
                UIView.animate(withDuration: 1) {
                    self.containerView.layoutIfNeeded()
                }
            }
        }
    }
            
}
