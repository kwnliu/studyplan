# UIKit Fundamentals

## Overview
UIKit is Apple's framework for building user interfaces in iOS applications. This section covers the fundamental concepts and components of UIKit, including view controllers, views, layout, and user interaction.

## Key Concepts

### 1. View Hierarchy
- UIView and its subclasses
- View containment
- View lifecycle
- Frame vs Bounds
- View coordinates

### 2. Auto Layout
- Constraints
- Stack Views
- Safe Area
- Layout Guides
- Dynamic Type
- Size Classes

### 3. View Controllers
- Types of view controllers
- Container view controllers
- Presentation styles
- Navigation patterns
- Data passing

### 4. User Interaction
- Touch handling
- Gesture recognizers
- Target-action pattern
- Responder chain
- Event handling

### 5. UI Components
- UIButton
- UILabel
- UITextField
- UIImageView
- UITableView
- UICollectionView
- UIScrollView

## Best Practices

1. **View Controller Design**
   - Proper separation of concerns
   - Avoiding massive view controllers
   - Proper lifecycle management
   - Memory management
   - State handling

2. **Layout Management**
   - Constraint priorities
   - Layout debugging
   - Dynamic layouts
   - Adaptive layouts
   - Performance optimization

3. **User Experience**
   - Responsive UI
   - Proper feedback
   - Accessibility
   - Localization
   - Dark mode support

4. **Performance**
   - View reuse
   - Offscreen rendering
   - Layer optimization
   - Memory footprint
   - Drawing optimization

## Common Use Cases

1. **Custom Views**
   ```swift
   class CustomView: UIView {
       override init(frame: CGRect) {
           super.init(frame: frame)
           setupUI()
       }
       
       required init?(coder: NSCoder) {
           super.init(coder: coder)
           setupUI()
       }
       
       private func setupUI() {
           // UI setup code
       }
   }
   ```

2. **Auto Layout**
   ```swift
   private func setupConstraints() {
       NSLayoutConstraint.activate([
           view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
           view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
           view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
           view.bottomAnchor.constraint(equalTo: bottomAnchor)
       ])
   }
   ```

3. **View Controller Lifecycle**
   ```swift
   class ViewController: UIViewController {
       override func viewDidLoad() {
           super.viewDidLoad()
           setupUI()
       }
       
       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           updateUI()
       }
   }
   ```

## Debug Tools
- View Hierarchy Debugger
- Auto Layout Debug
- Memory Graph
- Time Profiler
- Core Animation

## Common Pitfalls
1. Constraint conflicts
2. Memory leaks in closures
3. Main thread blocking
4. Improper view lifecycle handling
5. Incorrect view hierarchy management

