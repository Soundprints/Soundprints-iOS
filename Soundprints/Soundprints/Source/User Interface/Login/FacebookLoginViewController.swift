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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Improve the positioning
        let loginButton = LoginButton(readPermissions: [.publicProfile, .email])
        loginButton.center = view.center
        loginButton.delegate = self
    }

}

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
