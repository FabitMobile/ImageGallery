import PINRemoteImage
import UIKit

protocol ImageGalleryZomableViewDelegate: AnyObject {
    func tapGestureRecognized(_ tapGesture: UITapGestureRecognizer)
    func doubleTapGestureRecognized(_ doubleTapGesture: UITapGestureRecognizer)
    func pinchGestureRecognized(_ pinchGesture: UIPinchGestureRecognizer)
    func longPressGestureRecognized(_ longPressGesture: UILongPressGestureRecognizer)
}

class ImageGalleryZomableView: UIScrollView, UIScrollViewDelegate {
    weak var zoomableViewDelegate: ImageGalleryZomableViewDelegate?

    var imageView: UIImageView
    var imageSize: CGSize = .zero
    var minimumContentOffset: CGPoint = .zero
    var activityIndicatior: UIActivityIndicatorView

    var pointToCenterAfterResize: CGPoint!
    var scaleToRestoreAfterResize: CGFloat!

    var maximumContentOffset: CGPoint {
        CGPoint(x: contentSize.width - bounds.size.width,
                y: contentSize.height - bounds.size.height)
    }

    override var frame: CGRect {
        willSet {
            // check to see if there is a resize coming. prepare if there is one
            let sizeChanging: Bool = !frame.size.equalTo(newValue.size)
            if sizeChanging { prepareToResize() }
        }
        didSet {
            // check to see if there was a resize. recover if there was one
            let sizeChanged: Bool = !frame.size.equalTo(oldValue.size)
            if sizeChanged { recoverFromResizing() }
        }
    }

    init() {
        imageView = UIImageView()
        activityIndicatior = UIActivityIndicatorView(style: .whiteLarge)

        super.init(frame: UIScreen.main.bounds)

        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollView.DecelerationRate.fast
        delegate = self

        if #available(iOS 11, *) {
            contentInsetAdjustmentBehavior = .never
        }

        activityIndicatior.center = CGPoint(x: UIScreen.main.bounds.width / 2,
                                            y: UIScreen.main.bounds.height / 2)
        activityIndicatior.hidesWhenStopped = true
        addSubview(activityIndicatior)
        addGestureRecognizers()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError(#function)
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if let pinchGestureRecognizer = scrollView.pinchGestureRecognizer {
            zoomableViewDelegate?.pinchGestureRecognized(pinchGestureRecognizer)
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        resizeImageView(animated: false)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        resizeImageView(animated: true)
    }

    // MARK: - API

    func displayImageObject(_ imageObject: ImageObject) {
        if let url = imageObject as? URL {
            activityIndicatior.startAnimating()
            PINRemoteImageCategoryManager.setImageOnView(imageView,
                                                         from: url,
                                                         completion: { [weak self] result in
                                                             guard let __self = self else { return }
                                                             __self.activityIndicatior.stopAnimating()
                                                             if let image = result.image {
                                                                 __self.imageView = UIImageView(image: image)
                                                                 __self.configureForImageSize(image.size)
                                                                 __self.addSubview(__self.imageView)
                                                                 __self.resizeImageView(animated: false)
                                                             }
                                                         })

        } else if let image = imageObject as? UIImage {
            imageView = UIImageView(image: image)
            configureForImageSize(image.size)
            addSubview(imageView)
            resizeImageView(animated: false)
        }
    }

    // MARK: - Private

    func addGestureRecognizers() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        // Uncoment if longpress gesture need
//        addGestureRecognizer(longPressGesture)

        tapGesture.require(toFail: doubleTapGesture)
    }

