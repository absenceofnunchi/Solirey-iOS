//
//  CustomSegmentedControl.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-22.
//

import UIKit

class CustomSegmentedControl: UIControl {
    private var buttons = [UIButton]()
    var buttonTitles = [String]() {
        didSet {
            updateView()
        }
    }
    var selectedSegmentIndex: Int! = 0
    private var selector: UIView!
    private var selectorWidth: CGFloat! = 0
    private var stackView: UIStackView!
    
    var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    var textColor: UIColor = .lightGray {
        didSet {
            updateView()
        }
    }
    
    var selectorTextColor: UIColor = .darkGray {
        didSet {
            updateView()
        }
    }
    
    var selectorColor: UIColor = .orange {
        didSet {
            updateView()
        }
    }
    
    var selectorHeight: CGFloat = 3 {
        didSet {
            updateView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(buttonTitles: [String]) {
        super.init(frame: .zero)
        self.buttonTitles = buttonTitles
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension CustomSegmentedControl {
    func updateView() {
        buttons.removeAll()
        subviews.forEach { (sv) in
            sv.removeFromSuperview()
        }
        
        for buttonTitle in buttonTitles {
            let button = UIButton(type: .system)
            button.setTitle(buttonTitle, for: .normal)
            button.setTitleColor(textColor, for: .normal)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
        }
        
        buttons[0].setTitleColor(selectorTextColor, for: .normal)
        selector = UIView()
        selectorWidth = frame.width / CGFloat(buttonTitles.count)
        let y = (self.frame.maxY - self.frame.minY) - 3.0
        selector.frame = CGRect(x: 0, y: y, width: selectorWidth, height: selectorHeight)
        selector.backgroundColor = selectorColor
        addSubview(selector)
        
        stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0.0
        addSubview(stackView)
        stackView.fill()
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        for (buttonIndex, button) in buttons.enumerated() {
            button.setTitleColor(textColor, for: .normal)
            if button == sender {
                selectedSegmentIndex = buttonIndex
                let selectorStartPosition = selectorWidth * CGFloat(buttonIndex)
                let anim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
                    self?.selector.frame.origin.x = selectorStartPosition
                }
                anim.startAnimation()
                button.setTitleColor(selectorTextColor, for: .normal)
            }
        }
        sendActions(for: .valueChanged)
    }
}
