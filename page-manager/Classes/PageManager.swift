//
//  PageManager.swift
//  page-manager
//
//  Created by policp on 2018/9/19.
//

import UIKit

/// Push animation effect
///
/// - system: Default system animation
/// - present: presnt animation
/// - fade: fade in and fade out
/// - scale: zoom
/// - circleScale: circle zoom
public enum PushAnimator {
    case system
    case present
    case fade
    case scale
    case circleScale
}

/// If the current window's rootviewcontroller is a UIViewController instance holding a tabBarController then it should follow this protocol
public protocol PageProtocol {
    func pageTopViewController() -> UIViewController
}

open class PageManager: NSObject, UINavigationControllerDelegate {
    
    public static let share = PageManager()
    
    /// You can pass the parameters to the page through this closure.
    public typealias CompleteClosure = (_ controller: UIViewController) -> Void
    
    /// push animation type
    var pushAnimator: PushAnimator?
    
    private override init() {
        super.init()
    }
    
    /// Get the currently displayed page instance
    ///
    /// - Returns: instance
    public func currentTopViewController() -> UIViewController {
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        return (rootViewController?.getTopViewController())!
    }
    
    /// Alternative to native page push
    ///
    /// - Parameters:
    ///   - pageName: page name
    ///   - animation: Whether to display animation，default is true
    ///   - animatorType: animation type
    ///   - completeCallBack:
    public func push(
        _ pageName: String!,
        _ animation: Bool? = true,
        pushAnimator animatorType: PushAnimator? = .system,
        complete completeCallBack: @escaping CompleteClosure = PageManager.defaultComplete
        ) {
        let destinationVC = self.getDestinationVC(with: pageName!)
        completeCallBack(destinationVC!)
        destinationVC?.hidesBottomBarWhenPushed = true
        let nav = getNearNav()
        if animatorType == .system {
            nav?.delegate = nil
        } else {
            nav?.delegate = self
        }
        pushAnimator = animatorType
        nav?.pushViewController(destinationVC!, animated: animation!)
    }
    
    public func present(
        _ pageName: String!,
        _ animation: Bool? = true,
        finished completeCallBack: @escaping CompleteClosure = PageManager.defaultComplete
        ){
        let destinationVC = self.getDestinationVC(with: pageName!)
        completeCallBack(destinationVC!)
        self.currentTopViewController().present(destinationVC!, animated: animation!, completion: nil)
    }
    
    /// Alternative to native page pop
    ///
    /// - Parameters:
    ///   - pageName: page name ，default is last page
    ///   - animation:
    ///   - finishedCallBack:
    public func pop(
        _ pageName: String? = nil,
        _ animation: Bool? = true,
        finished finishedCallBack: @escaping CompleteClosure = PageManager.defaultComplete
        ) {
        let nav = self.getNearNav()
        if nav != nil {
            if (nav?.viewControllers.count)! < 2 {
                print("无页面返回")
                return
            }
            var destinationVC: UIViewController?
            if pageName != nil {
                let cls = self.getClass(with: pageName!)
                if cls == nil {
                    return
                }
                for vc in (nav?.viewControllers)! {
                    if vc.isKind(of: cls!) {
                        destinationVC = vc
                    }
                }
                finishedCallBack(destinationVC!)
                nav?.popToViewController(destinationVC!, animated: animation!)
            } else {
                let currentIndex = nav?.viewControllers.index(of: self.currentTopViewController())
                destinationVC = nav?.viewControllers[currentIndex! - 1]
                finishedCallBack(destinationVC!)
                nav?.popViewController(animated: animation!)
            }
        } else {
            let destinationVC = self.currentTopViewController()
            if let _ = destinationVC.presentingViewController {
                destinationVC.dismiss(animated: animation!, completion: nil)
            } else {
                if let nav = destinationVC.navigationController {
                    nav.popViewController(animated: animation!)
                }
            }
        }
        
    }
    
