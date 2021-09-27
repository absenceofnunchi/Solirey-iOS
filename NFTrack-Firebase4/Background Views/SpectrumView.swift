//
//  File.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-27.
//

import UIKit

class SpectrumView: UIView {
    private(set) var startingColor: UIColor! 
    private(set) var finishingColor: UIColor!
    var colors: [CGColor]! {
        return [startingColor.cgColor, finishingColor.cgColor]
    }
  
    required init(startingColor: UIColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1),
                  finishingColor: UIColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)) {
        super.init(frame: .zero)
        self.isOpaque = false
        self.startingColor = startingColor
        self.finishingColor = finishingColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
