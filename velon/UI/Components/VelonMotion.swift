//
//  VelonMotion.swift
//  velon
//

import UIKit

enum VelonMotion {
    static func staggerIn(views: [UIView], fromY: CGFloat = 28, baseDelay: TimeInterval = 0.05) {
        for (index, view) in views.enumerated() {
            view.alpha = 0
            view.transform = CGAffineTransform(translationX: 0, y: fromY).scaledBy(x: 0.96, y: 0.96)
            UIView.animate(
                withDuration: 0.55,
                delay: Double(index) * baseDelay,
                usingSpringWithDamping: 0.78,
                initialSpringVelocity: 0.6,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                view.alpha = 1
                view.transform = .identity
            }
        }
    }

    static func pop(_ view: UIView) {
        view.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0.9,
            options: [.allowUserInteraction]
        ) {
            view.transform = .identity
        }
    }

    static func press(_ view: UIView, down: Bool) {
        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            view.transform = down ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            view.alpha = down ? 0.92 : 1
        }
    }

    static func shimmerBorder(on layer: CALayer) {
        let glow = CABasicAnimation(keyPath: "shadowOpacity")
        glow.fromValue = 0.12
        glow.toValue = 0.4
        glow.duration = 1.6
        glow.autoreverses = true
        glow.repeatCount = .infinity
        layer.add(glow, forKey: "glowPulse")
    }
}

final class VelonPushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.42
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        if isPresenting {
            container.addSubview(toView)
            toView.alpha = 0
            toView.transform = CGAffineTransform(translationX: container.bounds.width * 0.18, y: 0)
                .scaledBy(x: 0.94, y: 0.94)
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.5, options: []) {
                toView.alpha = 1
                toView.transform = .identity
                fromView.transform = CGAffineTransform(translationX: -container.bounds.width * 0.08, y: 0).scaledBy(x: 0.98, y: 0.98)
                fromView.alpha = 0.7
            } completion: { finished in
                fromView.transform = .identity
                fromView.alpha = 1
                transitionContext.completeTransition(finished)
            }
        } else {
            container.insertSubview(toView, belowSubview: fromView)
            toView.transform = CGAffineTransform(translationX: -container.bounds.width * 0.08, y: 0)
            UIView.animate(withDuration: 0.36, delay: 0, options: [.curveEaseInOut]) {
                fromView.transform = CGAffineTransform(translationX: container.bounds.width * 0.2, y: 0)
                fromView.alpha = 0
                toView.transform = .identity
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }
}

final class VelonNavigationDelegate: NSObject, UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push: return VelonPushAnimator(isPresenting: true)
        case .pop: return VelonPushAnimator(isPresenting: false)
        default: return nil
        }
    }
}
