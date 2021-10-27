//
//  SendViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

import UIKit
import web3swift

class SendViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
    private var destinationLabel: UILabel!
    private var destinationTextField: UITextField!
    private var amountLabel: UILabel!
    private var amountTextField: UITextField!
    private var scanButton: UIButton!
    private var sendButton: UIButton!
    private var gasPriceLabel: UILabel!
    private var maxButton: UIButton!
    private var backgroundView: BackgroundView2!
    
    private let transactionService = TransactionService()
    private let localDatabase = LocalDatabase()
    private let alert = Alerts()
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCloseButton()
        setCloseButtonConstraints()
        configureUI()
        setConstraints()
        hideKeyboardWhenTappedAround()
    }
    
    // MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let totalCount = 6
        let duration = 1.0 / Double(totalCount)
        
        let animation = UIViewPropertyAnimator(duration: 0.7, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.destinationLabel.alpha = 1
                    self?.destinationLabel.transform = .identity
                    
                    self?.destinationTextField.alpha = 1
                    self?.destinationTextField.transform = .identity
                    
                    self?.scanButton.alpha = 1
                    self?.scanButton.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.amountLabel.alpha = 1
                    self?.amountLabel.transform = .identity
                    
                    self?.amountTextField.alpha = 1
                    self?.amountTextField.transform = .identity
                    
                    self?.maxButton.alpha = 1
                    self?.maxButton.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 3 / Double(totalCount), relativeDuration: duration) {
                    self?.sendButton.alpha = 1
                    self?.sendButton.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 4 / Double(totalCount), relativeDuration: duration) {
                    self?.gasPriceLabel.alpha = 1
                    self?.gasPriceLabel.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 5 / Double(totalCount), relativeDuration: duration) {
                    self?.backgroundView.alpha = 1
                    self?.backgroundView.transform = .identity
                }
            })
        }
        
        animation.startAnimation()
    }
}

extension SendViewController {
    
    // MARK: - configureUI
    func configureUI() {
        view.backgroundColor = .white
        
        backgroundView = BackgroundView2()
        backgroundView.transform = CGAffineTransform(translationX: 0, y: 40)
        backgroundView.alpha = 0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.setNeedsDisplay()
        view.addSubview(backgroundView)
        
        destinationLabel = createTitleLabel(title: "To", v: self.view)
        destinationLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        destinationLabel.alpha = 0
        
        destinationTextField = UITextField()
        destinationTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        destinationTextField.alpha = 0
        destinationTextField.textColor = .darkGray
        destinationTextField.placeholder = "public address (0x)"
        destinationTextField.setLeftPaddingPoints(10)
        BorderStyle.customShadowBorder(for: destinationTextField)
        destinationTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(destinationTextField)
        
        guard let scanButtonImage = UIImage(systemName: "qrcode.viewfinder") else { return }
        scanButton = UIButton.systemButton(with: scanButtonImage.withTintColor(.white, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonHandler(_:)))
        scanButton.backgroundColor = UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1)
        scanButton.transform = CGAffineTransform(translationX: 0, y: 40)
        scanButton.layer.cornerRadius = 7
        scanButton.alpha = 0
        scanButton.tag = 2
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanButton)
        
        amountLabel = createTitleLabel(title: "Amount", v: self.view)
        amountLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        amountLabel.alpha = 0
        
        amountTextField = UITextField()
        amountTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        amountTextField.alpha = 0
        amountTextField.textColor = .darkGray
        amountTextField.placeholder = "ETH"
        amountTextField.setLeftPaddingPoints(10)
        amountTextField.keyboardType = UIKeyboardType.decimalPad
        BorderStyle.customShadowBorder(for: amountTextField)
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(amountTextField)
        
        maxButton = UIButton()
        maxButton.setTitle("MAX", for: .normal)
        maxButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        maxButton.translatesAutoresizingMaskIntoConstraints = false
        maxButton.tag = 3
        maxButton.alpha = 0
        maxButton.layer.cornerRadius = 7
        maxButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        maxButton.transform = CGAffineTransform(translationX: 0, y: 40)
        maxButton.backgroundColor = UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1)
        view.addSubview(maxButton)
        
        sendButton = UIButton()
        sendButton.transform = CGAffineTransform(translationX: 0, y: 40)
        sendButton.alpha = 0
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        sendButton.tag = 4
        sendButton.backgroundColor = UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1)
        sendButton.layer.cornerRadius = 7
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        gasPriceLabel = UILabel()
        gasPriceLabel.sizeToFit()
        gasPriceLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        gasPriceLabel.alpha = 0
        gasPriceLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        gasPriceLabel.textColor = .gray
        gasPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gasPriceLabel)
        transactionService.requestGasPrice { (gasPrice) in
            guard let gasPrice = gasPrice else { return }
            self.gasPriceLabel.text = "Current avg. gas price: \(gasPrice) GWEI"
        }
    }
    
    // MARK: - setConstraints
    func setConstraints() {
        NSLayoutConstraint.activate([
            // background view
            backgroundView.widthAnchor.constraint(equalTo: view.widthAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/2),
            
            // destination label
            destinationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            destinationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 150),
            destinationLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            
            // destination text field
            destinationTextField.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 20),
            destinationTextField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            destinationTextField.heightAnchor.constraint(equalToConstant: 50),
            destinationTextField.trailingAnchor.constraint(equalTo: scanButton.leadingAnchor, constant: -10),
            
            // scan button
            scanButton.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 20),
            scanButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.widthAnchor.constraint(equalTo: scanButton.heightAnchor, multiplier: 1),
            
            // amount label
            amountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            amountLabel.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 40),
            amountLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            
            // amount text field
            amountTextField.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 20),
            amountTextField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            amountTextField.heightAnchor.constraint(equalToConstant: 50),
            amountTextField.trailingAnchor.constraint(equalTo: maxButton.leadingAnchor, constant: -10),
            
            // max button
            maxButton.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 20),
            maxButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
            maxButton.heightAnchor.constraint(equalToConstant: 50),
            maxButton.widthAnchor.constraint(equalTo: maxButton.heightAnchor, multiplier: 1),
            
            // send button
            sendButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 50),
            sendButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            // gas price label
            gasPriceLabel.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 10),
            gasPriceLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            gasPriceLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    
    // MARK: - createTitleLabel
    func createTitleLabel(title: String, v: UIView) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        return label
    }
}

