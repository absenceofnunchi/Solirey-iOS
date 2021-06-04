//
//  TransitioningDelegate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-31.
//

import UIKit

class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var height: CGFloat!
    
    init(height: CGFloat = 300) {
        self.height = height
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting, height: height)
    }
}
