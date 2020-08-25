import UIKit

class GalleryPreviewCell: UICollectionViewCell {
    @IBOutlet public var activityIndicator: UIActivityIndicatorView!
    @IBOutlet public var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.contentMode = .scaleAspectFill

        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .white
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.alpha = 1
        imageView.image = nil
    }

    func select(animated: Bool = true) {
        backgroundColor = UIColor(white: 1, alpha: 1.0)
        animate(alpha: 0.66, animated: animated)
    }

    func deselect(animated: Bool = true) {
        backgroundColor = UIColor(white: 0.11, alpha: 1.0)
        animate(alpha: 1, animated: animated)
    }

    private func animate(alpha: CGFloat, animated: Bool = true) {
        guard animated else {
            imageView.alpha = alpha
            return
        }
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let __self = self else { return }
            __self.imageView.alpha = alpha
        }
    }
}
