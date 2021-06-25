//
//  Document.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-25.
//


import UIKit

// MARK: - UIDocument
class Document: UIDocument {
    var data: Data?
    override func contents(forType typeName: String) throws -> Any {
        guard let data = data else { return Data() }
        return try NSKeyedArchiver.archivedData(withRootObject:data, requiringSecureCoding: true)
    }
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else { return }
        self.data = data
    }
}

// MARK: - Thumbnail
extension Document {
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocument.SaveOperation) throws -> [AnyHashable : Any] {
        let icon = UIImage(systemName: "trash")!
        let sz = CGSize(width: 1024,height: 1024)
        let im = UIGraphicsImageRenderer(
            size:sz, format:icon.imageRendererFormat).image {_ in
                icon.draw(in: CGRect(origin:.zero, size:CGSize(width: 1024,height: 1024)))
            }
        var d = try super.fileAttributesToWrite(to: url, for: saveOperation)
        let key1 = URLResourceKey.thumbnailDictionaryKey
        let key2 = URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey
        d[key1] = [key2:im]
        return d
    }
}
