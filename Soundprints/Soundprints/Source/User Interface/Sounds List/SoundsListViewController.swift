//
//  SoundsListViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

protocol SoundsListViewControllerDelegate: class {
    
    func soundsListViewControllerShouldBeDismissed(sender: SoundsListViewController)
    
}

class SoundsListViewController: BaseViewController {
    
    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView?
    
    // MARK: - Variables
    
    weak var delegate: SoundsListViewControllerDelegate?
    
    var sounds: [Sound] = []
    
    // MARK: - Actions
    
    @IBAction func closeButtonPressed(_ sender: Any) {
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
            
            return cell
        }
        
        return UITableViewCell()
    }
    
}
