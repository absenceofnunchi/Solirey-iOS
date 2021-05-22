//
//  AppExtensions.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-05.
//

import UIKit

// MARK: - UITextField
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

// MARK:  - UIViewController
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /*! @fn showSpinner
     @brief Shows the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func showSpinner(_ completion: (() -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: nil, message: "Please Wait...\n\n\n\n",
                                                    preferredStyle: .alert)
            SaveAlertHandle.set(alertController)
            let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
            spinner.color = UIColor(ciColor: .black)
            spinner.center = CGPoint(x: alertController.view.frame.midX,
                                     y: alertController.view.frame.midY)
            spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                        .flexibleLeftMargin, .flexibleRightMargin]
            spinner.startAnimating()
            alertController.view.addSubview(spinner)
            self?.present(alertController, animated: true, completion: completion)
        }
    }
    
    /*! @fn hideSpinner
     @brief Hides the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func hideSpinner(_ completion: (() -> Void)?) {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            controller.dismiss(animated: true, completion: completion)
        }
    }
}

// MARK: - SaveAlertHandle
private class SaveAlertHandle {
    static var alertHandle: UIAlertController?
    
    class func set(_ handle: UIAlertController) {
        alertHandle = handle
    }
    
    class func clear() {
        alertHandle = nil
    }
    
    class func get() -> UIAlertController? {
        return alertHandle
    }
}

// MARK: - UIFont
extension UIFont {
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let font: UIFont
        
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: size)
        } else {
            font = systemFont
        }
        return font
    }
}

// MARK: - UIView

extension UIView {
    // MARK: - dropShadow
    func dropShadow() {
        //        layer.masksToBounds = false
        //        layer.shadowColor = UIColor.black.cgColor
        //        layer.shadowOpacity = 0.5
        //        layer.shadowOffset = CGSize(width: -1, height: 1)
        //        layer.shadowRadius = 1
        //        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        //        layer.shouldRasterize = true
        //        layer.rasterizationScale = UIScreen.main.scale
        
        let borderColor = UIColor.lightGray
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 7.0;
        self.layer.borderColor = borderColor.withAlphaComponent(0.3).cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 0.2
        self.layer.shadowRadius = 4.0
        self.layer.backgroundColor = UIColor.white.cgColor
    }
    
    // MARK: - fill
    func fill(inset: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        guard let superview = self.superview else { return }
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.topAnchor, constant: inset),
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: inset),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -inset),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -inset)
        ])
    }
}

// MARK: - UIResponder
extension UIResponder {
    
    static weak var responder: UIResponder?
    
    static func currentFirst() -> UIResponder? {
        responder = nil
        UIApplication.shared.sendAction(#selector(trap), to: nil, from: nil, for: nil)
        return responder
    }
    
    @objc private func trap() {
        UIResponder.responder = self
    }
}

// MARK: - CGContext
extension CGContext {
    func drawLinearGradient(in rect: CGRect, startingWith startColor: CGColor, finishingWith endColor: CGColor) {
        let colorsSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [startColor, endColor] as CFArray
        let locations = [0.0, 1.0] as [CGFloat]
        
        guard let gradient = CGGradient(colorsSpace: colorsSpace, colors: colors, locations: locations) else { return }
        
        let startPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        let endPoint = CGPoint(x: rect.minX, y: rect.minY)
        
        saveGState()
        addRect(rect)
        clip()
        drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions())
        restoreGState()
    }
}

// MARK: - UIFont
extension UIFont {
    static func systemFontItalic(size fontSize: CGFloat = 17.0, fontWeight: UIFont.Weight = .regular) -> UIFont {
        let font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        return UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: fontSize)
    }
}


// MARK: - Scanner delegate
protocol ScannerDelegate: AnyObject {
    func scannerDidOutput(code: String)
}

// MARK: - UIImageView
extension UIImageView {
    func setImage(from urlAddress: String?) {
        print("urlAddress", urlAddress)
        guard let urlAddress = urlAddress, let url = URL(string: urlAddress) else { return }
        print("url", url)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                print("data", data)
                self.image = UIImage(data: data)
            }
        }
        task.resume()
    }
}

