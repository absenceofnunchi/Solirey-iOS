//
//  StandardAlertViewController.swift
//  Test
//
//  Created by J C on 2021-07-17.
//

/*
 Abstract:
 A single page view controller for AlertViewController which is the container page view controller
 Able to fine-grain control things like the height and the button availability
 Largely composed of three parts:
    1. Title
    2. Body
    3. Buttons
    
 The body consists of a subtitle and a text view which can either be used as a label or for a user input.
 The default values are geared towards displaying a general alert with a title (height: 50), a text view as a label (height: 150) and one button to dismiss (height: 50).
 The container alert view controller should be around height = 350 which is the default height. Anything under 300 will cover the title label. Needs to be fixed.
 When using the text view as an input source, use height = 50.
 The body's subtitles and the text views can be multiple.
 */

import UIKit


enum AlertStyle {
    case oneButton, withCancelButton, noButton
}

struct StandardAlertContent {
    var index: Int = 0
    let titleString: String
    let body: [String: String]
    var isEditable: Bool = false
    var fieldViewHeight: CGFloat = 150
    var buttonTitle: String = "OK"
    var titleAlignment: NSTextAlignment = .center
    var messageTextAlignment: NSTextAlignment = .center
    var alertStyle: AlertStyle = .oneButton
    var buttonAction: ((StandardAlertViewController)->Void)?
}

class StandardAlertViewController: UIViewController {
    var index: Int!
    private var titleString: String?
    // subtitle : the actual message
    private var body: [String: String]!
    private var titleLabel: UILabel!
    private var titleAlignment: NSTextAlignment!
    private var messageTextAlignment: NSTextAlignment!
    private var bodyStackView: UIStackView!
    private var isEditable: Bool!
    private var fieldViewHeight: CGFloat!
    var buttonAction: ((StandardAlertViewController)->Void)?
    private var buttonPanel: UIView!
    private var buttonTitle: String!
    private var closeButton: UIButton!
    private var cancelButton: UIButton!
    private var alertStyle: AlertStyle!
    private var constraints: [NSLayoutConstraint]!
    private var bodyArrangedSubviews: [UIView]!
    weak var delegate: DataFetchDelegate?
    
    init(content: StandardAlertContent) {
        super.init(nibName: nil, bundle: nil)
        
        self.index = content.index
        self.titleString = content.titleString
        self.body = content.body
        self.isEditable = content.isEditable
        self.fieldViewHeight = content.fieldViewHeight
        self.buttonTitle = content.buttonTitle
        self.alertStyle = content.alertStyle
        self.titleAlignment = content.titleAlignment
        self.messageTextAlignment = content.messageTextAlignment
        self.buttonAction = content.buttonAction
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        setConstraints()
    }
}

extension StandardAlertViewController: UITextFieldDelegate {
    func configure() {
        view.backgroundColor = .white
        
        titleLabel = UILabel()
        titleLabel.textColor = .gray
        titleLabel.text = titleString
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.rounded(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = titleAlignment
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        bodyArrangedSubviews = body.map { (key, value) -> UIView in
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            
            let subtitleLabel = UILabel()
            subtitleLabel.text = key
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(subtitleLabel)
            
            let messageTextView = UITextView()
            messageTextView.delegate = self
            messageTextView.text = value
            messageTextView.textColor = .lightGray
            messageTextView.textAlignment = messageTextAlignment
            messageTextView.isEditable = isEditable
            messageTextView.isUserInteractionEnabled = true
            messageTextView.layer.borderWidth = 0.7
            messageTextView.layer.borderColor = isEditable ? UIColor.gray.withAlphaComponent(0.5).cgColor: UIColor.white.cgColor
            messageTextView.layer.cornerRadius = 5
            messageTextView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            messageTextView.clipsToBounds = true
            messageTextView.showsVerticalScrollIndicator = true
            messageTextView.isScrollEnabled = true
            messageTextView.font = UIFont.rounded(ofSize: 20, weight: .medium)
            messageTextView.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(messageTextView)
            
            NSLayoutConstraint.activate([
                v.heightAnchor.constraint(equalToConstant: fieldViewHeight + 20 + 5),
                
                subtitleLabel.topAnchor.constraint(equalTo: v.topAnchor),
                subtitleLabel.widthAnchor.constraint(equalTo: v.widthAnchor),
                // eliminate the height of the subtitle if no subtitle exists
                subtitleLabel.heightAnchor.constraint(equalToConstant: key == "" ? 0 : 20),
                
                messageTextView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 5),
                messageTextView.widthAnchor.constraint(equalTo: v.widthAnchor),
                messageTextView.heightAnchor.constraint(equalToConstant: fieldViewHeight)
            ])
  
            return v
        }
        
        bodyStackView = UIStackView(arrangedSubviews: bodyArrangedSubviews)
        bodyStackView.axis = .vertical
        bodyStackView.spacing = 10
        bodyStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bodyStackView)
        
