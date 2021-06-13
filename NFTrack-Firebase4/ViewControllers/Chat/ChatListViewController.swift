//
//  ChatListViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-11.
//

import UIKit

struct Chat {
    let latestMessage: String
    let date: Date
    let imageURL: String
}

class ChatListViewController: UITableViewController {
    var chatArr = [Chat]()
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension ChatListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatArr.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as! ChatCell
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatVC = ChatViewController()
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
}
