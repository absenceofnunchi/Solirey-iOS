//
//  ViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-04.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {
    private var titleLabel: UILabel!
    private var signButton: UIButton!
    private var containerView: BlurEffectContainerView!
    private var emailTextField: UITextField!
    private var passwordTextField: UITextField!
    private var warningLabel: UILabel!
    private var textFields = [UITextField]()
    private var additionalContainer: UIView!
    private var additionalLabel: UILabel!
    private var toggleButton: UIButton!
    private let dissolveAnimator = DissolveTransitionAnimator()
    private let alert = Alerts()
    lazy private var centerConstraint: NSLayoutConstraint = containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    lazy private var topConstraint: NSLayoutConstraint = containerView.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 5)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
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

extension SignInViewController {
    func configureUI() {
        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
        
        // warning label
        warningLabel = UILabel()
        warningLabel.sizeToFit()
        warningLabel.isHidden = true
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningLabel)
        
        // title label
        titleLabel = UILabel()
        titleLabel.text = "Welcome Back"
        titleLabel.font = .rounded(ofSize: 25, weight: .bold)
        titleLabel.textColor = .gray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // container view
        containerView = BlurEffectContainerView()
        view.addSubview(containerView)
        
        //  password text field
        passwordTextField = UITextField()
        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.gray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.textContentType = .password
        passwordTextField.placeholder = "Enter your password"
        passwordTextField.setLeftPaddingPoints(10)
        textFields.append(passwordTextField)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(passwordTextField)
        
        // email text field
        emailTextField = UITextField()
        emailTextField.delegate = self
        emailTextField.autocapitalizationType = .none
        emailTextField.textContentType = .emailAddress
        emailTextField.autocorrectionType = .no
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.cornerRadius = 10
        emailTextField.placeholder = "Enter your email"
        emailTextField.layer.borderColor = UIColor.lightGray.cgColor
        emailTextField.setLeftPaddingPoints(10)
        textFields.append(emailTextField)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emailTextField)
        
        // create wallet button
        signButton = UIButton()
        signButton.setTitle("Signin", for: .normal)
        signButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        signButton.tag = 2
        signButton.backgroundColor = .black
        signButton.layer.cornerRadius = 10
        signButton.isEnabled = false
        signButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(signButton)
        
        additionalContainer = UIView()
        additionalContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(additionalContainer)
        
        additionalLabel = UILabel()
        additionalLabel.font = UIFont.systemFont(ofSize: 16)
        additionalLabel.text = "Don't have an account?"
        additionalLabel.textColor = .lightGray
        additionalLabel.translatesAutoresizingMaskIntoConstraints = false
        additionalContainer.addSubview(additionalLabel)
        
        toggleButton = UIButton()
        toggleButton.setTitle("Sign up", for: .normal)
        toggleButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        toggleButton.tag = 3
        toggleButton.setTitleColor(.gray, for: .normal)
        toggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        additionalContainer.addSubview(toggleButton)
    }
    
    func setConstraints() {
        centerConstraint.isActive = true
        topConstraint.isActive = false

        var constraints = [NSLayoutConstraint]()
        
//        constraints.append(contentsOf: [
//            // container view
//            topConstraint,
//            centerConstraint,
//            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
//            containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.2),
//        ])
        
        constraints.append(contentsOf: [
            // warning label
            warningLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // title label
            titleLabel.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 20),
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
//            topConstraint,
//            centerConstraint,
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.2),
            
            // password text field
            emailTextField.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant: -50),
            emailTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emailTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // emailTextField text field
            passwordTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            passwordTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // signin button
            signButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 50),
            signButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            signButton.heightAnchor.constraint(equalToConstant: 50),
            signButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            additionalContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            additionalContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            additionalContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            additionalContainer.heightAnchor.constraint(equalToConstant: 40),
            
            additionalLabel.centerYAnchor.constraint(equalTo: additionalContainer.centerYAnchor),
            additionalLabel.leadingAnchor.constraint(equalTo: additionalContainer.leadingAnchor),
            additionalLabel.widthAnchor.constraint(equalTo: additionalContainer.widthAnchor, multiplier: 0.7),
            additionalLabel.heightAnchor.constraint(equalToConstant: 40),
            
            toggleButton.centerYAnchor.constraint(equalTo: additionalContainer.centerYAnchor),
            toggleButton.trailingAnchor.constraint(equalTo: additionalContainer.trailingAnchor),
            toggleButton.widthAnchor.constraint(equalTo: additionalContainer.widthAnchor, multiplier: 0.3),
            toggleButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func buttonHandler(_ sender: UIButton!) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 1:
                self.dismiss(animated: true, completion: nil)
            case 2:
                didTapEmailLogin()
            case 3:
                let signupVC = SignUpViewController()
                // this allows the custom transition animator's fromView and fromVC to be the current one and not UITabBarVC
                signupVC.transitioningDelegate = dissolveAnimator
                signupVC.modalPresentationStyle = .fullScreen
                self.present(signupVC, animated: true, completion: nil)
            default:
                break
        }
    }
}

