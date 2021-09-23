//
//  ChatCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit

class ChatCell<T>: ParentTableCell<T> {
    var stackView: UIStackView!
    var dateLabel = UILabelPadding()
    lazy var seenImageView: UIImageView! = {
        let config = UIImage.SymbolConfiguration(pointSize: 6, weight: .bold, scale: .medium)
        let checkmarkImage = UIImage(systemName: "checkmark")?.withConfiguration(config).withTintColor(.gray, renderingMode: .alwaysOriginal)
        let image = UIImageView(image: checkmarkImage)
        image.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(image)
        return image
    }()
    var cellConstraints = [NSLayoutConstraint]()
    // The user ID of the current chat user (sender) to distinguish the sender messages from the recipient messages
    var myUserId: String!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        seenImageView.alpha = 0
    }
}