    /// Get the navigation stack
    ///
    /// - Returns: nav
    private func getNearNav() -> UINavigationController? {
        var destinationVc = self.currentTopViewController()
        while !(destinationVc.isKind(of: UINavigationController.self)) {
            if let presenting = destinationVc.presentingViewController {
                if presenting.isKind(of: UINavigationController.self) {
                    destinationVc = (presenting as! UINavigationController).topViewController!
                }
            } else {
                break;
            }
        }
        return destinationVc.navigationController
    }
    
    public final class func defaultComplete(_ controller: UIViewController) {
        
    }
    
    private func getClass(with pageName: String!) -> UIViewController.Type? {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let cls = NSClassFromString(appName+"."+pageName) as? UIViewController.Type
        return cls
    }
    
    private func getDestinationVC(with pageName:String!) -> UIViewController!{
        let cls = self.getClass(with: pageName)
        var destinationVC: UIViewController!
        if cls != nil {
            let hasNib = Bundle.main.path(forResource: pageName, ofType: "nib")
            if hasNib != nil {
                destinationVC = cls?.init(nibName: pageName, bundle: Bundle.main)
            } else {
                destinationVC = cls?.init()
            }
        } else {
            destinationVC = self.getErrorPage()
        }
        return destinationVC
    }
    
    private func getErrorPage() -> UIViewController! {
        let destinationVC = UIViewController.init()
        destinationVC.view.backgroundColor = UIColor.white
        destinationVC.title = "页面不存在"
        return destinationVC
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let navAnimator = NavAnimator.init(operation: operation, pushType: pushAnimator!)
        return navAnimator
    }
}

extension UIViewController {
    public func getTopViewController() -> UIViewController {
        if let presented = self.presentedViewController,self.isKind(of: UIAlertController.self) {
            return presented.getTopViewController()
        } else if self.isKind(of: UITabBarController.self) {
            let seletedVC = self as? UITabBarController
            return seletedVC!.selectedViewController!.getTopViewController()
        } else if self.isKind(of: UINavigationController.self) {
            let nav = (self as? UINavigationController)!
            return (nav.topViewController?.getTopViewController())!
        } else if let vc = self as? PageProtocol {
            return vc.pageTopViewController().getTopViewController()
        }
        return self
    }
}