## Additional Resources
- [UIKit Documentation](https://developer.apple.com/documentation/uikit)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WWDC Sessions on UIKit](https://developer.apple.com/videos/frameworks/uikit)
- [Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/)

## Exercise 1: Custom View Controller and Auto Layout

### Problem
Create a profile view controller with a custom layout using Auto Layout programmatically.

### Task
1. Create a view controller with profile information
2. Implement Auto Layout constraints programmatically
3. Handle different screen sizes
4. Add scrolling support for smaller screens

### Answer

```swift
class ProfileViewController: UIViewController {
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 50
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        return stackView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureConstraints()
        populateData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [profileImageView, nameLabel, bioLabel, statsStackView].forEach {
            contentView.addSubview($0)
        }
        
        // Add stat views
        ["Posts", "Followers", "Following"].forEach { title in
            let statView = createStatView(title: title, value: "0")
            statsStackView.addArrangedSubview(statView)
        }
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Profile Image
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Bio Label
            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Stats Stack View
            statsStackView.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 24),
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createStatView(title: String, value: String) -> UIView {
        let container = UIView()
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        
        container.addSubview(valueLabel)
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func populateData() {
        nameLabel.text = "John Doe"
        bioLabel.text = "iOS Developer | Swift Enthusiast | Open Source Contributor\nLoves creating beautiful and functional apps"
        
        // Update stats
        if let postsLabel = statsStackView.arrangedSubviews[0].subviews.first as? UILabel {
            postsLabel.text = "42"
        }
        if let followersLabel = statsStackView.arrangedSubviews[1].subviews.first as? UILabel {
            followersLabel.text = "1.2K"
        }
        if let followingLabel = statsStackView.arrangedSubviews[2].subviews.first as? UILabel {
            followingLabel.text = "890"
        }
    }
}
```

## Exercise 2: Custom Table View Implementation

### Problem
Create a customizable table view with different cell types and dynamic content.

### Task
1. Create a custom table view controller
2. Implement multiple cell types
3. Handle dynamic content and updates
4. Add pull-to-refresh and infinite scrolling

### Answer

```swift
// MARK: - Models
enum FeedItemType {
    case photo(PhotoItem)
    case text(TextItem)
    case link(LinkItem)
}

struct PhotoItem {
    let id: String
    let imageURL: URL
    let caption: String
    let likes: Int
}

struct TextItem {
    let id: String
    let text: String
    let likes: Int
}

struct LinkItem {
    let id: String
    let title: String
    let url: URL
    let preview: URL?
}

// MARK: - View Controller
class FeedViewController: UIViewController {
    private var items: [FeedItemType] = []
    private var isLoading = false
    private var currentPage = 1
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.estimatedRowHeight = 100
        table.rowHeight = UITableView.automaticDimension
        return table
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerCells()
        loadInitialData()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func registerCells() {
        tableView.register(PhotoCell.self, forCellReuseIdentifier: PhotoCell.identifier)
        tableView.register(TextCell.self, forCellReuseIdentifier: TextCell.identifier)
        tableView.register(LinkCell.self, forCellReuseIdentifier: LinkCell.identifier)
    }
    
    @objc private func handleRefresh() {
        currentPage = 1
        loadData()
    }
    
    private func loadInitialData() {
        loadData()
    }
    
    private func loadData() {
        guard !isLoading else { return }
        isLoading = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            if self.currentPage == 1 {
                self.items.removeAll()
            }
            
            // Add mock data
            self.items.append(contentsOf: self.generateMockData())
            
            self.isLoading = false
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    private func generateMockData() -> [FeedItemType] {
        // Generate mock data based on currentPage
        var mockItems: [FeedItemType] = []
        
        // Add photo item
        if let url = URL(string: "https://example.com/photo.jpg") {
            mockItems.append(.photo(PhotoItem(
                id: UUID().uuidString,
                imageURL: url,
                caption: "Beautiful sunset #nature",
                likes: Int.random(in: 10...1000)
            )))
        }
        
        // Add text item
        mockItems.append(.text(TextItem(
            id: UUID().uuidString,
            text: "Just finished an amazing iOS development session! #swiftui #ios",
            likes: Int.random(in: 5...500)
        )))
        
        // Add link item
        if let url = URL(string: "https://example.com/article"),
           let previewURL = URL(string: "https://example.com/preview.jpg") {
            mockItems.append(.link(LinkItem(
                id: UUID().uuidString,
                title: "10 Tips for Better Swift Code",
                url: url,
                preview: previewURL
            )))
        }
        
        currentPage += 1
        return mockItems
    }
}

// MARK: - UITableView DataSource & Delegate
extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        switch item {
        case .photo(let photoItem):
            let cell = tableView.dequeueReusableCell(withIdentifier: PhotoCell.identifier, for: indexPath) as! PhotoCell
            cell.configure(with: photoItem)
            return cell
            
        case .text(let textItem):
            let cell = tableView.dequeueReusableCell(withIdentifier: TextCell.identifier, for: indexPath) as! TextCell
            cell.configure(with: textItem)
            return cell
            
        case .link(let linkItem):
            let cell = tableView.dequeueReusableCell(withIdentifier: LinkCell.identifier, for: indexPath) as! LinkCell
            cell.configure(with: linkItem)
            return cell
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height - 100 {
            loadData()
        }
    }
}

// MARK: - Cells
class PhotoCell: UITableViewCell {
    static let identifier = "PhotoCell"
    
    // Add UI components and configuration method
    func configure(with item: PhotoItem) {
        // Configure cell with photo item
    }
}

class TextCell: UITableViewCell {
    static let identifier = "TextCell"
    
    // Add UI components and configuration method
    func configure(with item: TextItem) {
        // Configure cell with text item
    }
}

class LinkCell: UITableViewCell {
    static let identifier = "LinkCell"
    
    // Add UI components and configuration method
    func configure(with item: LinkItem) {
        // Configure cell with link item
    }
}
```

## Exercise 3: Custom Collection View Layout

### Problem
Create a Pinterest-style collection view layout with dynamic sizing.

### Task
1. Implement custom UICollectionViewLayout
2. Handle dynamic cell sizes
3. Support different screen sizes
4. Add animations for updates

### Answer

```swift
class PinterestLayout: UICollectionViewLayout {
    // Layout attributes
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    // Customizable properties
    var numberOfColumns = 2
    var cellPadding: CGFloat = 6.0
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func prepare() {
        guard cache.isEmpty,
              let collectionView = collectionView else { return }
        
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        
        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            
            // Calculate cell frame
            let height = CGFloat.random(in: 150...300) // In real app, get actual content height
            let frame = CGRect(x: xOffset[column],
                             y: yOffset[column],
                             width: columnWidth,
                             height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            // Create layout attributes
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
            // Update content height and column tracking
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
            column = column < (numberOfColumns - 1) ? (column + 1) : 0
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return newBounds.width != collectionView.bounds.width
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
        contentHeight = 0
    }
}

// MARK: - View Controller Implementation
class PinterestViewController: UIViewController {
    private var items: [PinterestItem] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = PinterestLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.register(PinterestCell.self, forCellWithReuseIdentifier: PinterestCell.identifier)
    }
    
    private func loadData() {
        // Simulate loading data
        items = (0...20).map { _ in
            PinterestItem(
                image: URL(string: "https://example.com/image.jpg")!,
                title: "Sample Pin",
                description: "This is a sample pin description"
            )
        }
        collectionView.reloadData()
    }
}

// MARK: - Collection View Delegate & DataSource
extension PinterestViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PinterestCell.identifier, for: indexPath) as! PinterestCell
        cell.configure(with: items[indexPath.item])
        return cell
    }
}

// MARK: - Models and Cell
struct PinterestItem {
    let image: URL
    let title: String
    let description: String
}

class PinterestCell: UICollectionViewCell {
    static let identifier = "PinterestCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.8),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
        
        layer.cornerRadius = 12
        clipsToBounds = true
        backgroundColor = .systemBackground
    }
    
    func configure(with item: PinterestItem) {
        titleLabel.text = item.title
        // Load image using your preferred image loading library
    }
}
```

## Testing Your Knowledge

1. What are the key differences between frame and bounds?
2. How does Auto Layout work internally?
3. When should you use a table view vs a collection view?
4. How do you handle memory management in custom views?
5. What are the different ways to animate UI changes?

## Additional Resources
- [Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/)
- [Table View Programming Guide](https://developer.apple.com/documentation/uikit/views_and_controls/table_views)
- [Collection View Programming Guide](https://developer.apple.com/documentation/uikit/views_and_controls/collection_views)
- [View Controller Programming Guide](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/) 