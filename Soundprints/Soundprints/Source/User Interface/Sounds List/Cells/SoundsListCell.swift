//
//  SoundsListCell.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

// MARK: - SoundsListCellDelegate 

protocol SoundsListCellDelegate: class {
    
    func soundListCell(_ sender: SoundsListCell, requestsToPlaySound soundToPlay: Sound?)
    
}

class SoundsListCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet private weak var contentContainerView: UIView?
    @IBOutlet private weak var profileImageView: UIImageView?
    @IBOutlet private weak var playButton: UIButton?
    @IBOutlet private weak var playButtonImageView: UIImageView?
    @IBOutlet private weak var userDisplayNameLabel: UILabel?
    @IBOutlet private weak var durationAndDistanceLabel: UILabel?
    @IBOutlet private weak var timestampLabel: UILabel?
    
    // MARK: - Variables
    
    weak var delegate: SoundsListCellDelegate?
    
    var sound: Sound? {
        didSet {
            updateContent(withSound: sound)
        }
    }
    
    // MARK: - Content updating
    
    private func updateContent(withSound sound: Sound?) {
        if let profileImageUrl = sound?.userProfileImageUrl {
            profileImageView?.kf.setImage(with: URL(string: profileImageUrl))
        } else {
            profileImageView?.image = nil
        }
        userDisplayNameLabel?.text = sound?.userDisplayName
        durationAndDistanceLabel?.text = {
            guard let distanceValue = sound?.initialDistance else {
                return sound?.durationDisplayString()
            }
            guard let durationString = sound?.durationDisplayString() else {
                return sound?.initialDistance?.displayString()
            }
            return "\(durationString), \(distanceValue.displayString())"
        }()
        timestampLabel?.text = {
            guard let submissionIntervalString = sound?.timeSinceSubmissionDisplayString() else {
                return nil
            }
            return "left \(submissionIntervalString) ago"
        }()
    }
    
    // MARK: - Actions
    
    @IBAction func playButtonPressed(_ sender: Any) {
        
    }

}
