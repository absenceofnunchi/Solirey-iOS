//
//  ChatCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit

class ChatCell: UITableViewCell {
    static let identifier = "ChatCell"
    
    var stackView: UIStackView!
    var contentLabel: UILabelPadding!
    var dateLabel: UILabelPadding!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

}

extension ChatCell {
    func configure() {
        contentLabel = UILabelPadding()
        contentLabel.numberOfLines = 0
        contentLabel.font = UIFont.systemFont(ofSize: 18)
        contentLabel.layer.cornerRadius = 10
        contentLabel.clipsToBounds = true
        contentLabel.adjustsFontForContentSizeCategory = true
        
        dateLabel = UILabelPadding()
        dateLabel.top = 0
        dateLabel.textColor = .lightGray
        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        dateLabel.adjustsFontForContentSizeCategory = true
        
        stackView = UIStackView(arrangedSubviews: [contentLabel, dateLabel])
        stackView.spacing = 0
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func set(with message: Message, senderId: String) {
        contentLabel.text = message.content
        dateLabel.text = message.sentAt
        
        print("senderId", senderId)
        print("message.id", message.id)
        if message.id != senderId {
            contentLabel?.backgroundColor = UIColor(red: 102/255, green: 140/255, blue: 255/255, alpha: 1)
            contentLabel?.textColor = .white
            stackView.alignment = .trailing
            
            NSLayoutConstraint.activate([
                stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            ])
        } else {
            contentLabel?.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            stackView.alignment = .leading
            
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            ])
        }
    }
}