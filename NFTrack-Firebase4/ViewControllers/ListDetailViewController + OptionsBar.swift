//
//  ListDetailViewController + OptionsBar.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-26.
//

/*
 Abstract:
 The options bar navigation item for the edit button, delete button, and txDetail
 */

import UIKit

extension ListDetailViewController {
    
    func configureOptionsBar() {
        let barButtonMenu = UIMenu(title: "", children: [
            UIAction(title: NSLocalizedString("Tx Detail", comment: ""), image: UIImage(systemName: "square.grid.2x2"), handler: menuHandler),
            UIAction(title: NSLocalizedString("Edit", comment: ""), image: UIImage(systemName: "c.circle"), handler: menuHandler),
            UIAction(title: NSLocalizedString("Delete", comment: ""), image: UIImage(systemName: "c.circle"), handler: menuHandler)
        ])
        
        let image = UIImage(systemName: "line.horizontal.3.decrease")?.withRenderingMode(.alwaysOriginal)
        if #available(iOS 14.0, *) {
            optionsBarItem = UIBarButtonItem(title: nil, image: image, primaryAction: nil, menu: barButtonMenu)
            navigationItem.rightBarButtonItem = optionsBarItem
        } else {
            optionsBarItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(menuHandler(action:)))
            navigationItem.rightBarButtonItem = optionsBarItem
        }
    }
    
    @objc func menuHandler(action: UIAction) {
        switch action.title {
            case "TxDetail":
                DispatchQueue.main.async {
                    let txDetailVC = TxDetailViewController()
                    self.navigationController?.pushViewController(txDetailVC, animated: true)
                }
            case "Edit":
                print("edit")
                break
            case "Delete":
                print("delete")
                break
            default:
                break
        }
    }
}
