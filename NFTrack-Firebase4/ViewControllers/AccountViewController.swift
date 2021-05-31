//
//  AccountViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit
import Firebase

class AccountViewController: UIViewController {
    var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        logoutButton = UIButton()
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        logoutButton.backgroundColor = .black
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 200),
            logoutButton.heightAnchor.constraint(equalToConstant: 100),
        ])
        
    }
    
    @objc func buttonPressed() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}

extension AccountViewController {

}
