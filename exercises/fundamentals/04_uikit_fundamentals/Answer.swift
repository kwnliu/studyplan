import UIKit
import XCTest

// MARK: - Exercise 1: Profile View Controller Implementation

struct Profile {
    let name: String
    let bio: String
    let imageURL: URL
    let stats: [String: Int]
}

class StatsView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

class ProfileViewController: UIViewController {
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bioTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.textAlignment = .center
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(bioTextView)
        view.addSubview(statsStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            bioTextView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            bioTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bioTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bioTextView.heightAnchor.constraint(equalToConstant: 100),
            
            statsStackView.topAnchor.constraint(equalTo: bioTextView.bottomAnchor, constant: 16),
            statsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    func updateProfile(_ profile: Profile) {
        nameLabel.text = profile.name
        bioTextView.text = profile.bio
        
        // Load image asynchronously
        URLSession.shared.dataTask(with: profile.imageURL) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }
        }.resume()
        
        // Update stats
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        profile.stats.forEach { key, value in
            let statsView = StatsView()
            statsView.configure(title: key, value: "\(value)")
            statsStackView.addArrangedSubview(statsView)
        }
    }
}

// MARK: - Exercise 2: Table View Implementation

struct TextItem {
    let text: String
    let author: String
}

struct ImageItem {
    let imageURL: URL
    let caption: String
}

struct VideoItem {
    let thumbnailURL: URL
    let duration: TimeInterval
    let title: String
}

enum FeedItem {
    case text(TextItem)
    case image(ImageItem)
    case video(VideoItem)
}

class TextCell: UITableViewCell {
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(messageLabel)
        contentView.addSubview(authorLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            authorLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with item: TextItem) {
        messageLabel.text = item.text
        authorLabel.text = item.author
    }
}

class FeedViewController: UITableViewController {
    private var items: [FeedItem] = []
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        registerCells()
    }
    
    private func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
    }
    
    private func registerCells() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "TextCell")
        // Register other cell types
    }
    
    func updateFeed(_ items: [FeedItem]) {
        self.items = items
        tableView.reloadData()
    }
    
    @objc private func refreshFeed() {
        // Implement refresh logic
        refreshControl.endRefreshing()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        switch item {
        case .text(let textItem):
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as! TextCell
            cell.configure(with: textItem)
            return cell
            
        case .image, .video:
            // Implement other cell types
            return UITableViewCell()
        }
    }
}

// MARK: - Exercise 3: Collection View Implementation

struct Photo: Hashable {
    let id: UUID
    let imageURL: URL
    let title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class PhotoCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with photo: Photo) {
        titleLabel.text = photo.title
        
        // Load image asynchronously
        URLSession.shared.dataTask(with: photo.imageURL) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.imageView.image = image
                }
            }
        }.resume()
    }
}

enum Section {
    case main
}

