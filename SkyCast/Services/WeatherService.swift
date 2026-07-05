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
