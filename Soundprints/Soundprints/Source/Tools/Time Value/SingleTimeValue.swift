//
//  TimeValue.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

struct SingleTimeValue {
    
    // MARK: - Variables
    
    var value: Int
    var unit: TimeUnit
    
    var interval: TimeInterval {
        switch unit {
        case .second: return TimeInterval(value)
        case .minute: return TimeInterval(value) * 60
        case .hour: return TimeInterval(value) * 3600
        }
    }
    
    var isZero: Bool {
        return value == 0
    }
    
    // MARK: - Instance from interval
    
    static func from(interval: TimeInterval, preferredUnit: TimeUnit? = nil) -> SingleTimeValue {
        guard interval >= 0 else {
            return SingleTimeValue(value: 0, unit: preferredUnit ?? .second)
        }
        
        if interval < 60 {
            return SingleTimeValue(value: Int(floor(interval)), unit: preferredUnit ?? .second)
        } else if interval < 3600 {
            return SingleTimeValue(value: Int(floor(interval / 60)), unit: preferredUnit ?? .minute)
        } else {
            return SingleTimeValue(value: Int(floor(interval / 3600)), unit: preferredUnit ?? .hour)
        }
    }

    // MARK: - Display string
    
    func displayString(withShortUnits shortUnits: Bool) -> String {
        let unitString = unit.toString(withValue: value, short: shortUnits)
        return "\(value)\(shortUnits ? "" : " ")\(unitString)"
    }
    
    // MARK: - Convenicence
    
    func equal(to singleTimeValue: SingleTimeValue) -> Bool {
        return value == singleTimeValue.value && unit == singleTimeValue.unit
    }
    
}

// MARK: - TimeUnit

extension SingleTimeValue {
    
    enum TimeUnit {
        case second
        case minute
        case hour
        
        func toString(withValue value: Int, short: Bool) -> String {
            switch self {
            case .second: 
                switch value {
                case 0: return short ? "s" : "seconds"
                case 1: return short ? "s" : "second"
                default: return short ? "s" : "seconds"
                }
            case .minute: 
                switch value {
                case 0: return short ? "m" : "minutes"
                case 1: return short ? "m" : "minute"
                default: return short ? "m" : "minutes"
                }
            case .hour: 
                switch value {
                case 0: return short ? "h" : "hours"
                case 1: return short ? "h" : "hour"
                default: return short ? "h" : "hours"
                }
            }
        }
    }
    
}