extension SignInViewController: UITextFieldDelegate {
    // MARK: - textFieldDidBeginEditing
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.returnKeyType = signButton.isEnabled ? UIReturnKeyType.done : .next
        //        textField.textColor = UIColor.orange
    }
    
    // MARK: - textField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text ?? "") as NSString
        let futureString = currentText.replacingCharacters(in: range, with: string) as String
        signButton.isEnabled = false
        
        switch textField {
            case passwordTextField:
                if !futureString.isEmpty {
                    warningLabel.isHidden = true
                    signButton.isEnabled = !(emailTextField.text?.isEmpty ?? true)
                } else {
                    warningLabel.isHidden = false
                    signButton.isEnabled = false
                }
            case emailTextField:
                if  !futureString.isEmpty {
                    signButton.isEnabled = !(passwordTextField.text?.isEmpty ?? true)
                } else {
                    warningLabel.isHidden = false
                    signButton.isEnabled = false
                }
            default:
                signButton.isEnabled = false
                warningLabel.isHidden = false
        }
        
        signButton.alpha = signButton.isEnabled ? 1.0 : 0.5
        textField.returnKeyType = signButton.isEnabled ? UIReturnKeyType.done : .next
        
        return true
    }
    
    // MARK: - textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done && signButton.isEnabled {
            print("login")
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

extension SignInViewController {
    func didTapEmailLogin() {
        guard let email = emailTextField.text, !email.isEmpty else {
            alert.showDetail("Missing Info", with: "Email can't be empty", height: 250, alignment: .center, for: self)
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            alert.showDetail("Missing Info", with: "Password can't be empty", height: 250, alignment: .center, for: self)
            return
        }
        
        showSpinner {
            // [START headless_email_auth]
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                // [START_EXCLUDE]
                strongSelf.hideSpinner {
                    if let error = error {
                        let authError = error as NSError
                        if (authError.code == AuthErrorCode.secondFactorRequired.rawValue) {
                            // The user is a multi-factor user. Second factor challenge is required.
                            let resolver = authError.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
                            var displayNameString = ""
                            for tmpFactorInfo in (resolver.hints) {
                                displayNameString += tmpFactorInfo.displayName ?? ""
                                displayNameString += " "
                            }
                            strongSelf.alert.showTextInputPrompt(withMessage: "Select factor to sign in\n\(displayNameString)", for: strongSelf ,completionBlock: { userPressedOK, displayName in
                                var selectedHint: PhoneMultiFactorInfo?
                                for tmpFactorInfo in resolver.hints {
                                    if (displayName == tmpFactorInfo.displayName) {
                                        selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                                    }
                                }
                                PhoneAuthProvider.provider().verifyPhoneNumber(with: selectedHint!, uiDelegate: nil, multiFactorSession: resolver.session) { verificationID, error in
                                    if error != nil {
                                        print("Multi factor start sign in failed. Error: \(error.debugDescription)")
                                    } else {
                                        strongSelf.alert.showTextInputPrompt(withMessage: "Verification code for \(selectedHint?.displayName ?? "")", for: strongSelf, completionBlock: { userPressedOK, verificationCode in
                                            let credential: PhoneAuthCredential? = PhoneAuthProvider.provider().credential(withVerificationID: verificationID!, verificationCode: verificationCode!)
                                            let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator.assertion(with: credential!)
                                            resolver.resolveSignIn(with: assertion!) { authResult, error in
                                                if error != nil {
                                                    print("Multi factor finanlize sign in failed. Error: \(error.debugDescription)")
                                                } else {
                                                    strongSelf.navigationController?.popViewController(animated: true)
                                                }
                                            }
                                        })
                                    }
                                }
                            })
                        } else {
                            strongSelf.alert.showDetail("Authentication Error", with: error.localizedDescription, for: self)
                            return
                        }
                    }
                    strongSelf.navigationController?.popViewController(animated: true)
                }
                // [END_EXCLUDE]
                if let authResult = authResult {
                    print("additional info", authResult.additionalUserInfo as Any)
                    print("credential", authResult.credential as Any)
                    print("user", authResult.user)
                    UserDefaults.standard.set(authResult.user.uid, forKey: "userId")
                }
            }
            // [END headless_email_auth]
        }
    }
}

extension SignInViewController {
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
                centerConstraint.isActive = true
                topConstraint.isActive = false
                UIView.animate(withDuration: 3, delay: 0, options: .curveEaseInOut) { [weak self] in
                    self?.view.layoutIfNeeded()
                } completion: { (_) in }
            } else {
                centerConstraint.isActive = false
                topConstraint.isActive = true
                UIView.animate(withDuration: 3, delay: 0, options: .curveEaseInOut) { [weak self] in
                    self?.view.layoutIfNeeded()
                } completion: { (_) in }
            }
        }
    }
}
