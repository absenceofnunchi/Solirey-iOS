//
//  DetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit

enum DetailVCStyle {
    case regular, withCancelButton, withTextField
}

class DetailViewController: UIViewController {
    var titleString: String?
    var message: String?
    var titleLabel: UILabel!
    var messageLabel: UILabel!
    var height: CGFloat!
    var buttonAction: ((UIViewController)->Void)?
    var buttonPanel: UIView!
    var closeButton: UIButton!
    var cancelButton: UIButton!
    var textField: UITextField!
    private var detailVCStyle: DetailVCStyle = .regular

    private lazy var customTransitioningDelegate = TransitioningDelegate(height: height)
    
    init(height: CGFloat = 300, buttonTitle: String = "OK", titleAlignment: NSTextAlignment = .center, messageTextAlignment: NSTextAlignment = .center, detailVCStyle: DetailVCStyle = .regular) {
        super.init(nibName: nil, bundle: nil)

        self.height = height
        
        self.titleLabel = UILabel()
        self.titleLabel.textAlignment = titleAlignment
        
        self.messageLabel = UILabel()
        self.messageLabel.textAlignment = messageTextAlignment
        
        self.closeButton = UIButton()
        self.closeButton.setTitle(buttonTitle, for: .normal)
        
        self.detailVCStyle = detailVCStyle
        
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

private extension DetailViewController {
    func configure() {
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        transitioningDelegate = customTransitioningDelegate
    }
    
    func configureUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        titleLabel.textColor = .lightGray
        titleLabel.text = titleString
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        switch detailVCStyle {
            case .regular:
                messageLabel.text = message
                messageLabel.textColor = .gray
                messageLabel.numberOfLines = 0
                messageLabel.sizeToFit()
                messageLabel.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(messageLabel)
                
                closeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
                closeButton.backgroundColor = .darkGray
                closeButton.layer.cornerRadius = 10
                closeButton.setTitleColor(.white, for: .normal)
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(closeButton)
            case .withCancelButton:
                messageLabel.text = message
                messageLabel.textColor = .gray
                messageLabel.numberOfLines = 0
                messageLabel.sizeToFit()
                messageLabel.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(messageLabel)
                
                buttonPanel = UIView()
                buttonPanel.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(buttonPanel)
                
                closeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
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
            case .withTextField:
                textField = UITextField()
                textField.autocapitalizationType = .none
                textField.setLeftPaddingPoints(10)
                textField.layer.borderWidth = 0.7
                textField.layer.cornerRadius = 5
                textField.layer.borderColor = UIColor.lightGray.cgColor
                textField.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(textField)
                
                buttonPanel = UIView()
                buttonPanel.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(buttonPanel)
                
                closeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
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
        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
//        view.addGestureRecognizer(tap)
    }
    
    func setConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(contentsOf: [
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            titleLabel.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.3)
        ])
        
        switch detailVCStyle {
            case .regular:
                constraints.append(contentsOf: [
                    messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    
                    closeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
                    closeButton.heightAnchor.constraint(equalToConstant: 50),
                    closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    closeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
                ])
            case .withCancelButton:
                constraints.append(contentsOf: [
                    messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    
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
            case .withTextField:
                constraints.append(contentsOf: [
                    textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    textField.heightAnchor.constraint(equalToConstant: 50),
                    
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
        }
        
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
