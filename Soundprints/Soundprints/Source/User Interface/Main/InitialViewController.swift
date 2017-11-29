//
//  InitialViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 29/11/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

class InitialViewController: BaseViewController {
    
    // MARK: - View controller lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handleRoutingFromViewDidAppear()
    }
    
    private func handleRoutingFromViewDidAppear() {
        // TODO: Add logic for checking whether the user is authenticated or should he be routed to the login screen
        
        let controller = R.storyboard.mainMap.mainMapViewController()!
        present(controller, animated: true, completion: nil)
    }
    
}