        buttonPanel = UIView()
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonPanel)
        
        closeButton = UIButton()
        closeButton.alpha = alertStyle == .noButton ? 0 : 1
        closeButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        closeButton.backgroundColor = .black
        closeButton.layer.cornerRadius = 10
        closeButton.tag = 1
        closeButton.setTitle(buttonTitle ?? "OK", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(closeButton)
        
        cancelButton = UIButton()
        cancelButton.backgroundColor = .red
        cancelButton.layer.cornerRadius = 10
        cancelButton.tag = 2
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(cancelButton)
    }
    
    func setConstraints() {
        var buttonConstraints = [NSLayoutConstraint]()
        if alertStyle == .withCancelButton {
            buttonConstraints.append(contentsOf: [
                closeButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
                closeButton.heightAnchor.constraint(equalToConstant: 50),
                closeButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
                closeButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
                
                cancelButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
                cancelButton.heightAnchor.constraint(equalToConstant: 50),
                cancelButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
                cancelButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
            ])
        } else {
            cancelButton.alpha = 0
            cancelButton.isEnabled = false
            
            buttonConstraints.append(contentsOf: [
                closeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
                closeButton.heightAnchor.constraint(equalToConstant: 50),
                closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                closeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            ])
        }
        
        // nested array only because the constraints that are contingent can be nested in here chronogically in one big block
        let constraints: [[NSLayoutConstraint]] = [
            [
                titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
                titleLabel.heightAnchor.constraint(equalToConstant: 50),
             
                bodyStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                bodyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                bodyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
             
                buttonPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                buttonPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                buttonPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                buttonPanel.heightAnchor.constraint(equalToConstant: 50)
            ],
            
            buttonConstraints
        ]
        let flattened = constraints.reduce ([], + )
        NSLayoutConstraint.activate(flattened)
    }
    
    @objc func buttonHandler(_ sender: UIButton) {
        switch sender.tag {
            case 1:
                if let buttonAction = self.buttonAction {
                    buttonAction(self)
                }
            case 2:
                self.dismiss(animated: true, completion: nil)
            default:
                break
        }
    }
    
    func fetchInputFromTextFields() -> [String: String]? {
        var inputFromTextFields = [String: String]()
        for case let arrangedSubview in bodyArrangedSubviews {
            var key, value: String!
            for case let subSubview in arrangedSubview.subviews {
                switch subSubview {
                    case is UILabel:
                        guard let text = (subSubview as! UILabel).text else { return nil }
                        key = text
                    case is UITextView:
                        value = (subSubview as! UITextView).text ?? ""
                    default:
                        break
                }
            }
            
            inputFromTextFields.updateValue(value, forKey: key)
        }
        return inputFromTextFields
    }
}

extension StandardAlertViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let inputData = fetchInputFromTextFields() {
            delegate?.didGetData(inputData)
        }
    }
}
