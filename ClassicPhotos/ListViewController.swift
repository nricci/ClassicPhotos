//
//  ListViewController.swift
//  ClassicPhotos
//
//  Created by Richard Turton on 03/07/2014.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import UIKit



class ListViewController: UITableViewController {
    
    let manager = PhotoManager.instance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Classic Photos"
        self.manager.delegate = self
        manager.fetchPhotoDetails()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // #pragma mark - Table view data source
    
    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return manager.photosRecords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
        
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            cell.accessoryView = indicator
        }
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        let photoDetails = manager.photosRecords[indexPath.row]
        
        cell.textLabel?.text = photoDetails.name
        cell.imageView?.image = photoDetails.image
        
        switch (photoDetails.state){
        case .Filtered:
            indicator.stopAnimating()
        case .Failed:
            indicator.stopAnimating()
            cell.textLabel?.text = "Failed to load"
        case .New, .Downloaded:
            indicator.startAnimating()
            if (!tableView.isDragging && !tableView.isDecelerating) {
                manager.startOperationsForPhotoRecord(indexPath: indexPath)
            }
        }
        
        return cell
    }
    
}

/* Methods from PhotoManagerDelegate
 * They serve to notify the controller of model changes
 * error and network activity
*/
extension ListViewController : PhotoManagerDelegate {
    
    func networkActivity(inUse: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = inUse
    }
    
    
    func modelDidChange() {
        self.tableView.reloadData()
    }
    
    
    func errorFetchingData() {
        let alert = UIAlertView(title:"Oops!",message:"Error fetching data", delegate:nil, cancelButtonTitle:"OK")
        alert.show()
    }
    
}


/* Override for methods from UIScrollView.
 * Cancel and restart operations based on visible cells
 * and dragging of the table
*/
extension ListViewController {
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        manager.suspendAllOperations()
    }
    

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let indexes = Set(self.tableView.indexPathsForVisibleRows ?? [])
            manager.loadImagesForOnscreenCells(visibleCells:indexes)
            manager.resumeAllOperations()
        }
    }
    
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexes = Set(self.tableView.indexPathsForVisibleRows ?? [])
        manager.loadImagesForOnscreenCells(visibleCells:indexes)
        manager.resumeAllOperations()
    }
    
}
