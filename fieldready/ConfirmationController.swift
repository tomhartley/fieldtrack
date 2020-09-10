//
//  ConfirmationController.swift
//  fieldready
//
//  Created by Tom on 10/09/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit

class ConfirmationController: UIViewController {

	@IBOutlet private var textView: UITextView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var pulseView: UIView!
	
	private var status : BatchStatus = .unknown
	
	var completionHandler: ((Bool, String)->Void)?
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		titleLabel.text = "Mark batch as " + status.completedRepresentation()
	}
	
	func setStatus(status : BatchStatus) {
		self.status = status
	}
	
	override func viewWillAppear(_ animated: Bool) {
		textView.becomeFirstResponder()
		if #available(iOS 13.0, *) {
			self.isModalInPresentation = true
		} else {
			// Fallback on earlier versions
		}
		//let pulse = CASpringAnimation(keyPath: "transform.scale")
		UIView.animate(withDuration: 1.0,
					   delay: 0,
					   options: [.autoreverse, .repeat, .curveEaseInOut],
					   animations: {
						self.pulseView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
		}, completion: nil)
		//pulse.initialVelocity = 0.5
		//pulse.damping = 0.8
	}
	
	@IBAction func cancelButton(_ sender: Any) {
		self.dismiss(animated: true, completion: {})
		if let handler = completionHandler {
			handler(false, textView.text)
		}
	}
	
	@IBAction func confirmButton(_ sender: Any) {
		self.dismiss(animated: true, completion: {})
		if let handler = completionHandler {
			handler(true, textView.text)
		}
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
