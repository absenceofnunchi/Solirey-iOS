//
//  DetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit

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
    var isTextField = false

    private lazy var customTransitioningDelegate = TransitioningDelegate(height: height)
    
    init(height: CGFloat = 300, buttonTitle: String = "OK", messageTextAlignment: NSTextAlignment = .center, isTextField: Bool = false) {
        super.init(nibName: nil, bundle: nil)

        self.height = height
        
        self.messageLabel = UILabel()
        self.messageLabel.textAlignment = messageTextAlignment
        
        self.closeButton = UIButton()
        self.closeButton.setTitle(buttonTitle, for: .normal)
        
        self.isTextField = isTextField
        
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
        
        titleLabel = UILabel()
        titleLabel.textColor = .lightGray
        titleLabel.text = titleString
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        if self.isTextField {
            textField = UITextField()
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
            closeButton.backgroundColor = .darkGray
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
        } else {
            messageLabel.text = message
            messageLabel.textColor = .gray
            messageLabel.numberOfLines = 0
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(messageLabel)
            
            closeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
            closeButton.backgroundColor = .darkGray
            closeButton.layer.cornerRadius = 10
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(closeButton)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        view.addGestureRecognizer(tap)
    }
    
    func setConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(contentsOf: [
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        if isTextField {
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
                
                cancelButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
                cancelButton.heightAnchor.constraint(equalToConstant: 50),
                cancelButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            ])
        } else {
            constraints.append(contentsOf: [
                messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                messageLabel.heightAnchor.constraint(equalToConstant: 50),
                
                closeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
                closeButton.heightAnchor.constraint(equalToConstant: 50),
                closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                closeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
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

class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var height: CGFloat!
    
    init(height: CGFloat = 300) {
        self.height = height
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting, height: height)
    }
}

class PresentationController: UIPresentationController {
    var height: CGFloat!
    let dimmingView: UIView = {
        let dimmingView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        return dimmingView
    }()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = presentingViewController.view.bounds
        let size = CGSize(width: bounds.size.width * 0.8, height: height)
        let origin = CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2)
        return CGRect(origin: origin, size: size)
    }
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, height: CGFloat) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        self.height = height
        
        presentedView?.autoresizingMask = [
            .flexibleTopMargin,
            .flexibleBottomMargin,
            .flexibleLeftMargin,
            .flexibleRightMargin
        ]
        
        presentedView?.translatesAutoresizingMaskIntoConstraints = true
    }
}

extension PresentationController {
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        let superview = presentingViewController.view!
        superview.addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            dimmingView.topAnchor.constraint(equalTo: superview.topAnchor)
        ])
        
        dimmingView.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.9
        }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }
}
