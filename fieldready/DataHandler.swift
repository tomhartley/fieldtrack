//
//  DataHandler.swift
//  fieldready
//
//  Created by Tom on 20/08/2020.
//  Copyright © 2020 Tom Hartley. All rights reserved.
//

import UIKit

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

struct TrackingResponse: Codable {
	struct TrackingItem: Codable {
		struct FieldsItem: Codable {
			var BatchNum : [String] //ID
			var Status : String
			var Email : String
			var TrackingID : String
			var Timestamp : Date
			var ProductName : [String]
			var Customer : [String]
			var BatchNumLookup : [Int]
		}
		var id : String
		var fields : FieldsItem
		var createdTime : Date
	}
	
	var records : [TrackingItem]
	
	func getLatestTracking() -> TrackingItem {
		var z = self.records
		z.sort { (a, b) -> Bool in
			return (a.fields.Timestamp > b.fields.Timestamp)
		}
		return z[0]
	}
}


class DataHandler: NSObject {
	
	func getTrackingForBatch(batchno : String, completion: @escaping (Result<TrackingResponse, Error>) -> Void) {
		let url = URL(string: "https://api.airtable.com/v0/appTl8nV3SedlJqEF/Tracking")!

		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

		components.queryItems = [
			//URLQueryItem(name: "maxRecords", value: "3"),
			URLQueryItem(name: "filterByFormula", value: "{BatchNumLookup} = '" + batchno + "'")
		]

		//The query will be a properly escaped string:

		//key1=NeedToEscape%3DAnd%26&key2=v%C3%A5l%C3%BC%C3%A9
		//Now you can create a request and use the query as HTTPBody:

		print(components.url!)

		var request = URLRequest(url: components.url!)
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
			
			let str = String(decoding: data, as: UTF8.self) // "Caf�"
			print(str)
			
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
			do {
				let result = try decoder.decode(TrackingResponse.self, from: data)
				DispatchQueue.main.async {
					completion(.success(result))
				}

			} catch {
				DispatchQueue.main.async {
					print(error as Any)
					completion(.failure(error))
				}
			}
			
		}
		task.resume()

	}
	
}
