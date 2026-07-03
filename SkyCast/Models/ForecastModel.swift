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

struct WhetherMetrics: Equatable {
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
                        
}
