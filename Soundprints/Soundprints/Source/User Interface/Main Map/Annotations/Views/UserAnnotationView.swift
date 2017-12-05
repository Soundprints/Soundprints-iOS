//
//  UserAnnotationView.swift
//  Soundprints
//
//  Created by Svit Zebec on 05/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit
import Mapbox

class UserAnnotationView: MGLUserLocationAnnotationView {
    
    // MARK: - Variables
    
    var userPositionImageView: UIImageView?
    
    // MARK: - Initializers
    
    convenience init(reuseIdentifier: String?, frame: CGRect) {
        self.init(reuseIdentifier: reuseIdentifier)
        
        let bounds = CGRect(origin: .zero, size: frame.size)
        
        self.frame = frame
        backgroundColor = .clear
        
        let userPositionImageView = UIImageView(frame: bounds)
        userPositionImageView.image = R.image.userLocationIcon()
        
        addSubview(userPositionImageView)
        
        self.userPositionImageView = userPositionImageView
    }
    
}
