//
//  PreviewCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-01.
//

import UIKit

class PreviewCell: UICollectionViewCell {
    var closeButton: UIButton!
    var buttonAction: ((UICollectionViewCell)->Void)?

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemnted")
    }
    
    func configure() {
        
    }
    func setConstraints() {
        
    }
    
    @objc func buttonPressed() {
        if let buttonAction = self.buttonAction {
            buttonAction(self)
        }
    }
    
}
