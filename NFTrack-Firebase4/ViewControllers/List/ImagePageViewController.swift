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
    var imageView: UIImageView!
    var pdfView: PDFView!
    var loadingIndicator: UIActivityIndicatorView!
    var document: PDFDocument!
    
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
        
        if let url = URL(string: gallery) {
            let fileExtension = url.pathExtension
            if fileExtension == "pdf" {
                pdfView = PDFView()
                pdfView.autoScales = true
                pdfView.setPDF(from: url) { [weak self] doc in
                    self?.document = doc
                    self?.loadingIndicator.stopAnimating()
                }
                pdfView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.size.width, height: 250))
                let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
                pdfView.tag = 1
                pdfView.isUserInteractionEnabled = true
                pdfView.addGestureRecognizer(tap)
                view.addSubview(pdfView)
            } else {
                imageView.setImage(from: gallery) { [weak self] in
                    self?.loadingIndicator.stopAnimating()
                }
                imageView.contentMode = .scaleAspectFill
                imageView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.size.width, height: 250))
                imageView.isUserInteractionEnabled = true
                let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
                imageView.tag = 2
                imageView.addGestureRecognizer(tap)
                view.addSubview(imageView)
            }
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