    func resizeImageView(animated: Bool) {
        // center the zoom view as it becomes smaller than the size of the screen
        var frameToCenter: CGRect = imageView.frame

        // center horizontally
        if frameToCenter.size.width < bounds.size.width {
            frameToCenter.origin.x = (bounds.size.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }

        // center vertically
        if frameToCenter.size.height < bounds.size.height {
            frameToCenter.origin.y = (bounds.size.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }

        if animated {
            UIView.animate(withDuration: 0.25) {
                self.imageView.frame = frameToCenter
            }
        } else {
            imageView.frame = frameToCenter
        }
    }

    // MARK: - Zoom/Scale

    func configureForImageSize(_ imageSize: CGSize) {
        self.imageSize = imageSize
        contentSize = imageSize
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale

        if (imageSize.width / UIScreen.main.scale) < bounds.size.width, imageSize.width >= imageSize.height {
            zoomScale = bounds.size.width / imageSize.width
        }
    }

    func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoom scale
        let xScale: CGFloat = bounds.size.width / imageSize.width
        let yScale: CGFloat = bounds.size.height / imageSize.height

        // fill width if the image nad phone are both in prortrait or both landscape; otherwise take smaller scale
        let imagePortrait: Bool = imageSize.height > imageSize.width
        let phonePortrait: Bool = bounds.size.height > bounds.size.width
        var minScale: CGFloat = imagePortrait == phonePortrait ? xScale : min(xScale, yScale)

        // on high res screens we have double the pixel density, so we will be seeing every pixel if we limit the max zoom scale to 0.5
        var maxScale: CGFloat = 1.0 / UIScreen.main.scale

        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)

        if minScale > maxScale {
            minScale = maxScale
            maxScale = xScale
        }

        maximumZoomScale = maxScale * 2
        minimumZoomScale = minScale
    }

    func prepareToResize() {
        let boundsCenter: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: imageView)

        scaleToRestoreAfterResize = zoomScale

        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.

        if Float(scaleToRestoreAfterResize) <= Float(minimumZoomScale) + Float.ulpOfOne {
            scaleToRestoreAfterResize = 0
        }
    }

    func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()

        // Step 1: restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale: CGFloat = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)

        // Step 2: restore center point, first making sure it is within the allowable range.
        // 2a: convert our desired center point back to our own coordinate space
        let boundsCenter: CGPoint = convert(pointToCenterAfterResize, from: imageView)

        // 2b: calculate the content offset that would yield that center point
        var offset: CGPoint = CGPoint(x: boundsCenter.x - bounds.size.width / 2.0,
                                      y: boundsCenter.y - bounds.size.height / 2.0)

        // 2c: restore offset, adjusted to be within the allowable range
        var realMaxOffset: CGFloat = min(maximumContentOffset.x, offset.x)
        offset.x = max(minimumContentOffset.x, realMaxOffset)

        realMaxOffset = min(maximumContentOffset.y, offset.y)
        offset.y = max(minimumContentOffset.y, realMaxOffset)

        contentOffset = offset
    }

    // MARK: - UIGestureRecognizer

    @objc
    func handleTapGesture(_ sender: UITapGestureRecognizer) {
        zoomableViewDelegate?.tapGestureRecognized(sender)
    }

    @objc
    func handleDoubleTapGesture(_ sender: UITapGestureRecognizer) {
        zoomableViewDelegate?.doubleTapGestureRecognized(sender)
        let scale = zoomScale == maximumZoomScale ? minimumZoomScale : maximumZoomScale
        let point = sender.location(in: imageView)
        let scrollSize = CGSize(width: frame.size.width / scale,
                                height: frame.size.height / scale)

        let visibleRect = CGRect(origin: point, size: CGSize.zero)

        let centeredRect = CGRect(x: visibleRect.origin.x + visibleRect.size.width / 2.0 - scrollSize.width / 2.0,
                                  y: visibleRect.origin.y + visibleRect.size.height / 2.0 - scrollSize.height / 2.0,
                                  width: scrollSize.width,
                                  height: scrollSize.height)

        UIView.animate(withDuration: 0.55,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.6,
                       options: .allowUserInteraction, animations: { [weak self] in
                           guard let __self = self else { return }
                           __self.zoom(to: centeredRect, animated: false)
                           __self.resizeImageView(animated: false)
                       }, completion: nil)
    }

    @objc
    func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        zoomableViewDelegate?.longPressGestureRecognized(sender)
    }
}
