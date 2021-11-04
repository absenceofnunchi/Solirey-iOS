//
//  AppExtensions.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-05.
//

import UIKit
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
    func showSpinner(message: String? = "Please Wait...\n\n\n\n", _ completion: (() -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: nil, message: message,
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
    
    func showSpinner() {
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
            self?.present(alertController, animated: true, completion: nil)
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
    
    func hideSpinner() {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            DispatchQueue.main.async {
                controller.dismiss(animated: true, completion: nil)
            }
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
    func createLabel(text: String, hashType: HashType? = nil, cornerRadius: CGFloat = 10, target: UIViewController? = nil, action: Selector? = nil) -> UILabelPadding {
        let label = UILabelPadding()
        if let hashType = hashType {
            label.tag = hashType.rawValue
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: target, action: action)
            label.addGestureRecognizer(tap)
        }
        label.text = text
        label.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        label.layer.cornerRadius = cornerRadius
        label.clipsToBounds = true
//        label.layer.borderColor = UIColor.lightGray.cgColor
//        label.layer.borderWidth = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    // MARK: - createTextField
    func createTextField(
        placeHolder: String? = nil,
        content: String? = nil,
        borderColor: CGColor = UIColor.lightGray.cgColor,
        delegate: UITextFieldDelegate? = nil
    ) -> UITextField {
        let textField = UITextField()
        textField.setLeftPaddingPoints(10)
        
        if let delegate = delegate {
            textField.delegate = delegate
        }
        
        if let placeHolder = placeHolder {
            textField.placeholder = placeHolder
        } else if let content = content {
            textField.text = content
        }
        
        textField.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
//        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 10
//        textField.layer.borderColor = borderColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }
    
    // MARK: - configureNavigationBar
    func configureNavigationBar(vc: UIViewController) {
        let bgColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)

        vc.view.backgroundColor = bgColor
        // navigation controller
        vc.navigationController?.navigationBar.tintColor = UIColor.gray
        vc.navigationController?.navigationBar.isTranslucent = true
        vc.navigationController?.navigationBar.prefersLargeTitles = true

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = bgColor
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            vc.navigationController?.navigationBar.standardAppearance = appearance
            vc.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            vc.navigationController?.navigationBar.compactAppearance = appearance
        } else {
            vc.navigationController?.navigationBar.barTintColor = bgColor
            vc.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            vc.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    func applyBarTintColorToTheNavigationBar(
        tintColor: UIColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1),
        titleTextColor: UIColor = .white
    ) {
        guard let navController = navigationController else { return }
        navController.isHiddenHairline = true
        
        // For comparison, apply the same barTintColor to the toolbar, which has been configured to be opaque.
        navController.toolbar.barTintColor = tintColor
        navController.toolbar.isTranslucent = true
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundImage = UIImage()
        appearance.backgroundColor = tintColor
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor, NSAttributedString.Key.font: UIFont.rounded(ofSize: 30, weight: .bold)]
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor]
        
        let navigationBarAppearance = navController.navigationBar
        navigationBarAppearance.prefersLargeTitles = true
        navigationBarAppearance.scrollEdgeAppearance = appearance
        navigationBarAppearance.standardAppearance = appearance
        navigationBarAppearance.tintColor = titleTextColor
        navigationBarAppearance.sizeToFit()
    }
    
//    func applyBarTintColorToTheNavigationBar(
//        tintColor: UIColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1),
//        titleTextColor: UIColor = .white
//    ) {
//        guard let navController = navigationController else { return }
//        navController.isHiddenHairline = true
//
//        // For comparison, apply the same barTintColor to the toolbar, which has been configured to be opaque.
//        navController.toolbar.barTintColor = tintColor
//        navController.toolbar.isTranslucent = true
//
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithDefaultBackground()
//        appearance.backgroundImage = UIImage()
//        appearance.backgroundColor = tintColor
//        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor, NSAttributedString.Key.font: UIFont.rounded(ofSize: 30, weight: .bold)]
//        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor]
//
//        let navigationBarAppearance = navController.navigationBar
//        navigationBarAppearance.prefersLargeTitles = true
//        navigationBarAppearance.scrollEdgeAppearance = appearance
//        navigationBarAppearance.standardAppearance = appearance
//    }
    
    func applyImageBackgroundToTheNavigationBar() {
        guard let navController = self.navigationController else { return }
        let bounds = navController.navigationBar.bounds
        
        let roundedPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: bounds.size)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = roundedPath.cgPath
        
        let view = UIView(frame: bounds)
        view.backgroundColor = .white
        view.layer.mask = shapeLayer
        
        UIGraphicsBeginImageContext(bounds.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
//        let renderer = UIGraphicsImageRenderer(bounds: bounds)
//        let image = renderer.image { (_) in
//            view.draw(bounds)
//        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundImage = image
        
        let navigationBarAppearance = navController.navigationBar
        navigationBarAppearance.prefersLargeTitles = true
//        navigationBarAppearance.setBackgroundImage(image, for: .default)
        navigationBarAppearance.scrollEdgeAppearance = appearance
        navigationBarAppearance.standardAppearance = appearance
    }
    
    /// Configures the navigation bar to use an image as its background.
    /// - Tag: BackgroundImageExample
    func applyImageBackgroundToTheNavigationBar(vc: UIViewController) {
        
        guard let bounds = navigationController?.navigationBar.bounds else { return }
        let startingColor: UIColor = UIColor(red: 248/255, green: 237/255, blue: 227/255, alpha: 1)
//        let finishingColor: UIColor = UIColor(red: 217/255, green: 158/255, blue: 172/255, alpha: 1)
        
        var backImageForDefaultBarMetrics =
            UIImage.gradientImage(bounds: bounds,
                                  colors: [startingColor.cgColor, startingColor.cgColor])
        var backImageForLandscapePhoneBarMetrics =
            UIImage.gradientImage(bounds: bounds,
                                  colors: [UIColor.systemTeal.cgColor, UIColor.systemFill.cgColor])

        backImageForDefaultBarMetrics =
            backImageForDefaultBarMetrics.resizableImage(
                withCapInsets: UIEdgeInsets(top: 0,
                                            left: 0,
                                            bottom: backImageForDefaultBarMetrics.size.height,
                                            right: backImageForDefaultBarMetrics.size.width))
        backImageForLandscapePhoneBarMetrics =
            backImageForLandscapePhoneBarMetrics.resizableImage(
                withCapInsets: UIEdgeInsets(top: 0,
                                            left: 0,
                                            bottom: backImageForLandscapePhoneBarMetrics.size.height - 1,
                                            right: backImageForLandscapePhoneBarMetrics.size.width - 1))
   
        guard let navController = navigationController else { return }
        let navigationBarAppearance = navController.navigationBar
        navigationBarAppearance.setBackgroundImage(backImageForDefaultBarMetrics, for: .default)
        navigationBarAppearance.setBackgroundImage(backImageForLandscapePhoneBarMetrics, for: .compact)
        navigationBarAppearance.barTintColor = .white
        navigationBarAppearance.prefersLargeTitles = true
        navigationBarAppearance.isTranslucent = false
        navigationBarAppearance.backgroundColor = .white
        
        navController.toolbar.barTintColor = .white
        navController.toolbar.backgroundColor = .white
        navController.toolbar.isTranslucent = true
    }
    
    /// Configures the navigation bar to use a transparent background (see-through but without any blur).
    func applyTransparentBackgroundToTheNavigationBar(_ opacity: CGFloat, vc: UIViewController) {
        vc.view.backgroundColor = .white
        var transparentBackground: UIImage
        
        /** The background of a navigation bar switches from being translucent to transparent when a background image is applied.
         The intensity of the background image's alpha channel is inversely related to the transparency of the bar.
         That is, a smaller alpha channel intensity results in a more transparent bar and vise-versa.
         Below, a background image is dynamically generated with the desired opacity.
         */
        guard let navController = navigationController else { return }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1),
                                               false,
                                               navController.navigationBar.layer.contentsScale)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: opacity)
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        transparentBackground = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        /** Use the appearance proxy to customize the appearance of UIKit elements.
         However changes made to an element's appearance proxy do not affect any existing instances of that element currently
         in the view hierarchy. Normally this is not an issue because you will likely be performing your appearance customizations in
         -application:didFinishLaunchingWithOptions:. However, this example allows you to toggle between appearances at runtime
         which necessitates applying appearance customizations directly to the navigation bar.
         */
        
        let navigationBarAppearance = self.navigationController!.navigationBar
        navigationBarAppearance.setBackgroundImage(transparentBackground, for: .default)
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}

