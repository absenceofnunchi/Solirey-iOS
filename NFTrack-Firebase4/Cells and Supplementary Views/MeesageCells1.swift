////
////  MessageCell.swift
////  NFTrack-Firebase4
////
////  Created by J C on 2021-06-11.
////
//
//import UIKit
//
//class MessageCell: ParentTableCell<Message> {
//    override class var identifier: String {
//        return "MessageCell"
//    }
//    
//    //    final var stackView: UIStackView!
//    //    final var contentLabel: UILabelPadding!
//    //    final var dateLabel: UILabelPadding!
//    final let stackView = UIStackView()
//    final let contentLabel = UILabelPadding()
//    final let dateLabel = UILabelPadding()
//    final var constraint = [NSLayoutConstraint]()
//    final var myId: String!
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
//        setup()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("not implemented")
//    }
//    
//    open override var intrinsicContentSize: CGSize {
//        layoutIfNeeded()
//        return CGSize(width: UIView.noIntrinsicMetric, height: CGFloat.greatestFiniteMagnitude)
//    }
//    
//    final func setup() {
//        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
//        stackView.spacing = 3
//        stackView.axis = .vertical
//        stackView.distribution = .fill
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(stackView)
//        
//        thumbImageView.contentMode = .scaleAspectFill
//        thumbImageView.clipsToBounds = true
//        thumbImageView.layer.cornerRadius = 5
//        //        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.addArrangedSubview(thumbImageView)
//        
//        //        contentLabel = UILabelPadding()
//        contentLabel.numberOfLines = 0
//        contentLabel.font = UIFont.systemFont(ofSize: 15)
//        contentLabel.layer.cornerRadius = 15
//        contentLabel.clipsToBounds = true
//        contentLabel.adjustsFontForContentSizeCategory = true
//        stackView.addArrangedSubview(contentLabel)
//        
//        //        dateLabel = UILabelPadding()
//        dateLabel.top = 0
//        dateLabel.textAlignment = .right
//        dateLabel.textColor = .lightGray
//        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
//        dateLabel.adjustsFontForContentSizeCategory = true
//        stackView.addArrangedSubview(dateLabel)
//        
//        //        stackView = UIStackView(arrangedSubviews: [thumbImageView, contentLabel, dateLabel])
//        
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
//            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
//    }
//    
//    final override func configure(_ post: Message?) {
//        guard let post = post, let myId = myId else { return }
//        dateLabel.text = post.sentAt
//        
//        NSLayoutConstraint.deactivate(constraint)
//        constraint.removeAll()
//        if post.imageURL != nil {
//            let placeholderImage = UIImage(named: "placeholder")
//            thumbImageView.image = placeholderImage
//            //            stackView.addArrangedSubview(thumbImageView)
//            //            constraint.append(thumbImageView.heightAnchor.constraint(equalToConstant: 200))
//            if post.id == myId {
//                stackView.alignment = .trailing
//                constraint.append(stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor))
//            } else {
//                stackView.alignment = .leading
//                constraint.append(stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor))
//            }
//        } else {
//            contentLabel.text = post.content
//            //            stackView.addArrangedSubview(contentLabel)
//            
//            if post.id == myId {
//                contentLabel.backgroundColor = UIColor(red: 102/255, green: 140/255, blue: 255/255, alpha: 1)
//                contentLabel.textColor = .white
//                stackView.alignment = .trailing
//                
//                constraint.append(stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor))
//            } else {
//                contentLabel.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
//                contentLabel.textColor = .black
//                stackView.alignment = .leading
//                
//                constraint.append(stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor))
//            }
//        }
//        
//        NSLayoutConstraint.activate(constraint)
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        contentLabel.text = nil
//        dateLabel.text = nil
//    }
//}
