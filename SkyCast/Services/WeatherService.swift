//
//  WeatherService.swift
//  SkyCast
//
//  Created by pooja kamble on 05/07/26.
//

import Foundation
import CoreLocation

enum WeatherServiceError: Error, LocalizedError {
    case invalidURL
    case badResponse(Int)
    case decoding(Error)
    case transport(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL : return "Bad URL"
        case .badResponse(let code) : return "Server error(\(code))"
            
        case .decoding(let e):
            return "Decoding failed:\(e.localizedDescription)"
        case .transport(let e):
            return e.localizedDescription
        }
    }
}
struct GeocodingResult: Identifiable, Hashable {
    let id = UUID()
    let name : String
    let country : String?
    let admin1 : String?
    let latitude: Double?
    let longitude: Double?
    
    var displayName : String {
        [name, admin1, country].compactMap { $0 }.filter{ !$0.isEmpty }.joined(separator: ",")
    }
    
    var shortName: String {
        [name, country].compactMap{ $0 }.filter{ !$0.isEmpty }.joined(separator: ", ")
    }
}
private struct OMGeocodingResponse: Decodable {
    struct Item: Decodable {
        let name: String
        let country: String?
        let admin1: String?
        let latitude: Double
        let longitude: Double
    }
    let results: [Item]?
}


private struct OMForecastResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
        let is_day: Int
        let apparent_temperature: Double?
        let relative_humidity_2m: Double?
        let wind_speed_10m: Double?
        let wind_direction_10m: Double?
        let surface_pressure: Double?
        let precipitation: Double?
        let dew_point_2m: Double?
    }
    struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let weather_code: [Int]
        let precipitation_probability: [Int]?
        let precipitation: [Double]?
        let visibility: [Double]?
    }
    struct Daily: Decodable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let weather_code: [Int]
        let precipitation_probability_max: [Int]?
        let precipitation_sum: [Double]?
        let sunrise: [String]?
        let sunset: [String]?
        let uv_index_max: [Double]?
    }
    let current: Current
    let hourly: Hourly
    let daily: Daily
    let timezone: String?
}

private struct OMAirQualityRespnse: Decodable {
    struct Current : Decodable {
        let us_aqi: Double?
    }
    let current: Current?
}

struct WetherBundle {
    let location : String
    let current : Forecast
    let currentDescription : String
    let hourly: [Forecast]
    let daily : [Forecast]
    let metrics : WeatherMetrics
}

final class WeatherService {
    static let shared = WeatherService()
    private let session : URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    
    func fetchWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WetherBundle {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "current", value: "temperature_2m,weather_code,is_day,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,surface_pressure,precipitation,dew_point_2m"),
            .init(name: "hourly", value: "temperature_2m,weather_code,precipitation_probability,precipitation,visibility"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,precipitation_sum,sunrise,sunset,uv_index_max"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "7")
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidURL }

        let decoded: OMForecastResponse = try await get(url)

        let tz = TimeZone(identifier: decoded.timezone ?? "UTC") ?? .current
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        localFormatter.timeZone = tz

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = tz

        // Hourly (next ~24 hours from now, keeping the current hour)
        let now = Date()
        var hourlyForecasts: [Forecast] = []
        var currentHourIndex: Int? = nil
        for i in 0..<decoded.hourly.time.count {
            guard let date = localFormatter.date(from: decoded.hourly.time[i]) else { continue }
            if date < now.addingTimeInterval(-3600) { continue }
            if currentHourIndex == nil { currentHourIndex = i }
            let (weather, _) = Weather.map(code: decoded.hourly.weather_code[i], isDay: date.isDaytime(tz: tz))
            let temp = Int(decoded.hourly.temperature_2m[i].rounded())
            let probability = decoded.hourly.precipitation_probability?[safe: i] ?? 0
            hourlyForecasts.append(
                Forecast(
                    date: date,
                    weather: weather,
                    probability: probability,
                    temperature: temp,
                    high: Int(decoded.current.temperature_2m.rounded()),
                    low: Int(decoded.current.temperature_2m.rounded()),
                    location: locationName
                )
            )
            if hourlyForecasts.count >= 24 { break }
        }

