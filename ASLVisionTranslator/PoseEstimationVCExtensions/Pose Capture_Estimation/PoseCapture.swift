//
//  PoseCapture.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 04.01.2021.
//

import Foundation


// MARK:- Pose Capture
extension PoseEstimationViewController {
    func captureCurrentPose() {
        if self.lastRecognizedHand != nil{
            
            let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: self.lastRecognizedHand!, requiringSecureCoding: false)
            // vytvořen objekt, který nese info o datu, písmenu a datech ruky
            guard let data = encodedData else {
                return
            }
            let savingDict = ASLLetterPose(letter: self.poseForLetter, poseDictData: data)
            
            let result = PoseDataManager.shared.savePoseData(pose: savingDict)
            let _ = result.map { if $0 == 1 {
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            }}
//
//            do{
//                let encoder = JSONEncoder()
//                // data ruky kódovaná jako Data
//                let encodedData = try NSKeyedArchiver.archivedData(withRootObject: self.lastRecognizedHand!, requiringSecureCoding: false)
//                // vytvořen objekt, který nese info o datu, písmenu a datech ruky
//                let savingDict = ASLLetterPose(letter: self.poseForLetter, poseDictData: encodedData)
//                //                načíst uložené pole a do něj přidat prvek
//
//                let defaults = UserDefaults.standard
//                // načtení již uložených
//                if let savedPosesFromDefaults = defaults.object(forKey: "savedLetterPoses") as? Data {
//                    let decoder = JSONDecoder()
//                    if let loadedPoses = try? decoder.decode([ASLLetterPose].self, from: savedPosesFromDefaults) {
//                        var new = loadedPoses
//                        new.append(savingDict)
//                        if let encoded = try? encoder.encode(new) {
//                            print(encoded)
//                            defaults.set(encoded, forKey: "savedLetterPoses")
//                        }
//                    }
//                }else{
//                    // nejsou zatím žádné uložené, uložíme aktuální
//                    if let encoded = try? encoder.encode([savingDict]) {
//                        print(encoded)
//                        defaults.set(encoded, forKey: "savedLetterPoses")
//                    }
//                }
//
//                DispatchQueue.main.async {
//                    self.dismiss(animated: true, completion: nil)
//                }
//                print(UserDefaults.standard.synchronize()) // je potřeba?
//
//
//            }catch let error{
//                print(error.localizedDescription)
//            }
        }
    }
}

