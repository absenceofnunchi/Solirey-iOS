//
//  ReviewDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-23.
//

import UIKit

class ReviewDetailViewController: UIViewController {
    var post: Review!
    
    override func viewDidLoad() {   
        super.viewDidLoad()
        configureUI()
    }
}

extension ReviewDetailViewController {
    func configureUI() {
        view.backgroundColor = .white
        
    }
}
