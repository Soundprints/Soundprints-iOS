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
    
    // MARK: - Properties
    
    static var accessToken: String?
    static var provider: AuthProvider = .facebook
    
    static var isLoggedIn: Bool {
        switch provider {
        case .facebook: return AccessToken.current != nil
        }
    }
    
    // MARK: - Access token
    
    class func refreshAccessToken(callback: @escaping ((_ token: String?, _ error: Error?) -> Void)) {
        
        accessToken = nil
        
        switch provider {
        case .facebook:
            if let _ = AccessToken.current {
                AccessToken.refreshCurrentToken { token, error in
                    self.accessToken = token?.authenticationToken
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

// MARK: - AuthProvider

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
