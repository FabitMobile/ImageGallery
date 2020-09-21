import Foundation
import UIKit

enum ImagePreviewState {
    case loading
    case image(UIImage)
}

class GalleryPreviewViewModel {
    var images: [ImagePreviewState] = [.loading]
    var selectedItem: Int?
}
