//
//  BigPreviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

//import UIKit
//
//class BigPreviewViewController: UIViewController, ModalConfigurable, PageVCConfigurable {
//    var closeButton: UIButton!
//    var pvc: PageViewController!
//    var singlePageVC: SmallSinglePageViewController!
//    var constraints: [NSLayoutConstraint]!
//    var imageHeightConstraint: NSLayoutConstraint!
//    var files: [String]?
//
//    init(files: [String]?) {
//        super.init(nibName: nil, bundle: nil)
//        self.files = files
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .black
//        configureCloseButton(tintColor: .white)
//        setButtonConstraints()
//        configureImageDisplay(files: files, v: view)
//        setConstraints()
//
//        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
//        swipe.direction = .down
//        view.addGestureRecognizer(swipe)
//    }
//
//    func setConstraints() {
//        constraints = [NSLayoutConstraint]()
//        imageHeightConstraint = pvc.view.heightAnchor.constraint(equalToConstant: view.bounds.height)
//        constraints.append(imageHeightConstraint)
////        setImageDisplayConstraints(v: view, topConstant: 0)
//        setImageDisplayConstraints1()
//
//        NSLayoutConstraint.activate(constraints)
//    }
//
//    func setImageDisplayConstraints1() {
//        guard let pv = pvc.view else { return }
//        NSLayoutConstraint.activate([
//            pv.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            pv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            pv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
//            pv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
//            pv.heightAnchor.constraint(equalTo: pv.widthAnchor)
//        ])
//    }
//
//    @objc func swiped() {
//        self.dismiss(animated: true, completion: nil)
//    }
//}
