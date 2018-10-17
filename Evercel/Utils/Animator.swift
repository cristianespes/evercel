//
//  Animator.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 16/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit

class Animator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 1.0
    var presenting = true
    var originFrame = CGRect.zero
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let noteDetailView = presenting ? toView : transitionContext.view(forKey: .from)!
        
        let initialFrame = presenting ? originFrame : noteDetailView.frame
        let finalFrame = presenting ? noteDetailView.frame : originFrame
        
        let xScaleFactor = presenting
            ? initialFrame.width / finalFrame.width
            : finalFrame.width / initialFrame.width
        
        let yScaleFactor = presenting
            ? initialFrame.height / finalFrame.height
            : finalFrame.height / initialFrame.height
        
        let scaleTransform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
        
        if presenting {
            noteDetailView.transform = scaleTransform
            noteDetailView.center = CGPoint(x: initialFrame.midX, y: initialFrame.midY)
            noteDetailView.clipsToBounds = true
        }
        
        containerView.addSubview(toView)
        containerView.bringSubviewToFront(noteDetailView)
        
        UIView.animate(
            withDuration: duration,
            delay:0.0,
            usingSpringWithDamping: 0.4,
            initialSpringVelocity: 0.0,
            animations: {
                noteDetailView.transform = self.presenting ?
                    CGAffineTransform.identity : scaleTransform
                noteDetailView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
        },
            completion: { _ in
                transitionContext.completeTransition(true)
        }
        )
    }
    
}
