//
// This is a generated file, do not edit!
// Generated by R.swift, see https://github.com/mac-cain13/R.swift
//

import Foundation
import Rswift
import UIKit

/// This `R` struct is generated and contains references to static resources.
struct R: Rswift.Validatable {
  fileprivate static let applicationLocale = hostingBundle.preferredLocalizations.first.flatMap(Locale.init) ?? Locale.current
  fileprivate static let hostingBundle = Bundle(for: R.Class.self)
  
  static func validate() throws {
    try intern.validate()
  }
  
  /// This `R.color` struct is generated, and contains static references to 0 colors.
  struct color {
    fileprivate init() {}
  }
  
  /// This `R.file` struct is generated, and contains static references to 1 files.
  struct file {
    /// Resource file `Info.plist`.
    static let infoPlist = Rswift.FileResource(bundle: R.hostingBundle, name: "Info", pathExtension: "plist")
    
    /// `bundle.url(forResource: "Info", withExtension: "plist")`
    static func infoPlist(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.infoPlist
      return fileResource.bundle.url(forResource: fileResource)
    }
    
    fileprivate init() {}
  }
  
  /// This `R.font` struct is generated, and contains static references to 0 fonts.
  struct font {
    fileprivate init() {}
  }
  
  /// This `R.image` struct is generated, and contains static references to 4 images.
  struct image {
    /// Image `annotation-in-range-icon`.
    static let annotationInRangeIcon = Rswift.ImageResource(bundle: R.hostingBundle, name: "annotation-in-range-icon")
    /// Image `annotation-not-in-range-icon`.
    static let annotationNotInRangeIcon = Rswift.ImageResource(bundle: R.hostingBundle, name: "annotation-not-in-range-icon")
    /// Image `play-icon`.
    static let playIcon = Rswift.ImageResource(bundle: R.hostingBundle, name: "play-icon")
    /// Image `user-location-icon`.
    static let userLocationIcon = Rswift.ImageResource(bundle: R.hostingBundle, name: "user-location-icon")
    
