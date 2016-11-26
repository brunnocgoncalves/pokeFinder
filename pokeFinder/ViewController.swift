//
//  ViewController.swift
//  pokeFinder
//
//  Created by Brunno Goncalves on 24/11/16.
//  Copyright © 2016 brunnogoncalves. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var geoFire: GeoFire!
    var geoFireReference: FIRDatabaseReference!
    var mapIsCentered: Bool = false
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        locationManager.delegate = self
        
        geoFireReference = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireReference)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        locationAuthStatus()
        
    }
    
    func locationAuthStatus(){
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            
            mapView.showsUserLocation = true
            
        } else{
            
            locationManager.requestWhenInUseAuthorization()
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            
            mapView.showsUserLocation = true
            
        }
        
    }
    
    func centerMapCurrentLocation(location: CLLocation){
        
        let coordinate = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinate, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let location = userLocation.location{
            
            if !mapIsCentered{
                
                centerMapCurrentLocation(location: location)
                mapIsCentered = true
                
            }
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView?
        let annotationId: String = "Pokemon"
        
        if annotation.isKind(of: MKUserLocation.self){
            
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
            
        } else if let dequeAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annotationId){
            
            annotationView = dequeAnno
            annotationView?.annotation = annotation
            
        } else{
            
            let annoView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationId)
            annoView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = annoView
            
        }
        
        if let annotationView = annotationView, let annotation = annotation as? PokeAnnotation{
            
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(annotation.podeId)")
            let button = UIButton()
            button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            button.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = button
            
        }
        
        return annotationView
        
    }
    
    func createPick(forLocation location: CLLocation, withPokemon pokeId: Int){
        
        geoFire.setLocation(location, forKey: "\(pokeId)")
        
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showPokeOnMap(location: location)
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let annotation = view.annotation as? PokeAnnotation{
            
            let placeMark = MKPlacemark(coordinate: annotation.coordinate)
            let destination = MKMapItem(placemark: placeMark)
            destination.name = "Pokemon found"
            let regionDist: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionDist, regionDist)
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            MKMapItem.openMaps(with: [destination], launchOptions: options)
            
        }
        
    }
    
    func showPokeOnMap(location: CLLocation){
        
        let query = geoFire.query(at: location, withRadius: 2.5)
        
        _ = query?.observe(GFEventType.keyEntered, with: { (key, location) in
            
            if let key = key, let location = location{
                
                let annotation = PokeAnnotation(coordinate: location.coordinate, pokeId: Int(key)!)
                self.mapView.addAnnotation(annotation)
                
            }
            
        })
        
    }
    
    @IBAction func pokeballPressed(_ sender: AnyObject){
        
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let rand = arc4random_uniform(151) + 1
        
        createPick(forLocation: location, withPokemon: Int(rand))
        
    }

}

