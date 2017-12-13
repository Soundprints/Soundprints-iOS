//
//  APIRequest.swift
//
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class APIRequest {
    
    // MARK: - Properties for configuring the request
    
    /// API Endpoint to use
    var endpoint = Endpoint.sound
    
    /// Request method
    var method = Method.GET {
        didSet {
            injectDefaultHeaders()
        }
    }
    
    /// Request query parameters
    var queryParameters = Parameters()
    
    /// Request form parameters
    var formParameters = Parameters()
    
    /// Request header parameters
    var headers = Parameters()
    
    /// used to upload any type of data
    var rawFormData: Data?
    
    /// Used to provide a custom URL path when the custom Endpoint is used
    var customUrlPath: String?
    
    /// Flag to indicate if this request needs to be signed
    var needsSignature = true
    
    /// The unique boundary string for multipart form data requests
    var boundary: String?
    
    // MARK: - Initialization and default configuration
    
    convenience init(endpoint: Endpoint, method: Method) {
        self.init()
        self.endpoint = endpoint
        self.method = method
        injectDefaultHeaders()
    }
    
    private func injectDefaultHeaders() {
        switch method {
        case .GET, .LIST: break
        case .POST, .PUT, .DELETE, .PATCH: headers["Content-Type"] = "application/json; charset=utf-8"
        case .UPLOAD_FILE: headers["Content-Type"] = "binary"
        case .MULTIPART:
            let boundary = MultipartFormDataHandler.generateBoundaryString()
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
            self.boundary = boundary
        }
    }
    
}

// MARK: - Endpoint configuration

extension APIRequest {
    
    enum Endpoint {
        
        // MARK: - Endpoint configuration - list all endpoints here
        
        case sound
        case soundResourceURL(id: String)
        case soundUpload
        
        case custom
        
        // MARK: - Configuration for specific endpoint
        
        /// API Endpoint paths
        private var suffix: String {
            switch self {
                
            case .sound: return "sounds"
            case .soundResourceURL(let id): return "sounds/\(id)/resourceUrl"
            case .soundUpload: return "sounds/upload"
                
            case .custom: return ""
            }
        }
        
        /// Indicates if this method endpoint requires signature or not
        var requiresAuthentication: Bool {
            // TODO: unused
            switch self {
            default: return true
            }
        }
        
        /// Base path for all endpoints
        var basePath: String {
            return Globals.environment.baseURL
        }
        
        /// Complete URL for this endpoint (made by combining basePath and the suffix)
        var url: String {
            return "\(basePath)/\(suffix)"
        }
    }
    
}

// MARK: Request Method

extension APIRequest {
    
    enum Method {
        case GET
        case POST
        case PUT
        case PATCH
        case DELETE
        case LIST
        case UPLOAD_FILE
        case MULTIPART
        
        var stringValue: String {
            switch self {
            case .GET: return "GET"
            case .POST: return "POST"
            case .PUT: return "PUT"
            case .PATCH: return "PATCH"
            case .DELETE: return "DELETE"
            case .UPLOAD_FILE: return "POST"
            case .LIST: return "GET"
            case .MULTIPART: return "POST"
            }
        }
    }
    
}

// MARK: Request Parameters

extension APIRequest {
    
    class Parameters {
        fileprivate var _parameters = [String : Any]()
        var parameters: [String : Any] {
            return _parameters
        }
        
        var urlEncodedString: String? {
            get {
                var toReturn: String = ""
                var first = true
                _parameters.forEach { (key, value) in
                    
                    if let string = value as? String {
                        if first {
                            toReturn += String(format: "%@=%@", key, string)
                        } else {
                            toReturn += String(format: "&%@=%@", key, string)
                        }
                        first = false
                        
                    } else if let array = value as? [String] {
                        
                        if first {
                            toReturn += String(format: "%@=%@", key, array.joined(separator: ","))
                        } else {
                            toReturn += String(format: "&%@=%@", key, array.joined(separator: ","))
                        }
                        first = false
                        
                    } else if let double = value as? Double {
                        
                        if first {
                            toReturn += String(format: "%@=%f", key, double)
                        } else {
                            toReturn += String(format: "&%@=%f", key, double)
                        }
                        first = false
                        
                    } else if let int = value as? Int {
                        
                        if first {
                            toReturn += String(format: "%@=%d", key, int)
                        } else {
                            toReturn += String(format: "&%@=%d", key, int)
                        }
                        first = false
                        
                    } else if let float = value as? Float {
                        
                        if first {
                            toReturn += String(format: "%@=%f", key, float)
                        } else {
                            toReturn += String(format: "&%@=%f", key, float)
                        }
                        first = false
                        
                    } else {
                        print("Unknown parameter type")
                    }
                }
                
                if toReturn.isEmpty == false {
                    guard let encoded = toReturn.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                        print("URL string encoding")
                        return nil
                    }
                    
                    return encoded
                    
                } else {
                    return nil
                }
            }
        }
        
        var JSONData: Data? {
            get {
                if _parameters.keys.count > 0 {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: _parameters, options: .prettyPrinted)
                        return data
                    } catch {
                        print("Cannot serialize JSON parameters")
                        return nil
                    }
                } else {
                    return nil
                }
            }
        }
        
        subscript(key: String) -> Any? {
            get {
                return _parameters[key]
            }
            set {
                if let newValue = newValue {
                    _parameters[key] = newValue
                } else {
                    _parameters.removeValue(forKey: key)
                }
            }
        }
    }
    
    private func injectQueryParameters(request: inout URLRequest) {
        if let query = queryParameters.urlEncodedString {
            let toReturn = endpoint.url + "?" + query
            if let url = URL(string: toReturn) {
                request.url = url
            } else {
                print("Cannot prepare url: \(toReturn)")
            }
            
        } else {
            let toReturn = endpoint.url
            if let url = URL(string: toReturn) {
                request.url = url
            } else {
                print("Cannot prepare url: \(toReturn)")
            }
        }
    }
    
    private func injectFormParameters( request: inout URLRequest) {
        if let data = rawFormData {
            request.httpBody = data
        } else if let data = formParameters.JSONData {
            request.httpBody = data
        }
    }
    
    private func injectHeaders(request: inout URLRequest) {
        headers._parameters.forEach { (key, value) in
            if let stringValue = value as? String {
                request.setValue(stringValue, forHTTPHeaderField: key)
            }
        }
    }
    
}

// MARK:  - URLRequest

extension APIRequest {
    
    var urlRequest: URLRequest {
        
        var request = URLRequest(url: URL(string: "www.nil.com")!) // can't initialize without url
        request.url = nil
        
        if let customUrlPath = customUrlPath, let url = URL(string: customUrlPath), case .custom = endpoint {
            request.url = url
            
        } else {
            injectQueryParameters(request: &request)
        }
        
        injectFormParameters(request: &request)
        injectHeaders(request: &request)
        
        request.httpMethod = method.stringValue
        
        return request
    }
    
}
