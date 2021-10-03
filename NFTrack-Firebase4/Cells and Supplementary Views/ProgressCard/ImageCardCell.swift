//
//  ImageCardCell.swift
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

class ImageCardCell: CardCell {
    class override var identifier: String {
        return "ImageCardCell"
    }

    override func configure(_ post: Post?) {
        super.configure(post)
        
        thumbImageView.image = UIImage(named: "placeholder")
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        //            thumbImageView.layer.cornerRadius = 5
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(thumbImageView)
        
        thumbImageView.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        
        NSLayoutConstraint.activate([
            thumbImageView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            thumbImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            thumbImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            thumbImageView.heightAnchor.constraint(equalToConstant: 200),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
        ])
    }
}
