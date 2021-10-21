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
    final var buttonAction: ((Int)->Void)?
    private var buttonInfoArr: [ButtonInfo]!
    private var buttonStackView: UIStackView!
    
    init(infoModelArr: [InfoModel], buttonInfoArr: [ButtonInfo]? = nil) {
        self.infoModelArr = infoModelArr
        self.buttonInfoArr = buttonInfoArr
        
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        if self.traitCollection.userInterfaceIdiom == .phone {
            self.modalPresentationStyle = .custom
        }
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    final override func viewDidLoad() {
        super.viewDidLoad()
        configureCloseButton()
        setButtonConstraints()
        configure()
        guard buttonInfoArr != nil else { return  }
        configureButton()
    }
    
    final override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentHeight: CGFloat = stackView.bounds.size.height + 100
        let contentSize = CGSize(width: view.bounds.width, height: contentHeight)
        scrollView.contentSize = contentSize
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
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
        stackView.layoutIfNeeded()
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }
    
    private func configureButton() {
        let buttonArr = buttonInfoArr.compactMap ({ createButton(buttonInfo: $0)})
        
        buttonStackView = UIStackView(arrangedSubviews: buttonArr)
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func createButton(buttonInfo: ButtonInfo) -> UIView? {
        let containerView = UIView()
        
        let button = ButtonWithShadow()
        button.tag = buttonInfo.tag
        button.backgroundColor = buttonInfo.backgroundColor
        button.setTitle(buttonInfo.title, for: .normal)
        button.layer.cornerRadius = 10
//        button.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
//        button.layer.shadowOpacity = 1
//        button.layer.shadowRadius = 10
//        button.layer.shadowOffset = CGSize(width: 0, height: 3)
//        button.layer.masksToBounds = false
        guard let pointSize = button.titleLabel?.font.pointSize else { return nil }
        button.titleLabel?.font = .rounded(ofSize: pointSize, weight: .medium)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        containerView.addSubview(button)
        button.fill()
        
        return containerView
    }
    
    @objc final func swiped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    final func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = PartialPresentationController(presentedViewController: presented, presenting: presenting)
        return pc
    }
    
    final func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
    
    @objc final func buttonPressed(_ sender: UIButton) {
        if let buttonAction = buttonAction {
            buttonAction(sender.tag)
        }
    }
}

struct InfoModel {
    let title: String
    let detail: String
}

private class InfoBlockView: UIView {
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
            
            detailTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            detailTextView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            detailTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            detailTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

struct ButtonInfo {
    let title: String
    let tag: Int
    let backgroundColor: UIColor
    var titleColor: UIColor = .white
}
