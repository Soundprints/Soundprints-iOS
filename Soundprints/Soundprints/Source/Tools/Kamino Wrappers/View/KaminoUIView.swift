//
//  KaminoUIView.swift
//
//  Created by Matic Oblak on 9/5/17.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

extension UIView {
    
    /// Used for static access. The lowercase is by design so you call UIView.kamino.func
    typealias kamino = KaminoUIView
    
    var kamino: KaminoUIView {
        return KaminoUIView(view: self)
    }
    
}

class KaminoUIView {

    var view: UIView
    
    init(view: UIView) {
        self.view = view
    }
    
}
