//
//  ViewController.swift
//  SimpleMaps
//
//  Created by Vũ Hoàng Trịnh on 12/7/19.
//  Copyright © 2019 Vũ Hoàng Trịnh. All rights reserved.
//

import UIKit
import MapKit

class Annotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    init(latitude: CLLocationDegrees, longtitue: CLLocationDegrees, title: String?, subtitle: String?) {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longtitue)
        self.title = title
        self.subtitle = subtitle
    }
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {

    // Direction
    var startLocationTextField : UITextField?
    var destinationTextField : UITextField?
    var start : String = ""
    var destination: String = ""
    var startLatitude : Double = 0.0
    var startLongtitude : Double = 0.0
    var destinationLatitude : Double = 0.0
    var destinationLongtitude: Double = 0.0
    let sourceAnnotation = MKPointAnnotation()
    let destinationAnnotation = MKPointAnnotation()

    // Annotation
    var lat : Double = 0.0
    var long :  Double = 0.0
    var titleAnnotation : String = ""
    var subTitleAnnotation : String = ""

    // Search
    var localSearch: MKLocalSearch!
    var localSearchRequest: MKLocalSearch.Request!
    var localSearchResponse: MKLocalSearch.Response!
    var annotation: MKAnnotation!

    // User's location
    var locationManager: CLLocationManager!
    var isCurrentLocation: Bool = false

    var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Display some locations
        display(lat: 10.7323239, long: 106.6527259, title: "My Apartment", subTitle: "1A Tạ Quang Bửu, phường 6, Quận 8, Hồ Chí Minh, Việt Nam")
        display(lat: 10.762802, long: 106.6818438, title: "Trường Đại học Khoa học Tự nhiên TP.HCM", subTitle: "227 Đường Nguyễn Văn Cừ, Phường 4, Quận 5, Hồ Chí Minh, Việt Nam")
        display(lat: 10.7745432, long: 106.6902481, title: "Công Viên Tao Đàn", subTitle: "Trương Định, Phường Bến Thành, Quận 1, Hồ Chí Minh, Việt Nam")
        display(lat: 10.7705174, long: 106.6673321, title: "Vạn Hạnh Mall", subTitle: "11 Sư Vạn Hạnh, Phường 12, Quận 10, Hồ Chí Minh, Việt Nam")
        display(lat: 10.794724, long: 106.7196078, title: "Vincom Landmark 81", subTitle: "208 Nguyễn Hữu Cảnh, Phường 22, Bình Thạnh, Hồ Chí Minh, Việt Nam")
        
        mapView.delegate = self
        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        getCurrentLocation()
        // Do any additional setup after loading the view.
    }

    func display(lat : CLLocationDegrees, long: CLLocationDegrees, title: String? = nil , subTitle: String? = nil) {
        let annotation = Annotation(latitude: lat, longtitue: long, title: title, subtitle: subTitle)
        mapView.addAnnotation(annotation)
    }

    @IBAction func currentLocationTapped(_ sender: Any) {
        getCurrentLocation()
    }
    
    func getCurrentLocation() {
        removeOldDirect()
        if (CLLocationManager.locationServicesEnabled()) {
            if locationManager == nil {
                locationManager = CLLocationManager()
            }
            
            locationManager?.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            isCurrentLocation = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !isCurrentLocation { return }
        
        isCurrentLocation = false
        // Get current location
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
        if self.mapView.annotations.count != 0 {
            annotation = self.mapView.annotations[0]
            self.mapView.removeAnnotation(annotation)
        }
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = location!.coordinate
        pointAnnotation.title = ""
        mapView.addAnnotation(pointAnnotation)
    }
    
    @IBAction func unwindToMapView(segue: UIStoryboardSegue) {
        if let vc = segue.source as? LocationTableViewController {
            titleAnnotation = vc.selectedLocation
            displaySearch(titleAnnotation)
            removeOldDirect()
        }
    }
    
    func displaySearch(_ title: String) {
        if self.mapView.annotations.count != 0 {
            annotation = self.mapView.annotations[0]
            self.mapView.removeAnnotation(annotation)
        }
        localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = title
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { [weak self] (localSearchResponse, error) -> Void in
            if (error != nil){
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            else if localSearchResponse?.mapItems.count == 0 {
                print("Not found")
            }
            else {
                let pointAnnotation = MKPointAnnotation()
                pointAnnotation.title = self?.title
                pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: localSearchResponse!.boundingRegion.center.latitude,longitude: localSearchResponse!.boundingRegion.center.longitude)
                
                let pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
                self!.mapView.centerCoordinate = pointAnnotation.coordinate
                self!.mapView.addAnnotation(pinAnnotationView.annotation!)
            }
        }
    }

    @IBAction func directionTapped(_ sender: Any) {
        let cancelAction = UIAlertAction(title: "Cancel", style:.cancel, handler: nil)
        let alert = UIAlertController(title: "Get Direction", message: "Choose start location", preferredStyle: .alert)
        let userLocation = UIAlertAction(title: "Your Location", style: .default, handler: self.startUserLocationTapped)
        let anotherLocation = UIAlertAction(title: "Another Location", style: .default, handler: self.anotherLocationTapped)
        alert.addAction(userLocation)
        alert.addAction(anotherLocation)
        alert.addAction(cancelAction)
        self.present(alert, animated: false)
    }

    func startUserLocationTapped(alert: UIAlertAction) {
        let get = UIAlertAction(title: "Direction", style: .default, handler: self.getDirectionFromUserLocation)
        let cancelAction = UIAlertAction(title: "Cancel", style:.cancel, handler: nil)
        let alert = UIAlertController(title: "Get Direction", message: "Start from your location", preferredStyle: .alert)
        alert.addTextField { (destinationTextField) in
            self.destinationPoint(textField: destinationTextField)
        }
        alert.addAction(cancelAction)
        alert.addAction(get)
        self.present(alert, animated: false)
        
    }
    func anotherLocationTapped(alert: UIAlertAction){
        let cancelAction = UIAlertAction(title: "Cancel", style:.cancel, handler: nil)
        let get = UIAlertAction(title: "Go", style: .default, handler: self.getDirecttionFromAnotherPoint)
        let alert = UIAlertController(title: "Get Direction", message:"", preferredStyle: .alert)
        alert.addTextField { (startLocationTextField) in
            self.startPoint(textField: startLocationTextField)
        }
        alert.addTextField { (destinationTextField) in
            self.destinationPoint(textField: destinationTextField)
        }
        alert.addAction(cancelAction)
        alert.addAction(get)
        self.present(alert, animated: false)
    }

    func startPoint(textField: UITextField!){
        startLocationTextField = textField
        startLocationTextField?.placeholder = "Choose start location..."
        
    }

    func destinationPoint(textField: UITextField!){
        destinationTextField = textField
        destinationTextField?.placeholder = "Choose destination..."
    }
    
    func getDirectionFromUserLocation(alert: UIAlertAction!){
        alert.isEnabled = true
        if (CLLocationManager.locationServicesEnabled()) {
            if locationManager == nil {
                locationManager = CLLocationManager()
            }
            locationManager?.requestWhenInUseAuthorization()
            locationManager.delegate = self

            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        startLatitude = (locationManager.location as AnyObject).coordinate.latitude
        startLongtitude = (locationManager.location?.coordinate.longitude)!
        
        localSearchRequest = MKLocalSearch.Request()
        let search = destinationTextField?.text
        localSearchRequest.naturalLanguageQuery = search
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { [weak self] (localSearchResponse, error) -> Void in
            if (error != nil){
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            else if localSearchResponse?.mapItems.count == 0 {
                let alert = UIAlertController(title: "Error", message: "Not found", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            else {
                self!.destinationLatitude = (localSearchResponse?.boundingRegion.center.latitude)!
                self!.destinationLongtitude = (localSearchResponse?.boundingRegion.center.longitude)!
                self!.removeOldDirect()
                self!.getDirect(sourcelat: self!.startLatitude, sourcelong: self!.startLongtitude, destinationlat: self!.destinationLatitude, destinationlong: self!.destinationLongtitude)
            }
        }
    }

    func getDirecttionFromAnotherPoint(alert: UIAlertAction) {
        
        localSearchRequest = MKLocalSearch.Request()
        var search = startLocationTextField!.text
        localSearchRequest.naturalLanguageQuery = search
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { [weak self] (localSearchResponse, error) -> Void in
            if (error != nil) {
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            else if localSearchResponse?.mapItems.count == 0 {
                let alert = UIAlertController(title: "Error", message: "Not found", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            else {
                self!.startLatitude = (localSearchResponse?.boundingRegion.center.latitude)!
                self!.startLongtitude = (localSearchResponse?.boundingRegion.center.longitude)!
                search = self!.destinationTextField!.text
                self!.localSearchRequest.naturalLanguageQuery = search
                self!.localSearch = MKLocalSearch(request: self!.localSearchRequest)
                self!.localSearch.start { [weak self] (localSearchResponse, error) -> Void in
                    if (error != nil) {
                        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self?.present(alert, animated: true, completion: nil)
                    }
                    else if localSearchResponse?.mapItems.count == 0 {
                        let alert = UIAlertController(title: "Error", message: "Not found", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self?.present(alert, animated: true, completion: nil)
                    }
                    else {
                        self!.destinationLatitude = (localSearchResponse?.boundingRegion.center.latitude)!
                        self!.destinationLongtitude = (localSearchResponse?.boundingRegion.center.longitude)!
                        self!.removeOldDirect()
                        self!.getDirect(sourcelat: self!.startLatitude, sourcelong: self!.startLongtitude, destinationlat: self!.destinationLatitude, destinationlong: self!.destinationLongtitude)
                    }
                }
            }
        }
    }

    func getDirect(sourcelat: Double, sourcelong: Double, destinationlat: Double, destinationlong: Double){
      
        let sourceLocation = CLLocationCoordinate2D(latitude: sourcelat, longitude: sourcelong)
        let destinationLocation = CLLocationCoordinate2D(latitude: destinationlat, longitude: destinationlong)
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        sourceAnnotation.title = "Start location"
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        destinationAnnotation.title = "Destination"
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) -> Void in
            guard let response = response else {
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
           
            let route = response.routes[0]
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }

    func removeOldDirect(){
        mapView.overlays.forEach {
            if ($0 is MKPolyline) {
                self.mapView.removeOverlay($0)
            }
        }
        mapView.removeAnnotation(sourceAnnotation)
        mapView.removeAnnotation(destinationAnnotation)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let polyLineRender = MKPolylineRenderer(overlay: overlay)
            polyLineRender.strokeColor = UIColor.init(red: 114/255, green: 156/255, blue: 239/255, alpha: 1)
            polyLineRender.lineWidth = 6
            return polyLineRender
    }
}
