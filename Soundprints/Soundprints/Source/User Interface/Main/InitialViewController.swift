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
        
        //handleRoutingFromViewDidAppear()
    }
    
    // MARK: - Routing
    
    private func handleRoutingFromViewDidAppear() {
    
        if AuthenticationManager.isLoggedIn {
            let controller = R.storyboard.mainMap.mainMapViewController()!
            present(controller, animated: true, completion: nil)
        } else {
            let login = R.storyboard.login.loginViewController()!
            present(login, animated: true, completion: nil)
        }
    }
    
}
