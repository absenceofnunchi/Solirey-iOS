//
//  ParentSinglePageViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-30.
//

/*
 Abstract:
 An individual
 The PageDataType is
 
 */

import UIKit
import PDFKit

class ParentSinglePageViewController<T: Equatable>: UIViewController, PageDataType {
    typealias Assoc = T
    var gallery: Assoc!
    var galleries: [Assoc]!
    var imageView = UIImageView()
    var pdfView: PDFView!
    var loadingIndicator = UIActivityIndicatorView()
    
    required init(gallery: Assoc, galleries: [Assoc]) {
        self.gallery = gallery
        self.galleries = galleries
        super.init(nibName: nil, bundle: nil)
    }
    
    init(gallery: Assoc) {
        self.gallery = gallery
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if T.self == UIImage.self {
            configureImage()
        } else if T.self == String.self {
            configureString()
        } else {
            print("no matching type to display")
        }
    }
    
    func configureString() {
        
    }
    
    func configureImage() {
        
    }
}
