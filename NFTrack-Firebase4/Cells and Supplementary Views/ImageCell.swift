//
//  TextCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-08.
//

import UIKit

class ImageCell: PreviewCell {
    let imageView = UIImageView()
    static let reuseIdentifier = "image-cell-reuse-identifier"
    
    override func configure() {
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        self.addSubview(imageView)
        imageView.fill(inset: 8)
        
        let image = UIImage(systemName: "multiply.circle.fill")!.withTintColor(.red, renderingMode: .alwaysOriginal)
        closeButton = UIButton.systemButton(with: image, target: self, action: #selector(buttonPressed))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(closeButton)
    }

    override func setConstraints() {
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: -5),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 5),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25),
        ])
    }
}
