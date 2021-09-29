//
//  PendingIndicatorView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-16.
//

/*
 Abstract:
 Simple indicator that shows the activity indicator view and a label that says "Pending" when an activity is in progress.
 It's used in AuctionDetailViewController to to be shown when a socket delegate captures certain topics.
 The user is informed that there is a certain event that is being mined and later to be displayed on the interface, such as the highest bid.
 It's also used in ListDetailViewController to show the pending status when either the buyer confirms the purchase or the sender transfers the token.
 
 The user can tap to see the modal that explains what it means to be pending.
 */

import UIKit

class PendingIndicatorView: UIView {
    private var activityIndicatorView: UIActivityIndicatorView!
    var buttonAction: ((UIView)->Void)?
    private var pendingLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PendingIndicatorView {
    func configure() {
        self.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 204/255, alpha: 1)
        self.layer.cornerRadius = 8
        let pendingContainerTap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        self.addGestureRecognizer(pendingContainerTap)
        
        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.startAnimating()
        activityIndicatorView.color = UIColor(red: 0/255, green: 155/255, blue: 0/255, alpha: 1)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activityIndicatorView)
        
        pendingLabel = UILabel()
        pendingLabel.text = "Pending"
        pendingLabel.font = .rounded(ofSize: pendingLabel.font.pointSize, weight: .light)
        pendingLabel.textColor = .lightGray
        pendingLabel.translatesAutoresizingMaskIntoConstraints = false
        pendingLabel.font = UIFont.systemFont(ofSize: 12)
        pendingLabel.textColor = UIColor(red: 0/255, green: 155/255, blue: 0/204, alpha: 1)
        self.addSubview(pendingLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            activityIndicatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            activityIndicatorView.heightAnchor.constraint(equalToConstant: 30),
            activityIndicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            activityIndicatorView.widthAnchor.constraint(equalTo: activityIndicatorView.heightAnchor),
            
            pendingLabel.leadingAnchor.constraint(equalTo: activityIndicatorView.trailingAnchor, constant: 5),
            pendingLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            pendingLabel.heightAnchor.constraint(equalTo: self.heightAnchor),
        ])
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        if let buttonAction = buttonAction {
            buttonAction(self)
        }
    }
}
