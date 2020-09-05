//
//  ViewController.swift
//  fieldready
//
//  Created by Tom on 19/08/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit
import QRCodeReader

class ViewController: UIViewController, UITextFieldDelegate, QRCodeReaderViewControllerDelegate {

	@IBOutlet var productName: UILabel!
	@IBOutlet var batchQuantity: UILabel!
	@IBOutlet var batchNum: UILabel!
	@IBOutlet var batchCustomer: UILabel!
	
	
	
	@IBOutlet var statusView: FRBatchStatusView!
	@IBOutlet var nextButton: UIButton!
	@IBOutlet var cardView: UIView!
	
	var cardViewOrigin: CGPoint? = nil
	
	var trackingItem : TrackingItem? = nil
	
	// Good practice: create the reader lazily to avoid cpu overload during the
	// initialization and each time we need to scan a QRCode
	lazy var readerVC: QRCodeReaderViewController = {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
			
			// Configure the view controller (optional)
			$0.showTorchButton        = false
			$0.showSwitchCameraButton = false
			$0.showCancelButton       = false
			$0.showOverlayView        = true
			$0.rectOfInterest         = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
		}
		
		return QRCodeReaderViewController(builder: builder)
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.cardViewOrigin = self.cardView.frame.origin
		// Do any additional setup after loading the view.
		getTrackingItem(batchNo: "6")
		nextButton.layer.cornerRadius = 16.0
		nextButton.clipsToBounds = true
	}
	
	func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
		self.view.endEditing(true)
		return false
	}
	
	func updateUI() {
		productName.text = trackingItem?.fields.ProductName[0]
		let num : Int = trackingItem?.fields.Quantity[0] ?? 0
		batchQuantity.text = "x " + String(num)
		let batchnum : Int = trackingItem?.fields.BatchNumLookup[0] ?? 0
		batchNum.text = String(batchnum)
		batchCustomer.text = trackingItem?.fields.Customer[0]
		
		UIView.animate(withDuration: 1.1, delay: 0.0, usingSpringWithDamping: 0.52, initialSpringVelocity: 0.0, options: .init(), animations: {
			self.cardView.frame.origin = self.cardViewOrigin!
		}, completion: nil)
		
		UIView.transition(with: statusView, duration: 0.3, options: .transitionCrossDissolve, animations: {
			self.statusView.setStatus(status: self.trackingItem?.getStatus() ?? BatchStatus.unknown)
		},
		completion: nil)


	}
	
	func getTrackingItem(batchNo : String) {
		let handler = DataHandler()
		handler.getTrackingForBatch(batchno: batchNo) {
			result in switch result {
			case .success(let result):
				//print("\(result)")
				//let x = result.records[0].fields.Customer[0]
				//print ("\(x)")
				let latestTrack = result.getLatestTracking()
				print ("\(latestTrack)")
				self.trackingItem = latestTrack
				self.updateUI()
			case .failure(let error):
				print(error.localizedDescription)
			}
		}

	}
	
	@IBAction func changeStatus(_ sender: Any) {
		//This is a total hack right now
		let currStatus = statusView.currentStatus
		if currStatus != .unknown && currStatus != .followedup {
			let newStatus = BatchStatus.init(rawValue: currStatus.rawValue+1)!
			UIView.transition(with: statusView, duration: 0.3, options: .transitionCrossDissolve, animations: {
				self.statusView.setStatus(status: newStatus)
			},
			completion: nil)

		}
	}
	
	
	@IBAction func loadScan(_ sender: AnyObject) {
	  // Retrieve the QRCode content
	  // By using the delegate pattern
	  readerVC.delegate = self

	  // Or by using the closure pattern
	  readerVC.completionBlock = { (result: QRCodeReaderResult?) in
		print(result)
		let bno = result?.value.split(separator: "/").last
		print(bno)
		self.cardViewOrigin = self.cardView.frame.origin
		self.cardView.frame.origin = CGPoint(x: 0, y: self.cardViewOrigin!.y + self.cardView.frame.height)
		self.getTrackingItem(batchNo: String(bno ?? "6"))

	  }

	  // Presents the readerVC as modal form sheet
		readerVC.modalPresentationStyle = .formSheet
	 
	  present(readerVC, animated: true, completion: nil)
	}

	// MARK: - QRCodeReaderViewController Delegate Methods

	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
	  reader.stopScanning()

	  dismiss(animated: true, completion: nil)
	}

	func readerDidCancel(_ reader: QRCodeReaderViewController) {
	  reader.stopScanning()
	  print("cancelled")
	  dismiss(animated: true, completion: nil)
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

}
