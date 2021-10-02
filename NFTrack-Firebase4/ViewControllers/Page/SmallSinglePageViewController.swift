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

class SmallSinglePageViewController<T: Equatable>: ParentSinglePageViewController<T> {
    private var containerView: UIView!
    private var pvc: PageViewController<BigSinglePageViewController<String>>!
    private var singlePageVC: BigSinglePageViewController<String>!
    
    final override func configureString() {
        createContainerView()
        
        guard let gallery = gallery as? String, let url = URL(string: gallery) else { return }
        let fileExtension = url.pathExtension
        if fileExtension == "pdf" {
            pdfView = PDFView()
            pdfView.autoScales = true
            pdfView.contentMode = .scaleAspectFill
            pdfView.setPDF(from: url) { [weak self] doc in
                self?.loadingIndicator.stopAnimating()
                self?.containerView.backgroundColor = .white
            }
            pdfView.isUserInteractionEnabled = true
            pdfView.layer.cornerRadius = 10
            pdfView.clipsToBounds = true
            pdfView.tag = 0
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
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
            imageView.enableZoom()
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            imageView.addGestureRecognizer(tap)
            imageView.tag = 0
            imageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
    }
    
    override func configureImage() {
        createContainerView()
        
        guard let gallery = gallery as? UIImage else { return }
        imageView.image = gallery
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.enableZoom()
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
    }
    
    private func createContainerView() {
        containerView = UIView()
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.darkGray.cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowOffset = CGSize.zero
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5)
        ])
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()

        guard let tag = sender.view?.tag else { return }
        switch tag {
            case 0:
                guard let gallery = gallery as? String,
                      let galleries = galleries as? [String] else { return }
                pvc = PageViewController<BigSinglePageViewController<String>>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: galleries)
                singlePageVC = BigSinglePageViewController(gallery: gallery, galleries: galleries)
                pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
                pvc.modalPresentationStyle = .fullScreen
                pvc.modalTransitionStyle = .crossDissolve
                present(pvc, animated: true, completion: nil)
                
                
                // ImagePageVC is used in both the initial small carousel (i.e. ListVC) as well as the enlarged version (i.e. BigPreviewVC)
                // Which means the tap gesture will recursively execute the below command which is to present the BigPreviewVC.
                // Prevent this recursion by checking the parent?.parent VC. The parent VC is always going to be PageVC.
                //                guard !(parent?.parent is BigPreviewViewController),
                //                      let pageVC = parent as? PageViewController<T>,
                //                      let galleries = pageVC.galleries else { return }
                //
                //                let bigPreviewVC = BigPreviewViewController(files: galleries)
                //                bigPreviewVC.modalPresentationStyle = .fullScreen
                //                bigPreviewVC.modalTransitionStyle = .crossDissolve
                //                present(bigPreviewVC, animated: true, completion: nil)
                break
            default:
                break
        }
    }
}

class NonSelectablePDFView: PDFView {
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        (gestureRecognizer as? UILongPressGestureRecognizer)?.isEnabled = false
        super.addGestureRecognizer(gestureRecognizer)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
}
