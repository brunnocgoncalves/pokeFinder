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
        
        if annotation.isKind(of: MKUserLocation.self){
            
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
            
        }
        
        return annotationView
        
    }
    
    func createPick(forLocation location: CLLocation, withPokemon pokeId: Int){
        
        geoFire.setLocation(location, forKey: "\(pokeId)")
        
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
        
        
    }

}

