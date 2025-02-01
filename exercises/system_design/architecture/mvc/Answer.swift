import Foundation
import UIKit

// MARK: - Model
enum TaskPriority: String {
    case high, medium, low
}

class Task {
    let id: UUID
    var title: String
    var description: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: TaskPriority
    
    init(id: UUID = UUID(), title: String, description: String, dueDate: Date, isCompleted: Bool = false, priority: TaskPriority) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
    }
}

protocol TaskStoreDelegate: AnyObject {
    func taskStoreDidUpdate()
}

class TaskStore {
    static let shared = TaskStore()
    private var tasks: [Task] = []
    private var delegates: [WeakTaskStoreDelegate] = []
    
    func addTask(_ task: Task) {
        tasks.append(task)
        notifyDelegates()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            notifyDelegates()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        notifyDelegates()
    }
    
    func getAllTasks() -> [Task] {
        return tasks
    }
    
    func getTasksByPriority(_ priority: TaskPriority) -> [Task] {
        return tasks.filter { $0.priority == priority }
    }
    
    func addDelegate(_ delegate: TaskStoreDelegate) {
        delegates.append(WeakTaskStoreDelegate(delegate))
    }
    
    private func notifyDelegates() {
        delegates.forEach { $0.delegate?.taskStoreDidUpdate() }
    }
}

// MARK: - Weak Delegate Wrapper
private class WeakTaskStoreDelegate {
    weak var delegate: TaskStoreDelegate?
    
    init(_ delegate: TaskStoreDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Controller
class TaskListViewController: UIViewController {
    private let taskStore = TaskStore.shared
    private let tableView = UITableView()
    private var tasks: [Task] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        taskStore.addDelegate(self)
        updateTasks()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.register(TaskCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTaskTapped)
        )
    }
    
    private func updateTasks() {
        tasks = taskStore.getAllTasks()
        tableView.reloadData()
    }
    
    @objc private func addTaskTapped() {
        let addTaskVC = TaskFormViewController()
        navigationController?.pushViewController(addTaskVC, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let task = tasks[indexPath.row]
        cell.configure(with: task)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        let detailVC = TaskDetailViewController(task: task)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - TaskStore Delegate
extension TaskListViewController: TaskStoreDelegate {
    func taskStoreDidUpdate() {
        updateTasks()
    }
}

// MARK: - Views
class TaskCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let priorityLabel = UILabel()
    private let dueDateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Add and configure subviews
        [titleLabel, priorityLabel, dueDateLabel].forEach {
            contentView.addSubview($0)
            // Add constraints here
        }
    }
    
    func configure(with task: Task) {
        titleLabel.text = task.title
        priorityLabel.text = task.priority.rawValue
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dueDateLabel.text = dateFormatter.string(from: task.dueDate)
        
        if task.isCompleted {
            titleLabel.attributedText = NSAttributedString(
                string: task.title,
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
        }
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. TaskFormViewController for creating/editing tasks
// 2. TaskDetailViewController for viewing task details
// 3. Proper error handling and validation
// 4. Complete UI layout with constraints
// 5. Unit tests
// 6. Data persistence
// 7. Better state management
// 8. Documentation
