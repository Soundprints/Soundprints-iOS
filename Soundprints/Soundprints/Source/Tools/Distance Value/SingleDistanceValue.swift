//
//  SingleDistanceValue.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

struct SingleDistanceValue {
    
    var value: Double
    var unit: DistanceUnit
    
    var distanceInMeters: Double {
        switch unit {
        case .meters: return value
        case .kilometers: return value * 1000
        }
    }
    
    var isZero: Bool {
        return value == 0
    }
    
    static func from(meters: Double) -> SingleDistanceValue {
        guard meters >= 0 else {
            return SingleDistanceValue(value: 0, unit: .meters)
        }
        
        if meters < 1000 {
            return SingleDistanceValue(value: meters, unit: .meters)
        } else {
            return SingleDistanceValue(value: meters/1000, unit: .kilometers)
        }
    }
    
    func displayString() -> String {
        let decimalPoints: Int = {
            switch unit {
            case .meters: return 0
            case .kilometers: return 1
            }
        }()
        let unitString = unit.toString()
        return String(format: "%\(decimalPoints > 0 ? ".\(decimalPoints)" : "")f\(unitString)", value)
    }
    
}

extension SingleDistanceValue {
    
    enum DistanceUnit {
        case meters
        case kilometers
        
        func toString() -> String {
            switch self {
            case .meters: return "m"
            case .kilometers: return "km"
            }
        }
    }
    
}
