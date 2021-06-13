//
//  AccountCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-05.
//

import UIKit

class AccountCell: UITableViewCell {
    static var identifier = "AccountCell"
    var iconView = UIImageView()
    var titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension AccountCell {
    func configure() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }
    
    func set(data: AccountMenu) {
        guard let image = UIImage(systemName: data.imageTitle) else { return }
        iconView.image = image.withTintColor(data.imageColor, renderingMode: .alwaysOriginal)
        titleLabel.text = data.titleString
    }
}
