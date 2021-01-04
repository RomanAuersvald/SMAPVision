//
//  CameraOutputVisionProcessing.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 04.01.2021.
//

import UIKit
import Vision
import AVFoundation

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


