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
    @IBOutlet private weak var closeButtonImageView: UIImageView?
    
    // MARK: - Variables
    
    weak var delegate: SoundsListViewControllerDelegate?
    
    var soundsModel: SoundsModel? {
        didSet {
            soundsModel?.setState(.list)
        }
    }
    
    private var sounds: [Sound] = []
    
    private var lastTableViewContentYOffset: CGFloat = 0
    private var previousToLastTableViewContentYOffset: CGFloat = 0
    
    // MARK: - View Controller lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sounds = soundsModel?.sounds ?? []
        tableView?.reloadData()
        
        soundsModel?.listDelegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let closeButtonHeight = closeButtonImageView?.bounds.height {
            tableView?.contentInset.bottom = closeButtonHeight + 20
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonPressed(_ sender: Any) {
        delegate?.soundsListViewControllerShouldBeDismissed(sender: self)
    }
    
    // MARK: - Sounds inserting
    
    private func appendSoundsToList(_ soundsToInsert: [Sound]) {
        guard soundsToInsert.isEmpty == false else {
            return
        }
        
        if let currentContentOffset = tableView?.contentOffset {
            tableView?.setContentOffset(currentContentOffset, animated: false)
        }
        
        tableView?.beginUpdates()        
        let indexPaths = (sounds.count..<sounds.count+soundsToInsert.count).map { IndexPath(row: $0, section: 0) }
        sounds.append(contentsOf: soundsToInsert)
        tableView?.insertRows(at: indexPaths, with: .automatic)
        tableView?.endUpdates()
    }
    
    private func insertSound(_ soundToInsert: Sound, atIndex: Int) {
        tableView?.beginUpdates()        
        sounds.insert(soundToInsert, at: atIndex)
        tableView?.insertRows(at: [IndexPath(row: atIndex, section: 0)], with: .automatic)
        tableView?.endUpdates()
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SoundsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == sounds.count-1 {
            soundsModel?.fetchAndAppendNewSoundsPage()
        }
        
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

extension SoundsListViewController: SoundsModelDelegate {
    
    func soundsModel(_ sender: SoundsModel, fetchedNewSoundsPage newSoundsPage: [Sound], isReload: Bool) {
        if isReload {
            sounds = newSoundsPage
            // TODO: Improve reloading
            tableView?.reloadData()
        } else {
            appendSoundsToList(newSoundsPage)
        }
    }
    
    func soundModelCouldNotUploadSound(sender: SoundsModel) {
        // TODO: Alert user
    }
    
    func soundModel(_ sender: SoundsModel, uploadedSound: Sound, whichWasInsertedAtIndex insertedAtIndex: Int?) {
        if let insertedAtIndex = insertedAtIndex {
            insertSound(uploadedSound, atIndex: insertedAtIndex)
        }
    }
    
}
