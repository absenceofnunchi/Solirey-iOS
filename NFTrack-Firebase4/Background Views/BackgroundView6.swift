//
//  BackgroundView6.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-26.
//

/*
 Abstract: Simple curved background in MainVC
 */

import UIKit

class BackgroundView6: SpectrumView {
    var bgShapeLayer: CAShapeLayer!
    var gradientLayer: CAGradientLayer!

    
//    init(startingColor: CGColor, finishingColor: CGColor) {
//        super.init(startingColor: startingColor, finishingColor: finishingColor)
//    }
    
//    init(colors: [CGColor] = [UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1).cgColor,
//                              UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1).cgColor]) {
//        super.init(startingColor: )
//        self.isOpaque = false
//        self.colors = colors
//    }
    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}

extension BackgroundView6 {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width
        
        let initialPath = CGMutablePath()
        initialPath.move(to: CGPoint(x: 0, y: y))
        initialPath.addQuadCurve(to: CGPoint(x: x, y: 0), control: CGPoint(x: x / 2, y: y))
        initialPath.addLine(to: CGPoint(x: 0, y: 0))
        initialPath.addLine(to: .zero)
        initialPath.closeSubpath()
        
        bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = initialPath
        bgShapeLayer.lineJoin = .round
        
        gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.7, y: 0.8)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1.0)
        gradientLayer.colors = colors
        gradientLayer.frame = self.bounds
        gradientLayer.mask = bgShapeLayer
        
        self.layer.addSublayer(gradientLayer)
    }
}
