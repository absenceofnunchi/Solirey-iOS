//
//  MainDetailCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-23.
//

/*
 Abstract:
 Parent cell with images that needs asynchrous fetching.
 Used by MainDetailCell and ProgressCell
 
 for chat list
 */

import UIKit

class ChatListCell: ParentTableCell<ChatListModel> {
    override class var identifier: String {
        return "ChatListCell"
    }
    private var titleLabel: UILabel!
    private var descLabel: UILabel!
    private var dateLabel: UILabel!
    private var timeLabel: UILabel!
    var userId: String!
    private var displayName: String!
    private var photoURL: String!
    
    final override func configure(_ post: ChatListModel?) {
        guard let post = post else { return }
        
        if post.sellerId != userId {
            displayName = post.sellerDisplayName
            photoURL = post.sellerPhotoURL
        } else {
            displayName = post.buyerDisplayName
            photoURL = post.buyerPhotoURL
        }
        
        guard let image = UIImage(systemName: "person.crop.circle.fill") else {
            return
        }
        let configuration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular, scale: .medium)
        let profileImage = image.withTintColor(.orange, renderingMode: .alwaysOriginal).withConfiguration(configuration)
        thumbImageView.image = profileImage
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 5
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbImageView)
        
        if photoURL != "NA" {
            thumbImageView.addSubview(loadingIndicator)
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            loadingIndicator.startAnimating()
            
            NSLayoutConstraint.activate([
                loadingIndicator.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor),
                loadingIndicator.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
            ])
        }
        
        titleLabel = UILabel()
        titleLabel.text = displayName
        titleLabel.textColor = .gray
        titleLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        descLabel = UILabel()
        descLabel.text = post.latestMessage
        descLabel.textColor = .gray
        descLabel.adjustsFontForContentSizeCategory = true
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: post.date)
        
        dateLabel = UILabel()
        dateLabel.text = formattedDate
        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = .lightGray
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        formatter.dateFormat = "HH:mm"
        let formattedTime = formatter.string(from: post.date)
        
        timeLabel = UILabel()
        timeLabel.text = ""
        timeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        timeLabel.textColor = .lightGray
        timeLabel.textAlignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            thumbImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            thumbImageView.widthAnchor.constraint(equalToConstant: 70),
            thumbImageView.heightAnchor.constraint(equalToConstant: 70),
            
            titleLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            titleLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.5),
            
            descLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
            descLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            descLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            descLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.5),
            
            dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            dateLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            dateLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
            
            timeLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            timeLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            timeLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
        ])
    }
}
