import Foundation
import UIKit

// MARK: - Models

struct Message: Identifiable {
    let id: UUID
    let text: String
    let sender: User
    let timestamp: Date
    var status: MessageStatus
}

struct User: Identifiable {
    let id: UUID
    let name: String
    let avatarURL: URL?
}

enum MessageStatus {
    case sending
    case sent
    case delivered
    case read
    case failed
}

// MARK: - Protocols

// View -> Interactor
protocol MessageListBusinessLogic {
    func loadMessages(request: MessageList.LoadMessages.Request)
    func sendMessage(request: MessageList.SendMessage.Request)
    func retryMessage(request: MessageList.RetryMessage.Request)
    func deleteMessage(request: MessageList.DeleteMessage.Request)
}

// Interactor -> Presenter
protocol MessageListPresentationLogic {
    func presentMessages(response: MessageList.LoadMessages.Response)
    func presentMessageUpdate(response: MessageList.MessageUpdate.Response)
    func presentError(response: MessageList.Error.Response)
}

// Presenter -> View
protocol MessageListDisplayLogic: AnyObject {
    func displayMessages(viewModel: MessageList.LoadMessages.ViewModel)
    func displayMessageUpdate(viewModel: MessageList.MessageUpdate.ViewModel)
    func displayError(viewModel: MessageList.Error.ViewModel)
}

// MARK: - VIP Scene

enum MessageList {
    // MARK: Use Cases
    
    enum LoadMessages {
        struct Request {
            let page: Int
            let pageSize: Int
        }
        
        struct Response {
            let messages: [Message]
            let hasMorePages: Bool
        }
        
        struct ViewModel {
            let sections: [MessageSection]
            let canLoadMore: Bool
        }
    }
    
    enum SendMessage {
        struct Request {
            let text: String
        }
    }
    
    enum RetryMessage {
        struct Request {
            let messageId: UUID
        }
    }
    
    enum DeleteMessage {
        struct Request {
            let messageId: UUID
        }
    }
    
    enum MessageUpdate {
        struct Response {
            let message: Message
        }
        
        struct ViewModel {
            let messageUpdate: MessageCellViewModel
            let indexPath: IndexPath
        }
    }
    
    enum Error {
        struct Response {
            let error: MessageError
        }
        
        struct ViewModel {
            let message: String
            let action: ErrorAction?
        }
    }
}

// MARK: - View

class MessageListViewController: UIViewController {
    // MARK: VIP
    var interactor: MessageListBusinessLogic?
    private var messages: [MessageSection] = []
    private var canLoadMore = true
    
    // MARK: UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private lazy var inputView: MessageInputView = {
        let input = MessageInputView()
        input.delegate = self
        return input
    }()
    
    // MARK: Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialMessages()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(inputView)
        // Add constraints
    }
    
    private func loadInitialMessages() {
        let request = MessageList.LoadMessages.Request(page: 1, pageSize: 20)
        interactor?.loadMessages(request: request)
    }
}

// MARK: - Display Logic
extension MessageListViewController: MessageListDisplayLogic {
    func displayMessages(viewModel: MessageList.LoadMessages.ViewModel) {
        messages = viewModel.sections
        canLoadMore = viewModel.canLoadMore
        tableView.reloadData()
    }
    
    func displayMessageUpdate(viewModel: MessageList.MessageUpdate.ViewModel) {
        if let cell = tableView.cellForRow(at: viewModel.indexPath) as? MessageCell {
            cell.configure(with: viewModel.messageUpdate)
        }
    }
    
    func displayError(viewModel: MessageList.Error.ViewModel) {
        // Show error alert or banner
    }
}

// MARK: - TableView DataSource & Delegate
extension MessageListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages[section].messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let message = messages[indexPath.section].messages[indexPath.row]
        cell.configure(with: message)
        return cell
    }
}

// MARK: - Input View Delegate
extension MessageListViewController: MessageInputViewDelegate {
    func messageInputView(_ view: MessageInputView, didSendMessage text: String) {
        let request = MessageList.SendMessage.Request(text: text)
        interactor?.sendMessage(request: request)
    }
}

// MARK: - Interactor

class MessageListInteractor {
    var presenter: MessageListPresentationLogic?
    private let messageService: MessageServiceProtocol
    private let currentUser: User
    
