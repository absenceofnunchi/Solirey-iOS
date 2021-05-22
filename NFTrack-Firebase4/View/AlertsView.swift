//
//  AlertsView.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//

import UIKit

class Alerts {
    func show(_ error: Error?, for controller: UIViewController) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        controller.present(alert, animated: true, completion: nil)
    }
    
    typealias Action = () -> Void
    var action: Action? = { }
    
    func show(_ title: String?, with message: String?, for controller: UIViewController, completion: Action? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        controller.present(alert, animated: true, completion: completion)
        
        //        if let popoverController = alert.popoverPresentationController {
        //            popoverController.sourceView = self.view
        //            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.height, width: 0, height: 0)
        //            popoverController.permittedArrowDirections = []
        //        }
    }
    
    func showDetail(_ title: String, with message: String?, height: CGFloat = 250, for controller: UIViewController, completion: Action? = nil) {
        DispatchQueue.main.async {
            let detailVC = DetailViewController(height: height)
            detailVC.titleString = title
            detailVC.message = message
            detailVC.buttonAction = { vc in
                controller.dismiss(animated: true, completion: completion)
            }
            controller.present(detailVC, animated: true, completion: nil)
        }
    }
        
    /*! @fn showTextInputPromptWithMessage
     @brief Shows a prompt with a text field and 'OK'/'Cancel' buttons.
     @param message The message to display.
     @param completion A block to call when the user taps 'OK' or 'Cancel'.
     */
    func showTextInputPrompt(withMessage message: String, for controller: UIViewController,
                             completionBlock: @escaping ((Bool, String?) -> Void)) {
//        DispatchQueue.main.async {
            let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionBlock(false, nil)
            }
            weak var weakPrompt = prompt
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                guard let text = weakPrompt?.textFields?.first?.text else { return }
                completionBlock(true, text)
            }
            prompt.addTextField(configurationHandler: nil)
            prompt.addAction(cancelAction)
            prompt.addAction(okAction)
            controller.present(prompt, animated: true, completion: nil)
//        }
    }
    
    // MARK: - fading
    func fading(controller: UIViewController, toBePasted: String) {
        let dimmingView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.layer.cornerRadius = 10
        dimmingView.clipsToBounds = true
        controller.view.addSubview(dimmingView)
        
        let label = UILabel()
        label.text = "Copied!"
        label.textColor = .white
        label.textAlignment = .center
        label.sizeToFit()
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.contentView.addSubview(label)
        
        if toBePasted != nil {
            let pasteboard = UIPasteboard.general
            pasteboard.string = toBePasted
        }
        
        NSLayoutConstraint.activate([
            dimmingView.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
            dimmingView.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            dimmingView.widthAnchor.constraint(equalToConstant: 150),
            dimmingView.heightAnchor.constraint(equalToConstant: 50),
            
            label.centerXAnchor.constraint(equalTo: dimmingView.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: dimmingView.contentView.centerYAnchor)
        ])
        
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { timer in
            dimmingView.removeFromSuperview()
            timer.invalidate()
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
