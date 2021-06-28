//
//  StarRatingView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-27.
//

import UIKit

class StarRatingView: UIView {
    var starTintColor: UIColor! = UIColor(red: 255/255, green: 213/255, blue: 0, alpha: 1) {
        didSet {
            configure()
        }
    }
    var starHeight: CGFloat! = 50 {
        didSet {
            configuration = UIImage.SymbolConfiguration(pointSize: self.starHeight, weight: .medium, scale: .small)
            configure()
        }
    }
    var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    var rating: Int! = 0 {
        didSet {
            configure()
        }
    }
    var isEnabled: Bool! = false {
        didSet {
            configure()
        }
    }
    var numOfStars: ((Int)->Void)?
    let star: UIImage? = UIImage(systemName: "star")
    let starFill: UIImage? = UIImage(systemName: "star.fill")

    private var stackView: UIStackView!
    lazy var configuration = UIImage.SymbolConfiguration(pointSize: self.starHeight, weight: .medium, scale: .small)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StarRatingView {
    func configure() {
        subviews.forEach { (sv) in
            sv.removeFromSuperview()
        }
        
        self.stackView = UIStackView()
        self.stackView.axis = .horizontal
        self.stackView.distribution = .fillEqually
        self.addSubview(self.stackView)
        self.stackView.fill()
        
        var image: UIImage!
        var count = 0
        for i in 0..<5 {
            if count < rating {
                image = self.starFill
            } else {
                image = self.star
            }
            let configuredImage = image.withTintColor(self.starTintColor, renderingMode: .alwaysOriginal).withConfiguration(self.configuration)
            let button = UIButton.systemButton(with: configuredImage, target: self, action: #selector(self.buttonPressed(_:)))
            button.isEnabled = self.isEnabled
            button.tag = i
            stackView.addArrangedSubview(button)
            count += 1
        }
    }
    
    func createRating(rating: Int, completion: (([UIButton]) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let `self` = self else { return }
            var starArr = [UIButton]()
            defer {
                completion?(starArr)
            }
            var count = 0
            var image: UIImage!
            for i in 0..<5 {
                if count < rating {
                    image = self.starFill
                } else {
                    image = self.star
                }
                let configuredImage = image.withTintColor(self.starTintColor, renderingMode: .alwaysOriginal).withConfiguration(self.configuration)
                let button = UIButton.systemButton(with: configuredImage, target: self, action: #selector(self.buttonPressed(_:)))
                button.isEnabled = self.isEnabled
                button.tag = i
                starArr.append(button)
                count += 1
            }
        }
    }
    
    @objc func buttonPressed(_ sender: UIButton!) {
        if let numOfStars = self.numOfStars {
            numOfStars(sender.tag)
        }
        
        for case let av as UIButton in stackView.arrangedSubviews {
            if av.tag <= sender.tag {
                av.setImage(starFill?.withTintColor(starTintColor, renderingMode: .alwaysOriginal).withConfiguration(configuration), for: .normal)
            } else {
                av.setImage(star?.withTintColor(starTintColor, renderingMode: .alwaysOriginal).withConfiguration(configuration), for: .normal)
            }
        }
    }
}
