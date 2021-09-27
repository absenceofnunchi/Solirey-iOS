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
        
        
        imageView.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
        
        guard let gallery = gallery, let url = URL(string: gallery) else { return }
        let fileExtension = url.pathExtension
        if fileExtension == "pdf" {
            pdfView = PDFView()
            pdfView.autoScales = true
            pdfView.setPDF(from: url) { [weak self] doc in
                self?.document = doc
                self?.loadingIndicator.stopAnimating()
            }
//            pdfView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.size.width, height: 250))
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
            pdfView.tag = 1
            pdfView.isUserInteractionEnabled = true
            pdfView.layer.cornerRadius = 8
            pdfView.clipsToBounds = true
            pdfView.addGestureRecognizer(tap)
            pdfView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pdfView)
            
            NSLayoutConstraint.activate([
                pdfView.topAnchor.constraint(equalTo: view.topAnchor),
                pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                pdfView.heightAnchor.constraint(equalToConstant: 250)
            ])
        } else {
            imageView.setImage(from: gallery) { [weak self] in
                self?.loadingIndicator.stopAnimating()
            }
            imageView.contentMode = .scaleAspectFill
//            imageView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.size.width, height: 250))
            imageView.isUserInteractionEnabled = true
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
            imageView.tag = 2
            imageView.addGestureRecognizer(tap)
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
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
