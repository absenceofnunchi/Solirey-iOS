//
//  MyDoneButtonVC.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

protocol HandleDone: AnyObject {
    func handleDone()
}
// you can optionally use a protocol for the delegate to be more precise

class MyDoneButtonVC : UIInputViewController {
    weak var delegate : UIViewController?
    override func viewDidLoad() {
        
        let iv = self.inputView!
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.allowsSelfSizing = true // crucial
        let b = UIButton(type: .system)
        b.tintColor = .black
        b.setTitle("Done", for: .normal)
        b.sizeToFit()
        b.addTarget(self, action: #selector(doDone), for: .touchUpInside)
        b.backgroundColor = UIColor.lightGray
        iv.addSubview(b)
        b.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            b.topAnchor.constraint(equalTo: iv.topAnchor),
//            b.heightAnchor.constraint(equalToConstant: 50),
            b.bottomAnchor.constraint(equalTo: iv.bottomAnchor),
            b.leadingAnchor.constraint(equalTo: iv.leadingAnchor),
            b.trailingAnchor.constraint(equalTo: iv.trailingAnchor),
        ])
    }
    
    @objc func doDone() {
        if let del = self.delegate {
            (del as AnyObject).doDone?()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func traitCollectionDidChange(_ prev: UITraitCollection?) {
        super.traitCollectionDidChange(prev)
    }
}
