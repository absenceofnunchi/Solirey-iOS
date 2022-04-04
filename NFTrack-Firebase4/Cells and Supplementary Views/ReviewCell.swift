//
//  ReviewCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-22.
//

/*
 Abstract:
 One of the tabs in a ProfileDetailTableVC
 ProfileReviewListVC
 */

import UIKit

class ReviewCell: ParentTableCell<Review> {
    override class var identifier: String {
        return "ReviewCell"
    }
    
    var usernameLabel: UILabel!
    var reviewLabel: UILabelPadding!
    let IMAGE_HEIGHT: CGFloat = 35
    let STAR_HEIGHT: CGFloat = 20
    var stackView: UIStackView!
    var starRatingView: StarRatingView!
    
    override func configure(_ post: Review?) {
        guard let post = post else { return }
        
        guard let placeholderImage = UIImage(systemName: "person.crop.circle.fill") else { return }
        thumbImageView.image = placeholderImage.withTintColor(.blue, renderingMode: .alwaysOriginal)
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = IMAGE_HEIGHT / 2
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(thumbImageView)
        
        usernameLabel = UILabel()
        usernameLabel.adjustsFontForContentSizeCategory = true
        usernameLabel.text = post.reviewerDisplayName
        usernameLabel.font = .rounded(ofSize: usernameLabel.font.pointSize, weight: .bold)
        usernameLabel.textColor = .lightGray
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(usernameLabel)
        
        starRatingView = StarRatingView()
        starRatingView.rating = post.starRating
        starRatingView.starHeight = STAR_HEIGHT
        starRatingView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(starRatingView)
        
//        createRating(post: post) { [weak self] starArr in
//            DispatchQueue.main.async {
//                guard let strongSelf = self else { return }
//                strongSelf.stackView = UIStackView(arrangedSubviews: starArr.map{ UIImageView(image: $0)})
//                strongSelf.stackView.axis = .horizontal
//                strongSelf.stackView.distribution = .fillEqually
//                strongSelf.stackView.translatesAutoresizingMaskIntoConstraints = false
//                strongSelf.contentView.addSubview(strongSelf.stackView)
//                
//                NSLayoutConstraint.activate([
//                    strongSelf.stackView.topAnchor.constraint(equalTo: strongSelf.contentView.topAnchor, constant: 15),
//                    //            strongSelf.stackView.leadingAnchor.constraint(equalTo: strongSelf.contentView.leadingAnchor, constant: 10),
//                    //            strongSelf.stackView.widthAnchor.constraint(equalToConstant: STAR_HEIGHT * 5),
//                    //            strongSelf.stackView.widthAnchor.constraint(equalTo: strongSelf.contentView.widthAnchor, multiplier: 0.5),
//                    strongSelf.stackView.widthAnchor.constraint(equalToConstant: strongSelf.STAR_HEIGHT * 5),
//                    strongSelf.stackView.trailingAnchor.constraint(equalTo: strongSelf.contentView.trailingAnchor, constant: -10),
//                    strongSelf.stackView.heightAnchor.constraint(equalToConstant: strongSelf.STAR_HEIGHT),
//                ])
//            }
//        }
        
        reviewLabel = UILabelPadding()
        reviewLabel.text = post.review
        reviewLabel.numberOfLines = 0
        reviewLabel.adjustsFontForContentSizeCategory = true
        reviewLabel.textColor = .lightGray
        reviewLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(reviewLabel)
        
        setConstraints()
    }
    
//    func createRating(post: Review, completion: (([UIImage]) -> Void)? = nil) {
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            guard let strongSelf = self else { return }
//            var starArr = [UIImage]()
//            defer {
//                completion?(starArr)
//            }
//            let starTintColor = UIColor(red: 255/255, green: 213/255, blue: 0, alpha: 1)
//            var count: Int = 0
//            
//            for _ in 0..<5 {
//                var image: UIImage!
//                if count < post.starRating {
//                    image = UIImage(systemName: "star.fill")
//                } else {
//                    image = UIImage(systemName: "star")
//                }
//                
//                let configuration = UIImage.SymbolConfiguration(pointSize: strongSelf.STAR_HEIGHT, weight: .bold, scale: .small)
//                let configuredImage = image.withTintColor(starTintColor, renderingMode: .alwaysOriginal).withConfiguration(configuration)
//                starArr.append(configuredImage)
//                count += 1
//            }
//        }
//    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            thumbImageView.heightAnchor.constraint(equalToConstant: IMAGE_HEIGHT),
            thumbImageView.widthAnchor.constraint(equalToConstant: IMAGE_HEIGHT),
            
            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            usernameLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 10),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            usernameLabel.heightAnchor.constraint(equalToConstant: IMAGE_HEIGHT + 5),
            
            starRatingView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            starRatingView.widthAnchor.constraint(equalToConstant: STAR_HEIGHT * 5),
            starRatingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            starRatingView.heightAnchor.constraint(equalToConstant: STAR_HEIGHT),
            
//            reviewLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 5),
            reviewLabel.topAnchor.constraint(equalTo: thumbImageView.bottomAnchor, constant: 5),
            reviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            reviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            reviewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
        usernameLabel.text = nil
        reviewLabel.text = nil
    }
}
