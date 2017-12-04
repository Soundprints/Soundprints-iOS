//
//  APIJSONTools.swift
//  Soundprints
//
//  Created by Svit Zebec on 30/11/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class APIJSONTools {
    
    static func object(data: Data?) -> Any? {
        guard let data = data else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
    
    static func data(object: Any?) -> Data? {
        guard let object = object else {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
    }
    
    static func string(value: Any?) -> String? {
        if let value = value as? String {
            return value
        } else if let value = value as? Int {
            return String(value)
        } else if let value = value as? Float {
            return String(value)
        } else if let value = value as? Double {
            return String(value)
        } else if let value = value as? Bool {
            return value ? "true" : "false"
        } else {
            return nil
        }
    }
    
    static func integer(value: Any?) -> Int? {
        if let value = value as? String {
            return Int(value)
        } else if let value = value as? Int {
            return value
        } else if let value = value as? Double {
            return Int(value)
        } else if let value = value as? Float {
            return Int(value)
        } else if let value = value as? Bool {
            return value ? 1 : 0
        } else {
            return nil
        }
    }
    
    static func floating(value: Any?) -> Float? {
        if let value = value as? String {
            return Float(value)
        } else if let value = value as? Float {
            return value
        } else if let value = value as? Double {
            return Float(value)
        } else if let value = value as? Int {
            return Float(value)
        } else if let value = value as? Bool {
            return value ? 1.0 : 0.0
        } else {
            return nil
        }
    }
    
    static func double(value: Any?) -> Double? {
        if let value = value as? String {
            return Double(value)
        } else if let value = value as? Double {
            return value
        } else if let value = value as? Float {
            return Double(value)
        } else if let value = value as? Int {
            return Double(value)
        } else if let value = value as? Bool {
            return value ? 1.0 : 0.0
        } else {
            return nil
        }
    }
    
    static func boolean(value: Any?) -> Bool {
        if let value = value as? String {
            return value.caseInsensitiveCompare("true") == .orderedSame
        } else if let value = value as? Bool {
            return value
        } else if let value = value as? Int {
            return value != 0
        } else if let value = value as? Float {
            return value != 0.0
        } else if let value = value as? Double {
            return value != 0.0
        } else {
            return false
        }
    }
    
    static func descriptor(value: Any?) -> [String: Any]? {
        if let value = value as? [String: Any] {
            return value
        } else {
            return nil
        }
    }
    
}

extension APIJSONTools {
    
    class DictionaryWrapper {
        
        var dictionary: [String: Any]?
        
        init(dictionary: [String: Any]?) {
            self.dictionary = dictionary
        }
        
        func string(key: String) -> String? {
            return APIJSONTools.string(value: dictionary?[key])
        }
        
        func integer(key: String) -> Int? {
            return APIJSONTools.integer(value: dictionary?[key])
        }
        
        func floating(key: String) -> Float? {
            return APIJSONTools.floating(value: dictionary?[key])
        }
        
        func double(key: String) -> Double? {
            return APIJSONTools.double(value: dictionary?[key])
        }
        
        func boolean(key: String) -> Bool {
            return APIJSONTools.boolean(value: dictionary?[key])
        }
        
        func descriptor(key: String) -> [String: Any]? {
            return APIJSONTools.descriptor(value: dictionary?[key])
        }
        
    }
    
}

