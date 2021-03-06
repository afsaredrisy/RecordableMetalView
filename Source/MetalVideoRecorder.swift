//
//  MetalVideoRecorder.swift
//  Nex2meV01
//
//  Created by Afsar Sir on 11/09/19.fAssetWriter
//  Copyright © 2019 Introtuce. All rights reserved.
//

import Foundation
import UIKit
import MetalKit
import Metal
import AVFoundation
import Photos
protocol ErrorDelegate{
    func didErrorOccured()
}


class MetalVideoRecorder: NSObject{
    
    var descriptioni: String
    var errorDelegate: ErrorDelegate?
    var isRecording = false
    var recordingStartTime = TimeInterval(0)
    var url: URL
    
    //Video related properties
    private var assetWriter: AVAssetWriter
    private var assetWriterVideoInput: AVAssetWriterInput
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor
    private var audioBuffer: CMSampleBuffer?
    private var exporter: SongExporter?
    
    //Audio related properties
    private var assertWriterAudioInput: AVAssetWriterInput
    private var audioConnection: AVCaptureConnection?
    private var audioOutput: AVCaptureAudioDataOutput
  
    private var session: AVCaptureSession = AVCaptureSession()
    
    private var recordingQueue = DispatchQueue(label: "recording.queue")
    
    init?(outputURL url: URL, size: CGSize) {
        self.url=url
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: AVFileType.mp4)
            self.assetWriter.movieFragmentInterval = CMTime.invalid
            self.assetWriter.shouldOptimizeForNetworkUse = true

        } catch {
            print("Initialization fail with file")
            return nil
        }
        
        let outputSettings: [String: Any] = [ AVVideoCodecKey : AVVideoCodecType.h264,
                                              AVVideoWidthKey : size.width,
                                              AVVideoHeightKey : size.height ]
        
        
        let audioSettings = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0,
            AVEncoderBitRateKey: 192000
            ] as [String : Any]
        

        
        
        assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        
        self.assertWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaType.audio,
                                                         outputSettings: audioSettings)
        
        
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assertWriterAudioInput.expectsMediaDataInRealTime = true
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String : size.width,
            kCVPixelBufferHeightKey as String : size.height ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        assetWriter.add(assetWriterVideoInput)
        
        if assetWriter.canAdd(assertWriterAudioInput){
            print("Added AudioInput")
            assetWriter.add(assertWriterAudioInput)
        }
        else{
            print("Can not add Audio input")
        }
        
        self.audioOutput = AVCaptureAudioDataOutput()
        self.descriptioni = "Nex2me"
        print("At metal initialization")
    }
    
    
    
    func setUpAudio(){
        print("Settingup audio")
        DispatchQueue.main.async{
            
            //setup Audio source
            self.session.beginConfiguration()
            
            
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            
            let audioIn = try? AVCaptureDeviceInput(device: audioDevice!)
            
            if self.session.canAddInput(audioIn!) {
                self.session.addInput(audioIn!)
            }
            if self.session.canAddOutput(self.audioOutput) {
                self.session.addOutput(self.audioOutput)
            }
            self.audioConnection = self.audioOutput.connection(with: AVMediaType.audio)
            self.session.commitConfiguration()
            self.startRecording()
       }
    }
    
    func setExporter(exporter: SongExporter)  {
        
        self.exporter = exporter
        
        
        
    }
    
    
    func startRecording() {
       
        
        assetWriter.startWriting()
         self.audioOutput.setSampleBufferDelegate(self, queue: self.recordingQueue)
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        recordingStartTime = CACurrentMediaTime()
        isRecording = true
        session.startRunning()
    }
    
    func endRecording(_ completionHandler: @escaping () -> ()) {
        isRecording = false
        session.stopRunning()
        //assetWriter.startWriting()
        self.audioOutput.setSampleBufferDelegate(nil, queue: nil)
        self.assertWriterAudioInput.markAsFinished()
        assetWriterVideoInput.markAsFinished()
        assetWriter.finishWriting(completionHandler: completionHandler)
    }
    
    func writeFrame(forTexture texture: MTLTexture) {
        if !isRecording {
            return
        }
        
        while !assetWriterVideoInput.isReadyForMoreMediaData {}
        
        guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
            print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
            //try file exits or not
            if let delegate = errorDelegate{
                delegate.didErrorOccured()
            }
            //checkFile(path: url.path)
            
            return
        }
       // checkFile(path: url.path)
        var maybePixelBuffer: CVPixelBuffer? = nil
        let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
        if status != kCVReturnSuccess {
            print("Could not get pixel buffer from asset writer input; dropping frame...")
            return
        }
        
        guard let pixelBuffer = maybePixelBuffer else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        
        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let frameTime = CACurrentMediaTime() - recordingStartTime
        let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 240)
        assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
       
        
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
    
    
    func checkFile(path: String){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("nexmetest") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("FILE AVAILABLE")
            } else {
                print("FILE NOT AVAILABLE")
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
    }
    
    
}
extension MetalVideoRecorder: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let description = CMSampleBufferGetFormatDescription(sampleBuffer)!
        
        if CMFormatDescriptionGetMediaType(description) == kCMMediaType_Audio {
            if self.assertWriterAudioInput.isReadyForMoreMediaData {
                self.audioBuffer = sampleBuffer
                if self.exporter != nil {
                    exporter?.writeAudioAsset(buffer: sampleBuffer)
                     print("Sending to exporter")
                }
            }
        }
    }
}

