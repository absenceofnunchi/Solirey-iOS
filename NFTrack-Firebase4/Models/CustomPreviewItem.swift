//
//  CustomPreviewItem.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-26.
//

import Foundation
import QuickLook

// MARK: - QLPreviewItem
class CustomPreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL, title: String?) {
        previewItemURL = url
        previewItemTitle = title
    }
}
