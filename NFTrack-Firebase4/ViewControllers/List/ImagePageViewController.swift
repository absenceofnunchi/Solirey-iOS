//
//  ImagePageViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-16.
//

/*
 Abstract: A preview for uploaded images with page view controllers
 */

import UIKit

class ImagePageViewController: UIViewController {
    var gallery: String!
    var imageView: UIImageView!
    var loadingIndicator: UIActivityIndicatorView!
    
    init(gallery: String) {
        self.gallery = gallery
        self.imageView = UIImageView()
        self.loadingIndicator = UIActivityIndicatorView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
}

extension ImagePageViewController {
    func configureUI() {
        view.backgroundColor = .white
        imageView.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
        imageView.setImage(from: gallery) { [weak self] in
            self?.loadingIndicator.stopAnimating()
        }
        imageView.contentMode = .scaleAspectFill
        imageView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.size.width, height: 250))
        imageView.isUserInteractionEnabled = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        imageView.addGestureRecognizer(tap)
        view.addSubview(imageView)
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        let previewVC = BigPreviewViewController()
        previewVC.view.backgroundColor = .black
        previewVC.modalPresentationStyle = .fullScreen
        previewVC.modalTransitionStyle = .crossDissolve
        previewVC.imageView.image = imageView.image
        self.present(previewVC, animated: true, completion: nil)
    }
}
