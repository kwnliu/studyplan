import Foundation
import Combine
import SwiftUI

// MARK: - Models
struct Location: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
}

struct WeatherData {
    let temperature: Double
    let condition: String
    let humidity: Int
    let windSpeed: Double
    let location: Location
}

enum WeatherError: Error {
    case networkError
    case invalidLocation
    case serviceUnavailable
}

// MARK: - Weather Service
protocol WeatherServiceProtocol {
    func fetchWeather(for location: Location) async throws -> WeatherData
    func searchLocations(query: String) async throws -> [Location]
}

class WeatherService: WeatherServiceProtocol {
    func fetchWeather(for location: Location) async throws -> WeatherData {
        // Simulated API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return WeatherData(
            temperature: Double.random(in: -10...35),
            condition: ["Sunny", "Cloudy", "Rainy", "Snowy"].randomElement()!,
            humidity: Int.random(in: 0...100),
            windSpeed: Double.random(in: 0...30),
            location: location
        )
    }
    
    func searchLocations(query: String) async throws -> [Location] {
        // Simulated API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Location(name: "\(query) City", latitude: 0, longitude: 0, country: "Country"),
            Location(name: "\(query) Town", latitude: 0, longitude: 0, country: "Country")
        ]
    }
}

// MARK: - ViewModel
@MainActor
class WeatherViewModel: ObservableObject {
    private let weatherService: WeatherServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var error: WeatherError?
    @Published var searchResults: [Location] = []
    @Published var selectedLocation: Location?
    @Published var temperatureUnit: TemperatureUnit = .celsius
    
    enum TemperatureUnit {
        case celsius
        case fahrenheit
    }
    
    init(weatherService: WeatherServiceProtocol = WeatherService()) {
        self.weatherService = weatherService
    }
    
    func searchLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            do {
                searchResults = try await weatherService.searchLocations(query: query)
            } catch {
                self.error = .networkError
            }
        }
    }
    
    func selectLocation(_ location: Location) {
        selectedLocation = location
        Task {
            await refreshWeather()
        }
    }
    
    func refreshWeather() async {
        guard let location = selectedLocation else { return }
        
        isLoading = true
        error = nil
        
        do {
            weatherData = try await weatherService.fetchWeather(for: location)
        } catch {
            self.error = .serviceUnavailable
        }
        
        isLoading = false
    }
    
    func toggleTemperatureUnit() {
        temperatureUnit = temperatureUnit == .celsius ? .fahrenheit : .celsius
    }
    
    var formattedTemperature: String {
        guard let temperature = weatherData?.temperature else { return "N/A" }
        
        let value = temperatureUnit == .celsius ? temperature : (temperature * 9/5 + 32)
        let unit = temperatureUnit == .celsius ? "°C" : "°F"
        return String(format: "%.1f%@", value, unit)
    }
    
    var formattedWindSpeed: String {
        guard let windSpeed = weatherData?.windSpeed else { return "N/A" }
        return String(format: "%.1f m/s", windSpeed)
    }
    
    var weatherStatusMessage: String {
        if isLoading {
            return "Loading weather data..."
        }
        if let error = error {
            return "Error: \(error)"
        }
        return weatherData?.condition ?? "No weather data available"
    }
}

// MARK: - Views
struct WeatherDashboardView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                
                if !viewModel.searchResults.isEmpty {
                    locationList
                }
                
                if let weatherData = viewModel.weatherData {
                    weatherDisplay(weatherData)
                } else {
                    noDataView
                }
            }
            .navigationTitle("Weather Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.toggleTemperatureUnit() }) {
                        Image(systemName: "thermometer")
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        TextField("Search location...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .onChange(of: searchText) { query in
                viewModel.searchLocation(query: query)
            }
    }
    
    private var locationList: some View {
        List(viewModel.searchResults) { location in
            Button(action: { viewModel.selectLocation(location) }) {
                Text("\(location.name), \(location.country)")
            }
        }
    }
    
    private func weatherDisplay(_ weather: WeatherData) -> some View {
        VStack(spacing: 20) {
            Text(weather.location.name)
                .font(.title)
            
            Text(viewModel.formattedTemperature)
                .font(.system(size: 50))
            
            Text(weather.condition)
                .font(.title2)
            
            HStack {
                WeatherInfoView(
                    icon: "humidity",
                    value: "\(weather.humidity)%",
                    label: "Humidity"
                )
                
                WeatherInfoView(
                    icon: "wind",
                    value: viewModel.formattedWindSpeed,
                    label: "Wind Speed"
                )
            }
        }
        .padding()
    }
    
    private var noDataView: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else {
                Text("Search for a location to see weather data")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WeatherInfoView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. Proper error handling with user-friendly messages
// 2. Persistence for user preferences
// 3. Comprehensive unit tests
// 4. Network layer with proper retry mechanism
// 5. Loading states and animations
// 6. More detailed weather information
// 7. Weather forecasts
// 8. Location favorites
// 9. Offline support
