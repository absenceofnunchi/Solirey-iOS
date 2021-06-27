//
//  ImagePreviewHeaderCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-25.
//

import UIKit

class ImagePreviewHeaderView: UICollectionReusableView {
    static let identifier = "ImagePreviewHeaderView"
    let titleLabel = UILabelPadding()
    let underlineView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension ImagePreviewHeaderView {
    func configure() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(underlineView)
        
        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -0.5),
            titleLabel.widthAnchor.constraint(equalTo: self.widthAnchor),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            
            underlineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            underlineView.widthAnchor.constraint(equalTo: self.widthAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
}
