//
//  PhotoManager.swift
//  ClassicPhotos
//
//  Created by Nicolas Ricci on 29/6/17.
//  Copyright © 2017 raywenderlich. All rights reserved.
//

import Foundation


protocol PhotoManagerDelegate : NSObjectProtocol {
    func networkActivity(inUse: Bool)
    func modelDidChange()
    func errorFetchingData()
}


class PhotoManager {
    
    static var instance = PhotoManager()

    var photosRecords = [PhotoRecord]()
    
    let pendingOperations = PendingOperations()
    
    weak var delegate : PhotoManagerDelegate?
    
    
    func fetchPhotoDetails() {
        let request = URLRequest(url: API.dataSourceURL)
        
        DispatchQueue.main.async {
            self.delegate?.networkActivity(inUse: true)
        }
        
        let q = OperationQueue()
        q.qualityOfService = .userInitiated
        NSURLConnection.sendAsynchronousRequest(request, queue: q) {response,data,error in
            if data != nil {
                do {
                    let datasourceDictionary = try PropertyListSerialization.propertyList(from: data!, options: [] , format: nil) as! NSDictionary
                    
                    for (key, value) in datasourceDictionary {
                        let name = key as? String
                        let url = URL(string: value as? String ?? "")
                        
                        if name != nil && url != nil {
                            let photoRecord = PhotoRecord(name: name!, url: url!)
                            self.photosRecords.append(photoRecord)
                        }
                    }
                } catch {
                    return
                }
                DispatchQueue.main.async {
                    self.delegate?.modelDidChange()
                }
            }
            
            if error != nil {
                DispatchQueue.main.async {
                    self.delegate?.errorFetchingData()
                }
            }
            DispatchQueue.main.async {
                self.delegate?.networkActivity(inUse: false)
            }
        }
    }
    
    func loadImagesForOnscreenCells(visibleCells: Set<IndexPath>) {
        
        var allPendingOperations = Set(pendingOperations.downloadsInProgress.keys)
        allPendingOperations.formUnion(Set(pendingOperations.filtrationsInProgress.keys))
        
        var toBeCancelled = allPendingOperations
        toBeCancelled.subtract(visibleCells)
        
        var toBeStarted = visibleCells
        toBeStarted.subtract(allPendingOperations)
        
        for indexPath in toBeCancelled {
            if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                pendingDownload.cancel()
            }
            pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
            if let pendingFiltration = pendingOperations.filtrationsInProgress[indexPath] {
                pendingFiltration.cancel()
            }
            pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
        }
        
        for indexPath in toBeStarted {
            let indexPath = indexPath as IndexPath
            startOperationsForPhotoRecord(indexPath: indexPath)
        }
    }
    
    func suspendAllOperations () {
        pendingOperations.downloadQueue.isSuspended = true
        pendingOperations.filtrationQueue.isSuspended = true
    }
    
    func resumeAllOperations () {
        pendingOperations.downloadQueue.isSuspended = false
        pendingOperations.filtrationQueue.isSuspended = false
    }
    
    
    func startOperationsForPhotoRecord(indexPath: IndexPath){
        switch (self.photosRecords[indexPath.row].state) {
        case .New:
            startDownloadForRecord(indexPath: indexPath)
        case .Downloaded:
            startFiltrationForRecord(indexPath: indexPath)
        default: break
        }
    }
    
    private func startDownloadForRecord(indexPath: IndexPath){
        
        if pendingOperations.downloadsInProgress[indexPath] != nil {
            return
        }
    
        let downloader = ImageDownloader(photoRecord: self.photosRecords[indexPath.row])
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            DispatchQueue.main.async {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.delegate?.modelDidChange()
            }
        }
        
        pendingOperations.downloadsInProgress[indexPath] = downloader
        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    private func startFiltrationForRecord(indexPath: IndexPath){
        if pendingOperations.filtrationsInProgress[indexPath] != nil{
            return
        }
        
        let filterer = ImageFiltration(photoRecord: self.photosRecords[indexPath.row])
        filterer.completionBlock = {
            if filterer.isCancelled {
                return
            }
            DispatchQueue.main.async {
                self.pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
                self.delegate?.modelDidChange()
            }
        }
        pendingOperations.filtrationsInProgress[indexPath] = filterer
        pendingOperations.filtrationQueue.addOperation(filterer)
    }
    
    

    
    
    
    
}