    init(messageService: MessageServiceProtocol, currentUser: User) {
        self.messageService = messageService
        self.currentUser = currentUser
    }
}

extension MessageListInteractor: MessageListBusinessLogic {
    func loadMessages(request: MessageList.LoadMessages.Request) {
        Task {
            do {
                let messages = try await messageService.fetchMessages(
                    page: request.page,
                    pageSize: request.pageSize
                )
                let response = MessageList.LoadMessages.Response(
                    messages: messages,
                    hasMorePages: messages.count == request.pageSize
                )
                presenter?.presentMessages(response: response)
            } catch {
                presenter?.presentError(response: .init(error: .fetchFailed))
            }
        }
    }
    
    func sendMessage(request: MessageList.SendMessage.Request) {
        let message = Message(
            id: UUID(),
            text: request.text,
            sender: currentUser,
            timestamp: Date(),
            status: .sending
        )
        
        // Optimistically update UI
        presenter?.presentMessageUpdate(response: .init(message: message))
        
        Task {
            do {
                let sentMessage = try await messageService.sendMessage(message)
                presenter?.presentMessageUpdate(response: .init(message: sentMessage))
            } catch {
                let failedMessage = Message(
                    id: message.id,
                    text: message.text,
                    sender: message.sender,
                    timestamp: message.timestamp,
                    status: .failed
                )
                presenter?.presentMessageUpdate(response: .init(message: failedMessage))
            }
        }
    }
    
    func retryMessage(request: MessageList.RetryMessage.Request) {
        // Implement retry logic
    }
    
    func deleteMessage(request: MessageList.DeleteMessage.Request) {
        // Implement delete logic
    }
}

// MARK: - Presenter

class MessageListPresenter {
    weak var viewController: MessageListDisplayLogic?
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
    }
}

extension MessageListPresenter: MessageListPresentationLogic {
    func presentMessages(response: MessageList.LoadMessages.Response) {
        let sections = createMessageSections(from: response.messages)
        let viewModel = MessageList.LoadMessages.ViewModel(
            sections: sections,
            canLoadMore: response.hasMorePages
        )
        viewController?.displayMessages(viewModel: viewModel)
    }
    
    func presentMessageUpdate(response: MessageList.MessageUpdate.Response) {
        // Create view model and find index path
        // viewController?.displayMessageUpdate(viewModel: viewModel)
    }
    
    func presentError(response: MessageList.Error.Response) {
        let viewModel = MessageList.Error.ViewModel(
            message: response.error.localizedDescription,
            action: nil
        )
        viewController?.displayError(viewModel: viewModel)
    }
    
    private func createMessageSections(from messages: [Message]) -> [MessageSection] {
        // Group messages by date and create sections
        return []
    }
}

// MARK: - Supporting Types

struct MessageSection {
    let date: Date
    let messages: [MessageCellViewModel]
}

struct MessageCellViewModel {
    let id: UUID
    let text: String
    let senderName: String
    let timestamp: String
    let status: MessageStatus
    let isFromCurrentUser: Bool
}

enum MessageError: Error {
    case fetchFailed
    case sendFailed
    case deleteFailed
}

enum ErrorAction {
    case retry(() -> Void)
    case dismiss
}

protocol MessageInputViewDelegate: AnyObject {
    func messageInputView(_ view: MessageInputView, didSendMessage text: String)
}

class MessageInputView: UIView {
    weak var delegate: MessageInputViewDelegate?
    // Implement input view UI
}

class MessageCell: UITableViewCell {
    func configure(with viewModel: MessageCellViewModel) {
        // Configure cell UI
    }
}

// MARK: - Service Layer

protocol MessageServiceProtocol {
    func fetchMessages(page: Int, pageSize: Int) async throws -> [Message]
    func sendMessage(_ message: Message) async throws -> Message
    func deleteMessage(_ messageId: UUID) async throws
}

// Note: This is a sample implementation. A complete solution would include:
// 1. Complete UI implementation with constraints
// 2. Message grouping by date
// 3. Proper error handling
// 4. Loading states
// 5. Pagination implementation
// 6. Message status updates
// 7. Retry mechanism
// 8. Unit tests
// 9. Documentation
