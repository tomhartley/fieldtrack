//
//  ViewController.swift
//  fieldready
//
//  Created by Tom on 19/08/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit
import QRCodeReader
import CoreLocation

class ViewController: UIViewController, QRCodeReaderViewControllerDelegate, UINavigationBarDelegate, CLLocationManagerDelegate {

	@IBOutlet var productName: UILabel! //IB outlets
	@IBOutlet var batchQuantity: UILabel!
	@IBOutlet var batchNum: UILabel!
	@IBOutlet var batchCustomer: UILabel!
	
	@IBOutlet var nextButton: UIButton!
	@IBOutlet var cardView: UIView!
	
	@IBOutlet var stackView: UIStackView!
	
	@IBOutlet var distConstraint: NSLayoutConstraint!
	@IBOutlet var topConstraint: NSLayoutConstraint!
	
	let detailView : DetailView = DetailView(frame: CGRect.zero)
	var detailLocation : Int? = nil
	var rowViews : [RowView] = []

	@IBOutlet var helpView: UIView!
	@IBOutlet var loadingView: UIView!
	
    var locationManager: CLLocationManager!
	
	var trackingItems : Dictionary<BatchStatus,TrackingItem?> = [.ordered : nil, .manufactured : nil, .tested: nil, .shipped: nil, .delivered: nil, .followedup: nil, .unknown: nil]
	var batchItem : BatchItem? = nil
	var currentBatchStatus : BatchStatus = .unknown
	
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
		// Do any additional setup after loading the view.
		
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
		}
		
		
		for i in stackView.arrangedSubviews {
			if let view = i as? RowView {
				rowViews.append(view)
			}
		}
		
		for (index, view) in rowViews.enumerated() {
			view.iconView.image = UIImage.init(named: "icon_"+String(index+1))
			let rowStatus = BatchStatus.init(rawValue: index)
			view.titleView.text = rowStatus?.textRepresentation()
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.rowTapped(recognizer:)))
			view.addGestureRecognizer(tapGesture)
			view.tag = index
		}
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.rowTapped(recognizer:)))
		detailView.addGestureRecognizer(tapGesture)
		detailView.translatesAutoresizingMaskIntoConstraints = false
		
		updateUI() //Set to default values, etc.
		moveTwoViews(visible: false, animated: false)
	}

	override func viewDidAppear(_ animated: Bool) {
		let x = UserDefaults.standard
		let id = x.string(forKey: "personID")
		if (id == nil || id == "") {
			let settings = SettingsController()
			settings.modalPresentationCapturesStatusBarAppearance = false
			self.present(settings, animated: false, completion: nil)
		}
	}
	
	//Set constraints such that the top and bottom views are offscreen
	func moveTwoViews(visible: Bool, animated: Bool) {
		if (visible) {
			self.distConstraint.constant = 15
			self.topConstraint.constant = 18
			//self.view.isUserInteractionEnabled = true //is this the right way to do it...?
		} else {
			let viewHeight = self.view.frame.height
			
			self.distConstraint.constant = viewHeight + 200
			self.topConstraint.constant = -200
			//self.view.isUserInteractionEnabled = false // Hmm

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
		if (detailLocation != nil) {
			print("Error: detail location not nil in showDetailView")
			return
		}
		
		let status = BatchStatus.init(rawValue: forRow) ?? BatchStatus.unknown
		if (trackingItems[status]! == nil) {
			print("No data for tapped row. Not unfolding.")
			return
		}
		
		updateDetailView(forStatus: status)
		
		detailLocation = forRow
		self.detailView.isHidden = true
		self.detailView.alpha = 0.0
		self.stackView.insertArrangedSubview(detailView, at: forRow+1)
		self.stackView.layoutIfNeeded()
		UIView.animate(withDuration: 0.25) {
			self.detailView.isHidden = false
			self.detailView.alpha = 1.0
			self.rowViews[forRow].setRotated(rotated: true)
		}
	} //refactored
	
	func hideRow(rowID : Int, animated: Bool) {
		self.rowViews[rowID].setRotated(rotated: false)
		self.detailView.isHidden = true
		self.detailView.alpha = 0.0
		if (!animated) {
			self.stackView.removeArrangedSubview(self.detailView)
		}
	}
	
	//Responder for the tap gesture recognizer to unfold or fold the detail view
	@objc func rowTapped(recognizer: UITapGestureRecognizer) {
		//When a row is tapped: A) nothing is unfolded. B) itself is unfolded C) something else is unfolded
		if let view = recognizer.view {
			var shouldUnfold = false
			if (detailLocation == view.tag || view == detailView) { //Type B
				//do nothing
			} else if (detailLocation == nil) { //Type A
				self.showDetailView(forRow: view.tag)
				return
			} else { //type C
				shouldUnfold = true
			}
			let rowLoc = detailLocation!
			detailLocation = nil
			UIView.animate(withDuration: 0.25, animations: {
				self.hideRow(rowID: rowLoc, animated: true)
			}) { (completed) in
				self.stackView.removeArrangedSubview(self.detailView)
				if (shouldUnfold) {
					self.showDetailView(forRow: view.tag)
				}
			}

		}
	} //refactored

	
	//Get data for a particular batch number from the server
	func getTrackingItems(batchNo : String) {
		let handler = DataHandler()
		let group = DispatchGroup()
		
		group.enter()
		handler.getTrackingForBatch(batchno: batchNo) {
			result in switch result {
				case .success(let resultSucc):
					self.trackingItems = [.ordered : nil, .manufactured : nil, .tested: nil, .shipped: nil, .delivered: nil, .followedup: nil, .unknown: nil]
					for i in resultSucc {
						self.trackingItems[i.status] = i
					}
				case .failure(let error):
					print(error)
			}
			group.leave()
		}
		
		group.enter()
		handler.getBatch(batchno: batchNo) {
			result in switch result {
			case .success(let resultSucc):
				self.batchItem = resultSucc
				self.trackingItems[.ordered] = TrackingItem.init(orderedFromBatch: resultSucc)
			case .failure(let error):
				print(error)
			}
			group.leave()
		}
		
		group.notify(queue: .main) { //only called when both the above functions have ended
			// Update UI
			self.updateUI()
			self.moveTwoViews(visible: true, animated: true)
			UIView.animate(withDuration: 0.2) {
				self.loadingView.alpha = 0.0
			}
		}
	}
	
	func updateUI() {
		//called when the tracking data gets updates
		if let batch = batchItem {
			self.productName.text = batch.productName
			self.batchQuantity.text = "x " + String(batch.quantity)
			self.batchCustomer.text = batch.customerName
			self.batchNum.text = batch.batchNum
		}

		var maxRowIndex = 0 //'ordered'. If it's scannable, it must be ordered, right.

		for (status,result) in trackingItems {
			if (status == .unknown) {
				continue
			}
			let rowIndex = status.rawValue
			if ((result != nil) && (rowIndex > maxRowIndex)){
				maxRowIndex = rowIndex
			}
		}
		
		self.currentBatchStatus = BatchStatus.init(rawValue: maxRowIndex) ?? BatchStatus.unknown
		
		if (currentBatchStatus == .followedup) {
			self.nextButton.isEnabled = false
			self.nextButton.alpha = 0.0
		} else {
			let buttonText = "Mark Batch as " + BatchStatus.init(rawValue: maxRowIndex+1)!.textRepresentation()
			self.nextButton.setTitle(buttonText, for: .normal)
			self.nextButton.setTitle(buttonText, for: .selected)
			self.nextButton.setTitle(buttonText, for: .highlighted)
			self.nextButton.setTitle(buttonText, for: .disabled)
			self.nextButton.alpha = 1.0
			self.nextButton.isEnabled = true
		}
		
		
		for (index, view) in rowViews.enumerated() {
			view.topLineView.isHidden = false
			view.bottomLineView.isHidden = false
			if (index==0) {
				view.topLineView.isHidden = true
			}
			if (index>=maxRowIndex) {
				view.bottomLineView.isHidden = true
			}
			if (index>maxRowIndex) {
				view.setCompleted(completed: false)
			} else {
				view.setCompleted(completed: true)
			}
		}
	}
	
	func updateDetailView(forStatus: BatchStatus) {
		let track = trackingItems[forStatus]
		detailView.reset()
		if case let unwrapped?? = track {
			detailView.nameLabel.text = "by " + unwrapped.personName
			
			if (Date().addingTimeInterval(-172800) > unwrapped.createdTime) {
				let formatter = DateFormatter()
				formatter.dateStyle = .short
				detailView.timeLabel.text = formatter.string(from: unwrapped.createdTime)
			} else {
				//if date is more than 1.5 days ago = 60*60*24*2 = 172,800
				let formatter = RelativeDateTimeFormatter()
				detailView.timeLabel.text = formatter.localizedString(for: unwrapped.createdTime, relativeTo: Date())
			}

			if let loc = unwrapped.location {
				detailView.refreshMapTo(loc: loc, title: forStatus.textRepresentation())
				detailView.locationLabel.text = "-"
				CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: loc.latitude, longitude: loc.longitude)) { placemark, error in
					guard let placemark = placemark, error == nil else {
						print(error)
						return
					}
					let str = (placemark[0].locality ?? "") + ", " + (placemark[0].country ?? "")
					self.detailView.locationLabel.text = str
				}
			} else {
				detailView.mapView.isHidden = true
				detailView.locationLabel.isHidden = true
			}
			if (unwrapped.comments != "") {
				detailView.commentsLabel.text = "Note: " + unwrapped.comments
			} else {
				detailView.commentsLabel.isHidden = true
			}
		}
	}
	
	//IB Action called when user wants to advance the status of that batch
	@IBAction func changeStatus(_ sender: Any) {
		let nextBatchStatus = BatchStatus(rawValue: currentBatchStatus.rawValue+1)
		if let nextStatus = nextBatchStatus, let ID = batchItem?.airtableID {
			if (nextStatus == .unknown) {
				return //no can do
			}
			let confController = ConfirmationController()
			confController.modalPresentationCapturesStatusBarAppearance = false
			if (self.locationManager.location == nil) {
				confController.pulseView.isHidden = true
			}
			confController.setStatus(status: nextStatus)
			confController.completionHandler = { completed, notes in
				if (completed) {//successful
					let DH = DataHandler()
					let curLoc = self.locationManager.location?.coordinate
					let x = UserDefaults.standard
					let id = x.string(forKey: "personID") ?? ""
					let submission = TrackingSubmission(withBatchID: ID, status: nextStatus, personID: id, loc: curLoc, notes: notes)
					DH.submitTracking(tracking: submission) {
						result in switch result {
							case .success(let resultSucc):
								self.trackingItems[resultSucc.status] = resultSucc
								UIView.animate(withDuration: 0.2) {
									self.updateUI() //Add it in, I guess
								}
							case .failure(let error):
								print(error)
						}
					}
				}
			}
			self.present(confController, animated: true) {
				//nada
			}
		}
	}
	
	@IBAction func openSettings(_ sender: Any) {
		let settings = SettingsController()
		settings.modalPresentationCapturesStatusBarAppearance = false
		self.present(settings, animated: true, completion: nil)
	}
	
	//Open the scanning view
	@IBAction func loadScan(_ sender: AnyObject) {
	  // Retrieve the QRCode content
	  // By using the delegate pattern
		readerVC.delegate = self

	  // Presents the readerVC as modal form sheet
		//readerVC.modalPresentationStyle = .formSheet
		readerVC.modalPresentationCapturesStatusBarAppearance = false
	 
		present(readerVC, animated: true, completion: nil)
	}

	// MARK: - QRCodeReaderViewController Delegate Methods
	//responding to the QR code scanning
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		reader.stopScanning()

		print(result)
		let bno = result.value.split(separator: "/").last
		print(bno ?? "QR Result not printable")
		if let str = bno {
			self.getTrackingItems(batchNo: String(str))
		}
		moveTwoViews(visible: false, animated: false)
		helpView.isHidden = true
		loadingView.alpha = 1.0
		if let dL = detailLocation {
			self.hideRow(rowID: dL, animated: false)
		}
		dismiss(animated: true, completion: nil)
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
