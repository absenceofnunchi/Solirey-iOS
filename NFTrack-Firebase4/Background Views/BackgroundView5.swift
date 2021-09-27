//
//  BackgroundView5.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-25.
//

/*
 Abstract: Simple curved background in MainVC
 */

import UIKit.UIView
import UIKit.UIColor

class BackgroundView5: SpectrumView {
    var bgShapeLayer: CAShapeLayer!
    var gradientLayer: CAGradientLayer!
//    override var startingColor: UIColor! {
//        return UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
//    }
//    override var finishingColor: UIColor! {
//        return UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
//    }
    
//    required init(startingColor: UIColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1),
//                  finishingColor: UIColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)) {
//        super.init(startingColor: startingColor, finishingColor: finishingColor)
//    }
    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}

extension BackgroundView5 {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width
        
        let initialPath = CGMutablePath()
        initialPath.move(to: CGPoint(x: 0, y: 20))
        initialPath.addQuadCurve(to: CGPoint(x: x, y: 20), control: CGPoint(x: x / 2, y: y))
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
