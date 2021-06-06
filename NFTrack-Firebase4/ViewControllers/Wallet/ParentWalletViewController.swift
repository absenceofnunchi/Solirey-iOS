//
//  ParentWalletViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-05.
//

import UIKit

class ParentWalletViewController: UIViewController {
    var closeButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCloseButton()
        setButtonConstraints()
    }
}

extension ParentWalletViewController {
    @objc func configureCloseButton() {
        // close button
        guard let closeButtonImage = UIImage(systemName: "multiply") else {
            self.dismiss(animated: true, completion: nil)
            return
        }

        closeButton = UIButton.systemButton(with: closeButtonImage, target: self, action: #selector(buttonHandler))
        closeButton.tag = 10
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .black
        view.addSubview(closeButton)
    }
    
    func setButtonConstraints() {
        NSLayoutConstraint.activate([
            // close button
            closeButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    @objc func buttonHandler(_ sender: UIButton!) {
        switch sender.tag {
            case 10:
                self.dismiss(animated: true, completion: nil)
            default:
                break
        }
    }
}
