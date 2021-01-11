//
//  PoseEstimationViewController.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 02.12.2020.
//

import UIKit
import Vision
import AVFoundation

class PoseEstimationViewController: UIViewController {
    
    var poseMatching: Bool = true
    
    var cameraPosition: AVCaptureDevice.Position = .back
    
    private var cameraView: CameraView { view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    internal var cameraFeedSession: AVCaptureSession?
    internal var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    var poseForLetter: String!
    
    var lastRecognizedHand: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]?
    
    var lastRecognizedLetter: String = ""
    var lastRecognizedLetterRecognitionCount: Float = 0
    var lastRecognizedLetterSum: Float = 0.0
    
    @IBOutlet weak var btnCapture: UIButton!
    @IBOutlet weak var lblRecognizedLetterWithAccuracy: UILabel!
    @IBOutlet weak var lblRecognizedText: UILabel!
    @IBOutlet weak var lblAccuracyMed: UILabel!
    
    func updateAveregeRecognitionLabel(for letter:String, withAccuracy accuracy: Float){
        if self.lastRecognizedLetter != letter {
            self.lblAccuracyMed.text?.append("\(lastRecognizedLetter) : " + String(format: "%.2f%", (self.lastRecognizedLetterSum / self.lastRecognizedLetterRecognitionCount)*100) + "\(self.lastRecognizedLetterRecognitionCount) x " + "\n")
            self.lastRecognizedLetterRecognitionCount = 0
            self.lastRecognizedLetterSum = 0
            self.lastRecognizedLetter = letter
            print(self.lblAccuracyMed.text!)
        }
        
        self.navigationItem.title = String(format: "%.2f%", (self.lastRecognizedLetterSum / self.lastRecognizedLetterRecognitionCount)*100)
        self.lastRecognizedLetterRecognitionCount = self.lastRecognizedLetterRecognitionCount + 1
        self.lastRecognizedLetterSum = lastRecognizedLetterSum + accuracy
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblRecognizedText.text = ""
        self.lblRecognizedLetterWithAccuracy.text = ""
        handPoseRequest.maximumHandCount = 1
        setupUI()
    }
    
    func setupUI(){
        if poseMatching{
            self.lblRecognizedText.isHidden = false
            self.lblRecognizedLetterWithAccuracy.isHidden = false
            self.btnCapture.isHidden = true
            self.navigationItem.title = ""
        }else{
            self.lblRecognizedText.isHidden = true
            self.lblRecognizedLetterWithAccuracy.isHidden = true
            self.btnCapture.isHidden = false
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Zrušit", style: .plain, target: self, action: #selector(self.dismissSelf) )
            self.navigationItem.leftBarButtonItem?.tintColor = .red
            self.navigationItem.title = poseForLetter
        }
    }
    
    @objc
    func dismissSelf(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func capturePose(_ sender: Any) {
        self.captureCurrentPose()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func setupAVSession() throws {
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            throw AppError.captureSessionSetup(reason: "Could not find a front facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    @IBAction func changeCamera(_ sender: Any) {
        if self.cameraPosition == .back{
            self.cameraPosition = .front
        }else{
            self.cameraPosition = .back
        }
        do{
            cameraFeedSession?.stopRunning()
            try self.setupAVSession()
            cameraView.previewLayer.session = cameraFeedSession
            cameraFeedSession?.startRunning()
        }catch {
            AppError.display(error, inViewController: self)
        }
        
    }
    
    func renderPoints(pointsToShow: [VNHumanHandPoseObservation.JointName : CGPoint]?){
        
        guard let points = pointsToShow else {
            cameraView.showPoints([], color: .clear)
            return
        }
        
        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView.previewLayer
        
        var convertedPoints = [CGPoint]()
        
        for (_, jointPoint) in points{
            // convert to avfoundation and show
            convertedPoints.append(previewLayer.layerPointConverted(fromCaptureDevicePoint: jointPoint))
        }
        
        cameraView.showPoints(convertedPoints, color: .orange)
    }
}
