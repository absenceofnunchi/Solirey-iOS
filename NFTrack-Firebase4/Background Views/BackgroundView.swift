//
//  BackgroundView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-11.
//
/*
 Abstract:
 RegisteredWalletViewController's lower container
 */

import UIKit

class BackgroundView: UIView {
    let startingColor = UIColor.systemGroupedBackground.cgColor

    init() {
        super.init(frame: .zero)
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BackgroundView {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: y / 10 * 2))
        path.addArc(tangent1End: CGPoint(x: x / 16, y: y / 10 * 1), tangent2End: CGPoint(x: x / 16 * 12, y: y / 10 * 1), radius: 80)
        path.addArc(tangent1End: CGPoint(x: x / 16 * 15, y: y / 10 * 1), tangent2End: CGPoint(x: x, y: y / 10 * 2), radius: 80)
        path.addLine(to: CGPoint(x: x, y: y / 10 * 2))
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: 0, y: y))
        path.closeSubpath()
        
        let bgShapeLayer = CAShapeLayer()
        bgShapeLayer.path = path
        bgShapeLayer.lineJoin = .round
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.colors = [startingColor, startingColor]
        gradientLayer.frame = self.bounds
        gradientLayer.mask = bgShapeLayer
        
        self.layer.addSublayer(gradientLayer)
    }
}
