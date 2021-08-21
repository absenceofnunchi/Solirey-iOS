//
//  DigitalListEditViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-18.
//

/*
 Abstract:
 The view controller to edit or delete a digital asset posting.
 Since the digital asset itself cannot be modified, the only thing that can be changed are the title and the description.
 Stackview below is the result of createUpdateDeleteButtons() in ParentListEditVC which creates two buttons: Update and Delete.
 Since no media files are concerned, the button panel is absent like the one in DigitalListEditVC and the stack view can be attached directly below descTextView
 */

import UIKit

class DigitalListEditViewController: ParentListEditViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let contentSize = CGSize(
            width: view.bounds.width,
            height: SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT
        )
        scrollView.contentSize = contentSize
    }
    
    override func setConstraints() {
        super.setConstraints()
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
