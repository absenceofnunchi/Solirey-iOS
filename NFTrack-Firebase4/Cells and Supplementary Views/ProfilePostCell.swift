//
//  ProfilePostCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-28.
//

import UIKit

class ProfilePostCell: ListCell {
    final override class var identifier: String {
        return "ProfilePostCell"
    }
    
    final override func configure(_ post: Post?) {
        guard let post = post else { return }
        
        guard let placeholderImage = UIImage(named: "placeholder") else {return}
        thumbImageView.image = placeholderImage
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 5
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(thumbImageView)
        
        titleLabel = UILabel()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.text = "Item Title"
        titleLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .bold)
        titleLabel.textColor = .lightGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(titleLabel)
        
        itemNameLabel = UILabel()
        itemNameLabel.text = post.title
        itemNameLabel.adjustsFontForContentSizeCategory = true
        itemNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(itemNameLabel)
        
        dateTitleLabel = UILabel()
        dateTitleLabel.adjustsFontForContentSizeCategory = true
        dateTitleLabel.text = "Date"
        dateTitleLabel.font = .rounded(ofSize: dateTitleLabel.font.pointSize, weight: .bold)
        dateTitleLabel.textColor = .lightGray
        dateTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(dateTitleLabel)
        
        dateLabel = UILabel()
        dateLabel.adjustsFontForContentSizeCategory = true
        let clockImage = UIImage(systemName:"calendar.circle")!.withTintColor(.green, renderingMode: .alwaysOriginal)
        let clock = NSTextAttachment(image:clockImage)
        let clockChar = NSAttributedString(attachment:clock)
        
        guard let date = post.date else { return }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let formattedDate = formatter.string(from: date)
        mas = NSMutableAttributedString(string: " \(formattedDate)", attributes: [.font: UIFont.systemFont(ofSize: 13)])
        mas.insert(clockChar, at:0)
        dateLabel.attributedText = mas
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(dateLabel)
        
        setConstraints()
    }
}
