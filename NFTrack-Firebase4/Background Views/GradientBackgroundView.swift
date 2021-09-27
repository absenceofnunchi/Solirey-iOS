//
//  GradientBackgroundView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-24.
//

/*
 Abstract:
 The gradient background as well as the patterns for views like the wallet balance or ReportVC
 */

import UIKit

class GradientBackgroundView: SpectrumView {
    required init(startingColor: UIColor = UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1),
                     finishingColor: UIColor = UIColor(red: 217/255, green: 158/255, blue: 172/255, alpha: 1)) {
        super.init(startingColor: startingColor, finishingColor: finishingColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func drawPattern (arcCenter: CGPoint, radius: CGFloat) {
        let path = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        UIColor.white.setFill()
        path.fill(with: .overlay, alpha: 0.1)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.drawLinearGradient(in: self.bounds, startingWith: startingColor.cgColor, finishingWith: finishingColor.cgColor)
        
        drawPattern(arcCenter: .zero, radius: self.bounds.height - 50)
        drawPattern(arcCenter: CGPoint(x: self.bounds.maxX, y: self.bounds.minY), radius: self.bounds.height / 3)
    }
}
