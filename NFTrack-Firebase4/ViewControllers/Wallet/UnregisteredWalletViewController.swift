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
    private var pvc: PageViewController<SingleWalletPageViewController<String>>!
    var containerViewConstraints = [NSLayoutConstraint]()
    var isFirstTimeLaunched: Bool = true
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        hideKeyboardWhenTappedAround()
        configureCloseButton()
        setCloseButtonConstraints()
        configurePageVC()
        
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
        singlePageVC.delegate = walletVC // wallet view controller for a protocol
        
        pvc = PageViewController<SingleWalletPageViewController<String>>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: galleries)
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        addChild(pvc)
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pvc.view)
        pvc.didMove(toParent: self)
        pvc.generalPurposeDelegate = self
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
        pageControl.currentPageIndicatorTintColor = .gray
        pageControl.backgroundColor = .clear
    }
    
    func setBaseContainerViewConstraints(heightConstant: CGFloat) -> [NSLayoutConstraint] {
        return [
            pvc.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pvc.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            pvc.view.heightAnchor.constraint(equalToConstant: heightConstant),
        ]
    }
    
    enum ContainerViewOrientation {
        case top, center
    }
    
    func orientContainerView(_ orientation: ContainerViewOrientation) {
        NSLayoutConstraint.deactivate(containerViewConstraints)
        containerViewConstraints.removeAll()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            containerViewConstraints = setBaseContainerViewConstraints(heightConstant: 350)
        } else {
            containerViewConstraints = setBaseContainerViewConstraints(heightConstant: 400)
        }
        
        switch orientation {
            case .top:
                containerViewConstraints.append(pvc.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 100))
            case .center:
                containerViewConstraints.append(pvc.view.centerYAnchor.constraint(equalTo: view.centerYAnchor))
        }
        
        NSLayoutConstraint.activate(containerViewConstraints)
    }
        
    @objc func swiped(_ sender: UISwipeGestureRecognizer) {
        view.endEditing(true)
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
    
    // MARK: - keyboardNotifications
    // This method will notify when keyboard appears/ dissapears
    @objc func keyboardNotifications(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            // here we will get frame of keyBoard (i.e. x, y, width, height)
            let keyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let keyBoardFrameY = keyBoardFrame!.origin.y
            
            //Check keyboards Y position and according to that move view up and down
            if keyBoardFrameY >= UIScreen.main.bounds.size.height {
                orientContainerView(.center)
                
                if isFirstTimeLaunched == false {
                    UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) { [weak self] in
                        self?.view.layoutIfNeeded()
                    } completion: { (_) in }
                }
            } else {
                orientContainerView(.top)
                
                if isFirstTimeLaunched == false {
                    UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) { [weak self] in
                        self?.view.layoutIfNeeded()
                    } completion: { (_) in }
                }
            }
            
            // prevent the unintended animation in the beginning
            isFirstTimeLaunched = false
        }
    }
}

// Since the page view controller delegate methods like viewControllerBefore and viewControllerAfter are within PageViewController that are used in a general purpose way, which would've been here otherwise
// there needs to be a way to pass values to the child view controllers of the page view controller from the parent view controller
// For the new view controllers that are instantiated as swiped, they are set as delegates of WalletViewController from here to transition between registered and unregistered vcs
extension UnregisteredWalletViewController: GeneralPurposePageViewDelegate {
    func didSet(_ vc: UIViewController) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        guard let walletVC = self.parent as? WalletViewController else { return }
        (vc as? SingleWalletPageViewController<String>)?.delegate = walletVC
    }
}
