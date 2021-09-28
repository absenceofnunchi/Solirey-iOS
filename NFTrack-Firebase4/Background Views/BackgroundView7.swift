//
//  BackgroundView7.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-27.
//

import UIKit

class BackgroundView7: SpectrumView {
    var bgShapeLayer: CAShapeLayer!
    var gradientLayer: CAGradientLayer!
}

extension BackgroundView7 {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width
        
        let initialPath = CGMutablePath()
        initialPath.move(to: CGPoint(x: 0, y: 0))
        initialPath.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x / 2, y: y))
        initialPath.addLine(to: CGPoint(x: x, y: 0))
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
