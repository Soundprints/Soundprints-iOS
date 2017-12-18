//
//  Globals.swift
//  Teodoor
//
//  Created by Andrej Rolih on 05/09/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class Globals {
    
    // MARK: - Enums
    
    enum Environment {
        case development
        case testing
        case production
        
        var baseURL: String {
            switch self {
            case .development: return "http://35.198.82.110:8080/api"
            case .testing: return "http://35.198.82.110:8081/api"
            case .production: return ""
            }
        }

    }
    
    
    // MARK: - Constants/variables
    
    
    static var environment: Environment = {
        #if DEV
            return .development
        #elseif TEST
            return .testing
        #else
            return .production
        #endif
    }()
    
}

