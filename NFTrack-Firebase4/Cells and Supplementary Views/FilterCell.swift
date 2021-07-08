//
//  FilterCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-30.
//

import UIKit

class FilterCell: UICollectionViewCell {
    static let reuseIdentifier = "FilterCell"
    var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemnted")
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                titleLabel.textColor = .white
                contentView.backgroundColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
            }else {
                titleLabel.textColor = .gray
                contentView.backgroundColor = .white
            }
        }
    }
}

extension FilterCell {
    func configure() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.cornerRadius = 5
        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor),
        ])
    }
    
    func set(title: String) {
        titleLabel.text = title
    }
}
