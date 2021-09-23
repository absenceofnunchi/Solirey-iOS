//
//  ChatViewController + ContextMenu.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-19.
//

import UIKit

extension ChatViewController: SharableDelegate {
    final func createMessageMenu(message: String, at index: Int) -> UIMenu {
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            let objectsToShare: [AnyObject] = [message as AnyObject]
            self?.showSpinner({
                self?.hideSpinner({
                    self?.share(objectsToShare)
                })
            })
        }
        
        let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            let pasteboard = UIPasteboard.general
            pasteboard.string = message
        }
        
        let info = UIAction(title: "Info", image: UIImage(systemName: "info")) { [weak self] _ in
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            guard let message = self?.postArr[index],
//                  let userId = self?.userId,
//                  let chatListModel = self?.chatListModel,
                  let lastSeenDate = self?.lastSeenDate else { return }
//                  let seenId = chatListModel.buyerUserId == userId ? chatListModel.sellerUserId : chatListModel.buyerUserId
            
//            let lastSeenDate = lastSeen[seenId]
            
            let chatInfoVC = ChatInfoViewController(
                seenTime: lastSeenDate,
                sentTime: message.sentAtFull,
                message: message.content,
                image: nil
            )
            self?.navigationController?.pushViewController(chatInfoVC, animated: true)
        }
        
        if userId == self.postArr[index].id {
            return UIMenu(title: "", children: [share, copy, info])
        } else {
            return UIMenu(title: "", children: [share, copy])
        }
    }
    
    final func createImageMenu(image: UIImage, at index: Int) -> UIMenu {
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] action in
            let objectsToShare: [AnyObject] = [image as AnyObject]
            self?.showSpinner({
                self?.hideSpinner({
                    self?.share(objectsToShare)
                })
            })
        }
        
        let copy = UIAction(title: "Open", image: UIImage(systemName: "magnifyingglass")) { [weak self] action in
            self?.openImage(image)
        }
        
        let info = UIAction(title: "Info", image: UIImage(systemName: "info")) { [weak self] _ in
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            guard let message = self?.postArr[index],
//                  let userId = self?.userId,
//                  let chatListModel = self?.chatListModel,
                  let lastSeenDate = self?.lastSeenDate,
                  let isOnline = self?.isOnline else { return }
//                  let seenId = chatListModel.buyerUserId == userId ? chatListModel.sellerUserId : chatListModel.buyerUserId,
//                  let lastSeenDate = lastSeen[seenId]
            
            let chatInfoVC = ChatInfoViewController(
                seenTime: lastSeenDate,
                sentTime: message.sentAtFull,
                message: nil,
                image: image,
                isOnline: isOnline
            )
            self?.navigationController?.pushViewController(chatInfoVC, animated: true)
        }
        
        if userId == self.postArr[index].id {
            return UIMenu(title: "", children: [share, copy, info])
        } else {
            return UIMenu(title: "", children: [share, copy])
        }
    }
    
    final func openImage(_ image: UIImage) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        let previewVC = BigPreviewViewController()
        previewVC.imageView.image = image
        previewVC.view.backgroundColor = .black
        previewVC.modalPresentationStyle = .fullScreen
        previewVC.modalTransitionStyle = .crossDissolve
        self.present(previewVC, animated: true, completion: nil)
    }
    
    final func openImage(_ imageURL: String) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        let previewVC = BigPreviewViewController()
        previewVC.imageURL = imageURL
        previewVC.view.backgroundColor = .black
        previewVC.modalPresentationStyle = .fullScreen
        previewVC.modalTransitionStyle = .crossDissolve
        self.present(previewVC, animated: true, completion: nil)
    }
}
