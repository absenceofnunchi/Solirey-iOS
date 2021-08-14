//
//  PageViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit

class PageViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    @objc func swiped(_ sender: UISwipeGestureRecognizer) {
        view.endEditing(true)
    }
}
