# View Controller Lifecycle Exercises

## Overview
This set of exercises focuses on understanding and implementing view controller lifecycle methods, managing view hierarchies, and handling memory management properly.

## Exercise 1: Basic Lifecycle Implementation

### Problem
Create a view controller that demonstrates all lifecycle methods and their proper usage.

### Task
1. Implement all lifecycle methods
2. Add proper logging
3. Handle memory management
4. Demonstrate view hierarchy management

### Answer

```swift
import UIKit

class LifecycleViewController: UIViewController {
    // MARK: - Properties
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private var lifecycleEvents: [String] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
    
    // MARK: - Initialization
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        logEvent("init(nibName:bundle:)")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        logEvent("init(coder:)")
    }
    
    // MARK: - Lifecycle Methods
    
    override func loadView() {
        super.loadView()
        setupView()
        logEvent("loadView()")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logEvent("viewDidLoad()")
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logEvent("viewWillAppear(_:)")
        
        // Register for notifications
        registerForNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent("viewDidAppear(_:)")
        
        // Start any ongoing processes
        startObservingData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        logEvent("viewWillLayoutSubviews()")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logEvent("viewDidLayoutSubviews()")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logEvent("viewWillDisappear(_:)")
        
        // Cleanup before disappearing
        pauseOngoingProcesses()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent("viewDidDisappear(_:)")
        
        // Remove notification observers
        removeNotificationObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        logEvent("didReceiveMemoryWarning()")
        
        // Clear any caches
        clearMemory()
    }
    
    deinit {
        logEvent("deinit")
        // Perform final cleanup
        cleanup()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        
        view.addSubview(contentView)
        contentView.addSubview(statusLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Lifecycle Management
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataUpdate(_:)),
            name: .dataDidUpdate,
            object: nil
        )
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func startObservingData() {
        DataManager.shared.startObserving()
    }
    
    private func pauseOngoingProcesses() {
        DataManager.shared.pauseObserving()
    }
    
    private func clearMemory() {
        lifecycleEvents.removeAll(keepingCapacity: true)
        updateStatusLabel()
    }
    
    private func cleanup() {
        DataManager.shared.stopObserving()
    }
    
    // MARK: - Event Handling
    
    @objc private func handleDataUpdate(_ notification: Notification) {
        guard let data = notification.userInfo?["data"] as? String else { return }
        logEvent("Data updated: \(data)")
    }
    
    // MARK: - Logging
    
    private func logEvent(_ event: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(event)"
        lifecycleEvents.append(logMessage)
        
        print(logMessage)
        updateStatusLabel()
    }
    
    private func updateStatusLabel() {
        let text = lifecycleEvents.joined(separator: "\n")
        statusLabel.text = text
    }
}

// MARK: - Support Classes

class DataManager {
    static let shared = DataManager()
    private var isObserving = false
    private var timer: Timer?
    
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        
        timer = Timer.scheduledTimer(
            withTimeInterval: 5.0,
            repeats: true
        ) { [weak self] _ in
            self?.notifyDataUpdate()
        }
    }
    
    func pauseObserving() {
        timer?.invalidate()
        timer = nil
    }
    
    func stopObserving() {
        isObserving = false
        pauseObserving()
    }
    
    private func notifyDataUpdate() {
        NotificationCenter.default.post(
            name: .dataDidUpdate,
            object: nil,
            userInfo: ["data": "Updated at \(Date())"]
        )
    }
}

extension Notification.Name {
    static let dataDidUpdate = Notification.Name("dataDidUpdate")
}
```

## Exercise 2: Container View Controller

### Problem
Create a custom container view controller that manages child view controllers.

### Task
1. Implement child view controller management
2. Handle transitions between children
3. Manage lifecycle events properly
4. Implement memory management

### Answer

```swift
class ContainerViewController: UIViewController {
    // MARK: - Properties
    private var currentViewController: UIViewController?
    private var childViewControllers: [String: UIViewController] = [:]
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Child View Controller Management
    
    func add(viewController: UIViewController, withIdentifier identifier: String) {
        // Remove existing controller with same identifier
        if let existingVC = childViewControllers[identifier] {
            remove(viewController: existingVC)
        }
        
        // Add new controller
        childViewControllers[identifier] = viewController
        addChild(viewController)
        
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        containerView.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    func remove(viewController: UIViewController) {
        // Remove from dictionary
        if let identifier = childViewControllers.first(where: { $0.value === viewController })?.key {
            childViewControllers.removeValue(forKey: identifier)
        }
        
        // Remove from hierarchy
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    func transition(to identifier: String, animated: Bool = true) {
        guard let targetVC = childViewControllers[identifier],
              targetVC !== currentViewController else {
            return
        }
        
        // Prepare transition
        targetVC.view.frame = containerView.bounds
        targetVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if animated {
            // Animated transition
            performAnimatedTransition(to: targetVC)
        } else {
            // Immediate transition
            performImmediateTransition(to: targetVC)
        }
    }
    
    private func performAnimatedTransition(to targetVC: UIViewController) {
        currentViewController?.willMove(toParent: nil)
        
        transition(from: currentViewController,
                  to: targetVC,
                  duration: 0.3,
                  options: [.transitionCrossDissolve],
                  animations: nil) { [weak self] _ in
            self?.currentViewController?.removeFromParent()
            self?.currentViewController = targetVC
        }
    }
    
    private func performImmediateTransition(to targetVC: UIViewController) {
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
        
        containerView.addSubview(targetVC.view)
        currentViewController = targetVC
    }
}

// Example Usage
class ExampleContainerViewController: ContainerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create child view controllers
        let firstVC = FirstViewController()
        let secondVC = SecondViewController()
        
        // Add them to container
        add(viewController: firstVC, withIdentifier: "first")
        add(viewController: secondVC, withIdentifier: "second")
        
        // Show initial controller
        transition(to: "first", animated: false)
    }
}
```

