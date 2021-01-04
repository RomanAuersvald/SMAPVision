//
//  etc.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 09.12.2020.
//

import Foundation
import Vision


struct CapturedPointVector {
    static let vectorIndicesArray = [
        // 20 propojů
        //index TDPMW
        // little
        // middle
        // ring
        // thumb
        // wrist
        
        //index
        (3,0),
        (0,2),
        (2,1),
        (1,20),
        //middle
        (7,4),
        (4,6),
        (6,5),
        (5,20),
        // pinky - wtf
        (11,8),
        (8,10),
        (10,9),
        (9,20),
        //ring
        (15,12),
        (12,14),
        (14,13),
        (13,20),
        // thumb
        (19,16),
        (16,18),
        (18,17),
        (17,20)
    ]
}

extension Array where Element == CGPoint? {
    func matchVector(with predictedPoints: [CGPoint?]) -> CGFloat {
        guard predictedPoints.count >= 8, self.count >= 8 else {
            return -100000
        }
        
        var numberOfValidCaputrePointAngle = 0
        var totalAngleLoss: CGFloat = 0
        
        for (index1, index2) in CapturedPointVector.vectorIndicesArray {
            guard let p1_1 = self[index1],
                let p1_2 = self[index2],
                let p2_1 = predictedPoints[index1],
                let p2_2 = predictedPoints[index2] else {
                    continue
            }
            
            let vec1 = p1_2 - p1_1
            let vec2 = p2_2 - p2_1
            let angleLoss = CGPoint.zero.angle(with: vec1, and: vec2)
            
            totalAngleLoss += angleLoss
            numberOfValidCaputrePointAngle += 1
        }
        
        if numberOfValidCaputrePointAngle == 0 {
            return 0
        } else {
            var ratio = (totalAngleLoss / CGFloat(numberOfValidCaputrePointAngle)) / ((CGFloat.pi)/2)
            if ratio < 0 { ratio = 0}
            else if ratio > 1 { ratio = 1}
            return 1 - ratio
        }
    }
}

extension CGPoint {
    func angle(with p1: CGPoint, and p2: CGPoint) -> CGFloat {
        let center = self
        let transformedP1 = CGPoint(x: p1.x - center.x, y: p1.y - center.y)
        let transformedP2 = CGPoint(x: p2.x - center.x, y: p2.y - center.y)
        
        let angleToP1 = atan2(transformedP1.y, transformedP1.x)
        let angleToP2 = atan2(transformedP2.y, transformedP2.x)
        
        return normaliseToInteriorAngle(with: angleToP2 - angleToP1)
    }
    
    func normaliseToInteriorAngle(with angle: CGFloat) -> CGFloat {
        var angle = angle
        if (angle < 0) { angle += (2*CGFloat.pi) }
        if (angle > CGFloat.pi) { angle = 2*CGFloat.pi - angle }
        return angle
    }
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
