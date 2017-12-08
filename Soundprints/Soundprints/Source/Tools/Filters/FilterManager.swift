//
//  FilterManager.swift
//  Soundprints
//
//  Created by Svit Zebec on 08/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

// MARK: - FilterManageDelegate

protocol FilterManageDelegate: class {
    
    func filterManagerUpdatedFilter(_ filter: Filter)
    
}

// MARK: - Filter Manager

class FilterManager {
    
    // MARK: - Variables
    
    private(set) static var filters: Filters = loadFilters()
    
    static weak var delegate: FilterManageDelegate?
    
    // MARK: - Filter management
    
    class func setFilter(_ filter: Filter) {
        if let type = filter as? Filters.SoundprintType {
            filters.type = type
        } else if let age = filter as? Filters.SoundprintAge {
            filters.age = age
        }
        saveFilters()
        
        delegate?.filterManagerUpdatedFilter(filter)
    }
    
    // MARK: - Filter loading and storing
    
    private class func loadFilters() -> Filters {
        guard let filtersData = UserDefaults.standard.object(forKey: Filters.defaultsKey) as? Data, let loadedFilters = try? JSONDecoder().decode(Filters.self, from: filtersData) else {
            return Filters.defaultFilters
        }
        
        return loadedFilters
    }
    
    private class func saveFilters(_ filtersToSave: Filters = filters) {
        guard let filtersData = try? JSONEncoder().encode(filters) else {
            return
        }
        
        UserDefaults.standard.set(filtersData, forKey: Filters.defaultsKey)
        filters = filtersToSave
    }
    
}

// MARK: - Filter protocol

protocol Filter {}

// MARK: - Filters structure

extension FilterManager {
    
    struct Filters: Codable {
        
        enum SoundprintType: String, Codable, Filter {
            case local
            case premium
        }
        
        enum SoundprintAge: String, Codable, Filter {
            case lastDay
            case allTime
        }
        
        var type: SoundprintType
        var age: SoundprintAge
        
        fileprivate static var defaultFilters: Filters {
            return Filters(type: .local, age: .allTime)
        }
        
        fileprivate static let defaultsKey = "filtersDefaults"
        
    }
    
}
