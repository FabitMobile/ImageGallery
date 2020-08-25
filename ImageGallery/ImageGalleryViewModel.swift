import UIKit

public protocol ImageObject {}
extension URL: ImageObject {}
extension UIImage: ImageObject {}

class ImageGalleryViewModel {
    var images: [ImageObject] = []
    var selectedIndex: Int = 0
    var navigationBarHidden: Bool = false
}
