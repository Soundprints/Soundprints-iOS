//
//  Alert.swift
//  Soundprints
//
//  Created by Svit Zebec on 18/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class Alert {
    
    static func showAlert(title: String, inController controller: UIViewController) {
        self.showAlert(title: title, message: nil, inController: controller)
    }
    
    static func showAlert(title: String, message: String?, inController controller: UIViewController) {
        showAlert(title: title, message: message, inController: controller, completion: nil)
    }
    
    static func showAlert(title: String, message: String?, inController controller: UIViewController, confirmationTitle: String? = nil, completion: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: confirmationTitle ?? "OK", style: .cancel, handler: { (_) in
            completion?()
        }))
        controller.present(alertController, animated: true, completion: nil)
    }
    
}
