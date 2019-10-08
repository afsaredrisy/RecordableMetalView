import Foundation
import AVFoundation
import QuartzCore

@objc public protocol RecorderDelegate: AVAudioRecorderDelegate {
    @objc optional func audioMeterDidUpdate(_ dB: Float)
}

open class Recording : NSObject {
    
    @objc public enum State: Int {
        case none, record, play
    }
    
    static var directory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    open weak var delegate: RecorderDelegate?
  //  open fileprivate(set) var url: URL
     open fileprivate(set) var url: URL
    open fileprivate(set) var state: State = .none
    
    open var bitRate = 192000
    open var sampleRate = 44100.0
    open var channels = 1
    
    fileprivate let session = AVAudioSession.sharedInstance()
    var recorder: AVAudioRecorder?
    fileprivate var player: AVAudioPlayer?
    fileprivate var link: CADisplayLink?
    
    var metering: Bool {
        return delegate?.responds(to: #selector(RecorderDelegate.audioMeterDidUpdate(_:))) == true
    }
    
    // MARK: - Initializers
    
    public init(to: String) {
        url = URL(fileURLWithPath: Recording.directory).appendingPathComponent(to)
        super.init()
    }
   
    public init(to: URL){
        self.url = to
        super.init()
    }
    
    
    // MARK: - Record
    
    open func prepare() throws {
        let settings: [String: AnyObject] = [
            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatAppleLossless) as Int32),
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue as AnyObject,
            AVEncoderBitRateKey: bitRate as AnyObject,
            AVNumberOfChannelsKey: channels as AnyObject,
            AVSampleRateKey: sampleRate as AnyObject
        ]
        
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.prepareToRecord()
        recorder?.delegate = delegate
        recorder?.isMeteringEnabled = metering
    }
    
    open func record() throws {
        if recorder == nil {
            try prepare()
        }
        
        try session.setCategory(AVAudioSession.Category.playAndRecord)
        try session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        
        recorder?.record()
        state = .record
        
        if metering {
            startMetering()
        }
    }
    
    // MARK: - Playback
    
    open func play() throws {
        try session.setCategory(AVAudioSession.Category.playback)
        
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
        state = .play
    }
    
    open func stop() {
        switch state {
        case .play:
            player?.stop()
            player = nil
        case .record:
            recorder?.stop()
            recorder = nil
            stopMetering()
        default:
            break
        }
        
        state = .none
    }
    
    // MARK: - Metering
    
    @objc func updateMeter() {
        print("Matering")
        guard let recorder = recorder else { return }
        
        recorder.updateMeters()
        
        let dB = recorder.averagePower(forChannel: 0)
        
        delegate?.audioMeterDidUpdate?(dB)
    }
    
    fileprivate func startMetering() {
        link = CADisplayLink(target: self, selector: #selector(Recording.updateMeter))
        link?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    fileprivate func stopMetering() {
        link?.invalidate()
        link = nil
    }
}
extension Recording{
    public func getUrl()-> URL{
            return url
    }
}
