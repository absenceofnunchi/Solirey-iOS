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
//    var gallery: String! {
//        didSet {
//            imageView.setImage(from: gallery)
//        }
//    }
    var gallery: String!
    var imageView: UIImageView!
    
    init(gallery: String) {
        self.gallery = gallery
        self.imageView = UIImageView()
        self.imageView.setImage(from: gallery)
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
        view.backgroundColor = .blue
        view.addSubview(imageView)
        imageView.fill()
        
//        imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 300)))
//        imageView.setImage(from: "https://firebasestorage.googleapis.com/v0/b/nftrack-69488.appspot.com/o/DpUgBbZzpQhHKnvKURZbyp3jeOA3%2FDD422D51-C41F-4FB5-B7F7-970DF6236A2C?alt=media&token=f4dec0ef-d76a-4876-865a-f98170009c8c")
//        view.addSubview(imageView)
    }
}
