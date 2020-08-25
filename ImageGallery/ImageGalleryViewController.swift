import UIKit

public protocol ImageGalleryModuleInput {
    func configureModule(provider: GalleryAsyncImagesProvider, previews: [UIImage])
    func configureModule(images: [ImageObject], showCloseButton: Bool, handlePanGesture: Bool)
    func configureModule(images: [ImageObject], selectedIndex: Int, showCloseButton: Bool, handlePanGesture: Bool)
}

public protocol ImageGalleryModuleOutput: AnyObject {
    func imageGalleryModuleDidTapClose(_ module: ImageGalleryViewController)
    func imageGalleryModuleWillCloseByGesture(_ module: ImageGalleryViewController)
}

public class ImageGalleryViewController: UIViewController,
    ImageGalleryModuleInput,
    UIPageViewControllerDataSource,
    UIPageViewControllerDelegate,
    ImageGalleryZomableViewDelegate,
    GalleryPreviewModuleOutput {
    // MARK: props

    public weak var output: ImageGalleryModuleOutput?
    var viewModel: ImageGalleryViewModel
    var pageViewController: UIPageViewController
    var previewController: GalleryPreviewViewController
    var updQueue: DispatchQueue
    var images: [ImageObject] = []
    var currentIndex = 0
    var showCloseButton: Bool = true
    var shouldHandlePanGesture: Bool = true

    // MARK: DI

    public init() {
        viewModel = ImageGalleryViewModel()
        updQueue = DispatchQueue(label: "ImageGalleryViewController")
        previewController = GalleryPreviewViewController()
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

        super.init(nibName: nil, bundle: nil)

        pageViewController.delegate = self
        pageViewController.dataSource = self
        previewController.output = self

        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.00)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    // MARK: - ImageGalleryModuleInput

    public func configureModule(provider: GalleryAsyncImagesProvider, previews: [UIImage]) {
        viewModel.images = previews

        let previews = previews.map { ImagePreviewState.image($0) } + [.loading]
        previewController.configureModule(images: previews, selectItem: 0)
        configure()

        provider.callback = { [weak self] images in
            guard let __self = self else { return }
            __self.viewModel.selectedIndex = 0
            __self.viewModel.images = images
            __self.configure()

            let previews = images.map { ImagePreviewState.image($0) }
            __self.previewController.configureModule(images: previews, selectItem: 0)
        }
    }

    public func configureModule(images: [ImageObject], showCloseButton: Bool, handlePanGesture: Bool) {
        viewModel.images = images
        configure(showCloseButton: showCloseButton, handlePanGesture: handlePanGesture)
    }

    public func configureModule(images: [ImageObject],
                                selectedIndex: Int,
                                showCloseButton: Bool,
                                handlePanGesture: Bool) {
        viewModel.images = images
        viewModel.selectedIndex = selectedIndex
        configure(showCloseButton: showCloseButton, handlePanGesture: handlePanGesture)
    }

    // MARK: Life cycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false

        let previewHeight: CGFloat = GalleryPreviewViewController.height

        let bottomAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor>
        if #available(iOS 11.0, *) {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            bottomAnchor = view.bottomAnchor
        }

        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            pageViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            pageViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -previewHeight),
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        pageViewController.didMove(toParent: self)

        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            previewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            previewController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            previewController.view.heightAnchor.constraint(equalToConstant: previewHeight)
        ])
        previewController.didMove(toParent: self)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = false
    }

    func setup() {
        if showCloseButton {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop,
                                              target: self,
                                              action: #selector(closeButtonTap))

            navigationItem.leftBarButtonItem = closeButton
        }

        if shouldHandlePanGesture {
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }

    // MARK: - private

    func updateList(_ viewModel: ImageGalleryViewModel) {
        updQueue.async { [weak self] in
            guard let __self = self else { return }
            __self.images = viewModel.images
            DispatchQueue.main.async { [weak self] in
                guard let __self = self else { return }
                if let startingViewController = __self.makeItemController(viewModel.selectedIndex) {
                    __self.pageViewController.setViewControllers([startingViewController],
                                                                 direction: .forward,
                                                                 animated: false,
                                                                 completion: nil)
                }
            }
        }
    }

    func setNavigationBarHidden(_ viewModel: ImageGalleryViewModel) {
        navigationController?.isNavigationBarHidden = viewModel.navigationBarHidden
        UIApplication.shared.isStatusBarHidden = viewModel.navigationBarHidden
    }

    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    func updateNavigationTitle(_ viewModel: ImageGalleryViewModel) {
        navigationItem.title = NSLocalizedString("ImageGallery_navigation_title_singlePhoto", comment: "")
        // TODO: fix later
        // disable in #41237#note-12
//        if viewModel.images.count == 1 {
//            navigationItem.title = R.string.localizable.imageGallery_navigation_title_singlePhoto()
//        } else {
//            let a = String(viewModel.selectedIndex + 1)
//            let b = String(viewModel.images.count)
//
//            navigationItem.title = R.string.localizable
//                .imageGallery_navigation_title_one_of(a, b)
//        }
    }

    // MARK: - GalleryPreviewModuleOutput

    func galleryPreviewModule(_ module: GalleryPreviewModuleInput, didSelectItemAt item: Int) {
        scrollToPage(item)
    }

    // MARK: - UIPageViewControllerDataSource

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let itemController = viewController as? ImageGalleryImageContainer,
            itemController.itemIndex + 1 < images.count else { return nil }

        return makeItemController(itemController.itemIndex + 1)
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let itemController = viewController as? ImageGalleryImageContainer,
            itemController.itemIndex > 0 else { return nil }

        return makeItemController(itemController.itemIndex - 1)
    }

    // MARK: - UIPageViewControllerDelegate

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   didFinishAnimating finished: Bool,
                                   previousViewControllers: [UIViewController],
                                   transitionCompleted completed: Bool) {
        if finished {
            guard let index = (pageViewController.viewControllers?.first as?
                ImageGalleryImageContainer)?.itemIndex else { return }
            viewModel.selectedIndex = index
            previewController.select(item: index, animated: true)
            updateNavigationTitle(viewModel)
        }
    }

    // MARK: - ImageGalleryZomableViewDelegate

    func tapGestureRecognized(_ tapGesture: UITapGestureRecognizer) {
        viewModel.navigationBarHidden = !viewModel.navigationBarHidden
        setNavigationBarHidden(viewModel)
    }

    func doubleTapGestureRecognized(_ doubleTapGesture: UITapGestureRecognizer) {
        viewModel.navigationBarHidden = true
        setNavigationBarHidden(viewModel)
    }

    func pinchGestureRecognized(_ pinchGesture: UIPinchGestureRecognizer) {
        viewModel.navigationBarHidden = true
        setNavigationBarHidden(viewModel)
    }

    func longPressGestureRecognized(_ longPressGesture: UILongPressGestureRecognizer) {}

    var originalPosition: CGPoint!

    @objc
    func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)

        var mainView: UIView
        if let navigationController = navigationController {
            mainView = navigationController.view
        } else {
            mainView = view
        }

        if sender.state == .began {
            originalPosition = view.center

        } else if sender.state == .changed {
            mainView.frame.origin = CGPoint(x: 0, y: translation.y)

        } else if sender.state == .ended {
            let velocity = sender.velocity(in: view)

            if abs(velocity.y) >= 100 {
                UIView.animate(withDuration: 0.2, animations: { [weak mainView] in
                    guard let __mainView = mainView else { return }
                    __mainView.frame.origin = CGPoint(x: __mainView.frame.origin.x,
                                                      y: velocity.y > 0 ? __mainView.frame.size.height :
                                                          -__mainView.frame.size.height)
                }, completion: { [weak self] isCompleted in
                    guard let __self = self else { return }
                    if isCompleted {
                        __self.output?.imageGalleryModuleWillCloseByGesture(__self)
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2) { [weak self] in
                    guard let __self = self else { return }
                    mainView.center = __self.originalPosition
                }
            }
        }
    }

    // MARK: - Private

    func scrollToPage(_ itemIndex: Int) {
        guard viewModel.selectedIndex != itemIndex else { return }
        guard let vc = makeItemController(itemIndex) else { return }

        pageViewController.setViewControllers([vc],
                                              direction: viewModel.selectedIndex < itemIndex ? .forward : .reverse,
                                              animated: true,
                                              completion: nil)

        viewModel.selectedIndex = itemIndex
    }

    func makeItemController(_ itemIndex: Int) -> UIViewController? {
        guard itemIndex < images.count else { return nil }
        let zoomableView = ImageGalleryZomableView()
        zoomableView.zoomableViewDelegate = self
        return ImageGalleryImageContainer(imageObject: images[itemIndex],
                                          zoomableView: zoomableView,
                                          itemIndex: itemIndex)
    }

    @objc
    func closeButtonTap() {
        output?.imageGalleryModuleDidTapClose(self)
    }

    private func configure(showCloseButton: Bool = true, handlePanGesture: Bool = true) {
        self.showCloseButton = showCloseButton
        shouldHandlePanGesture = handlePanGesture
        setup()
        updateNavigationTitle(viewModel)
        updateList(viewModel)
    }
}
