//
//  UnregisteredWalletViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit

class UnregisteredWalletViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
    private var backgroundAnimator: UIViewPropertyAnimator!
    final let galleries: [String] = ["1", "2"]
    private var pvc: UIPageViewController!
    lazy private var centerConstraint: NSLayoutConstraint = pvc.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    lazy private var topConstraint: NSLayoutConstraint = pvc.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
        configureCloseButton()
        setButtonConstraints()
        configurePageVC()
        setConstraints()
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addKeyboardObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeKeyboardObserver()
    }
}

extension UnregisteredWalletViewController {
    // MARK: - configurePageVC
    func configurePageVC() {
        let singlePageVC = SingleWalletPageViewController<String>(gallery: "1")
        guard let walletVC = self.parent as? WalletViewController else { return }
        singlePageVC.delegate =  walletVC // wallet view controller for a protocol
        
        pvc = PageViewController<SingleWalletPageViewController<String>>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: ["sting"])
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        addChild(pvc)
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pvc.view)
        pvc.didMove(toParent: self)
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
        pageControl.currentPageIndicatorTintColor = .gray
        pageControl.backgroundColor = .clear
    }
    
    // MARK: - setSinglePageConstraints
    func setConstraints() {
        topConstraint.isActive = false
        centerConstraint.isActive = true
        
        guard let pv = pvc.view else { return }
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                // container view
                topConstraint,
                centerConstraint,
                pv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                pv.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
                pv.heightAnchor.constraint(equalToConstant: 350),
            ])
        }else{
            NSLayoutConstraint.activate([
                // container view
                centerConstraint,
                pv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                pv.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
                pv.heightAnchor.constraint(equalToConstant: 400),
            ])
        }
    }
    
    @objc func swiped(_ sender: UISwipeGestureRecognizer) {
        view.endEditing(true)
    }
}

//extension UnregisteredWalletViewController: UIPageViewControllerDataSource {
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        guard let gallery = (viewController as! SinglePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
//        index -= 1
//        if index < 0 {
//            return nil
//        }
//        let spv = SinglePageViewController(gallery: galleries[index])
//        guard let walletVC = self.parent as? WalletViewController else { return nil }
//        spv.delegate = walletVC
//        return spv
//    }
//
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
//        guard let gallery = (viewController as! SinglePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
//        index += 1
//        if index >= galleries.count {
//            return nil
//        }
//        let spv = SinglePageViewController(gallery: galleries[index])
//        guard let walletVC = self.parent as? WalletViewController else { return nil }
//        spv.delegate = walletVC
//        return spv
////        return SinglePageViewController(gallery: galleries[index])
//    }
//
//    func presentationCount(for pageViewController: UIPageViewController) -> Int {
//        return self.galleries.count
//    }
//
//    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
//        let page = pageViewController.viewControllers![0] as! SinglePageViewController
//        let gallery = page.gallery!
//        return self.galleries.firstIndex(of: gallery)!
//    }
//}

extension UnregisteredWalletViewController {
    // MARK: - addKeyboardObserver
    func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotifications(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK: - keyboardNotifications
    // This method will notify when keyboard appears/ dissapears
    @objc func keyboardNotifications(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            // here we will get frame of keyBoard (i.e. x, y, width, height)
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyBoardFrameY = keyBoardFrame!.origin.y
            
            //Check keyboards Y position and according to that move view up and down
            if keyBoardFrameY >= UIScreen.main.bounds.size.height {
                NSLayoutConstraint.deactivate([topConstraint])
                NSLayoutConstraint.activate([centerConstraint])
                
                UIView.animate(withDuration: 2, delay: 0, options: .curveEaseInOut) { [weak self] in
                    self?.view.layoutIfNeeded()
                } completion: { (_) in }
            } else {
                NSLayoutConstraint.deactivate([centerConstraint])
                NSLayoutConstraint.activate([topConstraint])
                
                UIView.animate(withDuration: 2, delay: 0, options: .curveEaseInOut) { [weak self] in
                    self?.view.layoutIfNeeded()
                } completion: { (_) in }
            }
        }
    }
}