    /// `UIImage(named: "annotation-in-range-icon", bundle: ..., traitCollection: ...)`
    static func annotationInRangeIcon(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.annotationInRangeIcon, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "annotation-not-in-range-icon", bundle: ..., traitCollection: ...)`
    static func annotationNotInRangeIcon(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.annotationNotInRangeIcon, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "play-icon", bundle: ..., traitCollection: ...)`
    static func playIcon(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.playIcon, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "user-location-icon", bundle: ..., traitCollection: ...)`
    static func userLocationIcon(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.userLocationIcon, compatibleWith: traitCollection)
    }
    
    fileprivate init() {}
  }
  
  /// This `R.nib` struct is generated, and contains static references to 0 nibs.
  struct nib {
    fileprivate init() {}
  }
  
  /// This `R.reuseIdentifier` struct is generated, and contains static references to 0 reuse identifiers.
  struct reuseIdentifier {
    fileprivate init() {}
  }
  
  /// This `R.segue` struct is generated, and contains static references to 0 view controllers.
  struct segue {
    fileprivate init() {}
  }
  
  /// This `R.storyboard` struct is generated, and contains static references to 4 storyboards.
  struct storyboard {
    /// Storyboard `LaunchScreen`.
    static let launchScreen = _R.storyboard.launchScreen()
    /// Storyboard `Login`.
    static let login = _R.storyboard.login()
    /// Storyboard `MainMap`.
    static let mainMap = _R.storyboard.mainMap()
    /// Storyboard `Main`.
    static let main = _R.storyboard.main()
    
    /// `UIStoryboard(name: "LaunchScreen", bundle: ...)`
    static func launchScreen(_: Void = ()) -> UIKit.UIStoryboard {
      return UIKit.UIStoryboard(resource: R.storyboard.launchScreen)
    }
    
    /// `UIStoryboard(name: "Login", bundle: ...)`
    static func login(_: Void = ()) -> UIKit.UIStoryboard {
      return UIKit.UIStoryboard(resource: R.storyboard.login)
    }
    
    /// `UIStoryboard(name: "Main", bundle: ...)`
    static func main(_: Void = ()) -> UIKit.UIStoryboard {
      return UIKit.UIStoryboard(resource: R.storyboard.main)
    }
    
    /// `UIStoryboard(name: "MainMap", bundle: ...)`
    static func mainMap(_: Void = ()) -> UIKit.UIStoryboard {
      return UIKit.UIStoryboard(resource: R.storyboard.mainMap)
    }
    
    fileprivate init() {}
  }
  
  /// This `R.string` struct is generated, and contains static references to 0 localization tables.
  struct string {
    fileprivate init() {}
  }
  
  fileprivate struct intern: Rswift.Validatable {
    fileprivate static func validate() throws {
      try _R.validate()
    }
    
    fileprivate init() {}
  }
  
  fileprivate class Class {}
  
  fileprivate init() {}
}

struct _R: Rswift.Validatable {
  static func validate() throws {
    try storyboard.validate()
  }
  
  struct nib {
    fileprivate init() {}
  }
  
  struct storyboard: Rswift.Validatable {
    static func validate() throws {
      try main.validate()
      try login.validate()
      try mainMap.validate()
    }
    
    struct launchScreen: Rswift.StoryboardResourceWithInitialControllerType {
      typealias InitialController = UIKit.UIViewController
      
      let bundle = R.hostingBundle
      let name = "LaunchScreen"
      
      fileprivate init() {}
    }
    
    struct login: Rswift.StoryboardResourceType, Rswift.Validatable {
      let bundle = R.hostingBundle
      let facebookLoginViewController = StoryboardViewControllerResource<FacebookLoginViewController>(identifier: "FacebookLoginViewController")
      let loginViewController = StoryboardViewControllerResource<LoginViewController>(identifier: "LoginViewController")
      let name = "Login"
      
      func facebookLoginViewController(_: Void = ()) -> FacebookLoginViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: facebookLoginViewController)
      }
      
      func loginViewController(_: Void = ()) -> LoginViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: loginViewController)
      }
      
      static func validate() throws {
        if _R.storyboard.login().facebookLoginViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'facebookLoginViewController' could not be loaded from storyboard 'Login' as 'FacebookLoginViewController'.") }
        if _R.storyboard.login().loginViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'loginViewController' could not be loaded from storyboard 'Login' as 'LoginViewController'.") }
      }
      
      fileprivate init() {}
    }
    
    struct main: Rswift.StoryboardResourceWithInitialControllerType, Rswift.Validatable {
      typealias InitialController = InitialViewController
      
      let bundle = R.hostingBundle
      let initialViewController = StoryboardViewControllerResource<InitialViewController>(identifier: "InitialViewController")
      let name = "Main"
      
      func initialViewController(_: Void = ()) -> InitialViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: initialViewController)
      }
      
      static func validate() throws {
        if _R.storyboard.main().initialViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'initialViewController' could not be loaded from storyboard 'Main' as 'InitialViewController'.") }
      }
      
      fileprivate init() {}
    }
    
    struct mainMap: Rswift.StoryboardResourceType, Rswift.Validatable {
      let bundle = R.hostingBundle
      let mainMapViewController = StoryboardViewControllerResource<MainMapViewController>(identifier: "MainMapViewController")
      let name = "MainMap"
      
      func mainMapViewController(_: Void = ()) -> MainMapViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: mainMapViewController)
      }
      
      static func validate() throws {
        if _R.storyboard.mainMap().mainMapViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'mainMapViewController' could not be loaded from storyboard 'MainMap' as 'MainMapViewController'.") }
      }
      
      fileprivate init() {}
    }
    
    fileprivate init() {}
  }
  
  fileprivate init() {}
}
