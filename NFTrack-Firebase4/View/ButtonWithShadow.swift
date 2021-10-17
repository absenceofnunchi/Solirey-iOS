//
//  ButtonWithShadow.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-16.
//

/*
 Abstract:
 Button with a dropshadow. Requires it to be embedded in a container view.
 */

import UIKit.UIButton

class ButtonWithShadow: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        updateLayerProperties()
    }
    
    override var intrinsicContentSize : CGSize {
        return super.intrinsicContentSize.withDelta(dw:25, dh: 20)
    }
    
    override func backgroundRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.backgroundRect(forBounds:bounds)
        if self.isHighlighted {
            result = result.insetBy(dx: 20, dy: 20)
        }
        return result
    }
    
    func updateLayerProperties() {
        layer.masksToBounds = true
        layer.cornerRadius = 12.0
        
        //superview is your optional embedding UIView
        if let superview = superview {
            superview.backgroundColor = UIColor.clear
            superview.layer.shadowColor = UIColor.darkGray.cgColor
            superview.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12.0).cgPath
            superview.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
            superview.layer.shadowOpacity = 1.0
            superview.layer.shadowRadius = 2
            superview.layer.masksToBounds = true
            superview.clipsToBounds = false
        }
    }
}

extension CGSize {
    func withDelta(dw:CGFloat, dh:CGFloat) -> CGSize {
        return CGSize(width: self.width + dw, height: self.height + dh)
    }
}
