//
//  CategoryCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

class CategoryCell: UICollectionViewCell {
    static var identifier = "CategoryCell"
    let imageView = UIImageView()
    var titleLabel: UILabel!
    var buttonAction: ((UICollectionViewCell)->Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
        shadowDecorate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemnted")
    }

}

extension CategoryCell {
    func configure() {
        self.backgroundColor = .clear
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.fill()
        
        let overlay = UIView()
        overlay.backgroundColor = .gray
        overlay.alpha = 0.7
        contentView.addSubview(overlay)
        overlay.fill()
        
        titleLabel = UILabel()
        titleLabel.sizeToFit()
        titleLabel.textColor = .white
        let f = UIFont.systemFont(ofSize: 20, weight: .bold).fontDescriptor.withDesign(.rounded)!
        let f2 = UIFont(descriptor: f, size: 0)
        titleLabel.font = f2
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }
    
    func shadowDecorate() {
        let radius: CGFloat = 10
        contentView.layer.cornerRadius = radius
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1.0)
        layer.shadowRadius = 2.0
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        layer.cornerRadius = radius
    }
    
    func set(mainMenu: MainMenu) {
        imageView.image = mainMenu.image
        titleLabel.text = mainMenu.title
    }
    
    @objc func buttonPressed() {
        if let buttonAction = self.buttonAction {
            buttonAction(self)
        }
    }
}
