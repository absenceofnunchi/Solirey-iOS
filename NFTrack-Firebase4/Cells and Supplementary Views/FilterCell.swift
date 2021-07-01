//
//  FilterCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-30.
//

import UIKit

class FilterCell: UICollectionViewCell {
    static let reuseIdentifier = "FilterCell"
    var imageView = UIImageView()
    var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemnted")
    }
}

extension FilterCell {
    func configure() {
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(imageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = .gray
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.cornerRadius = 5
        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
//            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
//            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            imageView.heightAnchor.constraint(equalToConstant: 25),
//            imageView.widthAnchor.constraint(equalToConstant: 25),
            
//            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 5),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor),
        ])
    }
    
    func set(title: String) {
//        imageView.image = mainMenu.image
        titleLabel.text = title
    }
}
