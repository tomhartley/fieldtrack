//
//  DataHandler.swift
//  fieldready
//
//  Created by Tom on 20/08/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit
import CoreLocation

extension DateFormatter {
  static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

enum BatchStatus : Int {
	case ordered = 0
	case manufactured = 1
	case tested = 2
	case shipped = 3
	case delivered = 4
	case followedup = 5
	case unknown = 6
	
	func textRepresentation() -> String {
		let names = ["Ordered", "Manufactured", "QC Passed", "Shipped", "Delivered", "Followed Up","Unknown"]
		return names[self.rawValue]
	}
	
	func airtableRepresentation() -> String {
		let airtableNames = ["Ordered", "Manufactured", "Tested", "Shipped", "Delivered", "Followed Up",""]
		return airtableNames[self.rawValue]
	}
	
	func completedRepresentation() -> String { //"Mark batch as ..."
		let completedNames = ["ordered", "finished manufacturing", "quality control passed", "shipped", "delivered to customer", "followed up",""]
		return completedNames[self.rawValue]
	}
	
	init?(fromAirtable: String) {
		let airtableNames = ["Ordered", "Manufactured", "Tested", "Shipped", "Delivered", "Followed Up"]
		if let y = airtableNames.firstIndex(of: fromAirtable) {
			self.init(rawValue: y)
			return
		}
		self = .unknown
	}
}


fileprivate struct TrackingResponse: Codable {
	struct TrackingItemOG: Codable {
		struct FieldsItem: Codable {
			var BatchNum : [String] //ID
			var Status : String
			var Person : [String]?
			var PersonName : [String]?
			var TrackingID : String
			var BatchNumLookup : [String]
			var Notes : String?
			var Location : String?
		}
		var id : String
		var fields : FieldsItem
		var createdTime : Date
		
		func getStatus() -> BatchStatus {
			let x = BatchStatus.init(fromAirtable: fields.Status)!
			print(x)
			return x
		}
	}

	var records : [TrackingItemOG]
	
	func getLatestTracking() -> TrackingItemOG? {
		var z = self.records
		z.sort { (a, b) -> Bool in
			return (a.createdTime > b.createdTime)
		}
		if z.count > 0 {
			return z[0]
		} else {
			return nil
		}
	}
}

struct TrackingItem {
	var batchNum : String //The actual batch number
	var status : BatchStatus //The status of this tracking item
	var personName : String //The person's name
	var createdTime : Date
	var comments : String
	var location : CLLocationCoordinate2D?
	var airtableID : String?
	fileprivate var originalData : TrackingResponse.TrackingItemOG?
	
	fileprivate init(from: TrackingResponse.TrackingItemOG) {
		self.batchNum = from.fields.BatchNumLookup[0]
		self.status = from.getStatus()
		if let pNames = from.fields.PersonName {
			self.personName = pNames[0]
		} else {
			self.personName = "-"
		}
		self.createdTime = from.createdTime
		self.comments = from.fields.Notes ?? ""
		if let loc = from.fields.Location {
			let latlon = loc.split(separator: ",")
			let lat : CLLocationDegrees = Double(String(latlon[0]))!
			let lon : CLLocationDegrees = Double(String(latlon[1]))!
			self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
		}
		self.airtableID = from.id
		self.originalData = from
	}
	
	init(orderedFromBatch: BatchItem) {
		self.batchNum = orderedFromBatch.batchNum
		self.status = .ordered
		self.personName = orderedFromBatch.customerName
		self.createdTime = orderedFromBatch.createdTime
		self.comments = ""
	}
}

struct TrackingSubmission: Codable {
	struct FieldsItem : Codable {
		var BatchNum : [String]
		var Status : String
		var Person : [String]
		var Location : String
		var Notes : String
	}
	var fields : FieldsItem
	
	init(withBatchID: String, status: BatchStatus, personID: String?, loc: CLLocationCoordinate2D?, notes: String) {
		var locString = ""
		if let location = loc {
			locString = "\(location.latitude),\(location.longitude)"
		}
		var persons : [String] = []
		if let a = personID {
			persons.append(a)
		}
		fields = FieldsItem(BatchNum: [withBatchID], Status: status.airtableRepresentation(), Person: persons, Location: locString, Notes: notes)
	}
}

fileprivate struct BatchResponse: Codable {
	struct BatchItemOG: Codable {
		struct FieldsItem: Codable {
			var Quantity : Int
			var Product_Name : [String]
			var Batch_Num : String
			var Customer : [String]
		}
		var id : String
		var fields : FieldsItem
		var createdTime : Date
	}
	var records : [BatchItemOG]
}

struct BatchItem {
	var quantity: Int
	var batchNum: String
	var productName : String
	var customerName : String
	var createdTime : Date
	var airtableID : String
	fileprivate var originalData : BatchResponse.BatchItemOG
	