/// translation animation class
class NavAnimator: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    
    var duration = 0.5
    var operation: UINavigationControllerOperation = .push
    var animatorType: PushAnimator = .present
    
    private var navTransitionContext: UIViewControllerContextTransitioning?
    
    init(operation operationType: UINavigationControllerOperation, pushType pushAniamtor: PushAnimator) {
        operation = operationType
        animatorType = pushAniamtor
    }
    
    private var thumbnailFrame = CGRect.zero
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        navTransitionContext = transitionContext
        switch animatorType {
        case .system:
            return
        case .present:
            self.present(transitionContext)
        case .fade:
            self.fade(transitionContext)
        case .scale:
            self.scale(transitionContext)
        case .circleScale:
            self.circleScale(transitionContext)
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        navTransitionContext?.completeTransition(flag)
    }
    
    private func present(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        var animatedView: UIView!
        var destinationView: UIView!
        var destinationFrame: CGRect
        
        if operation == .push {
            animatedView = transitionContext.view(forKey: .to)!
            destinationView = transitionContext.view(forKey: .from)!
            animatedView.frame = CGRect(x: 0.0, y: destinationView.frame.height, width: destinationView.frame.width, height: destinationView.frame.height)
            destinationFrame = destinationView.bounds
            containerView.addSubview(animatedView)
        } else {
            animatedView = transitionContext.view(forKey: .from)!
            destinationView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
            destinationFrame = CGRect(x: 0.0, y: animatedView.frame.height, width: animatedView.frame.width, height: animatedView.frame.height)
            containerView.addSubview(destinationView)
            containerView.addSubview(animatedView)
        }
        
        UIView.animate(withDuration: self.duration, delay: 0.0, options: .curveEaseOut, animations: {
            animatedView.frame = destinationFrame
        }) { (finished) in
            transitionContext.completeTransition(finished)
        }
    }
    
    private func fade(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        var animatedView: UIView!
        var destinationView: UIView!
        var alpha: CGFloat = 0.0
        
        if operation == .push {
            destinationView = transitionContext.view(forKey: .from)
            animatedView = transitionContext.view(forKey: .to)
            animatedView.alpha = 0
            alpha = 1.0
            containerView.addSubview(animatedView)
        } else {
            destinationView = transitionContext.view(forKey: .to)
            animatedView = transitionContext.view(forKey: .from)
            alpha = 0
            containerView.addSubview(destinationView)
            containerView.addSubview(animatedView)
        }
        
        UIView.animate(withDuration: self.duration, animations: {
            animatedView.alpha = alpha
        }) { (finished) in
            transitionContext.completeTransition(finished)
        }
    }
    
    private func scale(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        var animatedView: UIView!
        var destinationView: UIView!
        
        var destinationFrame = CGRect.zero
        
        if operation == .push {
            animatedView = transitionContext.view(forKey: .to)
            destinationView = transitionContext.view(forKey: .from)
            animatedView.frame = CGRect(x: destinationView.frame.size.width/2, y: destinationView.frame.size.height/2, width: 0, height: 0)
            destinationFrame = destinationView.frame
            containerView.addSubview(animatedView)
        } else {
            animatedView = transitionContext.view(forKey: .from)
            destinationView = transitionContext.view(forKey: .to)
            destinationFrame =  CGRect(x: destinationView.frame.size.width/2, y: destinationView.frame.size.height/2, width: 0, height: 0)
            containerView.addSubview(destinationView)
            containerView.addSubview(animatedView)
        }
        
        UIView.animate(withDuration: self.duration, animations: {
            animatedView.frame = destinationFrame
        }) { (finished) in
            transitionContext.completeTransition(finished)
        }
    }
    
    private func circleScale(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        var animatedView: UIView!
        var destinationView: UIView!
        
        var startPath: UIBezierPath!
        var endPath: UIBezierPath!
        
        if operation == .push {
            animatedView = transitionContext.view(forKey: .to)
            destinationView = transitionContext.view(forKey: .from)
            
            let center = CGPoint(x: destinationView.frame.size.width/2, y: destinationView.frame.size.height/2)
            let radiu = sqrt(pow(center.x*2, 2) + pow(center.y*2, 2))/2
            
            startPath = UIBezierPath(ovalIn: CGRect(x: center.x, y: center.y, width: 0, height: 0))
            endPath = UIBezierPath(ovalIn: CGRect(x: center.x - radiu, y: center.y - radiu, width: radiu*2, height: radiu*2))
            
            containerView.addSubview(animatedView)
        } else {
            animatedView = transitionContext.view(forKey: .from)
            destinationView = transitionContext.view(forKey: .to)
            
            let center = CGPoint(x: destinationView.frame.size.width/2, y: destinationView.frame.size.height/2)
            let radiu = sqrt(pow(center.x*2, 2) + pow(center.y*2, 2))/2
            
            startPath = UIBezierPath(ovalIn: CGRect(x: center.x - radiu, y: center.y - radiu, width: radiu*2, height: radiu*2))
            endPath = UIBezierPath(ovalIn: CGRect(x: center.x, y: center.y, width: 0, height: 0))
            
            containerView.addSubview(destinationView)
            containerView.addSubview(animatedView)
        }
        
        let shaplayer = CAShapeLayer()
        shaplayer.path = endPath.cgPath
        animatedView.layer.mask = shaplayer
        
        let baseAnimation = CABasicAnimation(keyPath: "path")
        baseAnimation.fromValue = startPath.cgPath
        baseAnimation.toValue = endPath.cgPath
        baseAnimation.duration = duration
        baseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        baseAnimation.delegate = self
        shaplayer.add(baseAnimation, forKey: "path")
    }
    
}
