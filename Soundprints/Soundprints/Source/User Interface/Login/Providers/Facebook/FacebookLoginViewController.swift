//
//  FacebookLoginViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 04/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit
import FacebookLogin

class FacebookLoginViewController: ProviderLoginViewController {
    
    // MARK: - Properties
    
    private lazy var fbLoginButton: LoginButton = {
        let loginButton = LoginButton(readPermissions: [.publicProfile, .email])
        loginButton.delegate = self
        view.addSubview(loginButton)
        return loginButton
    }()
    
    // MARK: - View controller lifecycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        fbLoginButton.center = CGPoint(x: view.center.x, y: view.bounds.height - 80.0)
    }
    
}

// MARK: - LoginButtonDelegate

extension FacebookLoginViewController: LoginButtonDelegate {
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        let success: Bool = {
            switch result {
            case .success: return true
            case .cancelled, .failed: return false
            }
        }()
        delegate?.providerLoginViewController(self, didCompleteLoginWithSuccess: success)
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        delegate?.providerLoginViewControllerDidLogout(sender: self)
    }
    
}
