//
//  LocationTableViewController.swift
//  SimpleMaps
//
//  Created by Vũ Hoàng Trịnh on 12/13/19.
//  Copyright © 2019 Vũ Hoàng Trịnh. All rights reserved.
//

import UIKit
import MapKit

class LocationTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    var listLocation : [String] = []
    var filterSearchBar = [String]()
    var selectedLocation: String = ""
    var isSearched : Bool = false
    
    var mapView: MKMapView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        listLocation.append("Tao Dan Park")
        listLocation.append("Nguyen Hue Street")
        listLocation.append("White Palace")
        listLocation.append("University of Science")
        listLocation.append("Now Zone")
        listLocation.append("Hung Vuong Plaza")
        tableView.reloadData()
        searchBar.delegate = self
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterSearchBar.removeAll(keepingCapacity: false)
        
        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (listLocation as NSArray).filtered(using: searchPredicate)
        filterSearchBar = array as! [String]
        
        self.tableView.reloadData()
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        selectedLocation = searchBar.text!
        performSegue(withIdentifier: "unwindToMapViewSegue", sender: self)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearched = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearched = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearched = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterSearchBar = listLocation.filter({ (text) -> Bool in
            let temp: NSString = text as NSString
            let range = temp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
            return range.location != NSNotFound
        })
        if (filterSearchBar.count == 0) {
            isSearched = false;
        }
        else {
            isSearched = true;
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (isSearched) {
            return filterSearchBar.count
        }
        else {
            return listLocation.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
        if (isSearched) {
            cell.textLabel?.text = filterSearchBar[indexPath.row]
        }
        else {
            let selectedItem = listLocation[indexPath.row]
            cell.textLabel?.text = selectedItem
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let index = indexPath.row
        if (isSearched) {
            selectedLocation = filterSearchBar[index]
        }
        else {
            selectedLocation = listLocation[index]
        }
        performSegue(withIdentifier: "unwindToMapViewSegue", sender: self)
    }
}
