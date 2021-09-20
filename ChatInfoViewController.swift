//
//  ChatInfoViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-18.
//

import UIKit

class ChatInfoViewController: UIViewController {
    var scrollView: UIScrollView!
    var seenTime: Date!
    var sentTime: Date!
    var messageLabel: UILabelPadding!
    var imageView: UIImageView!
    var seenTitleLabel: UILabel!
    var seenLabel: UILabel!
    var sentTimeTitleLabel: UILabel!
    var sentTimeLabel: UILabelPadding!
    var constraints = [NSLayoutConstraint]()

    init(
        seenTime: Date?,
        sentTime: Date,
        message: String? = nil,
        image: UIImage? = nil
    ) {
        super.init(nibName: nil, bundle: nil)
        self.seenTime = seenTime
        self.sentTime = sentTime
        
        if message != nil {
            self.messageLabel = UILabelPadding()
            self.messageLabel.text = message
        } else {
            imageView = UIImageView(image: image)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if scrollView != nil {
            var contentHeight: CGFloat!
            if messageLabel != nil {
                contentHeight = getContentHeight(messageLabel)
            } else {
                contentHeight = getContentHeight(imageView)
            }
             
            print("contentHeight", contentHeight as Any)
            scrollView.contentSize = CGSize(width: view.bounds.size.width, height: contentHeight)
        }
    }
    
    func getContentHeight(_ v: UIView) -> CGFloat {
        return v.bounds.size.height +
            seenTitleLabel.bounds.size.height +
            seenLabel.bounds.size.height +
            sentTimeTitleLabel.bounds.size.height +
            sentTimeLabel.bounds.size.height +
            200
    }
}

extension ChatInfoViewController {
    func configureUI() {
        view.backgroundColor = .white
        title = "Chat Information"
        
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.fill()
        
        seenTitleLabel = createTitleLabel(text: "Status")
        scrollView.addSubview(seenTitleLabel)
        
        if messageLabel != nil {
            messageLabel.numberOfLines = 0
            messageLabel.font = UIFont.systemFont(ofSize: 15)
            messageLabel.layer.cornerRadius = 11
            messageLabel.clipsToBounds = true
            messageLabel.lineBreakMode = .byWordWrapping
            messageLabel.sizeToFit()
            messageLabel.backgroundColor = UIColor(red: 102/255, green: 140/255, blue: 255/255, alpha: 1)
            messageLabel.textColor = .white
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(messageLabel)
            
            constraints.append(contentsOf: [
                messageLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 100),
                messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                messageLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),
                seenTitleLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 100)
            ])
        } else {
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(imageView)
            
            constraints.append(contentsOf: [
                imageView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 100),
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 200),
                imageView.heightAnchor.constraint(equalToConstant: 200),
                seenTitleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 100)
            ])
        }

        if seenTime != nil {
            if let sentTime = sentTime, let seenTime = seenTime {
                if seenTime > sentTime {
                    seenLabel = createLabel(text: "Seen")
                } else {
                    seenLabel = createLabel(text: "Not seen")
                }
            }
        } else {
            seenLabel = createLabel(text: "Not seen")
        }
        
        scrollView.addSubview(seenLabel)
        
        sentTimeTitleLabel = createTitleLabel(text: "Sent Time")
        scrollView.addSubview(sentTimeTitleLabel)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let formattedSentTime = formatter.string(from: sentTime)
        
        sentTimeLabel = createLabel(text: formattedSentTime)
        scrollView.addSubview(sentTimeLabel)
        
        constraints.append(contentsOf: [
            seenTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            seenTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            
            seenLabel.topAnchor.constraint(equalTo: seenTitleLabel.bottomAnchor),
            seenLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            seenLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            
            sentTimeTitleLabel.topAnchor.constraint(equalTo: seenLabel.bottomAnchor, constant: 50),
            sentTimeTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            sentTimeTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            
            sentTimeLabel.topAnchor.constraint(equalTo: sentTimeTitleLabel.bottomAnchor),
            sentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            sentTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
}
