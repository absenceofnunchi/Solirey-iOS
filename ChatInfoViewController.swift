//
//  ChatInfoViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-18.
//

import UIKit

class ChatInfoViewController: UIViewController {
    private var scrollView: UIScrollView!
    private var seenTime: Date!
    private var sentTime: Date!
    private var messageLabel: UILabelPadding!
    private var imageView: UIImageView!
    private var seenTitleLabel: UILabel!
    private var seenLabel: UILabel!
    private var sentTimeTitleLabel: UILabel!
    private var sentTimeLabel: UILabelPadding!
    private var constraints = [NSLayoutConstraint]()
    private var isOnline: Bool!
    
    init(
        seenTime: Date?,
        sentTime: Date,
        message: String? = nil,
        image: UIImage? = nil,
        isOnline: Bool = false
    ) {
        super.init(nibName: nil, bundle: nil)
        self.seenTime = seenTime
        self.sentTime = sentTime
        self.isOnline = isOnline
        
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
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    final override func viewDidLayoutSubviews() {
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
    
    private func getContentHeight(_ v: UIView) -> CGFloat {
        return v.bounds.size.height +
            seenTitleLabel.bounds.size.height +
            seenLabel.bounds.size.height +
            sentTimeTitleLabel.bounds.size.height +
            sentTimeLabel.bounds.size.height +
            200
    }
}

private extension ChatInfoViewController {
    private func configureUI() {
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

        // If the recipient is currently online, all the messages have been seen.
        // If not, check the last seen time:
        //      1. If the last seen time doesn't exist, then the messages have not been seen.
        //      2. The last seen time exists:
        //          A. If the last seen time is greater (later) then the sent time of the messages, they have been read.
        //          B. If the sent time of the messages is greater (later) then the last seen time of the recipient, then the messages have not been read.
        if isOnline {
            seenLabel = createLabel(text: "Seen")
        } else {
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
        }
        
        scrollView.addSubview(seenLabel)
        
        sentTimeTitleLabel = createTitleLabel(text: "Sent Time")
        scrollView.addSubview(sentTimeTitleLabel)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let formattedSentTime = formatter.string(from: sentTime)
        
        sentTimeLabel = createLabel(text: formattedSentTime)
        sentTimeLabel.numberOfLines = 0
        sentTimeLabel.sizeToFit()
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
