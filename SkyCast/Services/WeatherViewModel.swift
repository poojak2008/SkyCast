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
    @Published var current : Forecast?
    @Published var currentDescription: String = "-"
    
}
