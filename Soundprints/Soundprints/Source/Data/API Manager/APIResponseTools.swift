//
//  APIResponseTools.swift
//
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

extension APIResponse {
    
    var url: String {
        if let toReturn = HTTPResponse?.url?.absoluteString {
            return toReturn
        } else {
            return "[EMPTY URL]"
        }
    }
    
    var requestBody: Data? {
        return request?.formParameters.JSONData
    }
    var requestBodyString: String {
        return dataToString(data: requestBody)
    }
    
    var requestHeaders: [String: Any]? {
        return request?.headers.parameters
    }
    var requestHeadersString: String {
        return stringFromValue(value: requestHeaders)
    }
    
    var responseBody: Data? {
        return data
    }
    var responseBodyString: String {
        return dataToString(data: responseBody)
    }
    var responseHeaders: [String: AnyObject]? {
        return HTTPResponse?.allHeaderFields as? [String: AnyObject]
    }
    var responseHeadersString: String {
        return stringFromValue(value: responseHeaders)
    }
    
    var stringValue: String {
        var toReturn = "-----------[START]-----------\n"
        
        if let status = statusCode {
            toReturn = toReturn + "API returned status code: \(status)\n\n"
        }
        
        if let method = request?.method.stringValue {
            toReturn = toReturn + "Method: " + method + "\n"
        }
        toReturn = toReturn + "URL: " + url + "\n"
        
        toReturn = toReturn + "\n\n"
        toReturn = toReturn + "[---REQUEST---]:\n\n"
        toReturn = toReturn + "[HEADERS]\n" + requestHeadersString
        toReturn = toReturn + "\n\n"
        toReturn = toReturn + "[BODY]\n" + requestBodyString
        
        toReturn = toReturn + "\n\n"
        toReturn = toReturn + "[---RESPONSE---]:\n"
        toReturn = toReturn + "[HEADERS]\n" + responseHeadersString
        toReturn = toReturn + "\n\n"
        toReturn = toReturn + "[BODY]\n" + responseBodyString
        
        toReturn = toReturn + "\n\n------------[END]------------\n\n"
        
        return toReturn as String
    }
    
    private func dataToString(data: Data?, prefixWhitespaceCount: Int = 0) -> String {
        guard let data = data else {
            return "[NO DATA]"
        }
        guard data.count > 0 else {
            return "[EMPTY DATA]"
        }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            return "[JSON]:\n" + stringFromValue(value: json, prefixWhitespaceCount: prefixWhitespaceCount)
        } catch {
            if let text = String(data: data, encoding: .utf8) {
                return "[TEXT DATA]" + text
            } else {
                if data.count < 1000 {
                    return "[UNKNOWN DATA]" + data.description
                } else {
                    return "[UNKNOWN DATA] \(data.count) bytes"
                }
                
            }
        }
    }
    
    private func stringFromValue(value: Any?, prefixWhitespaceCount: Int = 0) -> String {
        
        var prefix = ""
        for _ in 0..<prefixWhitespaceCount {
            prefix = prefix + " "
        }
        
        guard let value = value else {
            return prefix+"(null)"
        }
        
        if let value = value as? String {
            return value + "(String)"
        } else if let value = value as? Int {
            return String(value) + "(Int)"
        } else if let value = value as? Float {
            return String(value) + "(Float)"
        } else if let value = value as? [AnyObject] {
            var toReturn = prefix + "[\n"
            value.forEach { item in
                toReturn = toReturn + prefix + "    " + stringFromValue(value: item, prefixWhitespaceCount: prefixWhitespaceCount+4) + ",\n"
            }
            toReturn = toReturn + prefix +  "]"
            return prefix + toReturn
        } else if let value = value as? [String: AnyObject] {
            var toReturn = prefix + "{\n"
            for (key, item) in value {
                toReturn =  toReturn + prefix + "    " + key + " = " + stringFromValue(value: item, prefixWhitespaceCount: prefixWhitespaceCount+4) + ",\n"
            }
            toReturn = toReturn + prefix + "}"
            return toReturn
        }
        
        return prefix + String(describing: value) + "(Unknown)"
    }
    
}
