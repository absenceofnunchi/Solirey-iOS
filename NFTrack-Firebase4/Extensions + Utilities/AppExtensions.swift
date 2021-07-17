//
//  AppExtensions.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-05.
//

import UIKit
import Firebase
import FirebaseFirestore
import Combine

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
            DispatchQueue.main.async {
                controller.dismiss(animated: true, completion: completion)
            }
        } else {
            completion!()
        }
    }
    
    func hideSpinnerLite() {
        SaveAlertHandle.clear()
    }
    
    // MARK: - createTitleLabel
    func createTitleLabel(text: String, fontSize: CGFloat? = nil, weight: UIFont.Weight = .bold) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .rounded(ofSize: (fontSize != nil ? fontSize: label.font.pointSize)!, weight: weight)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    // MARK: - createLabel
    func createLabel(text: String, hashType: HashType? = nil, cornerRadius: CGFloat = 5, target: UIViewController? = nil, action: Selector? = nil) -> UILabelPadding {
        let label = UILabelPadding()
        if let hashType = hashType {
            label.tag = hashType.rawValue
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: target, action: action)
            label.addGestureRecognizer(tap)
        }
        label.text = text
        label.layer.cornerRadius = cornerRadius
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.borderWidth = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    // MARK: - createTextField
    func createTextField(placeHolder: String? = nil, content: String? = nil, delegate: UITextFieldDelegate) -> UITextField {
        let textField = UITextField()
        textField.setLeftPaddingPoints(10)
        textField.delegate = delegate
        
        if let placeHolder = placeHolder {
            textField.placeholder = placeHolder
        } else if let content = content {
            textField.text = content
        }
        
        textField.layer.borderWidth = 0.7
        textField.layer.cornerRadius = 5
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }
    
    // MARK: - configureNavigationBar
    func configureNavigationBar(vc: UIViewController) {
        vc.view.backgroundColor = .white
        // navigation controller
        vc.navigationController?.navigationBar.tintColor = UIColor.gray
        vc.navigationController?.navigationBar.isTranslucent = true
        vc.navigationController?.navigationBar.prefersLargeTitles = true
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .white
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            vc.navigationController?.navigationBar.standardAppearance = appearance
            vc.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            vc.navigationController?.navigationBar.compactAppearance = appearance
            
        } else {
            vc.navigationController?.navigationBar.barTintColor = .white
            vc.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            vc.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}

enum HashType: Int {
    case tx, address
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
    func setImage(from urlAddress: String?, completion: (() -> Void)? = nil) {
        guard let urlAddress = urlAddress, let url = URL(string: urlAddress) else {
            completion?()
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion?()
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
                completion?()
            }
        }
        task.resume()
    }
}

import PDFKit

extension PDFView {
    func setPDF(from url: URL?, completion: ((PDFDocument?) -> Void)? = nil) {
        guard let url = url else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion?(nil)
                return
            }
            if let doc = PDFDocument(data: data) {
                DispatchQueue.main.async {
                    self.document = doc
                    completion?(doc)
                }
            }
        }
        task.resume()
    }
}

// MARK: - UITableView
extension UITableView {
    func scrollToBottom(animated: Bool = true, completion: ((IndexPath) -> Void)? = nil) {
        let sections = self.numberOfSections
        let rows = self.numberOfRows(inSection: sections - 1)
        if (rows > 0){
            let indexPath = IndexPath(row: rows - 1, section: sections - 1)
            self.scrollToRow(at: indexPath, at: .bottom, animated: true)
            completion?(indexPath)
        }
    }
    
    func getCell(at indexPath: IndexPath) -> UITableViewCell? {
        let cell = self.cellForRow(at: indexPath)
        return cell
    }
}

// MARK: - UISearchController
/// SearchResultsController
extension UISearchController {
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let presentingVC = self.presentingViewController {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.view.frame = presentingVC.view.frame
            }
        }
    }
}


extension Notification.Name {
    static let didUpdateProgress = Notification.Name("didUpdateProgress")
    static let willDismiss = Notification.Name("willDismiss")
}

extension UIImageView {
    func enableZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(startZooming(_:)))
        isUserInteractionEnabled = true
        addGestureRecognizer(pinchGesture)
    }
    
    @objc
    private func startZooming(_ sender: UIPinchGestureRecognizer) {
        let scaleResult = sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)
        guard let scale = scaleResult, scale.a > 1, scale.d > 1 else { return }
        sender.view?.transform = scale
        sender.scale = 1
    }
}

// MARK: - Publisher
extension Publisher {
    func retryWithDelay<S>(
        retries: Int,
        delay: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        self
            .delayIfFailure(for: delay, scheduler: scheduler)
            .retry(retries)
            .eraseToAnyPublisher()
    }
    
    private func delayIfFailure<S>(
        for delay: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        self.catch { error in
            Future { completion in
                scheduler.schedule(after: scheduler.now.advanced(by: delay)) {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
