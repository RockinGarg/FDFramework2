//
//  CameraView.swift
//  FaceDetection
//
//  Created by iOSDev on 7/6/19.
//  Copyright © 2019 iOSDeveloper. All rights reserved.
//
import UIKit
import AVFoundation
import CoreVideo
import FirebaseMLVision
import FirebaseMLVisionObjectDetection
import FirebaseMLCommon
import FirebaseMLVisionAutoML
//MARK:- Camera View Protocol
public protocol CameraViewProtocol {
    //MARK: Performed User All Assigned Task
    func userTasksPerformed()
    //MARK: Current Action in Progress
    func userTaskInAction(Task task: UserTasks)
}

//MARK:- Extending Protocol
public extension CameraViewProtocol {
    //MARK: Performed User All Assigned Task
    func userTasksPerformed() { }
    //MARK: Current Action in Progress
    func userTaskInAction(Task task: UserTasks) { }
}

//MARK:  User Tasks To Perfomr
public enum UserTasks: String {
    /// Look Straight
    case straight = "Mira frente a la cámara"
    /// Smile
    case smile = "Sonríe"
    /// Move Face To Left
    case leftFace = "Mira a la izquierda"
    
    /// String Description Added
    var description : String {
        get {
            return self.rawValue
        }
    }
}

//MARK:- Camera View
public class CameraView: UIView {
    /// Queue
    fileprivate lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    /// Is Using Front Camera
    fileprivate var isUsingFrontCamera = true
    /// Vision Object
    fileprivate lazy var vision = Vision.vision()
    /// Last Frame Detected
    fileprivate var lastFrame: CMSampleBuffer?
    /// Preview Layer
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer!
    /// Label View
    fileprivate var bottomView: UIView!
    /// Comment Label
    fileprivate var commentLabel: UILabel!
    /// Bottom Constraint
    fileprivate var bottomViewHeightConstraint: NSLayoutConstraint!
    
    /// Camera Session
    fileprivate lazy var captureSession = AVCaptureSession()
    /// Timer
    fileprivate var taskTimer: Timer?
    /// Current Task
    fileprivate var currentTaskInAction: UserTasks = .straight {
        didSet {
            if showBottomView {
                
            }
            self.commentLabel.text = self.currentTaskInAction.description
            self.bottomViewHeightConstraint.constant = self.commentLabel.frame.height
            self.delegate?.userTaskInAction(Task: self.currentTaskInAction)
        }
    }
    
    /// Delegate
    public var delegate: CameraViewProtocol?
    /// Detection Time
    public var taskTimerDetectionTime: Int = 3
    /// Show Black Bar View
    fileprivate var showBottomView: Bool = true
    
    /// Bottom View BackGround Color
    public var bottomViewBackGroundColor: UIColor = .black {
        didSet {
            if showBottomView {
                bottomView.backgroundColor = self.bottomViewBackGroundColor
            }
        }
    }
    /// Bottom Label textColor
    public var commentLabelTextColor: UIColor = .white {
        didSet {
            if showBottomView {
                self.commentLabel.textColor = self.commentLabelTextColor
            }
        }
    }
    
    /// Comment Label Font
    public var commentLabelFont: UIFont = UIFont.systemFont(ofSize: 14) {
        didSet {
            if showBottomView {
                self.commentLabel.font = self.commentLabelFont
            }
        }
    }
    
    private lazy var previewOverlayView: UIImageView = {
        let previewOverlayView = UIImageView(frame: .zero)
        previewOverlayView.clipsToBounds = true
        previewOverlayView.contentMode = .scaleAspectFill
        previewOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return previewOverlayView
    }()

