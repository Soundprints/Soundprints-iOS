//
//  MultipartFormDataHandler.swift
//  Soundprints
//
//  Created by Peter Korošec 12/12/2017
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

class MultipartFormDataHandler: NSObject {
    
    class func createBodyWithParameters(name: String, filePath: String, boundary: String, mimeType: String?) -> Data? {
        
        let fileUrl = URL(fileURLWithPath: filePath)
        let fileName = fileUrl.lastPathComponent
        
        var body = Data()
        
        do {
            let fileData = try Data(contentsOf: fileUrl)
            
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
            
            if let mimeType = mimeType {
                body.appendString("Content-Type: \(mimeType)\r\n\r\n")
            } else {
                body.appendString("\r\n")
            }
            
            body.append(fileData)
            body.appendString("\r\n")
            
            return body
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    class func createFormBodyWithParameters(name: String, formString: String, boundary: String) -> Data? {
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString(formString) // removing the null terminated part
        body.appendString("\r\n")
        return body
    }
    
    class func createFormBodyWithParameters(name: String, formDouble: Double, boundary: String) -> Data? {
        var body = Data()
        
        var value = formDouble
        let data = withUnsafePointer(to: &value) {
            Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: value))
        }
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        return body
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns: The boundary string that consists of "Boundary-" followed by a UUID string.
    class func generateBoundaryString() -> String {
        return "----Boundary-\(UUID().uuidString)"
    }
    
}

// MARK: - appendString

extension Data {
    
    // TODO: kamino wrapper
    
    mutating func appendString(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            append(data)
        }
    }
    
}
