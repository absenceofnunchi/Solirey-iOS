//
//  UnregisteredWalletViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit

class UnregisteredWalletViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
    var backgroundAnimator: UIViewPropertyAnimator!
    let galleries: [String] = ["1", "2"]
    var pvc: UIPageViewController!
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        configureCloseButton()
        setButtonConstraints()
        configurePageVC()
        setConstraints()
    }
    
    // MARK: - viewWillAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateKeyframes(withDuration: 0.6, delay: 0.0, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.4) {
                self.pvc.view.alpha = 1
                self.pvc.view.transform = .identity
            }
        },
        completion: nil
        )
        
        self.addKeyboardObserver()
    }
    
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0.0, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.pvc.view.alpha = 0
                self.pvc.view.transform = CGAffineTransform(translationX: 0, y: 80)
            }
        },
        completion: nil
        )
        
        self.removeKeyboardObserver()
    }
}

extension UnregisteredWalletViewController {
    // MARK: - configurePageVC
    func configurePageVC() {
        let singlePageVC = SinglePageViewController(gallery: "1")
        guard let walletVC = self.parent as? WalletViewController else { return }
        singlePageVC.delegate =  walletVC // wallet view controller for a protocol
        
        pvc = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        pvc.dataSource = self
        addChild(pvc)
        view.addSubview(pvc.view)
        pvc.didMove(toParent: self)
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
        pageControl.currentPageIndicatorTintColor = .gray
        pageControl.backgroundColor = .clear
    }
    
    // MARK: - setSinglePageConstraints
    func setConstraints() {
        guard let pv = pvc.view else { return }
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                // container view
                pv.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                pv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                pv.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
                pv.heightAnchor.constraint(equalToConstant: 350),
            ])
        }else{
            NSLayoutConstraint.activate([
                // container view
                pv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                pv.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                pv.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
                pv.heightAnchor.constraint(equalTo: pv.widthAnchor, multiplier: 1.2),
            ])
        }
    }
}

extension UnregisteredWalletViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! SinglePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index -= 1
        if index < 0 {
            return nil
        }
        let spv = SinglePageViewController(gallery: galleries[index])
        guard let walletVC = self.parent as? WalletViewController else { return nil }
        spv.delegate = walletVC
        return spv
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! SinglePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index += 1
        if index >= galleries.count {
            return nil
        }
        let spv = SinglePageViewController(gallery: galleries[index])
        guard let walletVC = self.parent as? WalletViewController else { return nil }
        spv.delegate = walletVC
        return spv
//        return SinglePageViewController(gallery: galleries[index])
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.galleries.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let page = pageViewController.viewControllers![0] as! SinglePageViewController
        let gallery = page.gallery!
        return self.galleries.firstIndex(of: gallery)!
    }
}

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
    
    // This method will notify when keyboard appears/ dissapears
    @objc func keyboardNotifications(notification: NSNotification) {
        
        var txtFieldY : CGFloat = 0.0  //Using this we will calculate the selected textFields Y Position
        let spaceBetweenTxtFieldAndKeyboard : CGFloat = 5.0 //Specify the space between textfield and keyboard
        
        
        var frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        if let activeTextField = UIResponder.currentFirst() as? UITextField ?? UIResponder.currentFirst() as? UITextView {
            // Here we will get accurate frame of textField which is selected if there are multiple textfields
            frame = self.view.convert(activeTextField.frame, from:activeTextField.superview)
            txtFieldY = frame.origin.y + frame.size.height
        }
        
        if let userInfo = notification.userInfo {
            // here we will get frame of keyBoard (i.e. x, y, width, height)
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyBoardFrameY = keyBoardFrame!.origin.y
            let keyBoardFrameHeight = keyBoardFrame!.size.height
            
            var viewOriginY: CGFloat = 0.0
            //Check keyboards Y position and according to that move view up and down
            if keyBoardFrameY >= UIScreen.main.bounds.size.height {
                viewOriginY = 0.0
            } else {
                // if textfields y is greater than keyboards y then only move View to up
                if txtFieldY >= keyBoardFrameY {
                    
                    viewOriginY = (txtFieldY - keyBoardFrameY) + spaceBetweenTxtFieldAndKeyboard
                    
                    //This condition is just to check viewOriginY should not be greator than keyboard height
                    // if its more than keyboard height then there will be black space on the top of keyboard.
                    if viewOriginY > keyBoardFrameHeight { viewOriginY = keyBoardFrameHeight }
                }
            }
            
            //set the Y position of view
            self.view.frame.origin.y = -viewOriginY
        }
    }
}


