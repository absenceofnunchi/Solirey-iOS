//
//  ReviewDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-23.
//

import UIKit

class ReviewDetailViewController: UIViewController {
    var post: Review!
    let scrollView = UIScrollView()
    var constraints: [NSLayoutConstraint]!
    var userInfo: UserInfo! {
        didSet {
            processProfileImage()
        }
    }
    var usernameContainer: UIView!
    var dateLabel: UILabel!
    var displayNameLabel: UILabel!
    var underLineView: UnderlineView!
    var alert: Alerts!
    var fetchedImage: UIImage!
    var profileImageView: UIImageView!
    var reviewTitleLabel: UILabel!
    var reviewLabel: UILabelPadding!
    var starRatingView: StarRatingView!
    var pvc: PageViewController<SmallSinglePageViewController<String>>!
    var singlePageVC: SmallSinglePageViewController<String>!
    var imageHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {   
        super.viewDidLoad()
        configureUI()
        configureNameDisplay(post: post, v: scrollView) { (profileImageView, displayNameLabel) in
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            profileImageView.addGestureRecognizer(tap)
            displayNameLabel.addGestureRecognizer(tap)
        }
        configureImageDisplay(post: post)
        fetchUserData(id: post.reviewerUserId)
        setConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let files = post.files, files.count > 0 {
            scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: pvc.view.bounds.height + reviewLabel.bounds.size.height + 300)
        } else {
            scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: reviewLabel.bounds.size.height + 300)
        }
    }
}

extension ReviewDetailViewController: UsernameBannerConfigurable {
    // MARK: - configureUI()
    func configureUI() {
        title = "Review"
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.fill()
        constraints = [NSLayoutConstraint]()
        alert = Alerts()
        
        starRatingView = StarRatingView()
        starRatingView.rating = post.starRating
        starRatingView.starHeight = 40
        starRatingView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(starRatingView)
        
        reviewTitleLabel = createTitleLabel(text: "Review")
        scrollView.addSubview(reviewTitleLabel)

        reviewLabel = createLabel(text: post.review)
        reviewLabel.lineBreakMode = .byCharWrapping
        reviewLabel.numberOfLines = 0
        reviewLabel.sizeToFit()
        reviewLabel.extraInternalHeight = 80
        reviewLabel.baselineAdjustment = .none
        scrollView.addSubview(reviewLabel)
    }
    
    // MARK: - setConstraints
    func setConstraints() {
        guard let pv = pvc.view else { return }
        
        if let files = post.files, files.count > 0 {
            imageHeightConstraint = pv.heightAnchor.constraint(equalToConstant: 250)
        } else {
            imageHeightConstraint = pv.heightAnchor.constraint(equalToConstant: 0)
        }
        
        setImageDisplayConstraints(v: scrollView)
        setNameDisplayConstraints(topView: pv)
        
        constraints.append(contentsOf: [
            starRatingView.topAnchor.constraint(equalTo: usernameContainer.bottomAnchor, constant: 40),
            starRatingView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            starRatingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            starRatingView.heightAnchor.constraint(equalToConstant: 40),
            
            reviewTitleLabel.topAnchor.constraint(equalTo: starRatingView.bottomAnchor, constant: 40),
            reviewTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            reviewTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            reviewTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            reviewLabel.topAnchor.constraint(equalTo: reviewTitleLabel.bottomAnchor),
            reviewLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            reviewLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            reviewLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func configureImageDisplay(post: MediaConfigurable) {
        guard let files = post.files, files.count > 0 else { return }
        pvc = PageViewController<SmallSinglePageViewController<String>>(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil, galleries: files)
        singlePageVC = SmallSinglePageViewController(gallery: files[0])
        pvc.setViewControllers([singlePageVC], direction: .forward, animated: false, completion: nil)
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pvc)
        scrollView.addSubview(pvc.view)
        pvc.didMove(toParent: self)
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.6)
        pageControl.currentPageIndicatorTintColor = .gray
        pageControl.backgroundColor = .clear
    }
    
    func setImageDisplayConstraints<T: UIView>(v: T, topConstant: CGFloat = 20) {
        constraints.append(contentsOf: [
            imageHeightConstraint,
            pvc.view.topAnchor.constraint(equalTo: v.topAnchor, constant: topConstant),
            pvc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            pvc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
        ])
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer!) {
        let tag = sender.view?.tag

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch tag {
            case 1:
                // tapping on the user profile
                let profileDetailVC = ProfileDetailViewController()
                profileDetailVC.userInfo = userInfo
//                profileDetailVC.profileImage = fetchedImage
                self.navigationController?.pushViewController(profileDetailVC, animated: true)
            default:
                break
        }
    }
}

//extension ReviewDetailViewController {
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
//        index -= 1
//        if index < 0 {
//            return nil
//        }
//        
//        return ImagePageViewController(gallery: galleries[index])
//    }
//    
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
//        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
//        index += 1
//        if index >= galleries.count {
//            return nil
//        }
//        
//        return ImagePageViewController(gallery: galleries[index])
//    }
//    
//    func presentationCount(for pageViewController: UIPageViewController) -> Int {
//        return self.galleries.count
//    }
//    
//    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
//        let page = pageViewController.viewControllers![0] as! ImagePageViewController
//        
//        if let gallery = page.gallery {
//            return self.galleries.firstIndex(of: gallery)!
//        } else {
//            return 0
//        }
//    }
//}
