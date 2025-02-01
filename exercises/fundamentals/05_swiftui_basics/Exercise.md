# SwiftUI Basics Exercises

## Exercise 1: View Composition and Layout

### Objective
Create a profile card view using SwiftUI's layout system and view composition.

### Requirements

1. **Profile Card View**
   ```swift
   struct ProfileCardView: View {
       let profile: Profile
       @State private var isExpanded: Bool
       
       // Implement view body
       var body: some View
   }
   ```

2. **Profile Model**
   ```swift
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
   ```

3. **Supporting Views**
   ```swift
   struct ProfileImageView: View
   struct ProfileStatsView: View
   struct ExpandableTextView: View
   ```

### Tasks
1. Implement the profile card layout
2. Create reusable components
3. Add animations for state changes
4. Support dark mode
5. Add accessibility labels

## Exercise 2: State Management and Data Flow

### Objective
Create a task management app demonstrating SwiftUI's state management capabilities.

### Requirements

1. **Task List View**
   ```swift
   struct TaskListView: View {
       @StateObject private var viewModel: TaskViewModel
       @State private var isAddingTask: Bool
       
       // Implement view body
       var body: some View
   }
   ```

2. **View Model**
   ```swift
   class TaskViewModel: ObservableObject {
       @Published var tasks: [Task]
       @Published var filter: TaskFilter
       
       func addTask(_ task: Task)
       func toggleTask(_ task: Task)
       func deleteTask(_ task: Task)
   }
   ```

3. **Models**
   ```swift
   struct Task: Identifiable {
       let id: UUID
       var title: String
       var isCompleted: Bool
       var dueDate: Date
   }
   
   enum TaskFilter {
       case all, active, completed
   }
   ```

### Tasks
1. Implement task list with filtering
2. Create task creation/editing flow
3. Add persistence
4. Implement undo/redo
5. Add sorting options

## Exercise 3: Custom Components and Modifiers

### Objective
Create a set of custom UI components and modifiers for consistent styling.

### Requirements

1. **Custom Button Style**
   ```swift
   struct PrimaryButtonStyle: ButtonStyle {
       func makeBody(configuration: Configuration) -> some View
   }
   ```

2. **Custom View Modifiers**
   ```swift
   struct CardModifier: ViewModifier {
       func body(content: Content) -> some View
   }
   
   struct ShadowModifier: ViewModifier {
       let radius: CGFloat
       let color: Color
       
       func body(content: Content) -> some View
   }
   ```

3. **Theme System**
   ```swift
   struct AppTheme {
       static let colors: ThemeColors
       static let fonts: ThemeFonts
       static let spacing: ThemeSpacing
   }
   ```

### Tasks
1. Create custom button styles
2. Implement view modifiers
3. Build theme system
4. Add animations
5. Support dynamic type

## Exercise 4: Lists and Navigation

### Objective
Create a hierarchical navigation app using SwiftUI's navigation system.

### Requirements

1. **Category List**
   ```swift
   struct CategoryListView: View {
       @StateObject private var viewModel: CategoryViewModel
       
       // Implement view body
       var body: some View
   }
   ```

2. **Item List**
   ```swift
   struct ItemListView: View {
       let category: Category
       @StateObject private var viewModel: ItemViewModel
       
       // Implement view body
       var body: some View
   }
   ```

3. **Detail View**
   ```swift
   struct ItemDetailView: View {
       let item: Item
       @Binding var isFavorite: Bool
       
       // Implement view body
       var body: some View
   }
   ```

### Tasks
1. Implement navigation hierarchy
2. Add search functionality
3. Create custom transitions
4. Handle deep linking
5. Add state restoration

## Exercise 5: Gestures and Animations

### Objective
Create an interactive card game interface with gestures and animations.

### Requirements

1. **Card View**
   ```swift
   struct CardView: View {
       let card: Card
       @State private var offset: CGSize
       @State private var rotation: Angle
       
       // Implement view body
       var body: some View
   }
   ```

2. **Game View**
   ```swift
   struct GameView: View {
       @StateObject private var viewModel: GameViewModel
       @GestureState private var dragState: DragState
       
       // Implement view body
       var body: some View
   }
   ```

3. **Animation Configuration**
   ```swift
   struct CardAnimation {
       static let flip: Animation
       static let deal: Animation
       static let shuffle: Animation
   }
   ```

### Tasks
1. Implement card dragging
2. Add flip animations
3. Create dealing animation
4. Add haptic feedback
5. Handle game state transitions

## Evaluation Criteria
- Proper use of SwiftUI views
- State management implementation
- Animation smoothness
- Code organization
- Performance
- Accessibility support
- Dark mode support

## Time Estimate
- Exercise 1: 2-3 hours
- Exercise 2: 3-4 hours
- Exercise 3: 2-3 hours
- Exercise 4: 3-4 hours
- Exercise 5: 2-3 hours

## Submission Requirements
1. Complete implementation
2. Unit tests
3. UI tests
4. Performance analysis
5. Documentation 