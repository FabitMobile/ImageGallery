import Foundation
import UIKit

// dummy implementation of share replay
public class GalleryAsyncImagesProvider {
    var values: [UIImage] = []
    var imagesLeftToLoad: Int?
    
    public var callback: (([UIImage], Int) -> Void)? {
        didSet {
            queue.async { [weak self] in
                guard let __self = self else { return }
                __self.callCallback()
            }
        }
    }

    var queue = DispatchQueue(label: "GalleryAsyncImagesProvider")
    
    public init() { }
    
    public func appendLoadedImages(_ images: [UIImage]) {
        queue.async { [weak self] in
            guard let __self = self else { return }
            __self.values.append(contentsOf: images)
            __self.callCallback()
        }
    }
    
    public func setImagesLeftToLoad(_ value: Int) {
        queue.async { [weak self] in
            guard let __self = self else { return }
            __self.imagesLeftToLoad = value
            __self.callCallback()
        }
    }
    
    public func decreaseImagesLeftToLoad() {
        queue.async { [weak self] in
            guard let __self = self else { return }
            if let imagesLeftToLoad = __self.imagesLeftToLoad {
                if imagesLeftToLoad > 0 {
                    __self.imagesLeftToLoad = imagesLeftToLoad - 1
                } else {
                    __self.imagesLeftToLoad = 0
                }
                    
                __self.callCallback()
            }
        }
    }
    
    //MARK: -
    func callCallback() {
        DispatchQueue.main.async { [weak self] in
            guard let __self = self else { return }
            __self.callback?(__self.values,
                             __self.imagesLeftToLoad ?? 0)
        }
    }
}
