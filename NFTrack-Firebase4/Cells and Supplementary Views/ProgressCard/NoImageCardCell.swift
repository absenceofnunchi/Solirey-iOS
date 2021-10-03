//
//  NoImageCardCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-02.
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

class NoImageCardCell: CardCell {
    class override var identifier: String {
        return "NoImageCardCell"
    }
    
    let descLabel = TopAlignedLabel()
    var descContainer: UIView!
    
    override func configure(_ post: Post?) {
        super.configure(post)
        guard let post = post else { return }
        
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
        
        NSLayoutConstraint.activate([
            descContainer.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            descContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            descContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            descContainer.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        descLabel.fill(inset: 20)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        descContainer = nil
    }
}
