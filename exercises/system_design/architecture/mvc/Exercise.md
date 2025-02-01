# MVC Pattern Exercise: Task Management Application

## Objective
Create a simple task management application using the MVC architectural pattern. This exercise will help you understand how to properly separate concerns and implement communication between MVC components.

## Requirements

### Model
Create a `Task` model with the following properties:
- id: UUID
- title: String
- description: String
- dueDate: Date
- isCompleted: Bool
- priority: TaskPriority (enum: high, medium, low)

### View
Implement views for:
1. Task list display
2. Task creation form
3. Task detail view
4. Task edit form

### Controller
Implement a `TaskController` that handles:
1. Creating new tasks
2. Updating existing tasks
3. Marking tasks as complete
4. Deleting tasks
5. Filtering tasks by priority

## Specific Requirements

1. The Model must:
   - Implement proper data validation
   - Notify observers when tasks are modified
   - Handle data persistence (in-memory storage is acceptable)

2. The View must:
   - Update automatically when the model changes
   - Handle user input appropriately
   - Display error messages when validation fails
   - Implement proper UI state management

3. The Controller must:
   - Handle all user actions from the View
   - Update the Model accordingly
   - Implement proper error handling
   - Manage the flow between View and Model

## Bonus Challenges
1. Add sorting functionality for tasks
2. Implement task categories
3. Add data persistence using UserDefaults or Core Data
4. Implement task search functionality
5. Add unit tests for all components

## Evaluation Criteria
- Proper separation of concerns
- Clean and maintainable code
- Effective communication between components
- Proper error handling
- Code organization and structure
- Implementation of bonus features (optional)

## Time Estimate
- Basic Implementation: 2-3 hours
- With Bonus Features: 4-5 hours

## Submission
Your solution should include:
1. Source code for all components
2. Brief documentation explaining your implementation
3. Instructions for running the application
4. Unit tests (if implemented)
