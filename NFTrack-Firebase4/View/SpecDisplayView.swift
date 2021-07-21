//
//  ListingDetailContainer.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-14.
//

/*
 Abstract:
 To show the listing details like delivery method, payment method, and the sale format.
 Shows on ParentDetailVC
 */

import UIKit
import Combine

class SpecDisplayView: UIView {
    var borderColor: UIColor = .lightGray {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    var cornerRadius: CGFloat = 5 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    var borderWidth: CGFloat = 0.5 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    private var storage = Set<AnyCancellable>()
    var fetchedDataArr: [SmartContractProperty]! {
        didSet {
            stackView.arrangedSubviews.enumerated().forEach { (index, element) in
                let specDetail = fetchedDataArr[index]
                for case let subview as UILabel in element.subviews {
                    switch subview.tag {
                        case 1:
                            subview.text = specDetail.propertyName
                        case 2:
                            // parse according to the type of the instance property's value
                            switch specDetail.propertyDesc {
                                case is String:
                                    subview.text = specDetail.propertyDesc as? String
                                case is Date:
                                    guard let propDesc = specDetail.propertyDesc as? Date else { return }
                                    let formatter = DateFormatter()
                                    formatter.timeStyle = .short
                                    formatter.dateStyle = .short
                                    formatter.timeZone = .current
                                    let formattedDate = formatter.string(from: propDesc)
                                    subview.text = formattedDate
                                default:
                                    break
                            }
                        default:
                            break
                    }
                }
            }
        }
    }
    private var listingDetailArr: [SmartContractProperty]!
    private var stackView: UIStackView!
    
    init(listingDetailArr: [SmartContractProperty]) {
        super.init(frame: .zero)
        
        self.listingDetailArr = listingDetailArr
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SpecDisplayView {
    private func configure() {
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
        
        stackView = UIStackView()
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        addSubview(stackView)
        stackView.fill()
        
        listingDetailArr.forEach { [weak self] detail in
            let containerView = UIView()
            
            let titleLabel = UILabel()
            titleLabel.tag = 1
            titleLabel.text = detail.propertyName
            titleLabel.font = UIFont.rounded(ofSize: 14, weight: .medium)
            titleLabel.textColor = .lightGray
            titleLabel.sizeToFit()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(titleLabel)
            
            let descLabel = UILabel()
            descLabel.tag = 2
            descLabel.text = (detail.propertyDesc as? String) ?? "Loading..."
            descLabel.font = UIFont.rounded(ofSize: 14, weight: .medium)
            descLabel.sizeToFit()
            descLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(descLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                titleLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor),
                titleLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.4),
                
                descLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                descLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor),
                descLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.6),
            ])
            
            self?.stackView.addArrangedSubview(containerView)
            self?.setNeedsLayout()
        }
    }
}
