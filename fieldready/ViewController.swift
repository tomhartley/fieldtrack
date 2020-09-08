//
//  ViewController.swift
//  fieldready
//
//  Created by Tom on 19/08/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit
import QRCodeReader

class ViewController: UIViewController, QRCodeReaderViewControllerDelegate, UINavigationBarDelegate {

	@IBOutlet var productName: UILabel!
	@IBOutlet var batchQuantity: UILabel!
	@IBOutlet var batchNum: UILabel!
	@IBOutlet var batchCustomer: UILabel!
	
	@IBOutlet var nextButton: UIButton!
	@IBOutlet var cardView: UIView!
	
	@IBOutlet var stackView: UIStackView!
	
	@IBOutlet var distConstraint: NSLayoutConstraint!
	@IBOutlet var topConstraint: NSLayoutConstraint!
	
	let detailView : DetailView = DetailView(frame: CGRect.zero)
	
	var cardViewOrigin: CGPoint? = nil
	
	var trackingItem : TrackingItem? = nil
	
	var rowViews : [RowView] = []

	var detailLocation : Int = -1
	
	let names = ["Ordered", "Manufactured", "QC Passed", "Shipped", "Delivered", "Followed Up"]
	
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
		
		//self.setNeedsStatusBarAppearanceUpdate()
		
		for i in stackView.arrangedSubviews {
			if let view = i as? RowView {
				rowViews.append(view)
			}
		}
		for (index, view) in rowViews.enumerated() {
			view.iconView.image = UIImage.init(named: "icon_"+String(index+1))
			view.titleView.text = names[index]
			if (index==0) {
				view.topLineView.isHidden = true
			}
			if (index==3) {
				view.bottomLineView.isHidden = true
			}
			if (index>3) {
				view.setCompleted(completed: false)
			} else {
				view.setCompleted(completed: true)
			}
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.rowTapped(recognizer:)))
			view.addGestureRecognizer(tapGesture)
			view.tag = index
		}
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.rowTapped(recognizer:)))
		detailView.addGestureRecognizer(tapGesture)
		detailView.translatesAutoresizingMaskIntoConstraints = false
	}

	//Set constraints such that the top and bottom views are offscreen
	func moveTwoViews(visible: Bool, animated: Bool) {
		if (visible) {
			self.distConstraint.constant = 15
			self.topConstraint.constant = 18
		} else {
			let viewHeight = self.view.frame.height
			
			self.distConstraint.constant = viewHeight + 200
			self.topConstraint.constant = -200
		}
		if (animated) {
			UIView.animate(withDuration: 1.1, delay: 0.2, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.0, options: .init(), animations: {
				self.view.layoutIfNeeded()
			}, completion: nil)
		} else {
			self.view.layoutIfNeeded()
		}
	}

	//Show the detail view at a particular row. This function requires that the detail view not be currently visible.
	@objc func showDetailView(forRow : Int) {
		if (detailLocation != -1) {
			print("Error: detail location not -1 in showDetailView")
		}
		detailLocation = forRow
		self.detailView.isHidden = true
		self.detailView.alpha = 0.0
		self.stackView.insertArrangedSubview(detailView, at: forRow+1)
		self.stackView.layoutIfNeeded()
		UIView.animate(withDuration: 0.25) {
			self.detailView.isHidden = false
			self.detailView.alpha = 1.0
		}
	} //refactored
	
	//Responder for the tap gesture recognizer to unfold or fold the detail view
	@objc func rowTapped(recognizer: UITapGestureRecognizer) {
		//When a row is tapped: A) nothing is unfolded. B) itself is unfolded C) something else is unfolded
		if let view = recognizer.view {
			var shouldUnfold = false
			if (detailLocation == view.tag || view == detailView) { //Type B
				//do nothing
			} else if (detailLocation == -1) { //Type A
				self.showDetailView(forRow: view.tag)
				return
			} else { //type C
				shouldUnfold = true
			}
			
			detailLocation = -1
			UIView.animate(withDuration: 0.25, animations: {
				self.detailView.isHidden = true
				self.detailView.alpha = 0.0
			}) { (completed) in
				self.stackView.removeArrangedSubview(self.detailView)
				if (shouldUnfold) {
					self.showDetailView(forRow: view.tag)
				}
			}

		}
	} //refactored

	//??
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
		
		/*UIView.transition(with: statusView, duration: 0.3, options: .transitionCrossDissolve, animations: {
			self.statusView.setStatus(status: self.trackingItem?.getStatus() ?? BatchStatus.unknown)
		},
		completion: nil)*/
	}
	
	//??
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
	
	//IB Action called when user wants to advance the status of that batch
	@IBAction func changeStatus(_ sender: Any) {
		//This is a total hack right now
		/*let currStatus = statusView.currentStatus
		if currStatus != .unknown && currStatus != .followedup {
			let newStatus = BatchStatus.init(rawValue: currStatus.rawValue+1)!
			UIView.transition(with: statusView, duration: 0.3, options: .transitionCrossDissolve, animations: {
				self.statusView.setStatus(status: newStatus)
			},
			completion: nil)

		}*/
	}
	
	//Open the scanning view
	@IBAction func loadScan(_ sender: AnyObject) {
	  // Retrieve the QRCode content
	  // By using the delegate pattern
		readerVC.delegate = self

	  // Presents the readerVC as modal form sheet
		readerVC.modalPresentationStyle = .formSheet
	 
		present(readerVC, animated: true, completion: nil)
	}

	// MARK: - QRCodeReaderViewController Delegate Methods
	//responding to the QR code scanning
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		reader.stopScanning()

		print(result)
		let bno = result.value.split(separator: "/").last
		print(bno ?? "QR Result not printable")
		self.cardViewOrigin = self.cardView.frame.origin
		self.cardView.frame.origin = CGPoint(x: 0, y: self.cardViewOrigin!.y + self.cardView.frame.height)
		self.getTrackingItem(batchNo: String(bno ?? "6"))
		dismiss(animated: true, completion: nil)
		moveTwoViews(visible: false, animated: false)
		moveTwoViews(visible: true, animated: true)
	}

	//upon cancellation of the QR window. User is not able to cancel right now I think.
	func readerDidCancel(_ reader: QRCodeReaderViewController) {
	  reader.stopScanning()
	  print("cancelled")
	  dismiss(animated: true, completion: nil)
	}
	
	// MARK: - UINavigationBar Delegate Methods
	
	func position(for bar: UIBarPositioning) -> UIBarPosition {
		return .topAttached
	}
	
}
