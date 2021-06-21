//
//  ListCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit

class ListCell: ParentTableCell<Post> {
    override class var identifier: String {
        return "ListCell"
    }
    var titleLabel: UILabel!
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
        titleLabel.text = post.title
        titleLabel.adjustsFontForContentSizeCategory = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(titleLabel)
        
        dateLabel = UILabel()
        dateLabel.adjustsFontForContentSizeCategory = false
        let clockImage = UIImage(systemName:"calendar.circle")!.withRenderingMode(.alwaysOriginal)
        let clock = NSTextAttachment(image:clockImage)
        let clockChar = NSAttributedString(attachment:clock)
        mas = NSMutableAttributedString(string: " \(post.confirmReceivedHash ?? "N/A")", attributes: [.font: UIFont.systemFont(ofSize: 13)])
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
            
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            
            dateLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5)
        ])
    }
}
