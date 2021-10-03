//
//  CardCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-13.
//

/*
 Abstract:
 The tree of Card cell:
 1. ParentTableCell: Compatible with the asynchronous fetching of remote images using Operation and OperationQueue
    1. CardCell: A parent interface that shows the information regarding an item (without the progress meter)
        1. ImageCardCell: An interface with an image
            1. ImageProgressCard: An interface that shows an image and a progress meter
        2. NoImageCardCell: An interface without an image
            1. NoImageProgressCard: An interface that shows no image or a progress meter
 */

import UIKit

class CardCell: ParentTableCell<Post> {
    class override var identifier: String {
        return "CardCell"
    }
    
    var containerView: UIView!
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let dateLabel = UILabel()
    var documentId: String!
    
    override func configure(_ post: Post?) {
        guard let post = post else { return }
        
        containerView = UIView()
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
        
        NSLayoutConstraint.activate([
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
        ])
    }
}
