//
//  ListCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

import UIKit

class ListCell: UITableViewCell {
    static var identifier = "ListCell"
    var titleLabel: UILabel!
    var dateLabel: UILabel!
    var mas: NSMutableAttributedString!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

}

extension ListCell {
    func configure() {
        titleLabel = UILabel()
        titleLabel.adjustsFontForContentSizeCategory = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(titleLabel)
        
        dateLabel = UILabel()
        dateLabel.adjustsFontForContentSizeCategory = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(dateLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            
            dateLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            dateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5)
        ])
    }
    
    func set(title: String, date: String) {
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        
        let mas = NSMutableAttributedString(string: " \(date)", attributes: [.font: UIFont.systemFont(ofSize: 13)])
        
        let clockImage = UIImage(systemName:"clock")!.withRenderingMode(.alwaysOriginal)
        let clock = NSTextAttachment(image:clockImage)
        let clockChar = NSAttributedString(attachment:clock)
        mas.insert(clockChar, at:0)
        dateLabel.attributedText = mas
    }
}
