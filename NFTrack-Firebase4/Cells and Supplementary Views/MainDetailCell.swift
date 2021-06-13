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
 */

import UIKit

class MainDetailCell: ParentTableCell {
    override class var identifier: String {
        return "MainDetailCell"
    }
    var titleLabel: UILabel!
    var descLabel: UILabel!
    var dateLabel: UILabel!
    
    override func configure(_ post: Post?) {
        guard let post = post else { return }
        let title = post.title
        let description = post.description
        
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 5
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbImageView)
        
        thumbImageView.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
        ])
        
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        descLabel = UILabel()
        descLabel.text = description
        descLabel.adjustsFontForContentSizeCategory = true
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)
        
        dateLabel = UILabel()
        let date = post.date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let dateString = formatter.string(from: date)
        dateLabel.text = dateString
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        if let images = post.images, images.count > 0 {
            NSLayoutConstraint.activate([
                thumbImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
                thumbImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                thumbImageView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
                thumbImageView.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
                
                titleLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
                titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
                titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
                titleLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
                
                descLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
                descLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
                descLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
                descLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
            ])
        } else {
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
                titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
                titleLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
                
                descLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                descLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
                descLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
                descLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
            ])
        }
        
        NSLayoutConstraint.activate([
            dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            dateLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            dateLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
        ])
    }
}
