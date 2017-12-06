//
//  KaminoUIView+HiddenAnimations.swift
//
//  Created by Matic Oblak on 9/5/17.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

extension KaminoUIView {

    func animateHiden(hidden: Bool, duration: TimeInterval, completion: (() -> Void)? = nil) {
        
        if hidden == false {
            self.view.isHidden = false
        }
        
        UIView.animate(withDuration: duration, animations: { 
            self.view.alpha = hidden ? 0.0 : 1.0
        }) { (_) in
            self.view.isHidden = hidden
            completion?()
        }
        
    }
    
    static func animate(views: [UIView?], hidden: Bool, duration: TimeInterval, completion: (() -> Void)? = nil) {
        
        if hidden == false {
            views.forEach { $0?.isHidden = false }
        }
        
        UIView.animate(withDuration: duration, animations: {
            views.forEach { $0?.alpha = hidden ? 0.0 : 1.0 }
        }) { (_) in
            views.forEach { $0?.isHidden = hidden }
            completion?()
        }
        
    }
    
    typealias ViewFlag = (view: UIView?, flag: Bool)
    static func animateHidden(views: [ViewFlag], duration: TimeInterval, completion: (() -> Void)? = nil) {
        
        views.forEach { if $0.flag == false { $0.view?.isHidden = false } }
        
        UIView.animate(withDuration: duration, animations: {
            views.forEach { $0.view?.alpha = $0.flag ? 0.0 : 1.0 }
        }) { (_) in
            views.forEach { $0.view?.isHidden = $0.flag }
            completion?()
        }
        
    }
    
}
