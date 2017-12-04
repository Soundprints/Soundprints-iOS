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
        
        if AuthenticationManager.isLoggedIn {
            // TODO: Show the main screen
            
        } else {
            let login = R.storyboard.login.loginViewController()!
            present(login, animated: true, completion: nil)
        }
    }

}
