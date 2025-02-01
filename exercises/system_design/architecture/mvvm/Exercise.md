# MVVM Pattern Exercise: Weather Dashboard Application

## Objective
Create a weather dashboard application using the MVVM architectural pattern. This exercise will help you understand data binding, state management, and the separation of concerns in MVVM.

## Requirements

### Model
Create the following model classes:
1. `WeatherData`
   - temperature: Double
   - condition: String
   - humidity: Int
   - windSpeed: Double
   - location: Location

2. `Location`
   - name: String
   - latitude: Double
   - longitude: Double
   - country: String

3. `WeatherService`
   - fetchWeather(for location: Location) async throws -> WeatherData
   - searchLocations(query: String) async throws -> [Location]

### ViewModel
Implement `WeatherViewModel` with:
1. Published/Observable Properties:
   - weatherData: WeatherData?
   - isLoading: Bool
   - error: Error?
   - searchResults: [Location]
   - selectedLocation: Location?

2. User Actions:
   - searchLocation(query: String)
   - selectLocation(_ location: Location)
   - refreshWeather()
   - toggleTemperatureUnit()

3. Computed Properties:
   - formattedTemperature: String
   - formattedWindSpeed: String
   - weatherStatusMessage: String

### View
Create views for:
1. Location Search
   - Search bar
   - Results list
   - Error handling

2. Weather Display
   - Current conditions
   - Temperature
   - Humidity
   - Wind speed
   - Loading indicator
   - Error messages

## Specific Requirements

1. Data Binding:
   - Implement two-way binding between View and ViewModel
   - Use appropriate reactive framework (Combine, RxSwift, etc.)
   - Handle state updates efficiently

2. Error Handling:
   - Display user-friendly error messages
   - Implement retry mechanism
   - Handle network errors gracefully

3. State Management:
   - Handle loading states
   - Manage empty states
   - Handle transitions between states

4. Testing:
   - Unit tests for ViewModel
   - Mock WeatherService
   - Test error scenarios

## Bonus Challenges
1. Add weather forecast for next 5 days
2. Implement location favorites
3. Add weather alerts
4. Implement offline caching
5. Add weather maps integration

## Evaluation Criteria
- Proper MVVM implementation
- Effective use of data binding
- Clean and maintainable code
- Proper error handling
- State management
- Unit test coverage
- Code organization
- UI/UX design

## Time Estimate
- Basic Implementation: 3-4 hours
- With Bonus Features: 6-8 hours

## Submission
Your solution should include:
1. Complete source code
2. Unit tests
3. Documentation
4. Setup instructions
5. Screenshots of the application
