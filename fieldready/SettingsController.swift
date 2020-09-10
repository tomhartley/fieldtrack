//
//  SettingsController.swift
//  fieldready
//
//  Created by Tom on 10/09/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit

class SettingsController: UIViewController {

	@IBOutlet var textField: UITextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let defaults = UserDefaults.standard
		let s = defaults.string(forKey: "personID")
		textField.text = s
        // Do any additional setup after loading the view.
    }

	override func viewDidAppear(_ animated: Bool) {
		textField.becomeFirstResponder()
		if #available(iOS 13.0, *) {
			self.isModalInPresentation = true
		} else {
			// Fallback on earlier versions
		}
	}
	
	func savePersonValue() {
		let defaults = UserDefaults.standard
		defaults.set(textField.text, forKey: "personID")
	}
	
	@IBAction func confirmButton(_ sender: Any) {
		if ((self.textField.text ?? "") != "") {
			savePersonValue()
			self.dismiss(animated: true, completion: nil)
		} else {
			let midX = textField.center.x
			let midY = textField.center.y

			let anim = CASpringAnimation(keyPath: "position")
			anim.duration = 0.06
			anim.repeatCount = 4
			anim.autoreverses = true
			anim.damping = 0.2
			anim.initialVelocity = 1.0
			anim.fromValue = CGPoint(x: midX - 10, y: midY)
			anim.toValue = CGPoint(x: midX + 10, y: midY)
			textField.layer.add(anim, forKey: "position")
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
