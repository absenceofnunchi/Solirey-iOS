//
//  ImageMessageCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-17.
//

import UIKit

class ImageMessageCell: ChatCell<Message> {
    final class override var identifier: String {
        return "ImageMessageCell"
    }
    
    final var buttonAction: (()->Void)?
    
    final override func configure(_ post: Message?) {
        guard let message = post,
              let myUserId = myUserId else { return }
        
        stackView = UIStackView(arrangedSubviews: [thumbImageView])
        stackView.spacing = 3
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        dateLabel.text = message.sentAt
        dateLabel.top = 0
        dateLabel.textColor = .lightGray
        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        dateLabel.sizeToFit()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        cellConstraints.append(contentsOf: [
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            stackView.bottomAnchor.constraint(equalTo: dateLabel.topAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            seenImageView.topAnchor.constraint(equalTo: stackView.bottomAnchor),
            seenImageView.heightAnchor.constraint(equalTo: dateLabel.heightAnchor, multiplier: 0.5),
            seenImageView.widthAnchor.constraint(equalTo: seenImageView.heightAnchor)
        ])
        
        if let _ = message.imageURL {
            thumbImageView.image = UIImage(named: "placeholder")
            thumbImageView.layer.cornerRadius = 8
            thumbImageView.clipsToBounds = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            thumbImageView.isUserInteractionEnabled = true
            thumbImageView.addGestureRecognizer(tap)
            thumbImageView.translatesAutoresizingMaskIntoConstraints = false
            
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            thumbImageView.addSubview(loadingIndicator)
            loadingIndicator.startAnimating()
            
            cellConstraints.append(contentsOf: [
                thumbImageView.heightAnchor.constraint(equalToConstant: 200),
                loadingIndicator.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
                loadingIndicator.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor)
            ])
            
            if message.id == myUserId {
                stackView.alignment = .trailing
                dateLabel.textAlignment = .right
                dateLabel.right = 0
                
                cellConstraints.append(contentsOf: [
                    stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                    dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                    seenImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -55),
                ])
            } else {
                stackView.alignment = .leading
                dateLabel.textAlignment = .left
                dateLabel.left = 0
                seenImageView.alpha = 0
                
                cellConstraints.append(contentsOf: [
                    stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                    dateLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
                ])
            }
        }
        
        NSLayoutConstraint.activate(cellConstraints)
    }
    
    @objc final func tapped() {
        if let buttonAction = buttonAction {
            buttonAction()
        }
    }
}
