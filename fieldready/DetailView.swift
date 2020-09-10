//
//  DetailView.swift
//  fieldready
//
//  Created by Tom on 05/09/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit
import MapKit
import QuartzCore

class DetailView: UIView {

	@IBOutlet var contentView: UIView!
	@IBOutlet var lineView: UIView!
	@IBOutlet var locationLabel: UILabel!
	@IBOutlet var mapView: MKMapView!
	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var commentsLabel: UILabel!
	@IBOutlet var nameLabel: UILabel!
	
	
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
		mapView.layer.borderWidth = 1
		mapView.layer.borderColor = UIColor(white: 0.78, alpha: 1.0).cgColor
	}
	
	func reset() {
		refreshMapTo(loc: CLLocationCoordinate2D(latitude: 0, longitude: 0), title: "-")
		nameLabel.text = "by -"
		locationLabel.text = "-"
		timeLabel.text = "-"
		commentsLabel.text = "-"
		
		mapView.isHidden = false
		nameLabel.isHidden = false
		locationLabel.isHidden = false
		timeLabel.isHidden = false
		commentsLabel.isHidden = false
	}
	
	func refreshMapTo(loc: CLLocationCoordinate2D, title: String) {
		mapView.removeAnnotations(mapView.annotations)
		let annotation = MKPointAnnotation()
		annotation.coordinate = loc
		annotation.title = title
		mapView.addAnnotation(annotation)
		let region = MKCoordinateRegion( center: loc, latitudinalMeters: CLLocationDistance(exactly: 5000)!, longitudinalMeters: CLLocationDistance(exactly: 5000)!)
		mapView.setRegion(mapView.regionThatFits(region), animated: false)
		mapView.setCenter(loc, animated: false)
	}
}
