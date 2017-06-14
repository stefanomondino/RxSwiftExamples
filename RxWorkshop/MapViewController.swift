//
//  MapViewController.swift
//  RxWorkshop
//
//  Created by Stefano Mondino on 14/06/17.
//  Copyright © 2017 Deltatre. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa


class MapViewController: UIViewController {
    var disposeBag = DisposeBag()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lbl_place: UILabel!
    @IBOutlet weak var lbl_distance: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        RxLocationManager.shared.locationUpdates.subscribe(onNext:{ [weak self] in
        
            self?.mapView.setCenter($0.coordinate, animated: true)
        }).disposed(by: disposeBag)
        
        let location = CLLocation(latitude: 45.076764, longitude: 7.671552)
        
        let df = MKDistanceFormatter()
        df.unitStyle = .full
        df.locale = Locale(identifier: "it")
        
        RxLocationManager.shared
            .locationUpdates
            .startWith(location)
            .distinctUntilChanged()
            .flatMapLatest { $0.placemark }
            .map { $0.locality ?? "n/a"}
            .startWith("")
            .bind(to: self.lbl_place.rx.text)
            .disposed(by: disposeBag)
        
        RxLocationManager.shared
            .locationUpdates
            .startWith(location)
            .map {
            let meters = df.string(fromDistance: $0.distance(from: location))
            return "Distanza da qui: \(meters)"
        }.bind(to: self.lbl_distance.rx.text)
        .disposed(by: self.disposeBag)
        
    }




}
