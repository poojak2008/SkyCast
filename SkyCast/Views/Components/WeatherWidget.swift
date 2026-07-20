//
//  WeatherWidget.swift
//  SkyCast
//
//  Created by pooja kamble on 15/07/26.
//

import SwiftUI
 
struct WeatherWidget: View {
    var forecast: Forecast
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: Trapezoid
            Trapezoid()
                .fill(Color.weatherWidgetBackground)
                .frame(width: 342, height: 174)
            
            // MARK: Content
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    // MARK: Forecast Temperature
                    Text("\(forecast.temperature)°")
                        .font(.system(size: 64))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // MARK: Forecast Temperature Range
                        Text("H:\(forecast.high)°  L:\(forecast.low)°")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        // MARK: Forecast Location
                        Text(forecast.location)
                            .font(.body)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    // MARK: Forecast Large Icon (SF Symbol — uniform across cities)
                    Image(systemName: forecast.sfSymbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 60))
                        .padding(.trailing, 20)
                        .padding(.bottom, 10)
 
                    // MARK: Weather
                    Text(forecast.weather.rawValue)
                        .font(.footnote)
                        .padding(.trailing, 24)
                }
            }
            .foregroundColor(.white)
            .padding(.bottom, 20)
            .padding(.leading, 20)
        }
        .frame(width: 342, height: 184, alignment: .bottom)
    }
}
 
struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidget(
            forecast: Forecast(
                date: .now,
                weather: .rainy,
                probability: 0,
                temperature: 19,
                high: 24,
                low: 18,
                location: "Preview City"
            )
        )
        .preferredColorScheme(.dark)
    }
}
