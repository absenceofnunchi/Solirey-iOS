//
//  PostViewController.swift + Resale
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-06.
//

/*
 Abstract:
 Resale of a tangible item through shipping.
 The difference between a new sale and a resale is that the mintHash is going to be "Resale" since no new token is being minted.
 Therefore, only a new escrow contract is to be deployed and skips the call to the mint method.
 Also, the unique identifier has to be reused and bypass the duplicate check.
 
 For digital resale, the same image has to be reused.
 */

import UIKit
import Combine
import web3swift

extension PostViewController {
    func uploadFilesResale() -> AnyPublisher<[String?], PostingError> {
        // upload images/files to the Firebase Storage and get the array of URLs
        if let previewDataArr = self.previewDataArr, previewDataArr.count > 0 {
            let fileURLs = previewDataArr.map { (previewData) -> AnyPublisher<String?, PostingError> in
                return Future<String?, PostingError> { promise in
                    self.uploadFileWithPromise(
                        fileURL: previewData.filePath,
                        userId: self.userId,
                        promise: promise
                    )
                }.eraseToAnyPublisher()
            }
            return Publishers.MergeMany(fileURLs)
                .collect()
                .eraseToAnyPublisher()
        } else {
            // if there are none to upload, return an empty array
            return Result.Publisher([] as [String]).eraseToAnyPublisher()
        }
    }
}

