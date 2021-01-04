//
//  ASLLetterPose.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 04.01.2021.
//

import Foundation

// MARK:- Letter pose dictionary - pose model for saving
public struct ASLLetterPose: Codable{
    var letter: String
    var dateTaken: Date = Date()
    var poseDictData: Data
}
