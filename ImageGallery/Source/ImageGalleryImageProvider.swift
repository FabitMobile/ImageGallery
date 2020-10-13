import Foundation
import UIKit

// dummy implementation of share relay
public class GalleryAsyncImagesProvider {
    private var sharedValues: [UIImage] = []
    public var total: Int = 0 {
        didSet {
            callback(sharedValues)
        }
    }
    
    public var callback: (([UIImage]) -> Void)! {
        didSet {
            callback(sharedValues)
        }
    }

    public init() {
        callback = { [weak self] values in
            self?.sharedValues = values
        }
    }
    
    public func appendLoadedImages(_ images: [UIImage]) {
        sharedValues.append(contentsOf: images)
        callback(sharedValues)
    }
}
