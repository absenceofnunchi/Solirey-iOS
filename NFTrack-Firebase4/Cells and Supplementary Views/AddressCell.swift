//
//  AddressCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-27.
//

import UIKit

class AddressCell: UITableViewCell {
    static let reuseIdentifier = "address-cell-reuse-identifier"
    var mainLabel = UILabel()
    var detailLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension AddressCell {
    func configure() {
        mainLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        mainLabel.textColor = UIColor(red: 255/255, green: 102/255, blue: 102/255, alpha: 1)
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(mainLabel)
        
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = .gray
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(detailLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            mainLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10),
            mainLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainLabel.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            
            detailLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 10),
            detailLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
        ])
    }
}
