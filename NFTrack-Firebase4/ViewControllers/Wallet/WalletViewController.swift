//
//  WalletViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

import UIKit

class WalletViewController: UIViewController {
    private let localDatabase = LocalDatabase()
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
        oldPageVC.willMove(toParent: nil)
        addChild(newPageVC)
        oldPageVC.beginAppearanceTransition(false, animated: true)
        newPageVC.beginAppearanceTransition(true, animated: true)
        
        UIView.transition(from: oldPageVC.view, to: newPageVC.view, duration: 0.1, options: .transitionCrossDissolve) { (_) in
            self.oldPageVC.endAppearanceTransition()
            self.newPageVC.endAppearanceTransition()
            self.newPageVC.didMove(toParent: self)
            self.oldPageVC.removeFromParent()
//            self.oldPageVC = nil
            self.oldPageVC = self.newPageVC
            self.newPageVC.view.translatesAutoresizingMaskIntoConstraints = false
            self.oldPageVC.view.fill()
//            self.newPageVC = nil
        }
    }
}

extension WalletViewController: WalletDelegate {
    func didProcessWallet() {
        print("self.children", self.children)
        if let _ = localDatabase.getWallet() {
            newPageVC = RegisteredWalletViewController()
            print("newPageVC", newPageVC as Any)
            (newPageVC as! RegisteredWalletViewController).delegate = self
            delay(0.2) {
                self.configureChildVC()
            }
            
            
//            if !(self.children[0].isKind(of: RegisteredWalletViewController.self)) {
//                if self.parent == nil {
//                    let window = UIApplication.shared.windows.first
//                    let root = window?.rootViewController
//                    window?.rootViewController = nav
//                }
//                newPageVC = RegisteredWalletViewController()
//                print("newPageVC", newPageVC)~
//                (newPageVC as! RegisteredWalletViewController).delegate = self
            //                self.configureChildVC()
//            }
        } else {
            newPageVC = UnregisteredWalletViewController()
            delay(0.2) {
                self.configureChildVC()
            }
//            if !(self.children[0].isKind(of: UnregisteredWalletViewController.self)) {
//                newPageVC = UnregisteredWalletViewController()
//                configureChildVC()
//            }
        }
    }
}

// send, receive, reset password, private key, delete

