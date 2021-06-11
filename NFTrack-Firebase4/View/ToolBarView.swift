//
//  ToolBarView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-10.
//

import UIKit
import CryptoKit

class ToolBarView : UIView {
    var textView: UITextView!
    //    var textViewHeight: CGFloat = 50
    var sendButton: UIButton!
    var buttonAction: (()->Void)?
    
    var internalHeight : CGFloat = 200 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        return CGSize(width:300, height:self.internalHeight)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ToolBarView {
    func configure() {
        textView = UITextView(frame: CGRect(x: 4, y: 4, width: 0, height: 0))
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        //        textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        textView.frame.size = CGSize(width: fixedWidth, height: newSize.height)
        internalHeight = newSize.height
        textView.layer.borderWidth = 0.7
        textView.layer.cornerRadius = 10
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(textView)
        
        var sendImage: UIImage!
        if #available(iOS 14.0, *) {
            sendImage = UIImage(systemName: "paperplane.circle.fill")
        } else {
            sendImage = UIImage(systemName: "arrow.up.circle.fill")
        }
        
        sendButton = UIButton.systemButton(with: sendImage, target: self, action: #selector(sent))
        sendButton.tag = 1
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(sendButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            sendButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.2),
            sendButton.heightAnchor.constraint(equalTo: self.heightAnchor),
            sendButton.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -2),
            textView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.7),
            textView.heightAnchor.constraint(equalTo: self.heightAnchor),
        ])
    }
    
    @objc func sent(_ sender: UIButton!) {
        print("send pressed")
        if let buttonAction = self.buttonAction {
            buttonAction()
        }
    }
}
