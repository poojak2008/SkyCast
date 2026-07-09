//
//  Forecast.swift
//  SkyCast
//
//  Created by pooja kamble on 03/07/26.
//

import Foundation

enum ForecastPeriod{
    case hourly
    case daily

}

enum Weather : String {
    case clear = "Clear"
    case cloudy = "Cloudy"
    case rainy = "Mid Rain"
    case stromy = "Showers"
    case sunny = "Sunny"
    case tornado = "Tornado"
    case windy = "Fast Wind"
}

struct Forecast : Identifiable {
    var id = UUID()
    var date : Date
    var wether : Weather
    var probability : Int
    var temperature : Int
    var high : Int
    var low : Int
    var location : String
    
    var sfSymbols: String {
        switch wether {
        case .clear:
            return "moon.stars.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .stromy:
            return "cloud.bolt.rain.fill"
        case .sunny:
            return "sun.max.fill"
        case .tornado:
            return "tornado"
        case .windy:
            return "wind"
        }
    }
    var icon : String { sfSymbols }
}

struct WheatherMetrics: Equatable {
    var uvIndex: Double?
    var sunrise: Date?
    var sunset: Data?
    var timezoneIdentifier: String?
    var windSpeedKmh: Double?
    var windDirection: Double?
    var precipitationLastHourMM: Double?
    var precipitationNext24Mm: Double?
    var feelsLikeC: Double?
    var actualTempC : Double?
    var humidityPercent : Double?
    var dewPointC : Double?
    var visibilityKm : Double?
    var pressureHpa : Double?
    var airQuality : AirQuality
    
    var locationTimeZone: TimeZone {
        timezoneIdentifier.flatMap(TimeZone.init(identifier: )) ?? .current
    }
}

struct AirQuality : Equatable {
    var usAqi : Int
    var category : String
    var description: String
    var accent : AqiAccent
    
    enum AqiAccent {
        case good, moderate,sensitive,unhelthy,veryUnhelth , hazardous
    }
    
    static func classify(usAqi: Int) -> AirQuality {
        switch usAqi {
        case ..<51: return AirQuality(usAqi: usAqi, category: "Good", description: "Air Quality is satisfactory", accent: .good)
            
        case 51..<101: return AirQuality(usAqi: usAqi, category: "Moderate", description: "Acceptabel for most, sensitive groups take care", accent: .moderate)
            
        case 101..<151: return AirQuality(usAqi: usAqi, category: "Unhealthy for Sensitive", description: "Sensitive groups may experience effects.", accent: .sensitive)
        
        case 151..<201: return AirQuality(usAqi: usAqi, category: "Unhealthy", description: "Every may experince effect", accent: .unhelthy)
        
        case 201..<301: return AirQuality(usAqi: usAqi, category: "Very Unhealthy", description: "Health alert: serious effect for everyone", accent: .veryUnhelth)
        default:
            return AirQuality(usAqi: usAqi, category: "Hazardous", description: "Emergencey conditions", accent: .hazardous)
        }
    }
}
extension Weather {
    static func map(code : Int,isDay: Bool) ->(Weather , String) {
        switch code {
        case 0:return isDay ? (.sunny, "Sunny") : (.clear, "Clear")
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
            return (.stromy, "Freezing Rain")
        case 71, 73, 75:
            return (.cloudy, "Snow")
        case 77:
            return (.cloudy, "Snow Grains")
        case 80, 81, 82:
            return (.stromy, "Rain Showers")
        case 85, 86:
            return (.cloudy, "Snow Showers")
        case 95:
            return (.stromy, "Thunderstorm")
        case 96, 99:
            return (.stromy, "Thunderstorm w/ Hail")
        default:
            return (.cloudy, "Cloudy")
        }
    }
}
