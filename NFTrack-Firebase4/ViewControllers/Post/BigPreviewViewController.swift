//
//  BigPreviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

import UIKit

class BigPreviewViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCloseButton(tintColor: .white)
        setButtonConstraints()
        imageView.contentMode = .scaleAspectFit
        imageView.enableZoom()
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }
    
    @objc func swiped() {
        self.dismiss(animated: true, completion: nil)
    }
}
