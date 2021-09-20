//
//  ImageDataStore.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-23.
//

import Foundation
import UIKit.UIImage

class ImageDataStore<T> {
    fileprivate var posts: [T]!
    
    public func loadImage(at index: Int) -> DataLoadOperation? {
        if (0..<posts.count).contains(index) {
            return dataLoadBuffer(at: index)
        }
        return .none
    }
    
    fileprivate func dataLoadBuffer(at index: Int) -> DataLoadOperation? {
        return nil
    }
    
    init(posts: [T]) {
        self.posts = posts
    }
}

/// DataLeadOperation needs to take in a certain parameter, but the input data takes many different forms
class PostImageDataStore: ImageDataStore<Post> {
    final override func dataLoadBuffer(at index: Int) -> DataLoadOperation? {
        let post = posts[index]
        if let files = post.files, files.count > 0, let i = files.first {
            return DataLoadOperation(i, at: index)
        } else {
            return .none
        }
    }
}

class ChatImageDataStore: ImageDataStore<ChatListModel> {
    final var userId: String!
    final override func dataLoadBuffer(at index: Int) -> DataLoadOperation? {
        let post = posts[index]
        if post.sellerUserId != userId, post.sellerPhotoURL != "NA" {
            return DataLoadOperation(post.sellerPhotoURL, at: index)
        } else if post.buyerPhotoURL != "NA" {
            return DataLoadOperation(post.buyerPhotoURL, at: index)
        } else {
            return nil
        }
    }
    
    init(posts:[ChatListModel], userId: String) {
        super.init(posts: posts)
        self.userId = userId
    }
}

// 1. Determine whether the chat is pinned or unpinned
// 2. Determine whether the image exists in the datastore
// 3. Determine whether the image belongs to the sender or the recipient
//class SectionDataStore {
//    final var userId: String!
//    private var posts: SectionedChatList!
//
//    final func loadImage(at indexPath: IndexPath) -> DataLoadOperation? {
//        if indexPath.section == 0, (0..<posts.pinned.count).contains(indexPath.row) {
//            // pinned
//            return dataLoadBuffer(posts.pinned[indexPath.row])
//        } else if indexPath.section == 1, (0..<posts.unpinned.count).contains(indexPath.row) {
//            // unpinned
//            return dataLoadBuffer(posts.unpinned[indexPath.row])
//        } else {
//            return .none
//        }
//    }
//
//    final func dataLoadBuffer(at index: Int) -> DataLoadOperation? {
//        let post = posts[index]
//        if post.sellerUserId != userId, post.sellerPhotoURL != "NA" {
//            return DataLoadOperation(post.sellerPhotoURL)
//        } else if post.buyerPhotoURL != "NA" {
//            return DataLoadOperation(post.buyerPhotoURL)
//        } else {
//            return nil
//        }
//    }
//
//    init(posts: SectionedChatList, userId: String) {
//        self.userId = userId
//        self.posts = posts
//    }
//}

class MessageImageDataStore: ImageDataStore<Message> {
    override func dataLoadBuffer(at index: Int) -> DataLoadOperation? {
        let post = posts[index]
        if let imageURL = post.imageURL {
            return DataLoadOperation(imageURL, at: index)
        } else {
            return nil
        }
    }
}

class ReviewImageDataStore: ImageDataStore<Review> {
    final override func dataLoadBuffer(at index: Int) -> DataLoadOperation? {
        let post = posts[index]
        if post.reviewerPhotoURL != "NA" {
            return DataLoadOperation(post.reviewerPhotoURL, at: index)
        } else {
            return .none
        }
    }
}

class DataLoadOperation: Operation {
    final var image: UIImage?
    final var loadingCompleteHandler: ((UIImage?) -> ())?
    private var _imageString: String!
    private var _imageURL: URL!
    private var _index: Int!
    
    init(_ imageString: String, at index: Int) {
        _imageString = imageString
        _index = index
    }
    
    init(_ imageURL: URL, at index: Int) {
        _imageURL = imageURL
        _index = index
    }
    
    override func main() {
        if isCancelled { return }
        
        var url: URL!
        if let imageString = _imageString {
            url = URL(string: imageString)
        } else {
            url = _imageURL
        }
        
        if url.pathExtension == "pdf" {
            guard let _image = UIImage(systemName: "doc.circle") else { return }
            let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .light, scale: .small)
            let configuredImage = _image.withTintColor(.lightGray, renderingMode: .alwaysOriginal).withConfiguration(configuration)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isCancelled { return }
                self.image = configuredImage
                self.loadingCompleteHandler?(self.image)
                guard let index = self._index else { return }
                CacheManager.shared[index] = configuredImage
            }
        } else {
            downloadImageFrom(url) { (image) in
                DispatchQueue.main.async() { [weak self] in
                    guard let self = self, !self.isCancelled else { return }
                    self.image = image
                    self.loadingCompleteHandler?(self.image)
                    guard let image = image, let index = self._index else { return }
                    CacheService.shared[index as NSNumber] = image
                }
            }
        }
    }
}

func downloadImageFrom(_ url: URL, completeHandler: @escaping (UIImage?) -> ()) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard
            let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
            let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
            let data = data, error == nil,
            let _image = UIImage(data: data)
        else { return }

        completeHandler(_image)
    }.resume()
}
