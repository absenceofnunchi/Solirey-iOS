//
//  IPFSService.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-25.
//

import UIKit

class IPFSService {
    static let shared = IPFSService()
    
    private func generateBoundaryString() -> String {
        return "Boundary-\(Int.random(in: 1000 ... 9999))"
    }
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String, dataKey: Data, boundary: String, isImage: Bool) -> Data {
        let body = NSMutableData()
        var mimetype: String!
        
        if isImage == true {
            mimetype = "image/*"
        } else {
            mimetype = "application/*"
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filePathKey)\"\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Type: \(mimetype!)\r\n\r\n".data(using: .utf8) ?? Data())
        body.append(dataKey)
        body.append("\r\n".data(using: .utf8) ?? Data())
        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        print("body", body)
        return body as Data
    }
    
    // MARK: - uploadImage
    func uploadImage(image: UIImage, promise:  @escaping (Result<String?, PostingError>) -> Void) {
        // build request URL
        guard let requestURL = URL(string: "https://express-ipfs-4djcj3hprq-ue.a.run.app/addImage") else {
            promise(.failure(.generalError(reason: "Could not get the IPFS URL.")))
            return
        }
        
        // prepare request
        var request = URLRequest(url: requestURL)
        request.httpMethod = MethodHttp.post.rawValue
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // built data from img
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            request.httpBody = createBodyWithParameters(parameters: nil, filePathKey: "file", dataKey: imageData, boundary: boundary, isImage: true)
        }
        
        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                promise(.failure(.generalError(reason: error.localizedDescription)))
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               let httpStatusCode = APIError.HTTPStatusCode(rawValue: httpResponse.statusCode) {
                if !(200...299).contains(httpResponse.statusCode) {
                    promise(.failure(.apiError(APIError.generalError(reason: httpStatusCode.description))))
                }
            }
                        
            if let data = data {
                do {
                    if let responseObj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0)) as? [String:Any],
                       let status = responseObj["ipfs success"] as? [String: Any],
                       let path = status["path"] as? String {
                        print("ipfs success status", status)
                        promise(.success(path))
                    }
                } catch {
                    promise(.failure(.generalError(reason: error.localizedDescription)))
                }
            }
        })
        
        task.resume()
    }
    
    func uploadData(data: Data, title: String, password: String) {
        // build request URL
        guard let requestURL = URL(string: "https://express-ipfs-4djcj3hprq-ue.a.run.app/addFile") else {
            return
        }
        
        // prepare request
        var request = URLRequest(url: requestURL)
        request.httpMethod = MethodHttp.post.rawValue
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // built data from img
        request.httpBody = createBodyWithParameters(parameters: nil, filePathKey: "file", dataKey: data, boundary: boundary, isImage: false)
        
        let task =  URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
            
            let response = response as! HTTPURLResponse
            if !(200...299).contains(response.statusCode) {
                // handle HTTP server-side error
                debugPrint("response", response)
            }
            
            //            let contentType = response.allHeaderFields["Content-Type"] as? String
            
            if let data = data {
                print("data", data)
            }
        })
        
        task.resume()
    }
 
    enum MethodHttp: String {
        case get = "GET"
        case post = "POST"
    }
}
