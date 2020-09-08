//
//  DetailView.swift
//  fieldready
//
//  Created by Tom on 05/09/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit

class DetailView: UIView {

	@IBOutlet var contentView: UIView!
	
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
		Bundle.main.loadNibNamed("DetailView", owner: self, options: nil)
		addSubview(contentView)
		contentView.frame = self.bounds
		contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	}
}
