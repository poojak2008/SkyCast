//
//  Forecast.swift
//  SkyCast
//
//  Created by pooja kamble on 03/07/26.
//

import Foundation

enum ForecastPeriod {
    case hourly
    case daily
}

enum Weather: String {
    case clear = "Clear"
    case cloudy = "Cloudy"
    case rainy = "Mid Rain"
    case stormy = "Showers"
    case sunny = "Sunny"
    case tornado = "Tornado"
    case windy = "Fast Wind"
}

struct Forecast: Identifiable {
    var id = UUID()
    var date: Date
    var weather: Weather
    var probability: Int
    var temperature: Int
    var high: Int
    var low: Int
    var location: String
    
    /// SF Symbol used to render every weather state. Uniform across the app for visual
    /// consistency — the app only ships 5 bundled asset icons, so we always fall back
    /// to symbols with `.symbolRenderingMode(.multicolor)` for a colored look.
    var sfSymbolName: String {
        switch weather {
        case .clear: return "moon.stars.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .sunny: return "sun.max.fill"
        case .tornado: return "tornado"
        case .windy: return "wind"
        }
    }

    /// Backwards-compatible name — always the SF Symbol.
    var icon: String { sfSymbolName }
}

// MARK: - Weather Metrics

struct WeatherMetrics: Equatable {
    var uvIndex: Double?
    var sunrise: Date?
    var sunset: Date?
    var timezoneIdentifier: String?
    var windSpeedKmh: Double?
    var windDirection: Double?
    var precipitationLastHourMm: Double?
    var precipitationNext24hMm: Double?
    var feelsLikeC: Double?
    var actualTempC: Double?
    var humidityPercent: Double?
    var dewPointC: Double?
    var visibilityKm: Double?
    var pressureHpa: Double?
    var airQuality: AirQuality?

    var locationTimeZone: TimeZone {
        timezoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
    }
}

struct AirQuality: Equatable {
    var usAqi: Int
    var category: String
    var description: String
    var accent: AqiAccent

    enum AqiAccent {
        case good, moderate, sensitive, unhealthy, veryUnhealthy, hazardous
    }

    static func classify(usAqi: Int) -> AirQuality {
        switch usAqi {
        case ..<51:  return AirQuality(usAqi: usAqi, category: "Good",
                                        description: "Air quality is satisfactory.", accent: .good)
        case 51..<101: return AirQuality(usAqi: usAqi, category: "Moderate",
                                          description: "Acceptable for most, sensitive groups take care.", accent: .moderate)
        case 101..<151: return AirQuality(usAqi: usAqi, category: "Unhealthy for Sensitive",
                                           description: "Sensitive groups may experience effects.", accent: .sensitive)
        case 151..<201: return AirQuality(usAqi: usAqi, category: "Unhealthy",
                                           description: "Everyone may experience effects.", accent: .unhealthy)
        case 201..<301: return AirQuality(usAqi: usAqi, category: "Very Unhealthy",
                                           description: "Health alert: serious effects for everyone.", accent: .veryUnhealthy)
        default: return AirQuality(usAqi: usAqi, category: "Hazardous",
                                    description: "Emergency conditions.", accent: .hazardous)
        }
    }
}

extension Weather {
    /// Maps an Open-Meteo WMO weather code to a `Weather` case and a human-readable description.
    static func map(code: Int, isDay: Bool) -> (Weather, String) {
        switch code {
        case 0:
            return isDay ? (.sunny, "Sunny") : (.clear, "Clear")
        case 1:
            return isDay ? (.sunny, "Mostly Clear") : (.clear, "Mostly Clear")
        case 2:
            return (.cloudy, "Partly Cloudy")
        case 3:
            return (.cloudy, "Overcast")
        case 45, 48:
            return (.cloudy, "Fog")
        case 51, 53, 55:
            return (.rainy, "Drizzle")
        case 56, 57:
            return (.rainy, "Freezing Drizzle")
        case 61:
            return (.rainy, "Light Rain")
        case 63:
            return (.rainy, "Rain")
        case 65:
            return (.rainy, "Heavy Rain")
        case 66, 67:
            return (.stormy, "Freezing Rain")
        case 71, 73, 75:
            return (.cloudy, "Snow")
        case 77:
            return (.cloudy, "Snow Grains")
        case 80, 81, 82:
            return (.stormy, "Rain Showers")
        case 85, 86:
            return (.cloudy, "Snow Showers")
        case 95:
            return (.stormy, "Thunderstorm")
        case 96, 99:
            return (.stormy, "Thunderstorm w/ Hail")
        default:
            return (.cloudy, "Cloudy")
        }
    }
}
