//
//  BigImagePreviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-29.
//

import UIKit

class BigImagePreviewViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
    let imageView = UIImageView()
    var imageURL: String!

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
