//
//  ViewController.swift
//  MapAllFunctionality


import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblPickup: UILabel!
    @IBOutlet weak var lblLine: UILabel!
    @IBOutlet weak var imgviewPin: UIImageView!
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pickupView: UIView!
    @IBOutlet weak var dropView: UIView!
    @IBOutlet weak var btnZoom: UIButton!
    
    @IBOutlet weak var lblDrop: UILabel!
    
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblX: UILabel!
    var locationManager: CLLocationManager?
    var point: MKPointAnnotation = MKPointAnnotation()
    
    var selectedSeg: Int = 0

    var pickupLocation: CLLocation = CLLocation()
    var dropLocation: CLLocation?
    var pickupAnnotation: MKPointAnnotation = MKPointAnnotation()
    var dropAnnotation: MKPointAnnotation = MKPointAnnotation()
    
    var currentRoute: MKRoute = MKRoute()
    var routeOverlay: MKPolyline = MKPolyline()
    @IBOutlet weak var constrPick: NSLayoutConstraint!
    
    let appdelobj = UIApplication.shared.delegate as! AppDelegate
    
    var isGotRoute : Bool = false
    
     //MARK:- viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        dropLocation = CLLocation()
        locationManager = CLLocationManager()
        
        dropLocation = nil
        
        mapView.delegate = self
        locationManager?.delegate = self
        locationManager?.desiredAccuracy=kCLLocationAccuracyNearestTenMeters;
        locationManager?.distanceFilter=kCLDistanceFilterNone;
        
        
        let sysVer: Float = CFloat(UIDevice.current.systemVersion)!
        if sysVer > 8.00 {
            locationManager?.requestWhenInUseAuthorization()
            locationManager?.requestAlwaysAuthorization()
            locationManager?.startMonitoringSignificantLocationChanges()
        }

        locationManager?.startUpdatingLocation()
        mapView.showsUserLocation = true
        checkLocationAuthorizationStatus()
        
        lblX.isHidden = true
        constrPick.constant = 0
        
        btnBack.isHidden = true
        
        getSavedLocation()
    }
    
    func getSavedLocation()  {
        
        if let pickupDic: NSDictionary = appdelobj.defaults.object(forKey: "pickLocation") as? NSDictionary
        {
            let pickupLat: Double = pickupDic.object(forKey: "pickupLat") as! Double
            let pickupLon: Double = pickupDic.object(forKey: "pickupLon") as! Double
            
            let picklocation: CLLocation = CLLocation(latitude: pickupLat, longitude: pickupLon)
            
            pickupLocation = picklocation
        }
        
        if let dropDic: NSDictionary = appdelobj.defaults.object(forKey: "dropLocation") as? NSDictionary
        {
            let dropLat: Double = dropDic.object(forKey: "dropLat") as! Double
            let dropLon: Double = dropDic.object(forKey: "dropLon") as! Double
            
            let droplocation: CLLocation = CLLocation(latitude: dropLat, longitude: dropLon)
            
            dropLocation = droplocation
        }
        
        if pickupLocation != nil && dropLocation != nil  {
             self.done(self)
             self.btnStart(self)
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        point.title = "Where am I?";
        point.subtitle = "I'm here!!!";
        point.coordinate = mapView.userLocation.coordinate
        mapView.addAnnotation(point)
    }

    //MARK:- LocationAuthorization
    func checkLocationAuthorizationStatus() {
        // get current location
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager?.startUpdatingLocation()
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

   
    //MARK:- UISegmentedControl Action
    @IBAction func swgmentLocation(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedSeg = 0
            imgviewPin.image = UIImage(named: "pick_up_location")
            lblLine.backgroundColor = UIColor.green
            zoomToLocation(locationTo: pickupLocation)
            break
        case 1:
            selectedSeg = 1
            imgviewPin.image = UIImage(named: "drop_off_location")
            lblLine.backgroundColor = UIColor.red
            
            if dropLocation != nil {
                zoomToLocation(locationTo: dropLocation!)
            }
            
            break
        default:
            break;
        }
    }
    
     //MARK:- locationManager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch status {
        case .notDetermined:
            print("NotDetermined")
            locationManager?.requestAlwaysAuthorization()
        case .restricted:
            print("Restricted")
        case .denied:
            print("Denied")
           locationManager?.stopUpdatingLocation()
        case .authorizedAlways:
            print("AuthorizedAlways")
            locationManager?.startUpdatingLocation()
        case .authorizedWhenInUse:
            print("AuthorizedWhenInUse")
            locationManager?.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if locations.count == 0 {
            return
        }
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        let latitude = locValue.latitude
        let longitude = locValue.longitude
        
        for location in locations {
            print("**********************")
            print("Long \(location.coordinate.longitude)")
            print("Lati \(location.coordinate.latitude)")
            print("Alt \(location.altitude)")
            print("Sped \(location.speed)")
            print("Accu \(location.horizontalAccuracy)")
            print("**********************")
        }
        
        //locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to initialize GPS: ", error.localizedDescription)
    }
    
    //MARK:- mapView Delegate
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        var locationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
        locationCoordinate.latitude = userLocation.coordinate.latitude
        locationCoordinate.longitude = userLocation.coordinate.longitude
        zoomMap(byFactor: 0.2, Coordinate2D: locationCoordinate)
    }
    
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if isGotRoute == false {
            lblX.isHidden = false
            constrPick.constant = 30
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            }, completion: {(Bool)  in
                
            })
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //point.coordinate = mapView.centerCoordinate;
        
        if isGotRoute == false {
            lblX.isHidden = true
            constrPick.constant = 0
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            }, completion: {(Bool)  in
                self.getAddressFromLatAndLong()
            })
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer: MKPolylineRenderer = MKPolylineRenderer.init(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        return  renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
    
        let reuseId = "\(annotation.coordinate.longitude)"
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
  
        if pinView == nil {
            
            let annotationView: MKAnnotationView = MKAnnotationView.init(annotation: annotation, reuseIdentifier: reuseId)
            
            annotationView.canShowCallout = true
            annotationView.image = getRightImage(name: annotation.title!!)
                
            pinView?.animatesDrop = true
            
//            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//            pinView?.canShowCallout = true
//            pinView?.animatesDrop = true
//            pinView?.image = getRightImage(name: annotation.title!!)
            
            return annotationView
            
        }
        else{
             pinView?.annotation = annotation
        }

        let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
        pinView?.rightCalloutAccessoryView = button
        button.addTarget(self, action: #selector(ViewController.pinAction), for: UIControl.Event.touchUpInside)
        
        return pinView
    }
    
    @objc func pinAction(sender: UIButton)  {
        print("PinAction Fire")
    }
    
    func getRightImage (name:String)-> UIImage{
        var correctImage = UIImage()
        
        switch name
        {
        case "Pickup":
            correctImage = UIImage(named: "pick_up_location")!
        default:
            correctImage = UIImage(named: "drop_off_location")!
        }
        return correctImage
    }
    
    //MARK:- UIButton Action
    @IBAction func btnStart(_ sender: Any) {
        getDirection()
    }
    
    @IBAction func btnZoom(_ sender: Any) {
    }
    
    @IBAction func done(_ sender: Any) {
        mapView.removeAnnotations([pickupAnnotation,dropAnnotation])
        
        pickupAnnotation.title = "Pickup"
        pickupAnnotation.subtitle = "Passenger Here"
        
        dropAnnotation.title = "Drop"
        dropAnnotation.subtitle = "Drop Here"
        
        pickupAnnotation.coordinate = pickupLocation.coordinate
        dropAnnotation.coordinate = (dropLocation?.coordinate)!
        
        mapView.addAnnotation(pickupAnnotation)
        mapView.addAnnotation(dropAnnotation)
        self.afterRouteDraw()
        
    }
    
    
    //MARK:- Get Direction
    func getDirection() {
        let directionsRequest : MKDirections.Request = MKDirections.Request()
        
        let pickupCoords : CLLocationCoordinate2D = CLLocationCoordinate2DMake(pickupLocation.coordinate.latitude, pickupLocation.coordinate.longitude)
        
        let source : MKMapItem = MKMapItem.init(placemark: MKPlacemark.init(coordinate: pickupCoords))
        
        let destinationCoords : CLLocationCoordinate2D = CLLocationCoordinate2DMake(dropLocation!.coordinate.latitude, dropLocation!.coordinate.longitude)
        
        let destination : MKMapItem = MKMapItem.init(placemark: MKPlacemark.init(coordinate: destinationCoords))
    
        directionsRequest.source = source
        directionsRequest.destination = destination
    
        let directions : MKDirections = MKDirections.init(request: directionsRequest)
        self.mapView.removeOverlay(self.currentRoute.polyline)
        
        directions.calculate { response, error in
            if let route = response?.routes.first {
                print("Distance: \(route.distance), ETA: \(route.expectedTravelTime)")
                 self.currentRoute = route
                
                var add: Double = 0
                
                for steps in self.currentRoute.steps{
                    let step : MKRoute.Step = steps
                    add = add + step.distance;
                }
                
                print("%f",add/1609.344)
                self.lblDistance.text = "\(add/1609.344) Km"
                self.mapView.addOverlay(self.currentRoute.polyline)
                
                self.afterRouteDraw()
                self.saveToDefault()
                
            } else {
                print("Error!")
            }
        }
    }
    
    func saveToDefault()  {
        let pickupLat : Double = Double(pickupLocation.coordinate.latitude)
        let pickupLon : Double = Double(pickupLocation.coordinate.longitude)
        
        let dropLat : Double = Double(dropLocation!.coordinate.latitude)
        let dropLon : Double = Double(dropLocation!.coordinate.longitude)
        
        let pickupDic : NSDictionary = ["pickupLat" : pickupLat , "pickupLon": pickupLon]
        let dropDic : NSDictionary = ["dropLat" : dropLat , "dropLon": dropLon]
        
        appdelobj.defaults.set(pickupDic, forKey: "pickLocation")
        appdelobj.defaults.set(dropDic, forKey: "dropLocation")
    }
    
    //MARK:- Get Address From Location
    func getAddressFromLatAndLong() {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        if self.selectedSeg == 0 {
            pickupLocation = location
        }
        else{
            dropLocation = nil
            dropLocation = CLLocation()
            dropLocation = location
        }
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            
            if placeMark != nil
            {
                // Address dictionary
                print(placeMark.addressDictionary ?? "")
                
                // Location name
                if let locationName = placeMark.addressDictionary!["Name"] as? NSString {
                    print(locationName)
                    if self.selectedSeg == 0 {
                        self.lblPickup.text = "\(locationName as String)"
                    }
                    else
                    {
                        self.lblDrop.text = "\(locationName as String)"
                    }
                }
                
                // Street address
                if let street = placeMark.addressDictionary!["Thoroughfare"] as? NSString {
                    print(street)
                }
                
                // City
                if let city = placeMark.addressDictionary!["City"] as? NSString {
                    print(city)
                }
                
                // Zip code
                if let zip = placeMark.addressDictionary!["ZIP"] as? NSString {
                    print(zip)
                }
                
                // Country
                if let country = placeMark.addressDictionary!["Country"] as? NSString {
                    print(country)
                }
            }
        })
    }
    
    //MARK:- zoom Method
    func zoomToLocation(locationTo: CLLocation) {
        var locationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
        locationCoordinate.latitude = locationTo.coordinate.latitude
        locationCoordinate.longitude = locationTo.coordinate.longitude
        zoomMap(byFactor: 0.05, Coordinate2D: locationCoordinate)
    }
    
    func zoomMap(byFactor delta: Double, Coordinate2D: CLLocationCoordinate2D) {
        var region: MKCoordinateRegion = self.mapView.region
 //       var span: MKCoordinateSpan = mapView.region.span
//        span.latitudeDelta *= delta
//        span.longitudeDelta *= delta
//        region.span = span
        region = MKCoordinateRegion(center: Coordinate2D, latitudinalMeters: 1000, longitudinalMeters: 1000)
        region.center = Coordinate2D
        mapView.centerCoordinate=Coordinate2D;
        mapView.setRegion(region, animated: true)
    }

    func getDistanceZoomLevel() {
        var region: MKCoordinateRegion = self.mapView.region
        
        region.center.latitude =  (pickupLocation.coordinate.latitude +  (dropLocation?.coordinate.latitude)!)/2
        region.center.longitude =  (pickupLocation.coordinate.longitude +  (dropLocation?.coordinate.longitude)!)/2
        
        if pickupLocation.coordinate.latitude > (dropLocation?.coordinate.latitude)! {
            region.span.latitudeDelta = (pickupLocation.coordinate.latitude - (dropLocation?.coordinate.latitude)!) * 1.5;
        }
        else
        {
            region.span.latitudeDelta = ((dropLocation?.coordinate.latitude)! - pickupLocation.coordinate.latitude) * 1.5;
        }
        
        
        if pickupLocation.coordinate.longitude > (dropLocation?.coordinate.longitude)! {
            region.span.longitudeDelta = (pickupLocation.coordinate.longitude - (dropLocation?.coordinate.longitude)!) * 1.5;
        }
        else
        {
            region.span.longitudeDelta = ((dropLocation?.coordinate.longitude)! - pickupLocation.coordinate.longitude) * 1.5;
        }
        
        region.span.latitudeDelta = (region.span.latitudeDelta < 0.05)
            ? 0.05
            : region.span.latitudeDelta;
        
        let scaledRegion : MKCoordinateRegion = mapView.regionThatFits(region)
        mapView.setRegion(scaledRegion, animated: true)
    }
    
    @IBAction func btnBack(_ sender: Any) {
        btnBack.isHidden = true
        mapView.removeAnnotations([pickupAnnotation,dropAnnotation])
        self.mapView.removeOverlay(self.currentRoute.polyline)
        
        segment.selectedSegmentIndex = 0
        self.swgmentLocation(segment)
        self.isGotRoute = false
        lblX.isHidden = false
        lblLine.isHidden = false
        imgviewPin.isHidden = false
        zoomToLocation(locationTo: pickupLocation)
    }
    
    func afterRouteDraw() {
        btnBack.isHidden = false
        
        self.isGotRoute = true
        lblX.isHidden = true
        lblLine.isHidden = true
        imgviewPin.isHidden = true
        getDistanceZoomLevel()
    }
}

