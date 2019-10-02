
import Foundation
import Metal
import MetalKit

 public protocol RecordableMetalDelegate {
    func didCompleteRecording(url: URL)
    func didFailRecording(error: Error)
}
 public class RecordableMetalView: MTKView{
    
    var ciImage: CIImage?
    //GPU Delegate
    private var context: CIContext!
    // Recording Properties
    private var isRecoding = false
    private var trackUrl: URL?
    private var audioFileUrl: URL?
    private var isTrackSelected = false;
    private var fileUrl: URL?
    private var recoder: MetalVideoRecorder?
    private var audioRecorder: Recording?
    public var recordingDelegate: RecordableMetalDelegate? = nil
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private lazy var commandQueue: MTLCommandQueue? = {
        return self.device!.makeCommandQueue()
    }()
    
    private lazy var content: CIContext = {
        return CIContext(mtlDevice: self.device!, options: [kCIContextWorkingColorSpace : NSNull()])
    }()
    
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setupMetal()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        // Make sure we are on a device that can run metal!
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Device loading error")
        }
        device = defaultDevice
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0.1, green: 0.57, blue: 0.25, alpha: 1)
        setupMetal()
       
    }
    
    private func setupMetal(){
        self.layer.zPosition = 0
        context = CIContext(mtlDevice: device!, options: [kCIContextPriorityRequestLow: NSNumber(booleanLiteral: true)])
        commandQueue = device!.makeCommandQueue()!
        self.framebufferOnly = false
        self.colorPixelFormat = .bgra8Unorm
        self.device = device
    }
    
    
    public func draw(ciimage: CIImage){
        self.ciImage = ciimage
    }
    
    override public func draw(_ rect: CGRect) {
       
        guard let image = ciImage,
            let currentDrawable = currentDrawable,
            let commandBuffer = commandQueue?.makeCommandBuffer()
            else {
                return
        }
        let currentTexture = currentDrawable.texture
        let drawingBounds = CGRect(origin: .zero, size: drawableSize)
        
        let scaleX = drawableSize.width / image.extent.width
        let scaleY = drawableSize.height / image.extent.height
         let scale = min(scaleX, scaleY)
        let width = image.extent.width * scale
        let height = image.extent.height * scale
        let originX = (drawingBounds.width - width) / 2
        let originY = (drawingBounds.height - height) / 2
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY)).transformed(by: CGAffineTransform(translationX: originX, y: originY))
        
        content.render(scaledImage, to: currentTexture, commandBuffer: commandBuffer, bounds: scaledImage.extent, colorSpace: colorSpace)
        
        if isRecoding {
            commandBuffer.addCompletedHandler { (buffer) in
                self.recoder?.writeFrame(forTexture: currentTexture)
            }
        }
        
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
        
        
    }
}

// Recording extention
extension RecordableMetalView{
    
    fileprivate func startRecording(){
        //print("Recording will start")
        if isRecoding == false{
            let appname = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            let name = appname + String(Int(CFAbsoluteTimeGetCurrent()))
            self.fileUrl = createFile(name: name)
            //prepExporter()
            recoder = MetalVideoRecorder(outputURL: self.fileUrl!, size: self.drawableSize)
            //recoder?.setExporter(exporter: self.exporter!)
            createAudioRecorder()
            isRecoding=true
            //With track
            if isTrackSelected {
                playTrack()
                recoder?.setUpAudio()
            }
                // Without Track with MIC
            else{
                recoder?.setUpAudio()
                startAudioRecording()
            }
        }
        
    }
    
   fileprivate func createFile(name: String)->URL{
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
        let filePath="\(documentsPath)/"+name+".mp4"
        let url = URL(fileURLWithPath: filePath)
        // let url = URL(fileReferenceLiteralResourceName: filePath)
        let audioFilePath = "\(documentsPath)/"+name+"aud.m4a"
        self.audioFileUrl = URL(fileURLWithPath: audioFilePath)
        
        return url
    }
    
    
    fileprivate  func createAudioRecorder() {
        
        if isTrackSelected {
            
            guard let media = self.trackUrl else{
                createAudioRecorderWithoutTrack()
                return
            }
            
            audioRecorder = Recording(to: media)
            do {
                try self.audioRecorder!.prepare()
            } catch {
                print(error)
            }
        }
            
        else{
            createAudioRecorderWithoutTrack()
        }
        
    }
    
    fileprivate func createAudioRecorderWithoutTrack(){
        audioRecorder = Recording(to: "recording.m4a")
        //audioRecorder?.delegate = self
        do {
            try self.audioRecorder!.prepare()
        } catch {
            print(error)
        }
    }
    func playTrack(){
        
        guard self.trackUrl != nil else {
            return
        }
        
        do {
            try audioRecorder!.play()
        } catch {
            print(error)
        }
        
    }
    private func startAudioRecording() {
        
        do {
            try audioRecorder!.record()
            //print("Audio recording")
        } catch {
            print(error)
        }
    }
    
    
    func endRecording(){
        if isRecoding{
            isRecoding=false
            stopAudioRecording()
            recoder?.endRecording({(
               // print("Ended Recor"),
                self.merge()
                
                )})
            
        }
    }
    
    func merge(){
        
        let merger = Merger()
        merger.mergeVideoWithAudio(videoUrl: fileUrl!, audioUrl: audioRecorder!.getUrl(), success: {url in
           // print("Merger success")
            self.fileUrl = url
            if let rDelegate = self.recordingDelegate{
                rDelegate.didCompleteRecording(url: url)
            }
         //   self.saveFile()
        }, failure: {error in
           // print("Merge fail \(String(describing: error))")
            if let rDelegate = self.recordingDelegate{
                rDelegate.didFailRecording(error: error!)
            }
        })
        
        
        
    }
    
    
    func stopAudioRecording() {
        audioRecorder?.stop()
       // print("Audio recording stopped")
    }
    
    public func startVideoRecoding(){
        startRecording()
    }
    
    public func startVideoRecoding(backGroundAudioUrl: URL){
        self.trackUrl = backGroundAudioUrl
        self.isTrackSelected = true
        startRecording()
    }
    public func stopVideoRecording(){
    
        endRecording()
        
    }
    
    
}
