//
//  SoundsListViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

// MARK: - SoundsListViewControllerDelegate

protocol SoundsListViewControllerDelegate: class {
    
    func soundsListViewControllerShouldBeDismissed(sender: SoundsListViewController)
    func soundsListViewController(_ sender: SoundsListViewController, requestsToPlaySound soundToPlay: Sound)
    
}

// MARK: - SoundsListViewController

class SoundsListViewController: BaseViewController {
    
    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView?
    
    // MARK: - Variables
    
    weak var delegate: SoundsListViewControllerDelegate?
    
    var sounds: [Sound] = []
    
    // MARK: - Actions
    
    @IBAction private func closeButtonPressed(_ sender: Any) {
        delegate?.soundsListViewControllerShouldBeDismissed(sender: self)
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SoundsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.soundsListCell, for: indexPath) {
            let sound = sounds[indexPath.row]
            cell.sound = sound
            cell.delegate = self
            
            return cell
        }
        
        return UITableViewCell()
    }
    
}

// MARK: - SoundsListCellDelegate

extension SoundsListViewController: SoundsListCellDelegate {
    
    func soundListCell(_ sender: SoundsListCell, requestsToPlaySound soundToPlay: Sound?) {
        guard let soundToPlay = soundToPlay else {
            return
        }
        
        delegate?.soundsListViewController(self, requestsToPlaySound: soundToPlay)
    }
    
}
