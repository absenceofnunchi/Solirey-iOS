//
//  BigPreviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

/*
 Abstract:
 Big preview from local files instead of fetching the remote resources like BigSinglePageViewController.
 Used in previewing from ImagePreviewController
 */

import UIKit
import PDFKit

class BigLocalSinglePageViewController<T: Equatable>: ParentSinglePageViewController<T>, ModalConfigurable {
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
        setCloseButtonConstraints()
        
        guard let gallery = gallery as? String, let url = URL(string: gallery) else { return }
        let fileExtension = url.pathExtension
        if fileExtension == "pdf" {
            pdfView = PDFView()
            pdfView.autoScales = true
            pdfView.contentMode = .scaleAspectFit
            pdfView.document = PDFDocument(url: url)
            pdfView.isUserInteractionEnabled = true
            pdfView.layer.cornerRadius = 10
            pdfView.clipsToBounds = true
            pdfView.backgroundColor = .clear
            pdfView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pdfView)
            loadingIndicator.stopAnimating()
            
            NSLayoutConstraint.activate([
                pdfView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
                pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
            ])
        } else {
            guard let imageData = try? Data(contentsOf: url) else { return }
            imageView.image = UIImage(data: imageData)
            imageView.contentMode = .scaleAspectFit
            imageView.enableZoom()
            view.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
            ])
            
            loadingIndicator.stopAnimating()
        }
    }
    
    override func configureImage() {
        configureCloseButton(tintColor: .white)
        setCloseButtonConstraints()
        
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