    //MARK: Init
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.currentTaskInAction = .straight
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setUpPreviewOverlayView()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
    }
    
    
    //MARK: Init
    public init(frame: CGRect, CommentView visible: Bool) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        showBottomView = visible
        self.currentTaskInAction = .straight
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setUpPreviewOverlayView()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
    }
    
    //MARK: Coder
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//MARK:- Camera Setup
extension CameraView {
    //MARK: Set Preview Layer
    private func setUpPreviewOverlayView() {
        bottomView = UIView()
        commentLabel = UILabel()
        commentLabel.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(bottomView)
        bottomView.backgroundColor = .black
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bottomView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.bottomViewHeightConstraint = bottomView.heightAnchor.constraint(equalToConstant: 50)
        self.bottomViewHeightConstraint.isActive = true
        
        
        bottomView.addSubview(commentLabel)
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.text = "jatin"
        commentLabel.textAlignment = .center
        commentLabel.textColor = .white
        commentLabel.numberOfLines = 0
        NSLayoutConstraint.activate([
            commentLabel.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
            commentLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor),
            commentLabel.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor),
            commentLabel.topAnchor.constraint(equalTo: bottomView.topAnchor)
            ])
        
        self.addSubview(previewOverlayView)
        NSLayoutConstraint.activate([
            previewOverlayView.topAnchor.constraint(equalTo: self.topAnchor),
            previewOverlayView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
            previewOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            previewOverlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
    }
    
    //MARK: Set Up Capture Output
    private func setUpCaptureSessionOutput() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            // When performing latency tests to determine ideal capture settings,
            // run the app in 'release' mode to get accurate performance metrics
            self.captureSession.sessionPreset = AVCaptureSession.Preset.medium
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings =
                [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
            let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
            output.setSampleBufferDelegate(self, queue: outputQueue)
            guard self.captureSession.canAddOutput(output) else {
                print("Failed to add capture session output.")
                return
            }
            self.captureSession.addOutput(output)
            self.captureSession.commitConfiguration()
        }
    }
    
    //MARK: Capture Session Input
    private func setUpCaptureSessionInput() {
        sessionQueue.async {
            let cameraPosition: AVCaptureDevice.Position = self.isUsingFrontCamera ? .front : .back
            guard let device = self.captureDevice(forPosition: cameraPosition) else {
                print("Failed to get capture device for camera position: \(cameraPosition)")
                return
            }
            do {
                self.captureSession.beginConfiguration()
                let currentInputs = self.captureSession.inputs
                for input in currentInputs {
                    self.captureSession.removeInput(input)
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                guard self.captureSession.canAddInput(input) else {
                    print("Failed to add capture session input.")
                    return
                }
                self.captureSession.addInput(input)
                self.captureSession.commitConfiguration()
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: Capture Device
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            )
            return discoverySession.devices.first { $0.position == position }
        }
        return nil
    }
    
    //MARK: Update Preview Layer
    private func updatePreviewOverlayView() {
        guard let lastFrame = lastFrame,
            let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
            else {
                return
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        let rotatedImage =
            UIImage(cgImage: cgImage, scale: Constant.originalScale, orientation: .right)
        if isUsingFrontCamera {
            guard let rotatedCGImage = rotatedImage.cgImage else {
                return
            }
            let mirroredImage = UIImage(
                cgImage: rotatedCGImage, scale: Constant.originalScale, orientation: .leftMirrored)
            previewOverlayView.image = mirroredImage
        } else {
            previewOverlayView.image = rotatedImage
        }
        
        if showBottomView {
            self.bringSubviewToFront(self.bottomView)
        }
    }
}

//MARK:- Session Handler
extension CameraView {
    //MARK: Start Session
    public func startSession() {
        sessionQueue.async {
            self.delegate?.userTaskInAction(Task: self.currentTaskInAction)
            self.captureSession.startRunning()
        }
    }
    
    //MARK: End Session
    public func stopSession() {
        sessionQueue.async {
            self.taskTimer?.invalidate()
            self.taskTimer = nil
            self.captureSession.stopRunning()
        }
    }
}

//MARK:- Capture Session Delegates
extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }
        
        lastFrame = sampleBuffer
        let visionImage = VisionImage(buffer: sampleBuffer)
        let metadata = VisionImageMetadata()
        let orientation = UIUtilities.imageOrientation (
            fromDevicePosition: isUsingFrontCamera ? .front : .back
        )
        
        let visionOrientation = UIUtilities.visionImageOrientation(from: orientation)
        metadata.orientation = visionOrientation
        visionImage.metadata = metadata
        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        
        /*
        var shouldEnableClassification = true
        var shouldEnableMultipleObjects = true */
        
        detectFacesOnDevice(in: visionImage, width: imageWidth, height: imageHeight)
    }
    
    // MARK: Other On-Device Detections
    private func detectFacesOnDevice(in image: VisionImage, width: CGFloat, height: CGFloat) {
        let options = VisionFaceDetectorOptions()
        
        // When performing latency tests to determine ideal detection settings,
        // run the app in 'release' mode to get accurate performance metrics
        options.landmarkMode = .none
        options.contourMode = .all
        options.classificationMode = .all
        
        options.performanceMode = .accurate
        let faceDetector = vision.faceDetector(options: options)
        
        var detectedFaces: [VisionFace]? = nil
        do {
            detectedFaces = try faceDetector.results(in: image)
        } catch let error {
            print("Failed to detect faces with error: \(error.localizedDescription).")
        }
        guard let faces = detectedFaces, !faces.isEmpty else {
            print("On-Device face detector returned no results.")
            DispatchQueue.main.sync {
                self.updatePreviewOverlayView()
            }
            return
        }
        
        DispatchQueue.main.sync {
            self.updatePreviewOverlayView()
            for face in faces {
                self.addContours(for: face, width: width, height: height)
            }
        }
    }
    
    //MARK: Add Properties of Face
    private func addContours(for face: VisionFace, width: CGFloat, height: CGFloat) {
        let leftRightValue = face.headEulerAngleY
        switch currentTaskInAction {
        case .straight:
            if leftRightValue > 10 || leftRightValue < -10 {
                /// User Tilted Face
                /// Stop Timer and Set Step at back
                self.stopTaskTimer()
                self.currentTaskInAction = .straight
            } else {
                if self.taskTimer == nil {
                    /// We've no current process ongoing.
                    /// Start tiimer
                    self.startTaskTimer()
                }
            }
        case .smile:
            if leftRightValue > 10 || leftRightValue < -10 {
                /// User Tilted Face
                /// Stop Timer and Set Step at back
                self.stopTaskTimer()
                self.currentTaskInAction = .straight
            } else {
                /// User Looking Straight
                /// Check is User Smiling
                if face.smilingProbability < 0.3 {
                    /// User Smile Probablity is Less
                    /// Start Smiling Detection Task Again
                    self.stopTaskTimer()
                    self.currentTaskInAction = .smile
                } else {
                    /// User is continuously Smiling
                    if self.taskTimer == nil {
                        /// We've no current process ongoing.
                        /// Start tiimer
                        self.startTaskTimer()
                    }
                }
            }
        default:
            /// Left Direction Detection
            //print("leftRight: \(leftRightValue)")
            if leftRightValue > -10 {
                /// User Direction is not left
                /// User Tilted Face
                /// Stop Timer and Set Step at back
                self.stopTaskTimer()
                self.currentTaskInAction = .leftFace
            } else {
                /// User face is tilted to left
                if self.taskTimer == nil {
                    /// We've no current process ongoing.
                    /// Start tiimer
                    self.startTaskTimer()
                }
            }
        }
    }
}

//MARK:- Timer Handler
extension CameraView {
    //MARK: Start Task Timer
    fileprivate func startTaskTimer() {
        if taskTimer != nil {
            print("Func called to initiate timer again. It was Running already")
            return
        }
        taskTimer = Timer.scheduledTimer(timeInterval: TimeInterval(taskTimerDetectionTime), target: self, selector: #selector(taskTimerHandler), userInfo: nil, repeats: false)
    }
    
    //MARK: Stop Task Timer
    fileprivate func stopTaskTimer() {
        taskTimer?.invalidate()
        taskTimer = nil
    }
    
    //MARK: Timer Handler
    @objc fileprivate func taskTimerHandler() {
        taskTimer?.invalidate()
        taskTimer = nil
        switch currentTaskInAction {
        case .straight: currentTaskInAction = .smile
        case .smile: currentTaskInAction = .leftFace
        default: self.delegate?.userTasksPerformed()
        }
    }
}
