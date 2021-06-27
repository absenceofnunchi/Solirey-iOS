//
//  CardCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-13.
//

import UIKit

class CardCell: ParentTableCell<Post> {
    class override var identifier: String {
        return "ProgressCell"
    }
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let dateLabel = UILabel()
    let descLabel = TopAlignedLabel()
    var descContainer: UIView!
    var myConstraints = [NSLayoutConstraint]()
    var documentId: String!
    
    override func configure(_ post: Post?) {
        guard let post = post else { return }
        
        // for updating the save button feature
        documentId = post.documentId
        
        containerView.layer.borderWidth = 0.3
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.cornerRadius = 8
        contentView.addSubview(containerView)
        containerView.fill(inset: 20)
        
        titleLabel.text = post.title
        titleLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .bold)
        titleLabel.textColor = .gray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        priceLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .medium)
        priceLabel.textColor = .gray
        priceLabel.text = "Price: \(post.price!) ETH"
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(priceLabel)
        
        dateLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .medium)
        dateLabel.textColor = .gray
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: post.date)
        dateLabel.text = formattedDate
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dateLabel)
        
        myConstraints += [
            titleLabel.heightAnchor.constraint(equalToConstant: 20),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            
            priceLabel.heightAnchor.constraint(equalToConstant: 20),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            priceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            priceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            dateLabel.heightAnchor.constraint(equalToConstant: 20),
            dateLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 0),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ]
        
        if let files = post.files, files.count > 0 {
            thumbImageView.image = UIImage(named: "placeholder")
            thumbImageView.contentMode = .scaleAspectFill
            thumbImageView.clipsToBounds = true
//            thumbImageView.layer.cornerRadius = 5
            thumbImageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(thumbImageView)
            
            thumbImageView.addSubview(loadingIndicator)
            loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
            loadingIndicator.startAnimating()
            
            myConstraints += [
                thumbImageView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
                thumbImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
                thumbImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
                thumbImageView.heightAnchor.constraint(equalToConstant: 200),
                
                loadingIndicator.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor),
                loadingIndicator.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
            ]
        } else {
            descContainer = UIView()
            descContainer.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(descContainer)
            
            descLabel.text = post.description
            descLabel.numberOfLines = 0
            descLabel.lineBreakMode = .byTruncatingTail
            descLabel.layer.borderWidth = 0.3
            descLabel.layer.borderColor = UIColor.lightGray.cgColor
            descLabel.layer.cornerRadius = 8
            descLabel.translatesAutoresizingMaskIntoConstraints = false
            descContainer.addSubview(descLabel)
            
            myConstraints += [
                descContainer.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
                descContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
                descContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
                descContainer.heightAnchor.constraint(equalToConstant: 200),
            ]
            
            descLabel.fill(inset: 20)
        }
        
        NSLayoutConstraint.activate(myConstraints)
    }
}
