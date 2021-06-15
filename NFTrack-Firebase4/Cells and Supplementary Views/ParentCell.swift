//
//  ParentCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//
/*
 Abstract:
 ParentTableCell works with ParentListViewController that performs asynchronous fetching of nontrivial data like images.
 The implementation of how the data is be displayed should be done in the child cell
 */


import UIKit
import FirebaseFirestore

enum ImageFetchStatus<T> {
    case fetched(UIImage?)
    case pending(T)
}

class ParentTableCell<T>: UITableViewCell {
    class var identifier: String {
        return "ParentTableCell"
    }
    var thumbImageView = UIImageView()
    var loadingIndicator = UIActivityIndicatorView()
    
    func updateAppearanceFor(_ status: ImageFetchStatus<T>) {
        DispatchQueue.main.async { [unowned self] in
            switch status {
                case .fetched(let image):
                    DispatchQueue.main.async {
                        self.thumbImageView.image = image
                        loadingIndicator.stopAnimating()
                    }
                case .pending(let post):
                    DispatchQueue.main.async {
                        self.configure(post)
                    }
            }
        }
    }
    
    func configure(_ post: T?) {
        
    }
    
    override func prepareForReuse() {
        thumbImageView.image = nil
    }
}
