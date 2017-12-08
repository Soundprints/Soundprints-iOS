//
//  TimeValue.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

struct TimeValue {
    
    // MARK: - Properties
    
    var seconds: SingleTimeValue
    var minutes: SingleTimeValue
    var hours: SingleTimeValue
    
    var interval: TimeInterval {
        return seconds.interval + minutes.interval + hours.interval
    }
    
    static let zero = TimeValue(seconds: SingleTimeValue(value: 0, unit: .second), minutes: SingleTimeValue(value: 0, unit: .minute), hours: SingleTimeValue(value: 0, unit: .hour))
    
    // MARK: - Instance from interval
    
    static func from(interval: TimeInterval?) -> TimeValue {
        guard let interval = interval, interval >= 0 else {
            return TimeValue.zero
        }
        
        let secondsInterval = interval.truncatingRemainder(dividingBy: 60)
        let minutesInterval = interval.truncatingRemainder(dividingBy: 3600)
        let hoursInterval = interval
        
        return TimeValue(seconds: SingleTimeValue.from(interval: secondsInterval, preferredUnit: .second), minutes: SingleTimeValue.from(interval: minutesInterval, preferredUnit: .minute), hours: SingleTimeValue.from(interval: hoursInterval, preferredUnit: .hour))
    }
    
    // MARK: - Display string
    
    func displayString(forceShortUnits: Bool) -> String {
        let singleTimeValues = [seconds, minutes, hours]
        let isZeroIndicators = singleTimeValues.map { $0.isZero }
        
        guard isZeroIndicators.contains(true) else {
            return seconds.displayString(withShortUnits: false)
        }
        
        let valuesWithIndicators = zip(singleTimeValues, isZeroIndicators)
        // If there is more than one than one non-zero unit, use short units
        let shortUnits = forceShortUnits || isZeroIndicators.reduce(0, { $0 + ($1 ? 1 : 0) }) > 1
        
        return valuesWithIndicators.reduce("") { result, valueWithIndicator in
            let (singleTimeValue, isZero) = valueWithIndicator
            return result + (isZero ? singleTimeValue.displayString(withShortUnits: shortUnits) : "") 
        }
    }
    
}
