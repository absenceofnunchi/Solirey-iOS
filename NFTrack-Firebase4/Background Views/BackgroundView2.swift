//
//  BackgroundView2.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-12.
//

/*
 Abstract: background for Send
 */

import UIKit

class BackgroundView2: UIView {
    
    init() {
        super.init(frame: .zero)
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BackgroundView2 {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width
        
        let path1 = UIBezierPath()
        UIColor(red: 112/255, green: 159/255, blue: 176/255, alpha: 1).setFill()
        
        path1.move(to: CGPoint(x: 0, y: y))
        path1.addLine(to: CGPoint(x: 0, y: y - 20))
        path1.addCurve(to: CGPoint(x: x, y: y - 80), controlPoint1: CGPoint(x: x * 2 / 3, y: y), controlPoint2: CGPoint(x: x * 5 / 6, y: y - 100 * 6 / 5))
        path1.addLine(to: CGPoint(x: x, y: y))
        path1.close()
        path1.fill(with: .overlay, alpha: 0.6)
        
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: 0, y: y))
        path2.addLine(to: CGPoint(x: 0, y: y - 65))
        path2.addCurve(to: CGPoint(x: x, y: y - 20), controlPoint1: CGPoint(x: x * 3 / 6, y: y - 100 * 5 / 5), controlPoint2: CGPoint(x: x * 2 / 3, y: y))
        path2.addLine(to: CGPoint(x: x, y: y))
        path2.close()
        path2.fill(with: .overlay, alpha: 0.6)
        
        let path3 = UIBezierPath()
        path3.move(to: CGPoint(x: 0, y: y))
        path3.addLine(to: CGPoint(x: 0, y: y - 40))
        path3.addCurve(to: CGPoint(x: x, y: y - 60), controlPoint1: CGPoint(x: x * 5 / 6, y: y - 100 * 2 / 5), controlPoint2: CGPoint(x: x * 2 / 3, y: y - 10))
        path3.addLine(to: CGPoint(x: x, y: y))
        path3.close()
        path3.fill(with: .overlay, alpha: 0.5)
    }
}
