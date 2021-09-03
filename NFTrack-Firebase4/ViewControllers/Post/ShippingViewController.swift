//
//  ShippingViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-30.
//

import UIKit
import MapKit

protocol ShippingDelegate: AnyObject {
    func didFetchShippingInfo(_ shippingInfo: ShippingInfo)
}

class ShippingViewController: MapViewController, TableViewConfigurable, UITextFieldDelegate {
    private var filteredSearchVC: FilteredLocationSearchViewController!
    private var radiusTitleLabel: UILabel!
    private var radiusTextField: UITextField!
    lazy private var radiusTitleHeightConstraint: NSLayoutConstraint! = radiusTitleLabel.heightAnchor.constraint(equalToConstant: 0)
    lazy private var radiusTextFieldHeightConstraint: NSLayoutConstraint! = radiusTextField.heightAnchor.constraint(equalToConstant: 0)
    lazy private var refreshButtonHeightConstraint: NSLayoutConstraint! = refreshButton.heightAnchor.constraint(equalToConstant: 0)
    lazy private var addressTitleTopConstraint: NSLayoutConstraint! = addressTitleLabel.topAnchor.constraint(equalTo: radiusTextField.bottomAnchor, constant: 0)
    private var refreshButton: UIButton!
    private var infoButtonItem: UIBarButtonItem!
    lazy private var scrollView: UIScrollView! = {
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.fill()
        return scrollView
    }()
    private var addressTitleLabel: UILabel!
    private var addressTableView: UITableView!
    private var submitButton: UIButton!
    private var dataSource = [String]() {
        didSet {
            var filtered = Set<String>()
            dataSource = dataSource.filter { filtered.insert($0).inserted }
        }
    }
    private var radius: CLLocationDistance! = 1000
    private var placemark: MKPlacemark!
    private var alert: Alerts!
    private var scopeRetainer: ShippingRestriction! = .cities
    final weak var shippingDelegate: ShippingDelegate?
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureSelectedAddressDisplay()
        setConstraints()
    }
    
    final override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    final override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let contentHeight: CGFloat = mapView.bounds.size.height + addressTableView.bounds.size.height + submitButton.bounds.size.height + 350
        if scrollView != nil {
            let contentSize = CGSize(
                width: view.bounds.size.width,
                height: contentHeight
            )
            
            scrollView.contentSize = contentSize
        }
    }
    
    final override func configureUI() {
        super.configureUI()
        title = "Shipping Info"
        alert = Alerts()
        
        radiusTitleLabel = createTitleLabel(text: "Radius")
        scrollView.addSubview(radiusTitleLabel)
        
        let configuration = UIImage.SymbolConfiguration(pointSize: 30, weight: .light, scale: .large)
        guard let refreshImage = UIImage(systemName: "arrow.clockwise.circle")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal).withConfiguration(configuration) else { return }
        refreshButton = UIButton.systemButton(with: refreshImage, target: self, action: #selector(mapButtonPressed(_:)))
        refreshButton.tag = 5
//        refreshButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        refreshButton.transform = CGAffineTransform(translationX: 0, y: 7)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(refreshButton)
        
        radiusTextField = createTextField(placeHolder: "In meters", delegate: self)
        radiusTextField.keyboardType = .decimalPad
        scrollView.addSubview(radiusTextField)
        
        addressTitleLabel = createTitleLabel(text: "Selected Addresses")
        scrollView.addSubview(addressTitleLabel)
        
        submitButton = UIButton()
        submitButton.backgroundColor = .black
        submitButton.layer.cornerRadius = 5
        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(mapButtonPressed(_:)), for: .touchUpInside)
        submitButton.tag = 4
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(submitButton)
    }
    
    final override func configureNavigationBar() {
        guard let infoImage = UIImage(systemName: "info.circle") else { return }
        infoButtonItem = UIBarButtonItem(image: infoImage, style: .plain, target: self, action: #selector(mapButtonPressed(_:)))
        infoButtonItem.tag = 3
        self.navigationItem.rightBarButtonItem = infoButtonItem
    }
    
    final override func configureMapView() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 10
        mapView.delegate = self
        mapView.dropShadow()
        scrollView.addSubview(mapView)
    }
    
    private func configureSelectedAddressDisplay() {
        addressTableView = configureTableView(
            delegate: self,
            dataSource: self,
            height: nil,
            estimatedRowHeight: nil,
            cellType: UITableViewCell.self,
            identifier: "Cell"
        )
        addressTableView.separatorStyle = .none
        addressTableView.layer.cornerRadius = 10
        addressTableView.layer.borderWidth = 0.5
        addressTableView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        addressTableView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(addressTableView)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 25),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mapView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: 0.3),
            
            radiusTitleLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 35),
            radiusTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            radiusTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            radiusTitleHeightConstraint,
            
            refreshButton.topAnchor.constraint(equalTo: radiusTitleLabel.bottomAnchor, constant: 10),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            refreshButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            refreshButtonHeightConstraint,
            
            radiusTextField.topAnchor.constraint(equalTo: radiusTitleLabel.bottomAnchor, constant: 10),
            radiusTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            radiusTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            radiusTextFieldHeightConstraint,
            
            addressTitleTopConstraint,
            addressTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addressTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            addressTableView.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 10),
            addressTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addressTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addressTableView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: 0.3),

            submitButton.topAnchor.constraint(equalTo: addressTableView.bottomAnchor, constant: 40),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    override func configureSearch() {
        filteredSearchVC = FilteredLocationSearchViewController(regionRadius: regionRadius)
        filteredSearchVC.handleMapSearchDelegate = self
        
        if let location = location {
            filteredSearchVC.location = location
        }
        
        resultSearchController = UISearchController(searchResultsController: filteredSearchVC)
        resultSearchController.searchResultsUpdater = filteredSearchVC
        navigationItem.searchController = resultSearchController

        guard let searchBar = resultSearchController?.searchBar else { return }
        searchBar.sizeToFit()
        searchBar.delegate = filteredSearchVC
        searchBar.placeholder = "Search for places"
        searchBar.scopeButtonTitles = ShippingRestriction.getAll()
        resultSearchController?.hidesNavigationBarDuringPresentation = true
        resultSearchController?.obscuresBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    override func mapButtonPressed(_ sender: UIButton) {
        super.mapButtonPressed(sender)
        
        switch sender.tag {
            case 3:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Shipping Info", detail: InfoText.shippingInfo)])
                self.present(infoVC, animated: true, completion: nil)
            case 4:
                let shippingInfo = ShippingInfo(
                    scope: scopeRetainer,
                    addresses: dataSource,
                    radius: radius,
                    longitude: placemark?.coordinate.longitude,
                    latitude: placemark?.coordinate.latitude
                )
                
                shippingDelegate?.didFetchShippingInfo(shippingInfo)
                navigationController?.popViewController(animated: true)
                break
            case 5:
                if placemark != nil,
                   let radiusText = self.radiusTextField?.text,
                   let convertedRadius = Double(radiusText) {
                    radius = convertedRadius
                    showCircle(coordinate: placemark.coordinate, radius: convertedRadius)
                }
                break
            default:
                break
        }
    }
    
    override func dropPinZoomIn(placemark: MKPlacemark, addressString: String?, scope: ShippingRestriction?) {
        super.dropPinZoomIn(placemark: placemark, addressString: addressString, scope: scope)
        guard let addressString = addressString else { return }
        self.placemark = placemark
        scopeRetainer = scope
        
        if scope == .distance {
            if dataSource.count > 0 {
                alert.showDetail("Address Limit", with: "You can only up to one address for the Distance category.", for: self)
            } else {
                dataSource.append(addressString)
                showCircle(coordinate: placemark.coordinate, radius: radius)
            }
            
            radiusTitleHeightConstraint.constant = 40
            refreshButtonHeightConstraint.constant = 40
            radiusTextFieldHeightConstraint.constant = 50
            addressTitleTopConstraint.constant = 40
        } else {
            dataSource.append(addressString)
            radiusTitleHeightConstraint.constant = 0
            refreshButtonHeightConstraint.constant = 0
            radiusTextFieldHeightConstraint.constant = 0
            addressTitleTopConstraint.constant = 0
        }
        
        addressTableView.reloadData()
    }
    
    // Radius is measured in meters
    func showCircle(coordinate: CLLocationCoordinate2D,
                    radius: CLLocationDistance) {
        let circle = MKCircle(center: coordinate,
                              radius: radius)
    
        mapView.overlays.forEach { mapView.removeOverlay($0) }
        mapView.addOverlay(circle)
    }
    
    // the search result has to be reset every time the scope is changed throught the segmented control.
    // this is to prevent the results of different scopes to be mixed together.
    override func resetSearchResults() {
        dataSource.removeAll()
        addressTableView.reloadData()
    }
}

extension ShippingViewController {
    final override func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        filteredSearchVC.location = location
    }
}

extension ShippingViewController: UITableViewDelegate, UITableViewDataSource {
    final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        let addressString = dataSource[indexPath.section]
        cell.textLabel?.text = addressString
        cell.textLabel?.sizeToFit()
        cell.textLabel?.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.layer.cornerRadius = 10
        cell.textLabel?.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        alert.showDetail("Delete Address", with: "Proceed to delete the address?", for: self, alertStyle: .withCancelButton) { [weak self] in
            self?.dataSource.remove(at: indexPath.section)
            tableView.deleteSections([indexPath.section], with: .fade)
        } completion: {
        
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            dataSource.remove(at: indexPath.section)
            tableView.deleteSections([indexPath.section], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}

extension ShippingViewController {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = .black
        circleRenderer.alpha = 0.1
        
        return circleRenderer
    }
}
