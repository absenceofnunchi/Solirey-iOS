//
//  InfoViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-02.
//

import UIKit

class InfoViewController: UIViewController, ModalConfigurable, UIViewControllerTransitioningDelegate {
    internal var closeButton: UIButton!
    private var scrollView: UIScrollView!
    private var textView: UITextView!
    private var stackView: UIStackView!
    private var infoModelArr: [InfoModel]!
    
    init(infoModelArr: [InfoModel]) {
        self.infoModelArr = infoModelArr
        
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        if self.traitCollection.userInterfaceIdiom == .phone {
            self.modalPresentationStyle = .custom
        }
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCloseButton()
        setButtonConstraints()
        configure()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = stackView.bounds.size
    }
    
    private func configure() {
        view.backgroundColor = .white
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        for infoModel in infoModelArr {
            let infoBlockView = InfoBlockView(infoModel: infoModel)
            stackView.addArrangedSubview(infoBlockView)
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 18),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
        stackView.layoutIfNeeded()
        scrollView.contentSize = stackView.bounds.size
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }
    
    private func createInfoText(text: String) {
        textView = UITextView()
        textView.text = text
        textView.font = .rounded(ofSize: 19, weight: .regular)
        textView.isEditable = false
        textView.textColor = .lightGray
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 15),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
    }
    
    private func createInfoTextView(infoModelArr: [InfoModel]) {
        var infoBlockViewArr = [InfoBlockView]()
        for infoModel in infoModelArr {
            let infoBlockView = InfoBlockView(infoModel: infoModel)
            infoBlockViewArr.append(infoBlockView)
        }
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 18),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }
    
    @objc func swiped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = PartialPresentationController(presentedViewController: presented, presenting: presenting)
        return pc
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

struct InfoModel {
    let title: String
    let detail: String
}

class InfoBlockView: UIView {
    private var title: String!
    private var detail: String!
    private var titleLabel: UILabel!
    private var detailTextView: UITextView!
    
    init(infoModel: InfoModel) {
        self.title = infoModel.title
        self.detail = infoModel.detail
        super.init(frame: .zero)
        
        configure()
        setConstraint()
        detailTextView.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .bold)
        titleLabel.textColor = .lightGray
        titleLabel.sizeToFit()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        
        detailTextView = UITextView()
        detailTextView.sizeToFit()
        detailTextView.text = detail
//        detailTextView.font = UIFont.systemFont(ofSize: 19)
        detailTextView.font = .rounded(ofSize: 19, weight: .regular)
        detailTextView.isEditable = false
        detailTextView.textColor = .lightGray
        detailTextView.isUserInteractionEnabled = false
        detailTextView.isScrollEnabled = false
        detailTextView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailTextView)
    }
    
    private func setConstraint() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
//            titleLabel.heightAnchor.constraint(equalToConstant: 40),
            
            detailTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            detailTextView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            detailTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            detailTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
