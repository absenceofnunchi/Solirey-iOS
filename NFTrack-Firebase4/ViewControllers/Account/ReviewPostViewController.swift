//
//  ReviewPostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-21.
//
/*
 Where you create the review and submit it
 */

import UIKit

class ReviewPostViewController: UIViewController {
    var post: Post!
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
    }
}

extension ReviewPostViewController {
    func configureUI() {
        view.backgroundColor = .white
        title = "Post your review"
    }
}
