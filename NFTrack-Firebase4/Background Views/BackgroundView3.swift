//
//  BackgroundView3.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

/*
 Abstract: background for ReceiveVC
 */

import UIKit

class BackgroundView3: UIView {
    let startingColor = UIColor(red: 167/255, green: 197/255, blue: 235/255, alpha: 1).cgColor
    let finishingColor = UIColor(red: 102/255, green: 98/255, blue: 135/255, alpha: 1).cgColor
    
    init() {
        super.init(frame: .zero)
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BackgroundView3 {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width
        
        let initialPath = CGMutablePath()
        initialPath.move(to: CGPoint(x: 0, y: y / 10 * 8))
        initialPath.addArc(tangent1End: CGPoint(x: x / 3, y: y / 10 * 4), tangent2End: CGPoint(x: x / 3 * 2, y: y / 10 * 6), radius: 50)
        //        initialPath.addLine(to: CGPoint(x: x / 3 * 2, y: y / 10 * 6))
        initialPath.addArc(tangent1End: CGPoint(x: x / 3 * 2, y: y / 10 * 6), tangent2End: CGPoint(x: x, y: y / 10 * 2), radius: 50)
        //        initialPath.addLine(to: CGPoint(x: x, y: y / 6 * 4))
        initialPath.addLine(to: CGPoint(x: x, y: y / 10 * 2))
        initialPath.addLine(to: CGPoint(x: x, y: y))
        initialPath.addLine(to: CGPoint(x: 0, y: y))
        initialPath.closeSubpath()
        
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = initialPath
        bgShapeLayer.lineJoin = .round
        
        let secondPath = CGMutablePath()
        secondPath.move(to: CGPoint(x: 0, y: y / 10 * 9))
        secondPath.addArc(tangent1End: CGPoint(x: x / 5, y: y / 10 * 6), tangent2End: CGPoint(x: x / 4 * 3, y: y / 10 * 8), radius: 60)
        //        secondPath.addLine(to: CGPoint(x: x / 3 * 2, y: y / 10 * 6))
        secondPath.addArc(tangent1End: CGPoint(x: x / 4 * 3, y: y / 10 * 8), tangent2End: CGPoint(x: x, y: y / 10 * 1), radius: 40)
        //        secondPath.addLine(to: CGPoint(x: x, y: y / 6 * 4))
        secondPath.addLine(to: CGPoint(x: x, y: y / 10 * 1))
        secondPath.addLine(to: CGPoint(x: x, y: y))
        secondPath.addLine(to: CGPoint(x: 0, y: y))
        secondPath.closeSubpath()
        
        let bgShapeLayer2 = CAShapeLayer()
        bgShapeLayer2.path = secondPath
        bgShapeLayer2.lineJoin = .round
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: y / 3))
        
        path.addArc(tangent1End: path.currentPoint, tangent2End: CGPoint(x: x, y: y / 6 * 4), radius: 100)
        path.addArc(tangent1End: CGPoint(x: x, y: y / 6 * 4), tangent2End: CGPoint(x: x, y: y / 6 * 4), radius: 100)
        path.addArc(tangent1End: CGPoint(x: x / 3, y: y / 10 * 3), tangent2End: CGPoint(x: x / 3, y: y / 3 * 2), radius: 100)
        path.addArc(tangent1End: CGPoint(x: x / 3, y: y / 3 * 2), tangent2End: CGPoint(x: x, y: y / 6 * 4) , radius: 100)
        path.addLine(to: CGPoint(x: x, y: y / 6 * 4))
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: 0, y: y))
        path.addLine(to: .zero)
        path.closeSubpath()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.colors = [startingColor , UIColor.white.cgColor]
        gradientLayer.frame = self.bounds
        gradientLayer.mask = bgShapeLayer
        
        self.layer.addSublayer(gradientLayer)
        
        let gradientLayer2 = CAGradientLayer()
        gradientLayer2.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer2.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer2.colors = [finishingColor, startingColor]
        gradientLayer2.frame = self.bounds
        gradientLayer2.mask = bgShapeLayer2
        
        self.layer.addSublayer(gradientLayer2)
        
        //        let animation = CABasicAnimation(keyPath: "path")
        //        animation.fromValue = initialPath
        //        animation.toValue = path
        //        animation.duration = 1
        //        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        //        animation.fillMode = CAMediaTimingFillMode.both
        //        animation.isRemovedOnCompletion = false
        //
        //        bgShapeLayer.add(animation, forKey: animation.keyPath)
    }
}
