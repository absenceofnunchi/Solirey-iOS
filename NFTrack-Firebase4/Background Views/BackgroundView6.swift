//
//  BackgroundView6.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-26.
//

import Foundation
import UIKit.UIView

class BackgroundView6: UIView {
    let startingColor = UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1).cgColor
    let finishingColor = UIColor(red: 102/255, green: 98/255, blue: 135/255, alpha: 1).cgColor
    
    init() {
        super.init(frame: .zero)
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BackgroundView6 {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width
        
        let initialPath = CGMutablePath()
        initialPath.move(to: CGPoint(x: 0, y: y / 10 * 7))
        initialPath.addArc(tangent1End: CGPoint(x: x / 11, y: y / 10 * 8.5), tangent2End: CGPoint(x: x / 8 * 8.5, y: y / 10 * 8.5), radius: 80)
        initialPath.addArc(tangent1End: CGPoint(x: x / 8 * 8.5, y: y / 10 * 8.5), tangent2End: CGPoint(x: x, y: y), radius: 50)
        initialPath.addLine(to: CGPoint(x: x, y: y))
        initialPath.addLine(to: CGPoint(x: x, y: 0))
        initialPath.addLine(to: .zero)
        initialPath.closeSubpath()
        
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = initialPath
        bgShapeLayer.lineJoin = .round
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        //        gradientLayer.colors = [startingColor , UIColor.white.cgColor]
        gradientLayer.colors = [startingColor, startingColor]
        gradientLayer.frame = self.bounds
        gradientLayer.mask = bgShapeLayer
        
        self.layer.addSublayer(gradientLayer)
    }
}
