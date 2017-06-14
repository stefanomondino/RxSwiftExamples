//
//  RxLocationManager.swift
//  RxWorkshop
//
//  Created by Stefano Mondino on 14/06/17.
//  Copyright © 2017 Deltatre. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

extension CLLocation {
    var placemark:Observable<CLPlacemark> {
        
        return Observable.create({ observer -> Disposable in
             RxLocationManager.geocoder.reverseGeocodeLocation(self, completionHandler: { (placemarks, error) in
                if let placemark = placemarks?.first {
                    observer.onNext(placemark)
                }
                observer.onCompleted()
                
            })
            
            return Disposables.create {
                RxLocationManager.geocoder.cancelGeocode()
            }
            })
    }
}


class RxLocationManager : CLLocationManager, CLLocationManagerDelegate {
    static let shared = RxLocationManager()
    fileprivate static let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        self.delegate = self
        self.requestWhenInUseAuthorization()
        
    }
    
    lazy var locationUpdates:Observable<CLLocation> = {
        return self.rx.methodInvoked(#selector(locationManager(_:didUpdateLocations:))).map {
            return $0.last as? [CLLocation] ?? []
            }
            .flatMapLatest { Observable.from($0)}
            .do( onSubscribed: { [weak self] in
                self?.startUpdatingLocation()
                }, onDispose: {[weak self] in
                    self?.stopUpdatingLocation()
            })
            .shareReplay(1)
    }()
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print (locations.last)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    
    
    
}
