//
//  PartialPresentationController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-19.
//

import UIKit

class PartialPresentationController : UIPresentationController {
    override var shouldPresentInFullscreen: Bool {
        return false
    }
    override var frameOfPresentedViewInContainerView : CGRect {
        return CGRect(x: 0, y: super.frameOfPresentedViewInContainerView.height/2, width: super.frameOfPresentedViewInContainerView.width, height: super.frameOfPresentedViewInContainerView.height)
    }
}

// ==========================
extension PartialPresentationController {
    override func presentationTransitionWillBegin() {
        let con = self.containerView!
        let shadow = UIView(frame:con.bounds)
        shadow.backgroundColor = UIColor(white:0, alpha:0.4)
        con.insertSubview(shadow, at: 0)
        shadow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let tc = self.presentingViewController.transitionCoordinator {
            tc.animate { _ in
                if self.traitCollection.userInterfaceIdiom == .phone {
                    //                    self.presentingViewController.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                }
            }
        }
    }
}

// ==========================
extension PartialPresentationController {
    override func dismissalTransitionWillBegin() {
        let con = self.containerView!
        let shadow = con.subviews[0]
        if let tc = self.presentedViewController.transitionCoordinator {
            tc.animate { _ in
                shadow.alpha = 0
                self.presentingViewController.view.transform = .identity
            }
        }
    }
}


// ===========================
extension PartialPresentationController {
    override var presentedView : UIView? {
        let v = super.presentedView!
        v.layer.cornerRadius = 30
        v.layer.masksToBounds = true
        return v
    }
}


// ===========================
extension PartialPresentationController {
    override func presentationTransitionDidEnd(_ completed: Bool) {
        let vc = self.presentingViewController
        let v = vc.view
        v?.tintAdjustmentMode = .dimmed
    }
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        let vc = self.presentingViewController
        let v = vc.view
        v?.tintAdjustmentMode = .automatic
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
    
    func presentationControllerWillDismiss(_ pc: UIPresentationController) {
        if let tc = pc.presentedViewController.transitionCoordinator {
            tc.animate(alongsideTransition: {_ in
                for v in pc.presentedViewController.view.subviews {
                    print("v", v)
                    v.alpha = 0
                }
            })
        }
    }
}
