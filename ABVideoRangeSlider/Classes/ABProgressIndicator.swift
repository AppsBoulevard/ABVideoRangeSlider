//
//  ABProgressIndicator.swift
//  Pods
//
//  Created by Oscar J. Irun on 2/12/16.
//
//

import UIKit

class ABProgressIndicator: UIView {
    
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let bundle = Bundle(for: ABStartIndicator.self)
        let image = UIImage(named: "ProgressIndicator", in: bundle, compatibleWith: nil)
        imageView.frame = self.bounds
        imageView.image = image
        imageView.contentMode = UIViewContentMode.scaleToFill
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.bounds
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = CGRect(x: -self.frame.size.width / 2,
                           y: 0,
                           width: self.frame.size.width * 2,
                           height: self.frame.size.height)
        if frame.contains(point){
            return self
        }else{
            return nil
        }
    }
}
