//
//  LoginViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 04/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

class LoginViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var providerLoginContentControllerView: ContentControllerView?
    
    // MARK: - View controller lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handleRoutingFromViewWillAppear()
    }
    
    // MARK: - Routing
    
    private func handleRoutingFromViewWillAppear() {
        switch AuthenticationManager.provider {
        case .facebook:
            let facebookLogin = R.storyboard.login.facebookLoginViewController()!
            facebookLogin.delegate = self
            providerLoginContentControllerView?.setViewController(controller: facebookLogin, animationStyle: .none)
        }
    }
    
}

// MARK: - ProviderLoginViewControllerDelegate

extension LoginViewController: ProviderLoginViewControllerDelegate {
    
    func providerLoginViewController(_ sender: BaseViewController, didCompleteLoginWithSuccess success: Bool) {
        if success {
            dismiss(animated: true, completion: nil)
        } else {
            // TODO: Show alert or something
        }
    }
    
    func providerLoginViewControllerDidLogout(sender: BaseViewController) {
        // Do something here if needed
    }
    
}
