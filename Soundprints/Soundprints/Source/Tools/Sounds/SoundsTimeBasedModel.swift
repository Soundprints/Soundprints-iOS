//
//  SoundsTimeBasedModel.swift
//  Soundprints
//
//  Created by Svit Zebec on 20/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

// MARK: - SoundsTimeBasedModelDelegate

protocol SoundsTimeBasedModelDelegate: class {
    
    func soundsTimeBasedModel(_ sender: SoundsTimeBasedModel, fetchedNewSoundsPage newSoundsPage: [Sound], isReload: Bool)
    
}

// MARK: - SoundsTimeBasedModel

class SoundsTimeBasedModel {
    
    weak var delegate: SoundsTimeBasedModelDelegate?
    
    var isShowingList: Bool = false
    
    private(set) var sounds: [Sound] = []
    
    private(set) var currentFetchedUpToDate: Date?
    
    weak private var refreshTimer: Timer?
    
    private var fetchSoundsFromOnlyLastDay: Bool {
        return FilterManager.filters.age == .lastDay
    }
    private var soundTypeToFetch: Sound.SoundType {
        return Sound.SoundType.fromFilter(FilterManager.filters.type)
    }
    
    private var fetchNextPageLocked = false
    
    private var lastInvalidationDate: Date?
    private var fetchInvalidated = false
    private var sinceDate: Date?
    
    // MARK: - Constants
    
    private let itemsPerPage: Int = 50
    private let timeIntervalInvalidationTreshold: TimeInterval = 60
    
    // MARK: - Initialization
    
    init() {
        initializeTimer()
    }
    
    // MARK: - Deinitialization
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Timer
    
    private func initializeTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(refreshTimerFired), userInfo: nil, repeats: true)
        if let refreshTimer = refreshTimer {
            RunLoop.current.add(refreshTimer, forMode: .commonModes)
        }
    }
    
    @objc private func refreshTimerFired() {
        if shouldInvalidate() {
            invalidate()
        }
    }
    
    // MARK: - Invalidation
    
    private func invalidate() {
        lastInvalidationDate = Date()
        sinceDate = nil
        sounds = []
        currentFetchedUpToDate = nil
        fetchNextPageLocked = false
        fetchInvalidated = true
        fetchAndAppendNewSoundsPage(afterInvalidation: true)
    }
    
    private func shouldInvalidate() -> Bool {
        
        // If the model is marked as showing sounds list, it should not be invalidated.
        guard isShowingList == false else {
            return false
        }
        
        // If the model hasn't been invalidated in last 'timeIntervalInvalidationTreshold' seconds, it should be.
        guard let lastInvalidationDate = lastInvalidationDate, Date().timeIntervalSince(lastInvalidationDate) < timeIntervalInvalidationTreshold else {
            return true
        }
        
        return false
    }
    
    // MARK: - Sounds fetching
    
    func fetchAndAppendNewSoundsPage(afterInvalidation: Bool = false) {
        guard fetchNextPageLocked == false else {
            return
        }
        
        fetchNextPageLocked = true
        let isReload = (currentFetchedUpToDate == nil && sounds.isEmpty) || afterInvalidation
        
        if fetchSoundsFromOnlyLastDay {
            if sinceDate == nil {
                sinceDate = Date().addingTimeInterval(-60*60*24)
            }
        } else {
            sinceDate = nil
        }
        
        Sound.fetchTimeBasedSounds(withSoundType: soundTypeToFetch, upToDate: currentFetchedUpToDate, sinceDate: sinceDate, limit: itemsPerPage) { sounds, error in
            guard self.fetchInvalidated == false || afterInvalidation else {
                return
            }
            
            if error == nil, let sounds = sounds {
                
                let reversedExistingSounds = self.sounds.reversed()
                let filteredSounds = sounds.filter({ newSound in
                    return !reversedExistingSounds.contains(where: { existingSound in
                        return newSound.id == existingSound.id
                    })
                })
                
                if afterInvalidation {
                    self.sounds = sounds
                } else {
                    self.sounds.append(contentsOf: filteredSounds)
                }
                
                if let newFetchedUpToDate = filteredSounds.last?.submissionDate {
                    self.currentFetchedUpToDate = newFetchedUpToDate
                }
                
                DispatchQueue.main.async {
                    self.delegate?.soundsTimeBasedModel(self, fetchedNewSoundsPage: filteredSounds, isReload: isReload  )
                }
            }
            self.fetchInvalidated = false
            self.fetchNextPageLocked = false
        }
        
    }
    
}

// MARK: - FilterManagerDelegate

extension SoundsTimeBasedModel: FilterManagerDelegate {
    
    func filterManagerUpdatedFilter(_ filter: Filter) {
        // For now just invalidate the whole model
        invalidate()
    }
    
}
