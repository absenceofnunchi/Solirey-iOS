//
//  ViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-04.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    var titleLabel: UILabel!
    var signButton: UIButton!
    var containerView: BlurEffectContainerView!
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    var warningLabel: UILabel!
    var textFields = [UITextField]()
    var additionalContainer: UIView!
    var additionalLabel: UILabel!
    var toggleButton: UIButton!
    let dissolveAnimator = DissolveTransitionAnimator()
    let alert = Alerts()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
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
        titleLabel.text = "Create Account"
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
        passwordTextField.placeholder = "Enter your password"
        passwordTextField.setLeftPaddingPoints(10)
        textFields.append(passwordTextField)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(passwordTextField)
        
        // email text field
        emailTextField = UITextField()
        emailTextField.delegate = self
        emailTextField.autocapitalizationType = .none
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
                containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.2),
            ])
        }
        
        NSLayoutConstraint.activate([
            // warning label
            warningLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // title label
            titleLabel.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 20),
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
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
            additionalLabel.widthAnchor.constraint(equalTo: additionalContainer.widthAnchor, multiplier: 0.8),
            additionalLabel.heightAnchor.constraint(equalToConstant: 40),
            
            toggleButton.centerYAnchor.constraint(equalTo: additionalContainer.centerYAnchor),
            toggleButton.trailingAnchor.constraint(equalTo: additionalContainer.trailingAnchor),
            toggleButton.widthAnchor.constraint(equalTo: additionalContainer.widthAnchor, multiplier: 0.2),
            toggleButton.heightAnchor.constraint(equalToConstant: 40)
        ])
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
                            let detailVC = DetailViewController(height: 250)
                            detailVC.titleString = "Sorry!"
                            detailVC.message = error.localizedDescription
                            detailVC.buttonAction = { [weak self]vc in
                                self?.dismiss(animated: true, completion: nil)
                            }
                            strongSelf.present(detailVC, animated: true, completion: nil)
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
                }
            }
            // [END headless_email_auth]
        }
    }
}
