//
//  MainDetailCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-23.
//

import UIKit
import FirebaseFirestore

class MainDetailCell: UITableViewCell {
    var thumbImageView = UIImageView()
    var loadingIndicator = UIActivityIndicatorView()
    var titleLabel: UILabel!
    var descLabel: UILabel!
    var dateLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

enum ImageFetchStatus {
    case fetched(UIImage?, Post)
    case pending
    case none(Post)
}

extension MainDetailCell {
    func updateAppearanceFor(_ status: ImageFetchStatus) {
        DispatchQueue.main.async { [unowned self] in
            switch status {
                case .fetched(let image, let post):
                    DispatchQueue.main.async {
                        self.displayImage(image, post)
                    }
                case .pending:
                    DispatchQueue.main.async {
                        self.displayImage(nil, nil)
                    }
                case .none(let post):
                    DispatchQueue.main.async {
                        self.noImage(post)
                    }
            }
        }
    }
    
//    func updateAppearanceFor(_ image: UIImage?) {
//        DispatchQueue.main.async { [unowned self] in
//            self.displayImage(image)
//        }
//    }
    
    private func displayImage(_ image: UIImage?, _ post: Post?) {
        guard let post = post else { return }
        let title = post.title
        let description = post.description
        
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbImageView)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadingIndicator)
        
        if let _image = image {
            thumbImageView.image = _image
            thumbImageView.contentMode = .scaleAspectFill
            thumbImageView.clipsToBounds = true
            thumbImageView.layer.cornerRadius = 5
            loadingIndicator.stopAnimating()
        } else {
            loadingIndicator.startAnimating()
            thumbImageView.image = .none
        }
        
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        descLabel = UILabel()
        descLabel.text = description
        descLabel.adjustsFontForContentSizeCategory = true
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)
        
        dateLabel = UILabel()
        let date = post.date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let dateString = formatter.string(from: date)
        dateLabel.text = dateString
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            thumbImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            thumbImageView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            thumbImageView.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
            
            loadingIndicator.topAnchor.constraint(equalTo: contentView.topAnchor),
            loadingIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            loadingIndicator.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            
            titleLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            titleLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
            
            descLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
            descLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            descLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            descLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
            
            dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            dateLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            dateLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.3),
        ])
    }
    
    private func noImage(_ post: Post) {
        loadingIndicator.stopAnimating()

        titleLabel = UILabel()
        titleLabel.text = post.title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        descLabel = UILabel()
        descLabel.text = post.description
        descLabel.adjustsFontForContentSizeCategory = true
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)
        
        dateLabel = UILabel()
        let date = post.date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let dateString = formatter.string(from: date)
        dateLabel.text = dateString
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            titleLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.5),

            descLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            descLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            dateLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.5),
            
            dateLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            dateLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            dateLabel.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.5),
        ])
    }
}
