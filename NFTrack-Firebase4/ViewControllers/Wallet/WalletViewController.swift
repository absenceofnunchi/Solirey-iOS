//
//  WalletViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

import UIKit

class WalletViewController: UIViewController {
    let localDatabase = LocalDatabase()
    var newPageVC: UIViewController!
    var oldPageVC: UIViewController!
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        if let _ = localDatabase.getWallet() {
            let vc = RegisteredWalletViewController()
            vc.delegate = self
            newPageVC = vc
            oldPageVC = vc
        } else {
            let vc = UnregisteredWalletViewController()
            newPageVC = vc
            oldPageVC = vc
        }
        addChild(newPageVC)
        view.addSubview(newPageVC.view)
        newPageVC.view.frame = view.bounds
        newPageVC.didMove(toParent: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WalletViewController {
    func configureChildVC() {
        addChild(newPageVC)
        oldPageVC.willMove(toParent: nil)
        oldPageVC.beginAppearanceTransition(false, animated: true)
        newPageVC.beginAppearanceTransition(true, animated: true)
        
        UIView.transition(from: oldPageVC.view, to: newPageVC.view, duration: 0.1, options: .transitionCrossDissolve) { (_) in
            self.oldPageVC.endAppearanceTransition()
            self.newPageVC.endAppearanceTransition()
            self.newPageVC.didMove(toParent: self)
            self.oldPageVC.removeFromParent()
            self.oldPageVC = nil
            self.oldPageVC = self.newPageVC
            self.newPageVC.view.translatesAutoresizingMaskIntoConstraints = false
            self.oldPageVC.view.fill()
            self.newPageVC = nil
        }
    }
    

}

extension WalletViewController: WalletDelegate {
    func didProcessWallet() {
        if let _ = localDatabase.getWallet() {
            if !(self.children[0].isKind(of: RegisteredWalletViewController.self)) {
//                if self.parent == nil {
//                    let window = UIApplication.shared.windows.first
//                    let root = window?.rootViewController
//                    window?.rootViewController = nav
//                }
                newPageVC = RegisteredWalletViewController()
                (newPageVC as! RegisteredWalletViewController).delegate = self
                configureChildVC()
            }
        } else {
            if !(self.children[0].isKind(of: UnregisteredWalletViewController.self)) {
                newPageVC = UnregisteredWalletViewController()
                configureChildVC()
            }
        }
    }
}

// send, receive, reset password, private key, delete

