//
//  WeatherViewModel.swift
//  SkyCast
//
//  Created by pooja kamble on 09/07/26.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

struct SavedCity: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
}

@MainActor
final class WeatherViewModel : ObservableObject {
    @Published var current: Forecast?
    @Published var currentDescription: String = "—"
    @Published var hourly: [Forecast] = []
    @Published var daily: [Forecast] = []
    @Published var metrics: WeatherMetrics?
    @Published var savedCities: [SavedCity] = []
    @Published var cityForecasts: [UUID: Forecast] = [:]
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let service = WeatherService.shared
    private let locationManager = LocationManager()
    private let savedCitiesKey = "savedCities.v1"
    
    init(){
        
    }
    
    func bootstrap() async {
        
    }
    func refreshCurrentLocationWeather() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }
        do {
            let coord = try await locationManager.requestCurrentLocation()
            let name = await
            service.reverseGeocode(coordinate: coord)
            let bundel = try await service.fetchWeather(latitude: coord.latitude,
                                                        longitude: coord.longitude,
                                                        locationName: name)
            self.current = bundel.current
            self.currentDescription = bundel.currentDescription
            self.hourly = bundel.hourly
            self.daily = bundel.daily
            self.metrics = bundel.metrics
            
        }catch {
            // Fallback to first saved city so the UI still shows something meaningful.
            
            errorMessage = error.localizedDescription
            if let fallback = savedCities.first {
                await loadWeather(for: fallback, setAsCureent: true)
            }
        }
    }
    func loadWeather(for city: SavedCity, setAsCureent: Bool = false) async {
        do {
            let bundel = try await service.fetchWeather(latitude: city.latitude,
                                                        longitude: city.longitude,
                                                        locationName: city.name)
            cityForecasts[city.id] = bundel.current
            if setAsCureent {
                self.current = bundel.current
                self.currentDescription = bundel.currentDescription
                self.hourly = bundel.hourly
                self.daily = bundel.daily
                self.metrics = bundel.metrics
            }
        } catch {
            errorMessage = errorMessage
        }
    }
    func refreshSavedCityForecasts() async {
        await withTaskGroup(of: (UUID, Forecast?).self) {
            group in
            for city in savedCities {
                group.addTask {
                    [service] in
                    do {
                        let bundel = try await
                        service.fetchWeather(latitude: city.latitude,
                                             longitude: city.longitude,
                                             locationName: city.name)
                        return (city.id, bundel.current)
                    }
                    catch {
                        return (city.id,nil)
                    }
                }
            }
            for await (id, forcast) in group {
                if let forecast = forcast {
                    cityForecasts[id] = forcast
                }
            }
        }
    }
    func addCity(from result: GeocodingResult) {
        if let existingIdx = savedCities.firstIndex(where: { $0.name == result.shortName }) {
            promoteToFront(index: existingIdx)
            return
        }
        let city = SavedCity(name: result.shortName,
                             latitude: result.latitude ?? <#default value#>,
                             longitude: result.longitude ?? <#default value#>)
        savedCities.insert(city, at: 0)
        persistSavedCities()
        Task { await loadWeather(for: city)}
    }
    // Load a geocoding result as the current forecast, saving to the top of the list.
    func selectSearchResult(_ result: GeocodingResult) async {
        if let existingIdx = savedCities.firstIndex(where: {
            $0.name == result.shortName
        }) {
            promoteToFront(index: existingIdx)
        } else {
            let city = SavedCity(name: result.shortName,
                                 latitude: result.latitude!,
                                 longitude: result.longitude!)
            savedCities.insert(city, at: 0)
            persistSavedCities()
        }
        let city = savedCities[0]
        await loadWeather(for: city, setAsCureent: true)
    }
    func promoteToFront(_ city: SavedCity) {
        guard let idx = savedCities.firstIndex(where: { $0.id == city.id }) else { return }
        promoteToFront(index: idx)
        
    }
    private func promoteToFront(index: Int){
        guard index > 0 , index < savedCities.count else {
            return
        }
        let city = savedCities.remove(at: index)
        savedCities.insert(city, at: 0)
        persistSavedCities()
    }
    func removeCity(_ city : SavedCity){
        savedCities.removeAll { $0.id == city.id}
        cityForecasts.removeValue(forKey: city.id)
        persistSavedCities()
    }
    // Persistence
    private func loadSavedCities(){
        guard let data = UserDefaults.standard.data(forKey: savedCitiesKey) else {
            return
        }
        if let decode = try? JSONDecoder().decode([SavedCity].self, from: data){
            savedCities = decode
        }
    }
    private func persistSavedCities(){
        if let data = try? JSONEncoder().encode(savedCities) {
            UserDefaults.standard.set(data, forKey: savedCitiesKey)
        }
    }
    static let defaultCities: [SavedCity] = [
        
    SavedCity(name: "Montreal, Canada", latitude: 45.5019, longitude: -73.5674),
               SavedCity(name: "Toronto, Canada", latitude: 43.6532, longitude: -79.3832),
               SavedCity(name: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503),
               SavedCity(name: "New York, United States", latitude: 40.7128, longitude: -74.0060)
    ]
}
