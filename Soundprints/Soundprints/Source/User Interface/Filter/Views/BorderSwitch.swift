//
//  BorderSwitch.swift
//  Soundprints
//
//  Created by Svit Zebec on 08/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

class BorderSwitch: UISwitch {
    
    // MARK: - Variables
    
    var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    var borderWidth: CGFloat = 2 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        layer.cornerRadius = 16
        layer.borderWidth = borderWidth
        layer.borderColor = thumbTintColor?.cgColor
    }
    
}
