//
//  MessageCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit

class MessageCell: UITableViewCell {
    static let identifier = "MessageCell"
    
    final var stackView: UIStackView!
    final var contentLabel: UILabelPadding!
    final var dateLabel: UILabelPadding!
    final var constraint = [NSLayoutConstraint]()
    final let thumbImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
}

extension MessageCell {
    func configure() {
        contentLabel = UILabelPadding()
        contentLabel.numberOfLines = 0
        contentLabel.font = UIFont.systemFont(ofSize: 15)
        contentLabel.layer.cornerRadius = 15
        contentLabel.clipsToBounds = true
        contentLabel.adjustsFontForContentSizeCategory = true
        
        dateLabel = UILabelPadding()
        dateLabel.top = 0
        dateLabel.textAlignment = .right
        dateLabel.textColor = .lightGray
        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        dateLabel.adjustsFontForContentSizeCategory = true
        
        stackView = UIStackView(arrangedSubviews: [thumbImageView, contentLabel, dateLabel])
        stackView.spacing = 3
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
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
    
    func set(with message: Message, myId: String) {
        contentLabel.text = message.content
        dateLabel.text = message.sentAt
        
        NSLayoutConstraint.deactivate(constraint)
        constraint.removeAll()
        // message.id means the UID of the sender
        if message.id == myId {
            if let imageURL = message.imageURL {
//                let loadingIndicator = UIActivityIndicatorView()
                thumbImageView.image = UIImage(named: "placeholder")
                guard let url = URL(string: imageURL) else { return }
                downloadImageFrom(url) { [weak self] (image) in
                    DispatchQueue.main.async {
//                        self?.thumbImageView.bounds = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
                        self?.thumbImageView.image = image
                    }
                }
                thumbImageView.layer.cornerRadius = 8
                thumbImageView.translatesAutoresizingMaskIntoConstraints = false
                constraint.append(thumbImageView.heightAnchor.constraint(equalToConstant: 200))

            } else {
                contentLabel?.backgroundColor = UIColor(red: 102/255, green: 140/255, blue: 255/255, alpha: 1)
                contentLabel?.textColor = .white
                stackView.alignment = .trailing
            }
            
            constraint.append(contentsOf: [
                stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            ])
        } else {
            contentLabel?.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            contentLabel?.textColor = .black
            stackView.alignment = .leading
            
            constraint.append(contentsOf: [
                stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            ])
        }
        NSLayoutConstraint.activate(constraint)
        stackView.setNeedsLayout()
    }
    
    override func prepareForReuse() {
        thumbImageView.image = nil
    }
}
