//
//  DataManager.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 04.01.2021.
//

import UIKit

internal class PoseDataManager: NSObject {
    
    enum DataError: Error {
        case fucked
        case encodingFailure
        case decodingFailure
    }
    
    static let shared = PoseDataManager()
    
    private static let encoder = JSONEncoder()
    private static let defaults = UserDefaults.standard
    private static let decoder = JSONDecoder()
    
    func loadData() -> [ASLLetterPose]?{
        var savedPoses: [ASLLetterPose]? = nil
        
        if let savedPosesFromDefaults = PoseDataManager.defaults.object(forKey: "savedLetterPoses") as? Data {
            if let loadedPoses = try? PoseDataManager.decoder.decode([ASLLetterPose].self, from: savedPosesFromDefaults) {
                savedPoses = loadedPoses
            }
        }
        return savedPoses
    }
    
    func savePoseData(pose: ASLLetterPose) -> Result<Int, DataError>{
        var loadedPosesDict = [ASLLetterPose]()
            if let loadedPoses = PoseDataManager.shared.loadData() {
                loadedPosesDict = loadedPoses
                loadedPosesDict.append(pose)
            }else{
                loadedPosesDict = [pose]
            }
            if let encoded = try? PoseDataManager.encoder.encode(loadedPosesDict) {
                PoseDataManager.defaults.set(encoded, forKey: "savedLetterPoses")
                return .success(1)
            }else{
                return .failure(.encodingFailure)
            }
    }
    
    func deletePoseData(poseToDelete: ASLLetterPose)-> Result<Int, DataError>{
        let poses = PoseDataManager.shared.loadData()
        if poses == nil{
            return .failure(.fucked)
        }
        var poseDict = poses!
        let indexOfPoseToDelete = poseDict.firstIndex { (pose) -> Bool in
            pose.dateTaken == poseToDelete.dateTaken
        }
        poseDict.remove(at: indexOfPoseToDelete!)
        if let encoded = try? PoseDataManager.encoder.encode(poseDict) {
            PoseDataManager.defaults.set(encoded, forKey: "savedLetterPoses")
            return .success(1)
        }else{
            return .failure(.encodingFailure)
        }
    }
}
