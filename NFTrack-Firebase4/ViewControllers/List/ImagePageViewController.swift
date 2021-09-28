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
import PDFKit

class ImagePageViewController: UIViewController {
    var gallery: String!
    var containerView: UIView!
    var imageView: UIImageView!
    var pdfView: PDFView!
    var loadingIndicator: UIActivityIndicatorView!
    var document: PDFDocument!
    
    init(gallery: String?) {
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
        view.backgroundColor = .clear
        
        containerView = UIView()
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.darkGray.cgColor
//        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowOffset = CGSize.zero
//        containerView.layer.shadowRadius = 10
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        imageView.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5)
        ])
        
        guard let gallery = gallery, let url = URL(string: gallery) else { return }
        let fileExtension = url.pathExtension
        if fileExtension == "pdf" {
            pdfView = PDFView()
            pdfView.autoScales = true
            pdfView.setPDF(from: url) { [weak self] doc in
                self?.document = doc
                self?.loadingIndicator.stopAnimating()
                self?.containerView.backgroundColor = .white
            }
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
            pdfView.tag = 1
            pdfView.isUserInteractionEnabled = true
            pdfView.layer.cornerRadius = 10
            pdfView.clipsToBounds = true
            pdfView.addGestureRecognizer(tap)
            pdfView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(pdfView)
            
            NSLayoutConstraint.activate([
                pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
                pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        } else {
            imageView.setImage(from: gallery) { [weak self] in
                self?.loadingIndicator.stopAnimating()
                self?.containerView.backgroundColor = .white
            }
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
            imageView.tag = 2
            imageView.addGestureRecognizer(tap)
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)
  
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
//            containerView.layoutIfNeeded()
        }
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        guard let tag = sender.view?.tag else { return }
        switch tag {
            case 1:
                let previewVC = PDFPreviewViewController()
                previewVC.document = document
                previewVC.view.backgroundColor = .black
//                previewVC.modalPresentationStyle = .fullScreen
//                previewVC.modalTransitionStyle = .crossDissolve
                present(previewVC, animated: true, completion: nil)
            case 2:
                let previewVC = BigPreviewViewController()
                previewVC.view.backgroundColor = .black
                previewVC.modalPresentationStyle = .fullScreen
                previewVC.modalTransitionStyle = .crossDissolve
                previewVC.imageView.image = imageView.image
                self.present(previewVC, animated: true, completion: nil)
            default:
                break
        }

    }
}
