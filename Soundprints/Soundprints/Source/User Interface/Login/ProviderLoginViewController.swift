//
//  ProviderLoginViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 04/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

protocol ProviderLoginViewControllerDelegate: class {
    
    func providerLoginViewController(_ sender: BaseViewController, didCompleteLoginWithSuccess success: Bool)
    func providerLoginViewControllerDidLogout(sender: BaseViewController)
    
}

class ProviderLoginViewController: BaseViewController {

    weak var delegate: ProviderLoginViewControllerDelegate?

}