extension SendViewController: UITextFieldDelegate {
    // MARK: - buttonHandler
    @objc func buttonHandler(_ sender: UIButton!) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 2:
                let scannerVC = ScannerViewController()
                scannerVC.delegate = self
                scannerVC.modalPresentationStyle = .fullScreen
                self.present(scannerVC, animated: true, completion: nil)
            case 3:
                guard let address = Web3swiftService.currentAddress else {
                    print("invalid address")
                    return
                }
                
                DispatchQueue.global().async { [weak self] in
                    do {
                        let balance = try Web3swiftService.web3instance.eth.getBalance(address: address)
                        if let balanceString = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth, decimals: 17) {
                            DispatchQueue.main.async {
                                self?.amountTextField.text = self?.transactionService.stripZeros(balanceString)
                            }
                        }
                    } catch {
                        print("get balance error", error.localizedDescription)
                    }
                }
            case 4:
                transactionService.prepareTransactionForSending(destinationAddressString: destinationTextField.text, amountString: amountTextField.text) { [weak self](transaction, error) in
                    if let error = error {
                        switch error {
                            case .invalidDestinationAddress:
                                self?.alert.showDetail("Error", with: "Invalid destination address", for: self)
                            case .invalidAmountFormat:
                                self?.alert.showDetail("Error", with: "Invalid amount format", for: self)
                            case .emptyDestinationAddress:
                                self?.alert.showDetail("Error", with: "Destination address cannot be empty", for: self)
                            case .emptyAmount:
                                self?.alert.showDetail("Error", with: "Amount cannot be empty", for: self)
                            case .zeroAmount:
                                self?.alert.showDetail("Error", with: "Amount cannot be zero or below", for: self)
                            case .contractLoadingError:
                                self?.alert.showDetail("Error", with: "There was an error loading a contract. Please try again.", for: self)
                            case .createTransactionIssue:
                                self?.alert.showDetail("Error", with: "There was an error creating your transaction. Please try again.", for: self)
                            case .insufficientFund:
                                self?.alert.showDetail("Error", with: "Insufficient fund", for: self)
                            case .retrievingCurrentAddressError:
                                self?.alert.showDetail("Error", with: "There was an error getting your account address.", for: self)
                            default:
                                self?.alert.showDetail("Error", with: "Please try again.", for: self)
                        }
                    }
                    
                    if let transaction = transaction {
                        let content = [
                            StandardAlertContent(
                                titleString: AlertModalDictionary.passwordSubtitle,
                                body: ["": ""],
                                isEditable: true,
                                messageTextAlignment: .left,
                                alertStyle: .withCancelButton
                            )
                        ]
                        
                        let alertVC = AlertViewController(standardAlertContent: content)
                        alertVC.action = { [weak self] (modal, mainVC) in
                            guard  let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                                   !password.isEmpty else {
                                self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                                return
                            }
                        }
                        self?.present(alertVC, animated: true, completion: nil)
     
                        
//                        self?.alert.withPassword(title: "Send Ether", delegate: self!, controller: self!) { (password) in
//                            DispatchQueue.global().async {
//                                do {
//                                    let result = try transaction.send(password: password, transactionOptions: nil)
//                                    self?.localDatabase.saveTransactionDetail(walletAddress: Web3swiftService.currentAddressString!, txHash: result.hash, date: Date(), txType: .etherSent)
//
//                                    DispatchQueue.main.async {
//                                        let finalAC = UIAlertController(title: "Success!", message: "Your ether has been sent.", preferredStyle: .alert)
//                                        finalAC.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
//                                            self?.dismiss(animated: true, completion: nil)
//                                        }))
//                                        self?.present(finalAC, animated: true, completion: nil)
//                                    }
//                                } catch Web3Error.nodeError(let desc) {
//                                    if let index = desc.firstIndex(of: ":") {
//                                        let newIndex = desc.index(after: index)
//                                        let newStr = desc[newIndex...]
//                                        DispatchQueue.main.async {
//                                            self?.alert.show("Alert", with: String(newStr), for: self)
//                                        }
//                                    }
//                                } catch {
//                                    DispatchQueue.main.async {
//                                        self?.alert.show("Error", with: "Sorry, there was an error sending your ether. Please try again.", for: self)
//                                    }
//                                }
//                            }
//                        }
                    }
                }
            default:
                break
        }
    }
}

extension SendViewController: ScannerDelegate {
    
    // MARK: - scannerDidOutput
    func scannerDidOutput(code: String) {
        destinationTextField.text = code
    }
}
