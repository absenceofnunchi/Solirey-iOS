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
        
        UIView.transition(from: oldPageVC.view, to: newPageVC.view, duration: 0.6, options: .transitionCrossDissolve) { [weak self] (_) in
            guard let self = self else { return }
            self.oldPageVC.endAppearanceTransition()
            self.newPageVC.endAppearanceTransition()
            self.newPageVC.didMove(toParent: self)
            self.oldPageVC.removeFromParent()
//            self.oldPageVC = nil
            self.oldPageVC = self.newPageVC
            self.oldPageVC.view.translatesAutoresizingMaskIntoConstraints = false
            self.oldPageVC.view.fill()
//            self.newPageVC = nil
            print("configureChildVC")
        }
    }
}

extension WalletViewController: WalletDelegate {
    func didProcessWallet() {
        if let wallet = localDatabase.getWallet() {
            print("wallet in walletVC", wallet)
            let registeredWalletVC = RegisteredWalletViewController()
            registeredWalletVC.delegate = self
            newPageVC = registeredWalletVC
            
//            newPageVC = RegisteredWalletViewController()
//            (newPageVC as! RegisteredWalletViewController).delegate = self
            delay(0.2) { [weak self] in
                self?.configureChildVC()
            }
        } else {
            newPageVC = UnregisteredWalletViewController()
            delay(0.2) { [weak self] in
                self?.configureChildVC()
            }
        }
    }
}

// send, receive, reset password, private key, delete