## Exercise 3: View Controller Presentation

### Problem
Implement custom view controller presentations and transitions.

### Task
1. Create custom presentation controller
2. Implement transition animations
3. Handle interactive transitions
4. Manage presentation lifecycle

### Answer

```swift
// MARK: - Custom Presentation Controller
class SlideInPresentationController: UIPresentationController {
    private let direction: PresentationDirection
    private var dimmingView: UIView!
    
    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         direction: PresentationDirection) {
        self.direction = direction
        super.init(presentedViewController: presentedViewController,
                  presenting: presentingViewController)
        setupDimmingView()
    }
    
    private func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        dimmingView.alpha = 0.0
        
        let recognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap(recognizer:))
        )
        dimmingView.addGestureRecognizer(recognizer)
    }
    
    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
    
    // MARK: - Presentation Controller Lifecycle
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }
        
        coordinator.animate { [weak self] _ in
            self?.dimmingView.alpha = 1.0
        }
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }
        
        coordinator.animate { [weak self] _ in
            self?.dimmingView.alpha = 0.0
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return .zero
        }
        
        let size: CGSize
        switch direction {
        case .left, .right:
            size = CGSize(width: containerView.bounds.width * 0.7,
                         height: containerView.bounds.height)
        case .top, .bottom:
            size = CGSize(width: containerView.bounds.width,
                         height: containerView.bounds.height * 0.5)
        }
        
        let origin: CGPoint
        switch direction {
        case .left:
            origin = CGPoint(x: 0, y: 0)
        case .right:
            origin = CGPoint(x: containerView.bounds.width - size.width, y: 0)
        case .top:
            origin = CGPoint(x: 0, y: 0)
        case .bottom:
            origin = CGPoint(x: 0, y: containerView.bounds.height - size.height)
        }
        
        return CGRect(origin: origin, size: size)
    }
}

// MARK: - Animation Controller
class SlideInAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    private let direction: PresentationDirection
    private let isPresentation: Bool
    
    init(direction: PresentationDirection, isPresentation: Bool) {
        self.direction = direction
        self.isPresentation = isPresentation
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from
        guard let controller = transitionContext.viewController(forKey: key) else { return }
        
        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }
        
        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        
        switch direction {
        case .left:
            dismissedFrame.origin.x = -presentedFrame.width
        case .right:
            dismissedFrame.origin.x = transitionContext.containerView.frame.size.width
        case .top:
            dismissedFrame.origin.y = -presentedFrame.height
        case .bottom:
            dismissedFrame.origin.y = transitionContext.containerView.frame.size.height
        }
        
        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame : dismissedFrame
        
        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: .curveEaseInOut
        ) {
            controller.view.frame = finalFrame
        } completion: { finished in
            if !self.isPresentation {
                controller.view.removeFromSuperview()
            }
            transitionContext.completeTransition(finished)
        }
    }
}

// MARK: - Presentation Manager
enum PresentationDirection {
    case left
    case right
    case top
    case bottom
}

class SlideInPresentationManager: NSObject {
    var direction: PresentationDirection = .left
}

extension SlideInPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                              presenting: UIViewController?,
                              source: UIViewController) -> UIPresentationController? {
        return SlideInPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            direction: direction
        )
    }
    
    func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInAnimationController(direction: direction, isPresentation: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInAnimationController(direction: direction, isPresentation: false)
    }
}

// Example Usage
class PresentingViewController: UIViewController {
    private let presentationManager = SlideInPresentationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.setTitle("Present", for: .normal)
        button.addTarget(self, action: #selector(presentModal), for: .touchUpInside)
        // Add button to view hierarchy and set constraints
    }
    
    @objc private func presentModal() {
        let modalVC = ModalViewController()
        modalVC.modalPresentationStyle = .custom
        modalVC.transitioningDelegate = presentationManager
        
        presentationManager.direction = .right
        present(modalVC, animated: true)
    }
}
```

## Testing Your Knowledge

1. What is the difference between `loadView` and `viewDidLoad`?
2. When is `viewWillLayoutSubviews` called vs `viewDidLayoutSubviews`?
3. How do you properly manage memory in view controllers?
4. What are the best practices for container view controllers?
5. How do custom presentations work internally?

## Additional Resources
- [View Controller Programming Guide](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/)
- [View Controller Lifecycle](https://developer.apple.com/documentation/uikit/uiviewcontroller)
- [Custom Container View Controllers](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html)
- [Custom View Controller Presentations](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html) 