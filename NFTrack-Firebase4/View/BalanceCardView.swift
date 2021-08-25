//
//  BalanceCardView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-12.
//

import UIKit

class BalanceCardView: GradientBackgroundView {
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var balanceLabel: UILabel!
    var walletAddressLabel: UILabel!
    var expiryLabel: UILabel!
    
    init() {
        super.init(frame: .zero)
        configure()
        setConstraints()
    }
    
    init(titleString: String, subtitleString: String) {
        super.init(frame: .zero)
        
        self.titleLabel?.text = titleString
        self.subtitleLabel?.text = subtitleString
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK:- configure
extension BalanceCardView {
    func configure() {
        self.isOpaque = false
        self.backgroundColor = startingColor
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 15, leading: 30, bottom: 15, trailing: 20)
        
        // title
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFontItalic(size: 20, fontWeight: .heavy)
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
        self.addSubview(titleLabel)
        
        // subtitle
        subtitleLabel = UILabel()
        subtitleLabel.textColor = .white
        subtitleLabel.sizeToFit()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        self.addSubview(subtitleLabel)
        
        // balanceLabel
        balanceLabel = UILabel()
        balanceLabel.textColor = .white
        balanceLabel.sizeToFit()
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(balanceLabel)
        
        // card number label
        walletAddressLabel = UILabel()
        walletAddressLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        walletAddressLabel.textColor = .white
        walletAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(walletAddressLabel)
        
        // expiry label
        expiryLabel = UILabel()
        expiryLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        expiryLabel.textColor = .white
        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(expiryLabel)
    }
}

// MARK:- set constraints
extension BalanceCardView {
    @objc func setConstraints() {
        NSLayoutConstraint.activate([
            // title label
            titleLabel.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            titleLabel.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1/5),
            
            // subtitle label
            subtitleLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            subtitleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -30),
            
            // balance Label
            balanceLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 5),
            balanceLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            balanceLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            balanceLabel.heightAnchor.constraint(equalToConstant: 50),
            
            // card number label
            walletAddressLabel.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            walletAddressLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            walletAddressLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            
            // expiry label
            expiryLabel.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            expiryLabel.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor)
        ])
    }
}
