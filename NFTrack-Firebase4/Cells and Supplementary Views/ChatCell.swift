//
//  ChatCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit

class ChatCell: ParentTableCell<ChatListModel> {
    override class var identifier: String {
        return "ChatCell"
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension ChatCell {
    func configure() {
        
    }
    
    func setConstraints() {
        
    }
}
