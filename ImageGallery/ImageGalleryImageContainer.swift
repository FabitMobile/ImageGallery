import UIKit

class ImageGalleryImageContainer: UIViewController {
    var itemIndex: Int
    var zoomableView: ImageGalleryZomableView

    init(imageObject: ImageObject,
         zoomableView: ImageGalleryZomableView,
         itemIndex: Int = 0) {
        self.zoomableView = zoomableView
        self.itemIndex = itemIndex

        super.init(nibName: nil, bundle: nil)

        zoomableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view = zoomableView
        zoomableView.displayImageObject(imageObject)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
