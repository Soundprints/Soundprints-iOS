//
//  InteractionLockingContentControllerView.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

/// ContentControllerView subclass that makes sure that user interaction is disabled, while no content is set.
class InteractionLockingContentControllerView: ContentControllerView {
    
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
        isUserInteractionEnabled = false
    }
    
    // MARK: - Content VC controlls
    
    override func setViewController(controller: UIViewController?, animationStyle: ContentControllerView.AnimationStyle) {
        super.setViewController(controller: controller, animationStyle: animationStyle)
        
        isUserInteractionEnabled = controller != nil
    }
    
    override func clear() {
        super.clear()
        
        isUserInteractionEnabled = false
    }
    
}
