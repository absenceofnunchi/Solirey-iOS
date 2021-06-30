//
//  TextCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-08.
//

import UIKit

class ImageCell: UICollectionViewCell {
    let imageView = UIImageView()
    var closeButton: UIButton!
    static let reuseIdentifier = "image-cell-reuse-identifier"
    var buttonAction: ((UICollectionViewCell)->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemnted")
    }
}

extension ImageCell {
    func configure() {
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        imageView.fill(inset: 4)
        
        let image = UIImage(systemName: "multiply.circle.fill")!.withTintColor(.red, renderingMode: .alwaysOriginal)
        closeButton = UIButton.systemButton(with: image, target: self, action: #selector(buttonPressed))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(closeButton)
    }
    
    @objc func buttonPressed() {
        if let buttonAction = self.buttonAction {
            buttonAction(self)
        }
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: -5),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 5),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25),
        ])
    }
}
