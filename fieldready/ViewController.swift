//
//  ViewController.swift
//  fieldready
//
//  Created by Tom on 19/08/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		let handler = DataHandler()
		handler.getTrackingForBatch(batchno: "6") { result in
			switch result {
			case .success(let result):
				//print("\(result)")
				//let x = result.records[0].fields.Customer[0]
				//print ("\(x)")
				let latestTrack = result.getLatestTracking()
				print ("\(latestTrack)")
			case .failure(let error):
				print(error.localizedDescription)
			}
		}
	}
}

