//
//  WeatherService.swift
//  SkyCast
//
//  Created by pooja kamble on 05/07/26.
//

import Foundation
import Combine

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
        let us_aqi: Double
    }
}

struct WetherBundle {
    let location : String
    let current : Forecast
    let currentDescription : String
    let hourly: [Forecast]
    let daily : [Forecast]
    let metrics : WheatherMetrics
}

final class WeatherService {
    static let shared = WeatherService()
    private let session : URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    
    func fetchWeather(latitude: Double, longitude: Double,locationName: String) async throws -> WetherBundle{
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
        
        guard let url = components.url else {
            throw WeatherServiceError.invalidURL
        }
        let decode : OMForecastResponse = try await get(url)
    }
   
    private func get<T: Decodable>(_ url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse,!(200...299).contains(http.statusCode) {
                throw WeatherServiceError.badResponse(http.statusCode)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } } catch {
                throw WeatherServiceError.decoding(error)
            }
            catch let e as WeatherServiceError {
                throw e
            }
            catch {
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
