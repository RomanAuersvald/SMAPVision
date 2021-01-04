//
//  PoseEstimation.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 04.01.2021.
//

import UIKit
import Vision
import AVFoundation

extension PoseEstimationViewController{
    // this is where the magic happens
    func makeEstimation(){
        if self.lastRecognizedHand != nil{
//            let defaults = UserDefaults.standard
//            var savedPoses: [ASLLetterPose]? = nil
//
//            if let savedPosesFromDefaults = defaults.object(forKey: "savedLetterPoses") as? Data {
//                let decoder = JSONDecoder()
//                if let loadedPoses = try? decoder.decode([ASLLetterPose].self, from: savedPosesFromDefaults) {
//                    savedPoses = loadedPoses
//                }
//            }
            let savedPoses = PoseDataManager.shared.loadData()
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
            // MARK:- The real witchcraft
            let matchingRatios = capturedLetterPosesPoints
                .map { $0?.matchVector(with: predictedPoints) }
                .compactMap { $0 }
            
            var topCapturedPose: ASLLetterPose?
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
//                ----END QUEUE
            }
        }
    }
}