        // Daily (7 days)
        var dailyForecasts: [Forecast] = []
        for i in 0..<decoded.daily.time.count {
            guard let date = dayFormatter.date(from: decoded.daily.time[i]) else { continue }
            let (weather, _) = Weather.map(code: decoded.daily.weather_code[i], isDay: true)
            let high = Int(decoded.daily.temperature_2m_max[i].rounded())
            let low = Int(decoded.daily.temperature_2m_min[i].rounded())
            let probability = decoded.daily.precipitation_probability_max?[safe: i] ?? 0
            dailyForecasts.append(
                Forecast(
                    date: date,
                    weather: weather,
                    probability: probability,
                    temperature: high,
                    high: high,
                    low: low,
                    location: locationName
                )
            )
        }

        let (currentWeather, description) = Weather.map(code: decoded.current.weather_code, isDay: decoded.current.is_day == 1)
        let currentHigh = dailyForecasts.first?.high ?? Int(decoded.current.temperature_2m.rounded())
        let currentLow = dailyForecasts.first?.low ?? Int(decoded.current.temperature_2m.rounded())
        let current = Forecast(
            date: now,
            weather: currentWeather,
            probability: hourlyForecasts.first?.probability ?? 0,
            temperature: Int(decoded.current.temperature_2m.rounded()),
            high: currentHigh,
            low: currentLow,
            location: locationName
        )

        // Metrics
        let visibility: Double? = {
            guard let vis = decoded.hourly.visibility, let idx = currentHourIndex else { return nil }
            return vis[safe: idx].map { $0 / 1000.0 } // meters → km
        }()

        let sunrise = decoded.daily.sunrise?.first.flatMap { localFormatter.date(from: $0) }
        let sunset = decoded.daily.sunset?.first.flatMap { localFormatter.date(from: $0) }

        var metrics = WeatherMetrics(
            uvIndex: decoded.daily.uv_index_max?.first,
            sunrise: sunrise,
            sunset: sunset,
            timezoneIdentifier: decoded.timezone,
            windSpeedKmh: decoded.current.wind_speed_10m,
            windDirection: decoded.current.wind_direction_10m,
            precipitationLastHourMm: decoded.current.precipitation,
            precipitationNext24hMm: decoded.daily.precipitation_sum?.first,
            feelsLikeC: decoded.current.apparent_temperature,
            actualTempC: decoded.current.temperature_2m,
            humidityPercent: decoded.current.relative_humidity_2m,
            dewPointC: decoded.current.dew_point_2m,
            visibilityKm: visibility,
            pressureHpa: decoded.current.surface_pressure,
            airQuality: nil
        )

        // Air quality is best-effort — endpoint isn't always available for every location.
        if let aqi = try? await fetchAirQuality(latitude: latitude, longitude: longitude) {
            metrics.airQuality = aqi
        }

        return WetherBundle(
            location: locationName,
            current: current,
            currentDescription: description,
            hourly: hourlyForecasts,
            daily: dailyForecasts,
            metrics: metrics
        )
    }

    func fetchAirQuality(latitude: Double, longitude: Double) async throws -> AirQuality? {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "current", value: "us_aqi"),
            .init(name: "timezone", value: "auto")
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidURL }
        let decoded: OMAirQualityRespnse = try await get(url)
        guard let value = decoded.current?.us_aqi else { return nil }
        return AirQuality.classify(usAqi: Int(value.rounded()))
    }

    func searchCities(query: String) async throws -> [GeocodingResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            .init(name: "name", value: trimmed),
            .init(name: "count", value: "10"),
            .init(name: "language", value: "en"),
            .init(name: "format", value: "json")
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidURL }

        let decoded: OMGeocodingResponse = try await get(url)
        return (decoded.results ?? []).map {
            GeocodingResult(name: $0.name, country: $0.country, admin1: $0.admin1, latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.name ?? ""
                let country = placemark.country ?? ""
                let combined = [city, country].filter { !$0.isEmpty }.joined(separator: ", ")
                if !combined.isEmpty { return combined }
            }
        } catch {
            // fall through
        }
        return String(format: "%.2f, %.2f", coordinate.latitude, coordinate.longitude)
    }
    private func get<T: Decodable>(_ url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw WeatherServiceError.badResponse(http.statusCode)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw WeatherServiceError.decoding(error)
            }
        } catch let e as WeatherServiceError {
            throw e
        } catch {
            throw WeatherServiceError.transport(error)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension Date {
    func isDaytime(tz: TimeZone = .current) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let hour = cal.component(.hour, from: self)
        return (6..<19).contains(hour)
    }
}
