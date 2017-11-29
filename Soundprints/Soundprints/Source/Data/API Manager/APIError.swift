//
//  APIError.swift
//
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class APIError: Error {
    
    // MARK: - Enums
    
    enum LocalError {
        case noInternet
        case cannotParse
        case generalError
        case failedToSign
        
        var userMessage: String {
            // This method should return the error key for localization not the actual localized string (though doing so should still work as expected).
            switch self {
            case .noInternet: return "No internet"
            case .generalError: return "Something went wrong"
            case .cannotParse: return "Cannot parse"
            case .failedToSign: return "Something went wrong"
            }
        }
    }
    
    enum ApiErrorKeys: String {
        case userNotFound = "api/user/not-found"
    }

    
    // MARK: - Properties
    
    /// Description provided by the underlying error
    /// This is either localizedDescription (if case of an NSError), local message (for known errors - no internet, ...), message parsed from JSON (from json["error"]["message"])
    var developerMessage: String = ""
    
    /// Error message returned by the API.
    /// This message is already localized so it can be directly shown to the user. Messages that cannot be localized will be shown in the original form.
    var userMessage: String?
    
    /// API returned error key
    /// Used when more detailed error handling is required
    var errorKey: String?
    
    /// Status code of the request that failed, nil for local errors
    var statusCode: Int?
    
    /// If the request failed locally (no internet, couldn't parse data, coudln't sign request, ...) this will contain the cause
    var localError: LocalError?
    
    
    // MARK: - Initializers
    
    init?(response: APIResponse) {
        if response.errorCode == URLError.notConnectedToInternet.rawValue {
            developerMessage  = LocalError.noInternet.userMessage
            localError = .noInternet
            userMessage = developerMessage
        } else if let error = response.error {
            developerMessage = error.localizedDescription
            localError = .generalError
            userMessage = developerMessage
        } else {
            return nil
        }
    }
    
    init(localError: LocalError) {
        self.localError = localError
        self.developerMessage = "\(String(describing: localError)) - \(localError.userMessage)"
        self.userMessage = localError.userMessage
    }
    
    init(JSONData: Data?, statusCode: Int?) {
        self.statusCode = statusCode
        
        if let data = JSONData {
            let parsedObject = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any]
            
            if let errorDict = parsedObject?["error"] as? [String: String] {
                developerMessage = errorDict["developerMessage"] ?? ""
                
                let key = errorDict["errorCode"]
                userMessage = key
                errorKey = key
            }
        }
    }
    
}
