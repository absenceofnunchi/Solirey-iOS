//
//  ProgressCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-06.
//

import UIKit

class ProgressCell: UITableViewCell {
    var titleLabel = UILabel()
    var dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension ProgressCell {
    func configure() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            
        ])
    }
    
    func set(post: Post) {
        titleLabel.text = post.title
        
        let date = post.date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        dateLabel.text = formattedDate
        
    }
}
