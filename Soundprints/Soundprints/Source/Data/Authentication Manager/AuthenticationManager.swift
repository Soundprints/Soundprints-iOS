//
//  AuthenticationManager.swift
//  Soundprints
//
//  Created by Svit Zebec on 04/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation
import FacebookLogin
import FacebookCore

class AuthenticationManager {
    
    static var accessToken: String?
    static var provider: AuthProvider = .facebook
    
    static var isLoggedIn: Bool {
        switch provider {
        case .facebook: return AccessToken.current != nil
        }
    }
    
    class func refreshAccessToken(callback: @escaping ((_ token: String?, _ error: Error?) -> Void)) {
        
        accessToken = nil
        
        switch provider {
        case .facebook:
            if let _ = AccessToken.current {
                AccessToken.refreshCurrentToken { token, error in
                    if let token = token {
                        self.accessToken = token.authenticationToken
                    } else {
                        self.accessToken = nil
                    }
                    callback(self.accessToken, error)
                }
            } else {
                callback(nil, APIError(localError: .failedToSign))
            }
        }
    }
    
    class func clearAccessToken() {
        self.accessToken = nil
    }
    
}

extension AuthenticationManager {
    
    enum AuthProvider {
        case facebook
        
        func toString() -> String {
            switch self {
            case .facebook: return "facebook"
            }
        }
    }
    
}
