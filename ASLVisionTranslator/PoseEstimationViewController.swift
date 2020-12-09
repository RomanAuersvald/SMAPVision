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
    
    private var cameraView: CameraView { view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    
    var lastRecognizedHand: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]?
    
    @IBOutlet weak var lblRecognizedLetterWithAccuracy: UILabel!
    @IBOutlet weak var lblRecognizedText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblRecognizedText.text = ""
        self.lblRecognizedLetterWithAccuracy.text = ""
        handPoseRequest.maximumHandCount = 1
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
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
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
        
        cameraView.showPoints(convertedPoints, color: .lightGray)
    }
    
    // this is where the magic happens
    func makeEstimation(){
        if self.lastRecognizedHand != nil{
            let defaults = UserDefaults.standard
            var savedPoses: [LetterPoseDict]? = nil
            if let savedPosesFromDefaults = defaults.object(forKey: "savedLetterPoses") as? Data {
                let decoder = JSONDecoder()
                if let loadedPoses = try? decoder.decode([LetterPoseDict].self, from: savedPosesFromDefaults) {
                    savedPoses = loadedPoses
                }
            }
            // procházíme pole uložených a porovnáváme
            guard let poses = savedPoses else {return}
            
            var capturedLetterPosesPoints: [[CGPoint?]?] = []
            var predictedPoints = [CGPoint?]()
            // sort - because we dont trust vision to give the same dict all the time
            let lastRecognizedHandSorted = self.lastRecognizedHand!.sorted { $0.0.rawValue.rawValue < $1.0.rawValue.rawValue }
            for (_, recognizedPoint) in lastRecognizedHandSorted{
                predictedPoints.append(recognizedPoint.location)
            }
            for pose in poses{
                do{
                    if let loadedLetterCapture = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pose.poseDictData) as? [VNHumanHandPoseObservation.JointName : VNRecognizedPoint] {
                        var capturedPointsArray = [CGPoint]()
                        // sort - because we dont trust vision to give the same dict all the time
                        let loadedLetterCaptureSorted = loadedLetterCapture.sorted { $0.0.rawValue.rawValue < $1.0.rawValue.rawValue }
                        for (_, recognizedPoint) in loadedLetterCaptureSorted{
                            capturedPointsArray.append(recognizedPoint.location)
                        }
                        capturedLetterPosesPoints.append(capturedPointsArray)
                    }
                }catch let error {
                    print(error)
                }
                
            }
            
            let matchingRatios = capturedLetterPosesPoints
                .map { $0?.matchVector(with: predictedPoints) }
                .compactMap { $0 }
            
            var topCapturedPose: LetterPoseDict?
            var maxMatchingRatio: CGFloat = 0
            for (matchingRatio, capturedPose) in zip(matchingRatios, poses) {
                
                
                if matchingRatio > 0.80 && maxMatchingRatio < matchingRatio {
                    maxMatchingRatio = matchingRatio
                    topCapturedPose = capturedPose
                }
            }
            if topCapturedPose != nil{ // shit happend
                let accuracy = String(format: "%.2f%", maxMatchingRatio*100)
                print("we got a match! With \(topCapturedPose!.letter) at \(accuracy)")
                DispatchQueue.main.async {
                    // this makes the magic of not having milion same letters after another
                    if let capturedConfirmedLetter = topCapturedPose?.letter{
                        self.lblRecognizedLetterWithAccuracy.text = "\(capturedConfirmedLetter) at \(accuracy)"
                        if self.lblRecognizedText.text?.last != capturedConfirmedLetter.last{
                            self.lblRecognizedText.text? += capturedConfirmedLetter
                        }
                    }
                    
                }
            }

//
//
//
//            for pose in poses{
//                //                    do {
//                //                         let poseDict = try NSKeyedUnarchiver.unarchivedDictionary(keysOfClasses: [VNHumanHandPoseObservation.JointName], objectsOfClasses: [VNRecognizedPoint], from: pose.poseDictData)
//                //                    } catch let error {
//                //                        print(error)
//                //                    }
//
//
//                do {
//                    #warning("json")
////                    if let t = try NSKeyedUnarchiver.unarchivedDictionary(keysOfClasses: [VNHumanHandPoseObservation.JointName], objectsOfClasses: [VNRecognizedPoint], from: pose.poseDictData){}
//                    if let loadedLetterCapture = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pose.poseDictData) as? [VNHumanHandPoseObservation.JointName : VNRecognizedPoint] {
//
//
//                        var capturedPointsArray = [CGPoint]()
//                        var predictedPoints = [CGPoint]()
//
//                        for (_, recognizedPoint) in loadedLetterCapture{
//                            capturedPointsArray.append(recognizedPoint.location)
//                        }
//                        for (_, recognizedPoint) in self.lastRecognizedHand!{
//                            predictedPoints.append(recognizedPoint.location)
//                        }
//
//                        if loadedLetterCapture == self.lastRecognizedHand!{
//                            print("we got a match! With \(pose.letter)")
//                            DispatchQueue.main.async {
//                                self.lblRecognizedText.text? += pose.letter
//                            }
//
//                        }else{
//                            print("no luck")
//                        }
//                    }
//                } catch {
//                    print("Couldn't read file.")
//                }
//            }
        }
    }
    
}

extension PoseEstimationViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var convertedPointsToAVCoords : [VNHumanHandPoseObservation.JointName : CGPoint]?
        
        // spouští se poté, co je vše ve fci hotovo
        defer {
            DispatchQueue.main.sync {
                
                self.renderPoints(pointsToShow: convertedPointsToAVCoords)
                self.makeEstimation()
            }
        }
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            
            // získáme pointy z kompletní ruky
            let fullRecognizedHand = try observation.recognizedPoints(.all)
            
            for (jointName, jointPoint) in fullRecognizedHand{
                // Ignore low confidence points.
                guard jointPoint.confidence > 0.3 else {
                    return
                }
                // convert to avfoundation and show
                let modifiedJointPoint = CGPoint(x: jointPoint.location.x, y: 1 - jointPoint.location.y)
                
                if convertedPointsToAVCoords == nil{
                    convertedPointsToAVCoords = [jointName : modifiedJointPoint]
                }else{
                    convertedPointsToAVCoords!.updateValue(modifiedJointPoint, forKey: jointName)
                }
            }
            self.lastRecognizedHand = fullRecognizedHand
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}
