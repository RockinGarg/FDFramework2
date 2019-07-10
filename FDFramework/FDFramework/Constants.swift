//
//  Constants.swift
//  FaceDetection
//
//  Created by iOSDev on 7/6/19.
//  Copyright © 2019 iOSDeveloper. All rights reserved.
//

import UIKit

enum Constant {
    static let alertControllerTitle = "Vision Detectors"
    static let alertControllerMessage = "Select a detector"
    static let cancelActionTitleText = "Cancel"
    static let videoDataOutputQueueLabel = "com.developer.FaceDetection.VideoDataOutputQueue"
    static let sessionQueueLabel = "com.developer.FaceDetection.SessionQueue"
    static let noResultsMessage = "No Results"
    static let localAutoMLModelName = "local_automl_model"
    static let remoteAutoMLModelName = "remote_automl_model"
    static let localModelManifestFileName = "automl_labeler_manifest"
    static let autoMLManifestFileType = "json"
    static let labelConfidenceThreshold: Float = 0.75
    static let smallDotRadius: CGFloat = 4.0
    static let originalScale: CGFloat = 1.0
    static let padding: CGFloat = 10.0
    static let resultsLabelHeight: CGFloat = 200.0
    static let resultsLabelLines = 5
}
