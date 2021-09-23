//
//  MessageCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit

class MessageCell: ChatCell<Message> {
    final class override var identifier: String {
        return "MessageCell"
    }
    
    final var messageLabel = UILabelPadding()
    
    final override func configure(_ post: Message?) {
        guard let message = post,
              let myUserId = myUserId else { return }

        messageLabel.text = message.content
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        messageLabel.layer.cornerRadius = 11
        messageLabel.clipsToBounds = true
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.sizeToFit()

        stackView = UIStackView(arrangedSubviews: [messageLabel])
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
        
//        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .light, scale: .small)
//        let checkmarkImage = UIImage(systemName: "checkmark")?.withConfiguration(config).withTintColor(.lightGray, renderingMode: .alwaysOriginal)
//        seenImageView.image = checkmarkImage
//        seenImageView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(seenImageView)
        
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
            if message.id == myUserId {
                
            } else {
                
            }
        } else {
            if message.id == myUserId {
                messageLabel.backgroundColor = UIColor(red: 102/255, green: 140/255, blue: 255/255, alpha: 1)
                messageLabel.textColor = .white
                stackView.alignment = .trailing
                dateLabel.textAlignment = .right
                dateLabel.right = 0

                cellConstraints.append(contentsOf: [
                    stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                    dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                    seenImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -55),
                ])
            } else {
                messageLabel.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
                messageLabel.textColor = .black
                stackView.alignment = .leading
                dateLabel.textAlignment = .left
                dateLabel.left = 0
                seenImageView.alpha = 0
                
                cellConstraints.append(contentsOf: [
                    stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                    dateLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                ])
            }
        }

        NSLayoutConstraint.activate(cellConstraints)
//        stackView.layoutIfNeeded()
//        stackView.setNeedsLayout()
    }
}

extension MessageCell {
    final override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
    }
}
