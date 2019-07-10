Pod::Spec.new do |spec|

  spec.name         = "FDFramework"
  spec.version      = "1.0.0"
  spec.summary      = "Face Movement Detector"
  spec.description  = "Face Detection Framework that detect face movemnet is Straight, Left or Up. It make use of firebase ML-Kit to detect face movement. It is as easy to integrate just import this required framework and you are all set up for the tasl of face detection."
  spec.homepage     = "https://github.com/RockinGarg/FDFramework2"
  spec.license      = "MIT"
  spec.author       = { "iOSDev" => "gargjatin321@gmail.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/RockinGarg/FDFramework2.git", :tag => "1.0.0" }

  spec.swift_version = '5.0'

  spec.source_files  = "FDFramework/**/*.swift"

  spec.static_framework = true
  spec.dependency 'Firebase'
  spec.dependency 'Firebase/Analytics'
  spec.dependency 'Firebase/MLVision'
  spec.dependency 'Firebase/MLVisionFaceModel'
  spec.dependency 'Firebase/MLVisionObjectDetection'
  spec.dependency 'Firebase/MLVisionAutoML'

end
