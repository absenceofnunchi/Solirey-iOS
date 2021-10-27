//
//  PostViewController + Picker.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

extension ParentPostViewController {
    override var canBecomeFirstResponder: Bool {
        return showKeyboard
    }
    
    override var inputAccessoryViewController: UIInputViewController? {
        if showKeyboard {
            return self.mdbvc
        } else {
            return nil
        }
    }
    
    @objc func doPickBoy(_ sender: UITapGestureRecognizer) { // button in the interface
        guard let v = sender.view else { return }
        pickerTag = v.tag
        /// MyDoneButtonVC
        self.mdbvc.view.alpha = 1
        self.showKeyboard = true
        self.becomeFirstResponder()
    }
}
