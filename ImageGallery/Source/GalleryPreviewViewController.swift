import UIKit

protocol GalleryPreviewModuleInput {
    func configureModule(images: [ImagePreviewState], selectItem: Int?)
}

protocol GalleryPreviewModuleOutput: AnyObject {
    func galleryPreviewModule(_ module: GalleryPreviewModuleInput, didSelectItemAt row: Int)
}

class GalleryPreviewViewController: UICollectionViewController, GalleryPreviewModuleInput {
    static let height: CGFloat = 120

    var viewModel: GalleryPreviewViewModel
    weak var output: GalleryPreviewModuleOutput?

    init() {
        viewModel = GalleryPreviewViewModel()

        let layout = UICollectionViewFlowLayout()

        let insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let height = Self.height - insets.top - insets.bottom

        layout.itemSize = CGSize(width: height, height: height)
        layout.minimumInteritemSpacing = 8
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.sectionInset = insets

        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "GalleryPreviewCell", bundle: Bundle(for: GalleryPreviewViewController.self))
        collectionView.register(nib, forCellWithReuseIdentifier: "GalleryPreviewCell")
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.images.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "GalleryPreviewCell",
                                 for: indexPath) as? GalleryPreviewCell else { fatalError() }

        let preview = viewModel.images[indexPath.item]

        switch preview {
        case .loading:
            cell.activityIndicator.startAnimating()
            cell.imageView.image = nil
        case let .image(img):
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = img
            if let item = viewModel.selectedItem, item == indexPath.row {
                cell.select(animated: false)
            } else {
                cell.deselect(animated: false)
            }
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        switch viewModel.images[indexPath.item] {
        case .image:
            return true
        case .loading:
            return false
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        output?.galleryPreviewModule(self, didSelectItemAt: indexPath.item)
        select(item: indexPath.item)
    }

    // MARK: GalleryPreviewModuleInput

    func configureModule(images: [ImagePreviewState], selectItem: Int?) {
        viewModel.images = images
        if let selectItem = selectItem {
            viewModel.selectedItem = selectItem
        }
        collectionView.reloadData()
    }

    // MARK: - Helpers

    func select(item: Int, animated: Bool = true) {
        viewModel.selectedItem = item
        guard animated else { return collectionView.reloadData() }

        let ip = IndexPath(item: item, section: 0)
        let selectedCell = collectionView.cellForItem(at: ip)

        for cell in collectionView.visibleCells {
            guard let cell = cell as? GalleryPreviewCell else { continue }
            if cell === selectedCell {
                cell.select(animated: true)
            } else {
                cell.deselect(animated: true)
            }
        }
    }
}
