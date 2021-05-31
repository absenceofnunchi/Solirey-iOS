//
//  PostViewController + Picker.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

extension PostViewController {
    override var canBecomeFirstResponder: Bool {
        return showKeyboard
    }
    
    override var inputView: UIView? {
        return self.pvc.inputView
    }
    
    override var inputAccessoryViewController: UIInputViewController? {
        if showKeyboard {
            return self.mdbvc
        } else {
            return nil
        }
    }
    
    @objc func doPickBoy(_ sender: Any) { // button in the interface
        self.mdbvc.view.alpha = 1
        self.showKeyboard = true
        self.becomeFirstResponder()
    }
    
    @objc func doDone() { // user tapped button in accessory view
        self.pickerLabel.text = pvc.currentPep
        self.resignFirstResponder()
        self.showKeyboard = false
    }
}
