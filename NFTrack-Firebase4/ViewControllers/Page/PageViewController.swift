//
//  PageViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

/*
 Abstract:
 The PageVC should be able to accommodate 2 generics:
 
    1.  The individual page within the page view controller should be a generic since it can be of any size or shapes. For example, the individual page to be displayed in ParentDetailVC should be small and be enclosed in a container view to show the drop shadow. However, the individual page to be displayed when the images or the documents are enlarged should take up the entire screen, be in a aspect fit mode, and be without a container or the drop shadow. The PageDataType protocol ensures that as long as a type actualizes a view controller that has the gallery variable of the generic type (more on this in the second point) and the initializer for it, then it can be the individual page for the page view controller.
 
        This allows having the UIPageViewController delegate methods and data source methods within the generic PageVC so that having to create a separate delegate/data source methods for different types of individual page VCs is obviated.
 
    2.  The variable to be passed to the individual page view controller should be a generic as well as long as they are equatable.  This is to allow passing of the URL String of an image from FireStore to the individual page (such as from ParentDetailVC) or an UIImage to be passed (such as from ChatVC). It's currently constrained with Equatable, but we currently only process String and UIImage from ParentSinglePageVC.

 Important thing to note is that since the PageVC contains generic individual (or single) page that also contains a generic variable (gallery), PageVC essentially has a generic of a generic.  This is achieved by using a protocol (PageDataType) with an associated type. 
 */

import UIKit

class PageViewController<T: PageDataType>: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    typealias Assoc = T.Assoc
    var galleries: [Assoc]?
    weak var generalPurposeDelegate: GeneralPurposePageViewDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    init(
        transitionStyle style: UIPageViewController.TransitionStyle,
        navigationOrientation: UIPageViewController.NavigationOrientation,
        options: [UIPageViewController.OptionsKey : Any]? = nil,
        galleries: [T.Assoc]?
    ) {
        super.init(transitionStyle: style, navigationOrientation: navigationOrientation, options: options)
        self.galleries = galleries
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.windows.first?.endEditing(true)
    }
    
    func configure() {
        self.hideKeyboardWhenTappedAround()
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        delegate = self
        dataSource = self
    }
    
    @objc func swiped(_ sender: UISwipeGestureRecognizer) {
        view.endEditing(true)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? T,
              let gallery = vc.gallery,
              let galleries = galleries,
              var index = galleries.firstIndex(of: gallery) else { return nil }
        
        index -= 1
        if index < 0 {
            return nil
        }
        
        let vcBefore = T(gallery: galleries[index], galleries: galleries)
        generalPurposeDelegate?.didSet(vcBefore)
        return vcBefore
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? T,
              let gallery = vc.gallery,
              let galleries = galleries,
              var index = galleries.firstIndex(of: gallery) else { return nil }
        
        index += 1
        if index >= galleries.count {
            return nil
        }

        let vcAfter = T(gallery: galleries[index], galleries: galleries)
        generalPurposeDelegate?.didSet(vcAfter)
        return vcAfter
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return galleries != nil ? galleries!.count : 0
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let pages = pageViewController.viewControllers,
              let page = pages[0] as? T,
              let gallery = page.gallery,
              let galleries = galleries,
              let index = galleries.firstIndex(of: gallery)  else { return 0 }
        
        return index
    }
}

// Since the page view controller delegate methods like viewControllerBefore and viewControllerAfter are within PageViewController that are used in a general purpose way
// instead of the parent view controller of the page view controller having them
// there needs to be a way to pass values to the child view controllers of the page view controller from the parent view controller
protocol GeneralPurposePageViewDelegate: AnyObject {
    func didSet(_ vc: UIViewController)
}
