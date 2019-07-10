//
//  Utilities.swift
//  FaceDetection
//
//  Created by iOSDev on 7/6/19.
//  Copyright © 2019 iOSDeveloper. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseMLVision

class UIUtilities {
    public static func imageOrientation(fromDevicePosition devicePosition: AVCaptureDevice.Position = .back ) -> UIImage.Orientation {
        var deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp ||
            deviceOrientation == .unknown {
            deviceOrientation = currentUIOrientation()
        }
        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
        default:
            return .up
        }
    }
    
    private static func currentUIOrientation() -> UIDeviceOrientation {
        let deviceOrientation = { () -> UIDeviceOrientation in
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                return .portrait
            }
        }
        guard Thread.isMainThread else {
            var currentOrientation: UIDeviceOrientation = .portrait
            DispatchQueue.main.sync {
                currentOrientation = deviceOrientation()
            }
            return currentOrientation
        }
        return deviceOrientation()
    }
    
    public static func visionImageOrientation(from imageOrientation: UIImage.Orientation
        ) -> VisionDetectorImageOrientation {
        switch imageOrientation {
        case .up:
            return .topLeft
        case .down:
            return .bottomRight
        case .left:
            return .leftBottom
        case .right:
            return .rightTop
        case .upMirrored:
            return .topRight
        case .downMirrored:
            return .bottomLeft
        case .leftMirrored:
            return .leftTop
        default:
            return .rightBottom
        }
    }
}

