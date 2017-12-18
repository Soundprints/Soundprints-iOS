import UIKit

protocol ContentCotrollerViewDelegate: class {
    
    func contentControllerView(_ sender: ContentControllerView, didSet viewController: UIViewController?, animated: Bool)
    
}

class ContentControllerView: UIView {
    
    @IBOutlet weak var parentViewController: UIViewController?
    private(set) var currentController: UIViewController?
    
    weak var delegate: ContentCotrollerViewDelegate?
    
    private var addedConstraints: [NSLayoutConstraint] = [NSLayoutConstraint]()
    
    let transitionDuration: TimeInterval = 0.4
    
    func setViewController(controller: UIViewController?, animationStyle: AnimationStyle = .none) {
        guard let parentViewController = parentViewController else {
            print("ContentControllerView error: You need to set a parentViewController to add a new view controller")
            return
        }
        
        if controller?.view != currentController?.view {
            
            currentController?.willMove(toParentViewController: nil) // Notify the current controller it will move off the parent
            controller?.willMove(toParentViewController: parentViewController) // Notify the new controller it will move to the parent
            if let controller = controller {
                parentViewController.addChildViewController(controller) // Add child controller
            }
            let toRemove = addedConstraints
            addedConstraints.removeAll()
            
            let frames: (targetStartFrame: CGRect, targetEndFrame: CGRect, sourceEndFrame: CGRect, sourceFinalFrame: CGRect) = {
                switch animationStyle {
                case .fade:
                    return (
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height)
                    )
                case .fromLeft:
                    return (
                        CGRect(x: -self.frame.size.width, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: self.frame.size.width, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height)
                    )
                case .fromRight:
                    return (
                        CGRect(x: self.frame.size.width, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: -self.frame.size.width, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height)
                    )
                case .none:
                    return (
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height),
                        CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height)
                    )
                }
            }()
            
            let alphas: (targetStartAlpha: CGFloat, targetEndAlpha: CGFloat, sourceEndAlpha: CGFloat, sourceFinalAlpha: CGFloat) = {
                switch animationStyle {
                case .fade: return (0.0, 1.0, 0.0, 1.0)
                default: return (1.0, 1.0, 1.0, 1.0)
                }
            }()
            
            controller?.view.translatesAutoresizingMaskIntoConstraints = false // Disable this to add custom constraints
            if let controller = controller {
                self.addSubview(controller.view) // Add as subview
                
                
                addedConstraints.append(NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: controller.view, attribute: .left, multiplier: 1.0, constant: 0.0))
                addedConstraints.append(NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: controller.view, attribute: .right, multiplier: 1.0, constant: 0.0))
                addedConstraints.append(NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: controller.view, attribute: .top, multiplier: 1.0, constant: 0.0))
                addedConstraints.append(NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: controller.view, attribute: .bottom, multiplier: 1.0, constant: 0.0))
                
                // Assign new constraints
                self.addConstraints(addedConstraints)
            }
            
            
            self.layoutIfNeeded()
            toRemove.forEach { self.removeConstraint($0) }
            self.currentController?.view.translatesAutoresizingMaskIntoConstraints = true
            
            controller?.view.frame = frames.targetStartFrame
            controller?.view.alpha = alphas.targetStartAlpha
            
            
            UIView.animate(withDuration: animationStyle == .none ? 0.0 : transitionDuration, delay: 0.0, options: [], animations: {
                controller?.view.frame = frames.targetEndFrame
                controller?.view.alpha = alphas.targetEndAlpha
                self.currentController?.view.frame = frames.sourceEndFrame
                self.currentController?.view.alpha = alphas.sourceEndAlpha
            }, completion: { _ in
                self.currentController?.view.removeFromSuperview()
                self.currentController?.didMove(toParentViewController: nil) // Notify the current controller it did move off the parent
                self.currentController?.view.frame = frames.sourceFinalFrame
                self.currentController?.view.alpha = alphas.sourceFinalAlpha
                
                self.currentController?.removeFromParentViewController() // remove the current controller from parrent
                controller?.didMove(toParentViewController: parentViewController) // Notify the new controller it did move to the parent
                
                self.currentController = controller
                self.setNeedsLayout()
                self.layoutIfNeeded()
                controller?.viewDidLayoutSubviews()
                
                self.delegate?.contentControllerView(self, didSet: controller, animated: animationStyle != .none)
            })
            
        }
    }
    
    func clear() {
        guard currentController != nil else {
            return
        }
        
        setViewController(controller: nil)
    }
    
}

extension ContentControllerView {
    
    enum AnimationStyle {
        case none
        case fade
        case fromLeft
        case fromRight
    }
    
}