class GalleryViewController: UICollectionViewController {
    private var photos: [Photo] = []
    private var dataSource: UICollectionViewDiffableDataSource<Section, Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createLayout()
        configureDataSource()
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                            heightDimension: .fractionalWidth(0.5))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .fractionalWidth(0.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                     subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoCell, Photo> { cell, _, photo in
            cell.configure(with: photo)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Photo>(collectionView: collectionView) {
            collectionView, indexPath, photo in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                              for: indexPath,
                                                              item: photo)
        }
    }
    
    func updateGallery(_ photos: [Photo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Photo>()
        snapshot.appendSections([.main])
        snapshot.appendItems(photos)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Exercise 4: Container View Controller Implementation

protocol TransitionCoordinator {
    func performTransition(from: UIViewController,
                         to: UIViewController,
                         completion: @escaping () -> Void)
}

protocol ContainerViewControllerDelegate: AnyObject {
    func containerViewController(_ container: ContainerViewController,
                               didTransitionTo viewController: UIViewController)
}

class ContainerViewController: UIViewController {
    private var viewControllers: [UIViewController] = []
    private var currentIndex: Int = 0
    private let transitionCoordinator: TransitionCoordinator
    weak var delegate: ContainerViewControllerDelegate?
    
    init(transitionCoordinator: TransitionCoordinator) {
        self.transitionCoordinator = transitionCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addChild(_ viewController: UIViewController) {
        viewControllers.append(viewController)
        
        if viewControllers.count == 1 {
            transition(to: 0)
        }
    }
    
    func removeChild(_ viewController: UIViewController) {
        if let index = viewControllers.firstIndex(of: viewController) {
            viewControllers.remove(at: index)
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
    }
    
    func transition(to index: Int) {
        guard index >= 0 && index < viewControllers.count else { return }
        
        let toViewController = viewControllers[index]
        
        if let fromViewController = children.first {
            transitionCoordinator.performTransition(from: fromViewController, to: toViewController) { [weak self] in
                self?.delegate?.containerViewController(self!, didTransitionTo: toViewController)
            }
        } else {
            addChild(toViewController)
            view.addSubview(toViewController.view)
            toViewController.view.frame = view.bounds
            toViewController.didMove(toParent: self)
            delegate?.containerViewController(self, didTransitionTo: toViewController)
        }
        
        currentIndex = index
    }
}

// MARK: - Exercise 5: Custom Control Implementation

class CustomSlider: UIControl {
    private var value: Float = 0 {
        didSet {
            if oldValue != value {
                sendActions(for: .valueChanged)
            }
        }
    }
    
    private var isTracking = false
    private var panGesture: UIPanGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }
    
    private func setupGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let progress = Float(translation.x / bounds.width)
        
        switch gesture.state {
        case .began:
            isTracking = true
            
        case .changed:
            let newValue = max(0, min(1, value + progress))
            updateValue(newValue)
            gesture.setTranslation(.zero, in: self)
            
        case .ended, .cancelled:
            isTracking = false
            animate()
            
        default:
            break
        }
    }
    
    func updateValue(_ newValue: Float) {
        value = newValue
        setNeedsDisplay()
    }
    
    func animate() {
        UIView.animate(withDuration: 0.3,
                      delay: 0,
                      options: [.curveEaseOut],
                      animations: { [weak self] in
            self?.layoutIfNeeded()
        })
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw track
        let trackPath = UIBezierPath(roundedRect: bounds, cornerRadius: 4)
        UIColor.systemGray5.setFill()
        trackPath.fill()
        
        // Draw progress
        let progressRect = CGRect(x: 0, y: 0, width: CGFloat(value) * bounds.width, height: bounds.height)
        let progressPath = UIBezierPath(roundedRect: progressRect, cornerRadius: 4)
        UIColor.systemBlue.setFill()
        progressPath.fill()
        
        // Draw knob
        let knobSize = CGSize(width: 20, height: bounds.height + 10)
        let knobX = CGFloat(value) * (bounds.width - knobSize.width)
        let knobRect = CGRect(x: knobX, y: -5, width: knobSize.width, height: knobSize.height)
        let knobPath = UIBezierPath(roundedRect: knobRect, cornerRadius: knobSize.width / 2)
        
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.2).cgColor)
        UIColor.white.setFill()
        knobPath.fill()
    }
}

// MARK: - Tests

class UIKitTests: XCTestCase {
    func testProfileViewController() {
        let profile = Profile(
            name: "John Doe",
            bio: "iOS Developer",
            imageURL: URL(string: "https://example.com/image.jpg")!,
            stats: ["Posts": 100, "Followers": 1000, "Following": 500]
        )
        
        let viewController = ProfileViewController()
        viewController.loadViewIfNeeded()
        viewController.updateProfile(profile)
        
        // Add assertions
    }
    
    func testFeedViewController() {
        let feedVC = FeedViewController()
        feedVC.loadViewIfNeeded()
        
        let items: [FeedItem] = [
            .text(TextItem(text: "Hello", author: "John")),
            .text(TextItem(text: "World", author: "Jane"))
        ]
        
        feedVC.updateFeed(items)
        
        XCTAssertEqual(feedVC.tableView.numberOfRows(inSection: 0), items.count)
    }
    
    func testGalleryViewController() {
        let galleryVC = GalleryViewController(collectionViewLayout: UICollectionViewFlowLayout())
        galleryVC.loadViewIfNeeded()
        
        let photos = [
            Photo(id: UUID(), imageURL: URL(string: "https://example.com/1.jpg")!, title: "Photo 1"),
            Photo(id: UUID(), imageURL: URL(string: "https://example.com/2.jpg")!, title: "Photo 2")
        ]
        
        galleryVC.updateGallery(photos)
        
        // Add assertions
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. More comprehensive error handling
// 2. Better resource management
// 3. More test cases
// 4. Proper cleanup
// 5. Documentation
// 6. Logging
// 7. Metrics collection
// 8. Performance optimizations 