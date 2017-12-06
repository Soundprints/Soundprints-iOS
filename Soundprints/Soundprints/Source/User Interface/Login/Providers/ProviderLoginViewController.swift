//
//  ProviderLoginViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 04/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

// MARK: - ProviderLoginViewControllerDelegate

protocol ProviderLoginViewControllerDelegate: class {
    
    func providerLoginViewController(_ sender: BaseViewController, didCompleteLoginWithSuccess success: Bool)
    func providerLoginViewControllerDidLogout(sender: BaseViewController)
    
}

// MARK: - ProviderLoginViewController

class ProviderLoginViewController: BaseViewController {
    
    // MARK: - Properties

    weak var delegate: ProviderLoginViewControllerDelegate?

}
