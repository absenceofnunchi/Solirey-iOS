//
//  ImageDataStore.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-23.
//

import Foundation
import UIKit.UIImage

class ImageDataStore {
    private var posts: [Post]!
    public var numberOfImage: Int {
        return posts.count
    }
    
    public func loadImage(at index: Int) -> DataLoadOperation? {
        if (0..<posts.count).contains(index) {
            if let images = posts[index].images, images.count > 0 {
                return DataLoadOperation(posts[index])
            } else {
                return nil
            }
        }
        return .none
    }
    
    init(posts: [Post]) {
        self.posts = posts
    }
}

class DataLoadOperation: Operation {
    var image: UIImage?
    var loadingCompleteHandler: ((UIImage?) -> ())?
    private var _post: Post
    
    init(_ post: Post) {
        _post = post
    }
    
    override func main() {
        if isCancelled { return }
        guard let images = _post.images,
              images.count > 0,
              let url = URL(string: images[0]) else {
            return
        }
        
        downloadImageFrom(url) { (image) in
            DispatchQueue.main.async() { [weak self] in
                guard let `self` = self else { return }
                if self.isCancelled { return }
                self.image = image
                self.loadingCompleteHandler?(self.image)
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
