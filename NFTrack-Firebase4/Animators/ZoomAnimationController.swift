//
//  ZoomAnimationController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

import UIKit

class ZoomAnimationController : NSObject, UIViewControllerAnimatedTransitioning {
    var anim: UIViewImplicitlyAnimating?
    var tappedView: UIView!
    var tappedLocation: CGPoint!
    var window: UIWindow!
    
    init(tappedView: UIView, tappedLocation: CGPoint, window: UIWindow) {
        self.tappedView = tappedView
        self.tappedLocation = tappedLocation
        self.window = window
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if self.anim != nil {
            return self.anim!
        }
        
        let vc2 = transitionContext.viewController(forKey:.to)
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for:vc2!)
        let v2 = transitionContext.view(forKey:.to)!
        
        let widthRatio =  self.tappedView.frame.width / v2.frame.width
        let heightRatio = self.tappedView.frame.height / v2.frame.height
        let convertedLocation = self.tappedView.convert(self.tappedLocation, to: self.window)
        let center = (x: convertedLocation.x - v2.center.x, y: convertedLocation.y - v2.center.y)
        
        v2.frame = finalFrame
        v2.transform = CGAffineTransform(scaleX: widthRatio, y: heightRatio).concatenating(CGAffineTransform(translationX: center.x, y: center.y))
        containerView.addSubview(v2)
        v2.layer.cornerRadius = 20
        
        let anim = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            v2.transform = .identity
        }
        anim.addCompletion { _ in
            transitionContext.completeTransition(true)
        }
        
        self.anim = anim
        return anim
        
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let anim = self.interruptibleAnimator(using: transitionContext)
        anim.startAnimation()
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        self.anim = nil
    }
}
