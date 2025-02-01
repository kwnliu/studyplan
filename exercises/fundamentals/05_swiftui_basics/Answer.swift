import SwiftUI
import XCTest

// MARK: - Exercise 1: View Composition and Layout

struct Profile {
    let name: String
    let title: String
    let bio: String
    let imageURL: URL
    let stats: ProfileStats
}

struct ProfileStats {
    let followers: Int
    let following: Int
    let posts: Int
}

struct ProfileImageView: View {
    let url: URL
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }.resume()
    }
}

struct ProfileStatsView: View {
    let stats: ProfileStats
    
    var body: some View {
        HStack(spacing: 40) {
            StatItemView(title: "Posts", value: stats.posts)
            StatItemView(title: "Followers", value: stats.followers)
            StatItemView(title: "Following", value: stats.following)
        }
    }
}

struct StatItemView: View {
    let title: String
    let value: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ExpandableTextView: View {
    let text: String
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(text)
                .lineLimit(isExpanded ? nil : 2)
                .animation(.easeInOut, value: isExpanded)
            
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                Text(isExpanded ? "Show Less" : "Show More")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct ProfileCardView: View {
    let profile: Profile
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            ProfileImageView(url: profile.imageURL)
            
            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(profile.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ExpandableTextView(text: profile.bio, isExpanded: $isExpanded)
                .padding(.horizontal)
            
            ProfileStatsView(stats: profile.stats)
                .padding(.vertical)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

// MARK: - Exercise 2: State Management and Data Flow

struct Task: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var dueDate: Date
}

enum TaskFilter {
    case all, active, completed
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filter: TaskFilter = .all
    
    var filteredTasks: [Task] {
        switch filter {
        case .all:
            return tasks
        case .active:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func toggleTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
}

struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredTasks) { task in
                    TaskRow(task: task) {
                        viewModel.toggleTask(task)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        viewModel.deleteTask(viewModel.filteredTasks[index])
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingTask = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Filter", selection: $viewModel.filter) {
                        Text("All").tag(TaskFilter.all)
                        Text("Active").tag(TaskFilter.active)
                        Text("Completed").tag(TaskFilter.completed)
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(isPresented: $isAddingTask) { task in
                    viewModel.addTask(task)
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                Text(task.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddTaskView: View {
    @Binding var isPresented: Bool
    let onAdd: (Task) -> Void
    
    @State private var title = ""
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Task Title", text: $title)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
            }
            .navigationTitle("New Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Add") {
                    let task = Task(title: title, isCompleted: false, dueDate: dueDate)
                    onAdd(task)
                    isPresented = false
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// MARK: - Exercise 3: Custom Components and Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct ShadowModifier: ViewModifier {
    let radius: CGFloat
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius)
    }
}

struct ThemeColors {
    let primary = Color.blue
    let secondary = Color.gray
    let background = Color(.systemBackground)
    let text = Color(.label)
}

struct ThemeFonts {
    let title = Font.title
    let headline = Font.headline
    let body = Font.body
    let caption = Font.caption
}

struct ThemeSpacing {
    let small: CGFloat = 8
    let medium: CGFloat = 16
    let large: CGFloat = 24
}

struct AppTheme {
    static let colors = ThemeColors()
    static let fonts = ThemeFonts()
    static let spacing = ThemeSpacing()
}

// MARK: - Exercise 4: Lists and Navigation

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

struct Item: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    var isFavorite: Bool
}

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = [
        Category(name: "Work", icon: "briefcase"),
        Category(name: "Personal", icon: "person"),
        Category(name: "Shopping", icon: "cart"),
        Category(name: "Travel", icon: "airplane")
    ]
}

class ItemViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func toggleFavorite(_ item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
        }
    }
}

struct CategoryListView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State private var searchText = ""
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        return viewModel.categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List(filteredCategories) { category in
                NavigationLink(destination: ItemListView(category: category)) {
                    Label(category.name, systemImage: category.icon)
                }
            }
            .navigationTitle("Categories")
            .searchable(text: $searchText)
        }
    }
}

struct ItemListView: View {
    let category: Category
    @StateObject private var viewModel = ItemViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            NavigationLink(destination: ItemDetailView(item: item, isFavorite: Binding(
                get: { item.isFavorite },
                set: { _ in viewModel.toggleFavorite(item) }
            ))) {
                ItemRow(item: item)
            }
        }
        .navigationTitle(category.name)
    }
}

struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct ItemDetailView: View {
    let item: Item
    @Binding var isFavorite: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text(item.title)
                .font(.title)
            
            Text(item.description)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: { isFavorite.toggle() }) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "star.fill" : "star"
                )
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Exercise 5: Gestures and Animations

struct Card: Identifiable {
    let id = UUID()
    let value: String
    var isFlipped = false
}

enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
}

struct CardAnimation {
    static let flip = Animation.easeInOut(duration: 0.5)
    static let deal = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let shuffle = Animation.spring(response: 0.35, dampingFraction: 0.5)
}

struct CardView: View {
    let card: Card
    @State private var offset = CGSize.zero
    @State private var rotation = Angle.zero
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 5)
            
            if card.isFlipped {
                Text(card.value)
                    .font(.largeTitle)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
            }
        }
        .frame(width: 80, height: 120)
        .rotation3DEffect(rotation, axis: (x: 0, y: 1, z: 0))
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                }
        )
    }
}

class GameViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var selectedCard: Card?
    
    init() {
        cards = ["🂡", "🂢", "🂣", "🂤", "🂥"].map { Card(value: $0) }
    }
    
    func flipCard(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            withAnimation(CardAnimation.flip) {
                cards[index].isFlipped.toggle()
            }
        }
    }
    
    func shuffle() {
        withAnimation(CardAnimation.shuffle) {
            cards.shuffle()
        }
    }
}

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @GestureState private var dragState = DragState.inactive
    
    var body: some View {
        VStack {
            HStack {
                ForEach(viewModel.cards) { card in
                    CardView(card: card)
                        .onTapGesture {
                            viewModel.flipCard(card)
                        }
                }
            }
            .padding()
            
            Button("Shuffle") {
                viewModel.shuffle()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }
}

// MARK: - Tests

class SwiftUITests: XCTestCase {
    func testTaskViewModel() {
        let viewModel = TaskViewModel()
        let task = Task(title: "Test Task", isCompleted: false, dueDate: Date())
        
        // Test adding task
        viewModel.addTask(task)
        XCTAssertEqual(viewModel.tasks.count, 1)
        
        // Test toggling task
        viewModel.toggleTask(task)
        XCTAssertTrue(viewModel.tasks[0].isCompleted)
        
        // Test deleting task
        viewModel.deleteTask(task)
        XCTAssertTrue(viewModel.tasks.isEmpty)
    }
    
    func testTaskFiltering() {
        let viewModel = TaskViewModel()
        let task1 = Task(title: "Task 1", isCompleted: false, dueDate: Date())
        let task2 = Task(title: "Task 2", isCompleted: true, dueDate: Date())
        
        viewModel.addTask(task1)
        viewModel.addTask(task2)
        
        viewModel.filter = .active
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
        XCTAssertFalse(viewModel.filteredTasks[0].isCompleted)
        
        viewModel.filter = .completed
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
        XCTAssertTrue(viewModel.filteredTasks[0].isCompleted)
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. More comprehensive error handling
// 2. Better resource management
// 3. More test cases
// 4. Proper cleanup
// 5. Documentation
// 6. Accessibility support
// 7. Localization
// 8. Performance optimizations 