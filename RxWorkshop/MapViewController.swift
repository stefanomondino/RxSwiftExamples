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


extension CLLocation : MKAnnotation {
    public var title: String? { return "" }
}
class MapViewController: UIViewController, MKMapViewDelegate {
    var disposeBag = DisposeBag()
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var lbl_place: UILabel!
    @IBOutlet weak var lbl_distance: UILabel!
    @IBOutlet weak var lbl_cupertino: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let mapView:MKMapView = self.mapView
        mapView.delegate = self
        RxLocationManager.shared.locationUpdates.distinctUntilChanged().subscribe(onNext:{
            mapView.addAnnotation($0)
            //self?.mapView.setCenter($0.coordinate, animated: true)
        }).disposed(by: disposeBag)
        
        
        
        RxLocationManager.shared.locationUpdates.filter {
            let mapLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            return $0.distance(from: mapLocation) > 10000
            }
            .distinctUntilChanged()
            .subscribe(onNext:{ mapView.showAnnotations([$0], animated: true)})
            .disposed(by: disposeBag)
        
        RxLocationManager.shared.locationUpdates.distinctUntilChanged().scan([CLLocation]()) { (accumulator, location)  in
            return accumulator + [location]
            }.subscribe(onNext:{ [unowned self] in
                self.mapView.removeOverlays(self.mapView.overlays)
                let coordinates = $0.map{ $0.coordinate}
                let overlay = MKPolyline(coordinates: coordinates, count: coordinates.count)
                self.mapView.add(overlay)
            }).disposed(by: disposeBag)
        
        let tagLocation = CLLocation(latitude: 45.076764, longitude: 7.671552)
        let cupertinoStatic = CLLocation(latitude:37.33523566,longitude:-122.03254863)
        let df = MKDistanceFormatter()
        df.unitStyle = .full
        df.locale = Locale(identifier: "it")
        
        RxLocationManager.shared
            .locationUpdates
            .startWith(tagLocation)
            .distinctUntilChanged()
            .flatMapLatest { $0.placemark }
            .map { $0.locality ?? "n/a"}
            .startWith("")
            .bind(to: self.lbl_place.rx.text)
            .disposed(by: disposeBag)
        
        RxLocationManager.shared
            .locationUpdates
            .startWith(tagLocation)
            .map {
            let meters = df.string(fromDistance: $0.distance(from: tagLocation))
            return "Distanza da qui: \(meters)"
        }.bind(to: self.lbl_distance.rx.text)
        .disposed(by: disposeBag)
        
        RxLocationManager.shared
            .locationUpdates
            .startWith(cupertinoStatic)
            .map {
                let meters = df.string(fromDistance: $0.distance(from: cupertinoStatic))
                return "Distanza da Cupertino: \(meters)"
            }.bind(to: self.lbl_cupertino.rx.text)
        .disposed(by: self.disposeBag)
        
    }


    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let polyline as MKPolyline:
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 3
            renderer.strokeColor = UIColor.blue
            return renderer
        default:
            return MKOverlayRenderer(overlay: overlay)
        }
    }

}
