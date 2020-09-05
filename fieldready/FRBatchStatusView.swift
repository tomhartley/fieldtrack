//
//  FRBatchStatusView.swift
//  fieldready
//
//  Created by Tom on 24/08/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit

let itemwidth = 40

class FRBatchStatusView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
	var currentStatus : BatchStatus = .ordered
	var circleViews : [UIImageView] = []
	var labels : [UILabel] = []
	var lineviews : [UIView] = []
	
	var fnamePrefix : String = "batchview_"
	let names = ["Ordered", "Manufactured", "QC Passed", "Shipped", "Delivered", "Followed Up"]
	
	func setupViews() {
		for i in 0...5 {
			let v = UIImageView(frame: CGRect(x: 0, y: (itemwidth+10)*i, width: itemwidth, height: itemwidth))
			circleViews.append(v)
			self.addSubview(v)
			let fname = genname(index: i+1)
			circleViews[i].image = UIImage.init(named: fname)

			let l = UILabel(frame: CGRect(x: itemwidth+10, y: (itemwidth+10)*i, width: 200, height: itemwidth))
			l.textAlignment = .left
			l.text = names[i]
			labels.append(l)
			self.addSubview(l)
			
			if (i != 5) {
				let lineview = UIView(frame: CGRect(x: itemwidth/2, y: ((itemwidth+10)*i)-2+itemwidth, width: 3, height: 10+4))
				lineview.backgroundColor = .systemGray3
				self.addSubview(lineview)
				self.sendSubviewToBack(lineview)
				lineviews.append(lineview)
			}
		}
		self.updateContent()
	}
	
	func genname(index : Int) -> String {
		return fnamePrefix + String(index) + "_" + "sel"
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.setupViews()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.setupViews()
	}
	
	func updateContent() {
		let rawStatus = currentStatus.rawValue
		
		for i in 0...5 {
			if i<=rawStatus {
				labels[i].font = .boldSystemFont(ofSize: 15)
				labels[i].textColor = UIColor.init(named: "FRWhite")
				circleViews[i].tintColor = UIColor.init(named: "FRWhite")
				if (i != 0) {
					lineviews[i-1].backgroundColor = UIColor.init(named: "FRWhite")
				}
			} else {
				labels[i].font = .systemFont(ofSize: 15)
				labels[i].textColor = UIColor.init(named: "FRWhiteFade")

				circleViews[i].tintColor =  UIColor.init(named: "FRWhiteFade") //try 2 if this is too light
				if (i != 0) {
					lineviews[i-1].backgroundColor = .clear
				}

			}

		}
	}
	
	func setStatus(status : BatchStatus) {
		self.currentStatus = status
		self.updateContent()
	}

}
