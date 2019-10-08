

import UIKit
import AVFoundation
import RecordableMetalView

class ViewController: UIViewController, RecordableMetalDelegate, CameraCaptureDelegate {
    
    
    
    let recordText = "Start Recording"
    let stopText = "Stop Recording"
    @IBOutlet weak var clickMe: UIButton!
    @IBOutlet weak var meatlView: RecordableMetalView!
    let albumName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    var fileUrl: URL?
    var recoding = false
    let staticImage = UIImage(named: "anim")
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
        
        clickMe.layer.cornerRadius = 10
        
        updateUI()
        
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
        updateUI()
        
    }
    
    func updateUI(){
        
        if recoding{
            clickMe.setTitle(stopText, for: .normal)
        }
        else {
            clickMe.setTitle(recordText, for: .normal)
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
        SDPhotosHelper.addNewVideo(withFileUrl: fileUrl, inAlbum: self.albumName, onSuccess: { ( identifier) in
   
            let alert = UIAlertController.init(title: "Success", message: "File added, id : \(identifier)", preferredStyle: .alert)
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
        let maskedCg = imageByMergingImages(topImage: staticImage!, bottomImage: UIImage(cgImage: imageCg!))
        let ciimage = CIImage(cgImage: maskedCg.cgImage!)
        let image : UIImage = UIImage(ciImage: ciimage)
        drawImage(image: image)
        
        
    }
    
    func drawImage(image: UIImage){
        
        
        
        guard let ciimage = image.ciImage else{
            return
        }
        meatlView.draw(ciimage: applyFiletr(ciimage: ciimage))
    }
    
    
    //MARK: Image proccessing
    
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
    
    
    func imageByMergingImages(topImage: UIImage, bottomImage: UIImage, scaleForTop: CGFloat = 1.0) -> UIImage {
        let size = bottomImage.size
        let container = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        UIGraphicsGetCurrentContext()!.interpolationQuality = .high
        bottomImage.draw(in: container)
        
        let topWidth = size.width / scaleForTop
        let topHeight = size.height / scaleForTop
        let topX = (size.width / 2.0) - (topWidth / 2.0)
        let topY = (size.height / 2.0) - (topHeight / 2.0)
        
        topImage.draw(in: CGRect(x: topX, y: topY, width: topWidth, height: topHeight), blendMode: .normal, alpha: 1.0)
        let im = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return im
    }
    
}