extension UIImage {
    static func gradientImage(bounds: CGRect, colors: [CGColor]) -> UIImage {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors
        
        UIGraphicsBeginImageContext(gradient.bounds.size)
        gradient.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
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
    func dropShadow2() {
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
    
    func dropShadow() {
        self.layer.shadowRadius = 10
        self.layer.shadowOffset = .zero
        self.layer.shadowOpacity = 0.5
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.clipsToBounds = true
    }
    
    func dropShadow3() {
        self.layer.cornerRadius = 10
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize.zero
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
    
    func setImage(from urlAddress: URL?, completion: ((Data?) -> Void)? = nil) {
        guard let url = urlAddress else {
            completion?(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion?(nil)
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
                completion?(data)
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
            self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            completion?(indexPath)
        }
    }
    
    func scrollToTop(animated: Bool = true, completion: ((IndexPath) -> Void)? = nil) {
        let sections = self.numberOfSections
        let rows = self.numberOfRows(inSection: sections - 1)
        if (rows > 0){
            let indexPath = IndexPath(row: 0, section: 0)
            self.scrollToRow(at: indexPath, at: .top, animated: animated)
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
    static let auctionButtonDidUpdate = Notification.Name("auctionButtonDidUpdate")
    static let auctionDidWithdraw = Notification.Name("auctionDidWithdraw")
    static let progressViewUpdate = Notification.Name("progressViewUpdate")
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
extension Publishers {
    struct RetryIf<P: Publisher>: Publisher {
        typealias Output = P.Output
        typealias Failure = P.Failure

        let publisher: P
        let times: Int
        let condition: (P.Failure) -> Bool

        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            guard times > 0 else { return publisher.receive(subscriber: subscriber) }

            publisher.catch { (error: P.Failure) -> AnyPublisher<Output, Failure> in
                if condition(error)  {
                    return RetryIf(publisher: publisher, times: times - 1, condition: condition).eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }.receive(subscriber: subscriber)
        }
    }
}

extension Publisher {
    func retry(
        times: Int,
        if condition: @escaping (Failure) -> Bool
    ) -> Publishers.RetryIf<Self> {
        Publishers.RetryIf(publisher: self, times: times, condition: condition)
    }
    
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
    
    func retryIfWithDelay<S>(
        retries: Int,
        delay: S.SchedulerTimeType.Stride,
        scheduler: S,
        if condition: @escaping (Failure) -> Bool
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        self.delayIfFailure(for: delay, scheduler: scheduler)
            .retry(times: retries, if: condition)
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

extension String {
    func trimmingAllSpaces(using characterSet: CharacterSet) -> String {
        return components(separatedBy: characterSet).joined()
    }
}

extension UINavigationController {
    var isHiddenHairline: Bool {
        get {
            guard let hairline = findHairlineImageViewUnder(navigationBar) else { return true }
            return hairline.isHidden
        }
        set {
            if let hairline = findHairlineImageViewUnder(navigationBar) {
                hairline.isHidden = newValue
            }
        }
    }
    
    private func findHairlineImageViewUnder(_ view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.size.height <= 1.0 {
            return view as? UIImageView
        }
        
        for subview in view.subviews {
            if let imageView = self.findHairlineImageViewUnder(subview) {
                return imageView
            }
        }
        
        return nil
    }
}
