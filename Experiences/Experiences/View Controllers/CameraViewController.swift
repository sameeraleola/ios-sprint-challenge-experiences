//
//  CameraViewController.swift
//  Experiences
//
//  Created by Sameera Roussi on 7/29/19.
//  Copyright © 2019 Sameera Roussi. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    private var player: AVPlayer!
    var experienceTitle: String?
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = bestCamera()
        
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
            fatalError("Can't create input from camera")
        }
        
        // Setup inputs
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            fatalError("Can't find microphone")
        }
        
        guard let microphoneInput = try? AVCaptureDeviceInput(device: microphone) else {
            fatalError("Can't create input from microphone")
        }
        
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
        
        
        // Setup outputs
        if captureSession.canAddOutput(fileOutput) {
            captureSession.addOutput(fileOutput)
        }
        
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.canSetSessionPreset(.hd1920x1080)
        }
        
        captureSession.commitConfiguration()
        
        cameraView.session = captureSession
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("The title is \(String(describing: experienceTitle))")
    }
    
    
    @objc func handleTapGesture(_ tapGesture: UITapGestureRecognizer) {
        // play the movie
        if let player = player {
            player.seek(to: CMTime.zero)
            player.play()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }
    
    
    private func bestCamera() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        
        fatalError("No cameras exist - you're probably running on the simulator")
    }
    
    func newRecordingURL() -> URL {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let name = "movie"  // TODO: Use ISO8601Formatter with a Date
        let url = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
        print("Url: \(url)")
        return url
    }
    
    func updateViews() {
        if fileOutput.isRecording {
            recordButton.setImage(UIImage(named: "Stop"), for: .normal)
            recordButton.tintColor = UIColor.black
        } else {
            recordButton.setImage(UIImage(named: "Record"), for: .normal)
            recordButton.tintColor = UIColor.red
        }
    }
    
    func playMovie(url: URL) {
        
        player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        var topRect = self.view.bounds
        topRect.size.width = topRect.width / 4
        topRect.size.height = topRect.height / 4
        topRect.origin.y = view.layoutMargins.top
        
        playerLayer.frame = topRect
        
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
    }
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        print("Record")
        
        if fileOutput.isRecording {
            fileOutput.stopRecording()
        } else {
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        self.navigationController!.popToRootViewController(animated: true)
    }
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
        DispatchQueue.main.async {
            self.updateViews()
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        DispatchQueue.main.async {
            self.updateViews()
            self.playMovie(url: outputFileURL)
        }
    }
    
    
}
