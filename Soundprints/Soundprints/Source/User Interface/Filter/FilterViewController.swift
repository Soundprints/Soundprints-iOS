//
//  FilterViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 08/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

// MARK: - FilterViewControllerDelegate

protocol FilterViewControllerDelegate: class {
    
    func filterViewControllerShouldBeDismissed(sender: FilterViewController)
    
}

// MARK: - FilterViewController

class FilterViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var typeFilterSwitch: BorderSwitch?
    @IBOutlet private weak var ageFilterSwitch: BorderSwitch?
    
    // MARK: - Variables
    
    weak var delegate: FilterViewControllerDelegate?
    
    // MARK: - View Controller lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateContent(withFilters: FilterManager.filters)
    }
    
    // MARK: - Filter content updating
    
    private func updateContent(withFilters filters: FilterManager.Filters) {
        typeFilterSwitch?.isOn = {
            switch filters.type {
            case .local: return false
            case .premium: return true
            }
        }()
        ageFilterSwitch?.isOn = {
            switch filters.age {
            case .lastDay: return false
            case .allTime: return true
            }
        }()
    }

    // MARK: - Actions
    
    @IBAction private func typeFilterValueChanged(_ sender: UISwitch) {
        let newTypeFilterValue: FilterManager.Filters.SoundprintType = sender.isOn ? .premium : .local
        FilterManager.setFilter(newTypeFilterValue)
    }
    
    @IBAction private func ageFilterValueChanged(_ sender: UISwitch) {
        let newTypeFilterValue: FilterManager.Filters.SoundprintAge = sender.isOn ? .allTime : .lastDay
        FilterManager.setFilter(newTypeFilterValue)
    }
    
    @IBAction private func closeButtonPressed(_ sender: Any) {
        delegate?.filterViewControllerShouldBeDismissed(sender: self)
    }
    
}