	fileprivate init(from: BatchResponse.BatchItemOG) {
		self.quantity = from.fields.Quantity
		self.batchNum = from.fields.Batch_Num
		self.productName = from.fields.Product_Name[0]
		self.customerName = from.fields.Customer[0]
		self.createdTime = from.createdTime
		self.airtableID = from.id
		self.originalData = from
	}
}

class DataHandler: NSObject {
	
	func submitTracking(tracking: TrackingSubmission, completion: @escaping (Result<TrackingItem, Error>) -> Void) {
		let dbID = "***REMOVED***"
		var request = URLRequest(url: URL(string: "https://api.airtable.com/v0/" + dbID + "/Tracking")!)
		request.httpMethod = "POST"
		let apiKey = "***REMOVED***"
		request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		let jsonData = try! JSONEncoder().encode(tracking)
		let x = String.init(decoding: jsonData, as: UTF8.self)
		print(x)
		request.httpBody = jsonData
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				print(error?.localizedDescription ?? "No data")
				DispatchQueue.main.async {
					print(error)
					completion(.failure(error!)) //The upload/some other part failed?
				}
				return
			}
			
			let x = String.init(decoding: data, as: UTF8.self)
			print(x)

			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
			do {
				let trackingResponse = try decoder.decode(TrackingResponse.TrackingItemOG.self, from: data)
				let item : TrackingItem = TrackingItem.init(from: trackingResponse)
				DispatchQueue.main.async {
					completion(.success(item))
				}
			} catch {
				print(error)
				DispatchQueue.main.async {completion(.failure(error))} //the JSON failed
			}
		}
		task.resume()
	}
	
	//Get the batch details for a particular batch
	func downloadURL(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("Bearer ***REMOVED***", forHTTPHeaderField: "Authorization")
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				print(error?.localizedDescription ?? "No data")
				DispatchQueue.main.async {
					completion(.failure(error!))
				}
				return
			}
			DispatchQueue.main.async {
				let x = String.init(decoding: data, as: UTF8.self)
				print(x)
				completion(.success(data))
			}
		}
		task.resume()
	}
	
	//Get tracking items for a particular batch
	func getTrackingForBatch(batchno : String, completion: @escaping (Result<[TrackingItem], Error>) -> Void) {
		let url = URL(string: "https://api.airtable.com/v0/***REMOVED***/Tracking")!
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		components.queryItems = [
			URLQueryItem(name: "filterByFormula", value: "{BatchNumLookup} = '" + batchno + "'")
		]
		downloadURL(url: components.url!) { result in
			switch result {
				case .success(let result): //if the download was successful
					let decoder = JSONDecoder()
					decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
					do {
						let trackingResponse = try decoder.decode(TrackingResponse.self, from: result)
						var processedItems : [TrackingItem] = []
						for i in trackingResponse.records {
							processedItems.append(TrackingItem.init(from: i))
						}
						DispatchQueue.main.async {
							completion(.success(processedItems))
						}
					} catch {
						DispatchQueue.main.async {completion(.failure(error))} //the JSON failed
					}
					return
				case .failure(let error):
					completion(.failure(error)) //The downloading failed
					return
			}
		}
	}

	//Get tracking items for a particular batch
	func getBatch(batchno : String, completion: @escaping (Result<BatchItem, Error>) -> Void) {
		let url = URL(string: "https://api.airtable.com/v0/***REMOVED***/Batches")!
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		components.queryItems = [
			URLQueryItem(name: "filterByFormula", value: "{Batch_Num} = '" + batchno + "'")
		]
		downloadURL(url: components.url!) { result in
			switch result {
				case .success(let result): //if the download was successful
					let decoder = JSONDecoder()
					decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
					do {
						let batchResponse = try decoder.decode(BatchResponse.self, from: result)

						let batchItem = BatchItem.init(from: batchResponse.records[0])
						DispatchQueue.main.async {
							completion(.success(batchItem))
						}
					} catch {
						DispatchQueue.main.async {completion(.failure(error))} //the JSON failed
					}
					return
				case .failure(let error):
					completion(.failure(error)) //The downloading failed
					return
			}
		}
	}

	
}
