import CoreImage
import SwiftUI



class ContentViewModel: ObservableObject {
    @Published var error: Error?
    @Published var frame: CGImage?
    @EnvironmentObject var classificationViewModel: ClassificationViewModel
    
    var comicFilter = false
    var monoFilter = false
    var crystalFilter = false
    
    private let context = CIContext()
    
    private let cameraManager = CameraManager.shared
    private let frameManager = FrameManager.shared
    
    init() {
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        // swiftlint:disable:next array_init
        cameraManager.$error
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: &$error)
        
        frameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                guard let image = CGImage.create(from: buffer) else {
                    return nil
                }
                
                var ciImage = CIImage(cgImage: image)
                //        classificationViewModel.classifyImage(tmpImage: UIImage(cgImage: image)) //QUAAAAAA
                if self.comicFilter {
                    ciImage = ciImage.applyingFilter("CIComicEffect")
                }
                
                if self.monoFilter {
                    ciImage = ciImage.applyingFilter("CIPhotoEffectNoir")
                }
                
                if self.crystalFilter {
                    ciImage = ciImage.applyingFilter("CICrystallize")
                }
                
                return self.context.createCGImage(ciImage, from: ciImage.extent)
            }
            .assign(to: &$frame)
    }
}
