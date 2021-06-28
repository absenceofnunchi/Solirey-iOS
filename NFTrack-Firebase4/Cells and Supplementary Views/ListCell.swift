//
//  ListCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//
/*
 Abstract:
 used in ReviewPost, pending reviews
 */

import UIKit

class ListCell: ParentTableCell<Post> {
    override class var identifier: String {
        return "ListCell"
    }
    var titleLabel: UILabel!
    var itemNameLabel: UILabel!
    var dateTitleLabel: UILabel!
    var dateLabel: UILabel!
    var mas: NSMutableAttributedString!

    override func configure(_ post: Post?) {
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
        dateTitleLabel.text = "Finalized Date"
        dateTitleLabel.font = .rounded(ofSize: dateTitleLabel.font.pointSize, weight: .bold)
        dateTitleLabel.textColor = .lightGray
        dateTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(dateTitleLabel)
        
        dateLabel = UILabel()
        dateLabel.adjustsFontForContentSizeCategory = true
        let clockImage = UIImage(systemName:"calendar.circle")!.withRenderingMode(.alwaysOriginal)
        let clock = NSTextAttachment(image:clockImage)
        let clockChar = NSAttributedString(attachment:clock)
        
        guard let confirmReceivedDate = post.confirmReceivedDate else { return }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let formattedDate = formatter.string(from: confirmReceivedDate)
        mas = NSMutableAttributedString(string: " \(formattedDate)", attributes: [.font: UIFont.systemFont(ofSize: 13)])
        mas.insert(clockChar, at:0)
        dateLabel.attributedText = mas
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(dateLabel)
        
        setConstraints()
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            thumbImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            thumbImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            thumbImageView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            itemNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            itemNameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            itemNameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            itemNameLabel.heightAnchor.constraint(equalToConstant: 20),

            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            dateLabel.heightAnchor.constraint(equalToConstant: 20),
            
            dateTitleLabel.bottomAnchor.constraint(equalTo: dateLabel.topAnchor),
            dateTitleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dateTitleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            dateTitleLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
        itemNameLabel.text = nil
        dateLabel.text = nil
    }
}
