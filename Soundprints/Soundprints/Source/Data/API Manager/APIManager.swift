//
//  APIManager.swift
//
//  Copyright © 2017 Kamino. All rights reserved.
//


import Foundation
import FacebookLogin
import FacebookCore

class APIManager {
    
    ///
    /// Performs the request provided.
    ///
    /// - Parameters:
    /// - request: The request to perform
    /// - callback: Called on response with either response data (in the form of a dictionary) or an error
    class func performRequest(request: APIRequest, callback: ((Any?, APIError?) -> Void)?) {
        if request.needsSignature {
            let signed = signRequest(request)
            guard signed == true else {
                // Seems we have no token so push to stack
                let wrapped = APIRequestWithCallback(request: request, callback: callback)
                pushRequestToPool(wrapped)
                refreshAccessToken()
                return
            }
        }
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        
        // Create a session data task
        let task = session.dataTask(with: request.urlRequest) { data, response, error in
            
            let response = APIResponse(response: response, data: data, error: error, request: request)
            
            if let responseError = APIError(response: response) {
                // Callback with error
                
                callback?(nil, responseError)
            } else if let statusCode = response.statusCode {
                if statusCode >= 200 && statusCode < 300 && (response.data?.count ?? 0) > 0 {
                    // Status code OK, data received
                    
                    if let json = response.JSONDictionary {
                        // Data could be parsed from JSON
                        
                        callback?(json, nil)
                    } else {
                        // Here you can handle non-JSON data
                        
                        let error = APIError(localError: .cannotParse)
                        callback?(nil, error)
                    }
                } else if statusCode == 401 && request.needsSignature {
                    let wrappedRequest = APIRequestWithCallback(request: request, callback: callback)
                    pushRequestToPool(wrappedRequest)
                    
                    refreshAccessToken()
                } else if statusCode >= 200 && statusCode < 300 && (response.data?.count ?? 0) == 0 {
                    // Status code OK, no data
                    
                    callback?(nil, nil)
                } else {
                    // Status code not OK
                    
                    let error = APIError(JSONData: response.data, statusCode: response.statusCode)
                    callback?(nil, error)
                }
            } else {
                callback?(nil, APIError(localError: .generalError))
            }
        }
        
        task.resume()
    }
    
    // MARK: Request pool
    
    fileprivate static var requestPool = [APIRequestWithCallback]()
    
    /// Flushes the pending requests if any
    fileprivate class func flushPendingRequests() {
        requestPool.forEach { request in
            if let original = request.request {
                self.performRequest(request: original, callback: request.callback)
            }
        }
        requestPool = [APIRequestWithCallback]()
    }
    
    ///
    /// Pushes the request to the pending pool
    ///
    /// - Parameters:
    /// - request: The request to push
    fileprivate class func pushRequestToPool(_ request: APIRequestWithCallback) {
        requestPool.append(request)
    }
    
    /// Clears all pending requests from the pool, triggering the failedToSign error
    fileprivate class func clearPendingRequests() {
        for request in requestPool {
            request.callback?(nil, APIError(localError: .failedToSign))
        }
        
        requestPool.removeAll()
    }
    
    // MARK: - Request signing
    
    fileprivate static var accessToken: String?
    fileprivate static var provider: AuthProvider = .facebook
    fileprivate static var refreshInProgress: Bool = false
    
    ///
    /// Signs the APIRequest with token
    ///
    /// - Parameters:
    /// - request: The target request
    ///
    /// - Returns: A boolean value indicating if the request is signed
    fileprivate class func signRequest(_ request: APIRequest?) -> Bool {
        if let accessToken = accessToken {
            request?.headers["Authorization"] = "Bearer \(accessToken)"
            request?.headers["Provider"] = provider.toString()
            return true
        } else {
            return false
        }
    }
    
    ///
    /// Fetches a new access token from Firebase and flushes the remaining requests
    /// When an access token cannot be retreived it completes all requests with failedToSign
    fileprivate class func refreshAccessToken() {
        guard refreshInProgress == false else {
            return
        }
        
        self.accessToken = nil
        
        switch provider {
        case .facebook:
            if let _ = AccessToken.current {
                refreshInProgress = true
                AccessToken.refreshCurrentToken { token, error in
                    if let token = token {
                        self.accessToken = token.authenticationToken
                        self.refreshInProgress = false
                        self.flushPendingRequests()
                    } else {
                        self.accessToken = nil
                        self.refreshInProgress = false
                        self.clearPendingRequests()
                    }
                }
            } else {
                clearPendingRequests()
            }
        }
    }
    
    /// Cancels all pending requests and invalidates the current accessToken.
    /// Use this when logging out the user. Failure to call this will result in unexpected behaviour
    class func clearAccessToken() {
        clearPendingRequests()
        self.accessToken = nil
    }
    
}

// MARK: Request wrapper

extension APIManager {
    
    fileprivate class APIRequestWithCallback {
        typealias CallbackType = ((Any?, APIError?) -> Void)
        
        var request: APIRequest?
        var callback: CallbackType?
        
        init(request: APIRequest, callback: CallbackType?) {
            self.request = request
            self.callback = callback
        }
    }
}

extension APIManager {
    
    enum AuthProvider {
        case facebook
        
        func toString() -> String {
            switch self {
            case .facebook: return "facebook"
            }
        }
    }
    
}

