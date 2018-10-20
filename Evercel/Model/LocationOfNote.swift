//
//  LocationOfNote
//  coreLocation_mapKit
//
//  Created by Charles Moncada on 15/10/18.
//  Copyright © 2018 Charles Moncada. All rights reserved.
//

import UIKit
import MapKit

class LocationOfNote: NSObject {
	let _title: String
	let _date: String
    let _location: CLLocationCoordinate2D

    init(title: String, date: String, location: CLLocationCoordinate2D) {
		_title = title
		_date = date
        _location = location
	}
}

extension LocationOfNote: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        get {
            return _location
        }
    }
    
    var title: String? {
        get {
            return _title
        }
    }
    
    var subtitle: String? {
        get {
            return _date
        }
    }
}
