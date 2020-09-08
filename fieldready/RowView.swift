//
//  RowView.swift
//  fieldready
//
//  Created by Tom on 05/09/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit

class RowView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
	@IBOutlet var contentView: UIView!
	@IBOutlet var iconView: UIImageView!
	@IBOutlet var topLineView: UIView!
	@IBOutlet var bottomLineView: UIView!
	@IBOutlet var titleView: UILabel!
	@IBOutlet var checkmarkView: UIImageView!
		
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	private func commonInit() {
		//we're going to do stuff here!
		Bundle.main.loadNibNamed("RowView", owner: self, options: nil)
		addSubview(contentView)
		contentView.frame = self.bounds
		contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	}

	func setCompleted(completed: Bool) {
		if completed {
			checkmarkView.isHidden = false
			titleView.textColor = UIColor.init(named: "FRPurple")
			iconView.tintColor = UIColor.init(named: "FRPurple")
			//leave the line views as is... we don't know where this sits in relation
		} else {
			checkmarkView.isHidden = true
			titleView.textColor = UIColor.init(named: "FRLightestPurple")
			iconView.tintColor = UIColor.init(named: "FRLightestPurple")
			topLineView.isHidden = true //just to help out
			bottomLineView.isHidden = true
		}
	}
}
