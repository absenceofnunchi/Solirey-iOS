//
//  MyPresentationController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

import UIKit

class MyPresentationController : UIPresentationController {
    override var frameOfPresentedViewInContainerView : CGRect {
        return super.frameOfPresentedViewInContainerView.insetBy(dx: 0, dy: 0)
    }
}

// ==========================
extension MyPresentationController {
    override func presentationTransitionWillBegin() {
        let con = self.containerView!
        let shadow = UIView(frame:con.bounds)
        shadow.backgroundColor = UIColor(white:0, alpha:0.4)
        con.insertSubview(shadow, at: 0)
        // deal with what happens on rotation
        shadow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // can play tricks with the presenting view just like phone sheet
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
extension MyPresentationController {
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
extension MyPresentationController {
    override var presentedView : UIView? {
        let v = super.presentedView!
        v.layer.cornerRadius = 6
        v.layer.masksToBounds = true
        return v
    }
    //    override func shouldRemovePresentersView() -> Bool {
    //        return true
    //    }
}


// ===========================
extension MyPresentationController {
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
