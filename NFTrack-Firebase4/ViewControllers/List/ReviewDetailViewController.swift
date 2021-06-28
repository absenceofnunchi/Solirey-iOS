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
    var pvc: UIPageViewController!
    var galleries: [String]!
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

    override func viewDidLoad() {   
        super.viewDidLoad()
        configureUI()
        configureNameDisplay(post: post, v: scrollView)
        configureImageDisplay(post: post, v: scrollView)
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

extension ReviewDetailViewController: PageVCConfigurable, UsernameBannerConfigurable {
    // MARK: - configureUI()
    func configureUI() {
        title = "Review"
        view.backgroundColor = .white
//        scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.fill()
        galleries = [String]()
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
        if let files = post.files, files.count > 0 {
            guard let pv = pvc.view else { return }
            setImageDisplayConstraints(v: scrollView)
            setNameDisplayConstraints(topView: pv)
        } else {
            setNameDisplayConstraints(topView: scrollView)
        }
        
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
    
    func tapped(_ sender: UITapGestureRecognizer!) {
        print("pressed")
    }
}

extension ReviewDetailViewController {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index -= 1
        if index < 0 {
            return nil
        }
        
        return ImagePageViewController(gallery: galleries[index])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let gallery = (viewController as! ImagePageViewController).gallery, var index = galleries.firstIndex(of: gallery) else { return nil }
        index += 1
        if index >= galleries.count {
            return nil
        }
        
        return ImagePageViewController(gallery: galleries[index])
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.galleries.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let page = pageViewController.viewControllers![0] as! ImagePageViewController
        
        if let gallery = page.gallery {
            return self.galleries.firstIndex(of: gallery)!
        } else {
            return 0
        }
    }
}
