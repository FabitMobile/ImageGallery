import Foundation
import UIKit

// dummy implementation of share relay
public class GalleryAsyncImagesProvider {
    private var sharedValues: [UIImage]?

    public var callback: (([UIImage]) -> Void)! {
        didSet {
            if let sharedValues = sharedValues {
                callback(sharedValues)
            }
        }
    }

    public init() {
        callback = { [weak self] values in
            self?.sharedValues = values
        }
    }
}
