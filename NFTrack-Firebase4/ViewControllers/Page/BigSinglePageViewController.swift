//
//  BigSinglePageViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-30.
//

import UIKit
import PDFKit

class BigSinglePageViewController<T: Equatable>: ParentSinglePageViewController<T>, ModalConfigurable {
    var closeButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }
    
    final override func configureString() {
        configureCloseButton(tintColor: .white)
        setButtonConstraints()
        
        guard let gallery = gallery as? String, let url = URL(string: gallery) else { return }
        let fileExtension = url.pathExtension
        if fileExtension == "pdf" {
            pdfView = PDFView()
            pdfView.autoScales = true
            pdfView.contentMode = .scaleAspectFit
            pdfView.setPDF(from: url) { [weak self] doc in
                self?.loadingIndicator.stopAnimating()
            }
            pdfView.isUserInteractionEnabled = true
            pdfView.layer.cornerRadius = 10
            pdfView.clipsToBounds = true
            pdfView.backgroundColor = .clear
            pdfView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pdfView)
            
            NSLayoutConstraint.activate([
                pdfView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
                pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
            ])
        } else {
            imageView.setImage(from: gallery) { [weak self] in
                self?.loadingIndicator.stopAnimating()
            }
            imageView.contentMode = .scaleAspectFit
            imageView.enableZoom()
            view.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
//                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
//                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
                
                imageView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
            ])
        }
    }
    
    override func configureImage() {
        configureCloseButton(tintColor: .white)
        setButtonConstraints()
        
        guard let gallery = gallery as? UIImage else { return }
        imageView.image = gallery
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func swiped() {
        self.dismiss(animated: true, completion: nil)
    }
}
