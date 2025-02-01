# VIP Pattern Exercise: Chat Message List

## Objective
Create a chat message list screen using the VIP (View-Interactor-Presenter) pattern. This exercise will help you understand unidirectional data flow, separation of concerns, and proper component communication in the VIP pattern.

## Requirements

### Models

1. Domain Models:
   ```swift
   struct Message {
       let id: UUID
       let text: String
       let sender: User
       let timestamp: Date
       let status: MessageStatus
   }
   
   struct User {
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
   ```

2. Request Models:
   - LoadMessagesRequest
   - SendMessageRequest
   - RetryMessageRequest
   - DeleteMessageRequest

3. Response Models:
   - MessagesResponse
   - MessageUpdateResponse
   - MessageErrorResponse

4. View Models:
   - MessageListViewModel
   - MessageCellViewModel

### View (MessageListViewController)

1. UI Components:
   - Message list (UITableView/UICollectionView)
   - Input field
   - Send button
   - Loading indicator
   - Error states

2. User Actions:
   - Load messages
   - Send message
   - Retry failed message
   - Delete message
   - Refresh messages

### Interactor

1. Business Logic:
   - Fetch messages from service
   - Process message sending
   - Handle message updates
   - Manage pagination
   - Handle errors

2. Workers:
   - MessageService
   - UserService
   - CacheWorker

### Presenter

1. Presentation Logic:
   - Format dates
   - Create message bubbles
   - Handle message status display
   - Format user names
   - Create error messages

## Specific Requirements

1. VIP Cycle Implementation:
   - Use protocols for communication
   - Implement proper data flow
   - Handle state updates correctly

2. Features:
   - Pagination (load more messages)
   - Message status updates
   - Error handling and retries
   - Message deletion
   - Pull to refresh

3. UI Requirements:
   - Different bubble styles for sent/received
   - Message status indicators
   - Timestamp formatting
   - Loading states
   - Error states

4. Testing:
   - Unit tests for each component
   - Mock dependencies
   - Test error scenarios
   - Test data flow

## Bonus Challenges
1. Add message reactions
2. Implement message editing
3. Add file attachments
4. Implement message search
5. Add read receipts

## Evaluation Criteria
- Proper VIP implementation
- Clean code organization
- Error handling
- Test coverage
- UI/UX implementation
- Code reusability
- Documentation

## Time Estimate
- Basic Implementation: 3-4 hours
- With Bonus Features: 6-8 hours

## Submission
Your solution should include:
1. Complete source code
2. Unit tests
3. Documentation
4. UI screenshots
5. Setup instructions
