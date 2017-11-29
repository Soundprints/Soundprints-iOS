//
//  APIResponse.swift
//
//  Copyright © 2017 Kamino. All rights reserved.
//


import Foundation

class APIResponse {
    
    /// Error that was returned when performing the request
    private(set) var error: Error?
    
    /// Raw URL Response
    private(set) var response: URLResponse?
    
    /// Raw response data
    private(set) var data: Data?
    
    /// Original request to which this response belongs to
    private(set) var request: APIRequest?
    
    
    /// Original URL response as a HTTPURLResponse
    var HTTPResponse: HTTPURLResponse? {
        return response as? HTTPURLResponse
    }
    
    /// Error code that was returned in case of an error
    var errorCode: Int? {
        return (error as NSError?)?.code
    }
    
    /// Status code returned by the server
    var statusCode: Int? {
        return HTTPResponse?.statusCode
    }
    
    /// Response data parsed from JSON
    var JSON: AnyObject? {
        if let data = data {
            return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as AnyObject?
        }
        
        return nil
    }
    
    /// Parsed JSON response data in the form of a dictionary
    var JSONDictionary: [String: AnyObject]? {
        return JSON as? [String: AnyObject]
    }
    
    // MARK: - Initializers
    
    init(response: URLResponse?, data: Data?, error: Error?, request: APIRequest?) {
        self.error = error
        self.response = response
        self.data = data
        self.request = request
    }
}
