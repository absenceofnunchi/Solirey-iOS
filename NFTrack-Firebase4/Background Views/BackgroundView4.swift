//
//  BackgroundView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-23.
//

/*
 Abstract: The S curve background used in ParetPostVC
 */

import UIKit.UIView
import UIKit.UIColor

class BackgroundView4: UIView {
    var bgShapeLayer: CAShapeLayer!
    var gradientLayer: CAGradientLayer!
    var colors: [CGColor]! {
        didSet {
            gradientLayer?.colors = colors
        }
    }
    
    init(colors: [CGColor] = [UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1).cgColor, UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1).cgColor]) {
        super.init(frame: .zero)
        self.isOpaque = false
        self.colors = colors
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BackgroundView4 {
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
