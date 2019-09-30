//
//  ViewController.swift
//  RecordMetal
//
//  Created by Introtuce on 28/09/19.
//  Copyright © 2019 Introtuce. All rights reserved.
//

import UIKit
import AVFoundation
import RecordableMetalView

class ViewController: UIViewController, RecordableMetalDelegate, CameraCaptureDelegate {
    
    
    
    
    @IBOutlet weak var clickMe: UIButton!
    @IBOutlet weak var meatlView: RecordableMetalView!
    let albumName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    var fileUrl: URL?
    var recoding = false
    
    let cameraCapturer = CameraCapture()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cameraCapturer.delegate = self
        meatlView.layer.zPosition = 0
        print("View is apearing")
        let image = UIImage(named: "bgimg")
        let ciimage = CIImage(cgImage: (image?.cgImage)!)
        meatlView.recordingDelegate = self
        meatlView.draw(ciimage: ciimage)
        
    }
    
    @IBAction func clikMeAction(_ sender: Any) {
        
        meatlView.draw()
        
        if recoding{
            meatlView.stopVideoRecording()
            recoding = false
            
        }
        else{
            recoding = true
            meatlView.startVideoRecoding()
        }
        
    }
    func didCompleteRecording(url: URL) {
        print("Completed at \(url)")
        self.fileUrl = url
        createAlbumAndSave()
    }
    
    func didFailRecording(error: Error) {
        print("Error: \(error)")
    }
    func createAlbumAndSave()
    {
        createAlbum()
    }
    
    func createAlbum(){
        SDPhotosHelper.createAlbum(withTitle: self.albumName) { (success, error) in
            if success {
                print("Created album : \(self.albumName)")
                self.saveFileWithSD(fileUrl: self.fileUrl!)
            } else {
                if let error = error {
                    print("Error in creating album : \(error.localizedDescription)")
                    self.saveFileWithSD(fileUrl: self.fileUrl!)
                }
            }
        }
        
    }
    
    func saveFileWithSD(fileUrl: URL){
        //saveImageWithSD()
        print("Saving with SD")
        SDPhotosHelper.addNewVideo(withFileUrl: fileUrl, inAlbum: self.albumName, onSuccess: { ( identifier) in
            print("Saved image successfully, identifier is \(identifier)")
            let alert = UIAlertController.init(title: "Success", message: "Image added, id : \(identifier)", preferredStyle: .alert)
            let actionOk = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
            alert.addAction(actionOk)
            OperationQueue.main.addOperation({
                self.present(alert, animated: true, completion: nil)
            })
        }) { (error) in
            if let error = error {
                print("Error in creating album : \(error.localizedDescription)")
            }
        }
        
        
        
    }
    
    
    
    func bufferCaptured(buffer: CMSampleBuffer!) {
        
        guard let pixelBuffer =  CMSampleBufferGetImageBuffer(buffer) else {
            return
        }
        
        let imageCg = CGImage.create(pixelBuffer: pixelBuffer)
        let ciimage = CIImage(cgImage: imageCg!)
        let image : UIImage = UIImage(ciImage: ciimage)
        
        drawImage(image: image)
        
        
    }
    
    func drawImage(image: UIImage){
        
        guard let ciimage = image.ciImage else{
            return
        }
        meatlView.draw(ciimage: applyFiletr(ciimage: ciimage))
    }
    func applyFiletr(ciimage: CIImage) -> CIImage{
        if let currentFilter = CIFilter(name: "CISepiaTone"){
            currentFilter.setValue(ciimage, forKey: kCIInputImageKey)
            currentFilter.setValue(0.5, forKey: kCIInputIntensityKey)
            
            if let output = currentFilter.outputImage{
                return output
            }
            
        }
        return ciimage
        
    }
    
    
    
}

