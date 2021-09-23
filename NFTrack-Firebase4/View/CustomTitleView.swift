//
//  CustomTitleView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-21.
//

import Foundation
import UIKit.UIView
import UIKit.UIImageView
import UIKit.UIButton

class CustomTitleView: UIView {
    var buttonAction: (() -> Void)?
    var displayName: String!
    var onlineImageView: UIImageView!
    let configuration = UIImage.SymbolConfiguration(pointSize: 9, weight: .light, scale: .small)
    var isOnline: Bool = false {
        didSet {
            var color: UIColor!
            if isOnline {
                color = .green
            } else {
                color = .red
            }
            onlineImageView?.image = UIImage(systemName: imageString)?
                .withConfiguration(configuration)
                .withTintColor(color, renderingMode: .alwaysOriginal)
        }
    }
    var imageString: String!
    var button: UIButton!
    
    var titleLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    } 
    
    convenience init(displayName: String, imageString: String) {
        self.init()
        self.displayName = displayName
        self.imageString = imageString
        configure()
        setContraints()
    }
    
    func configure() {
        guard let image = UIImage(systemName: imageString)?
                .withConfiguration(configuration)
                .withTintColor(.red, renderingMode: .alwaysOriginal) else { return }
        onlineImageView = UIImageView(image: image)
        onlineImageView.translatesAutoresizingMaskIntoConstraints = false
        onlineImageView.backgroundColor = .yellow
        self.addSubview(onlineImageView)
        
//        button =  UIButton()
//        button.setTitle(displayName, for: .normal)
//        button.setTitleColor(.gray, for: .normal)
//        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        self.addSubview(button)
        
        titleLabel = UILabel()
        titleLabel.text = displayName
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
    }
    
    func setContraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            titleLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
            
            onlineImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            onlineImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -5),
        ])
    }
    
    @objc func buttonPressed() {
        print("pressed1")
        if let buttonAction = buttonAction {
            print("pressed2")
            buttonAction()
        }
    }
}
