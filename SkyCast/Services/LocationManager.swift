//
//  LocationManager.swift
//  SkyCast
//
//  Created by pooja kamble on 04/07/26.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject,ObservableObject {
    @Published var lastCoordinate: CLLocationCoordinate2D?
    @Published var authrizationStatus: CLAuthorizationStatus
    @Published var didfail: Bool = false
    
    private let manager = CLLocationManager()
    private var pendingRequest : [CheckedContinuation<CLLocationCoordinate2D, Error>] = []
    
    override init() {
        self.authrizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestCurrentLocation() async throws -> CLLocationCoordinate2D {
        switch manager.authorizationStatus{
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            throw LocationError.notAuthorized
        default:
            break
        }
    
        return try await withCheckedThrowingContinuation { contribution in
            pendingRequest.append(contribution)
            manager.requestLocation()
        }
    }
    enum LocationError: Error , LocalizedError {
        case notAuthorized
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized: return "Location acess is not authorized. Enabel it in Settings."
            case .unknown: return "Could not determine your location."
            }
        }
    }
    
    private func resume(with result: Result<CLLocationCoordinate2D,Error>) {
        let requests = pendingRequest
        pendingRequest.removeAll()
        for contribution in requests {
            switch result {
            case .success(let coord) : contribution.resume(returning: coord)
            case .failure(let err): contribution.resume(throwing: err)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else {
            return
    }
        Task {
            @MainActor in
            self.lastCoordinate = coord
            self.didfail = false
            self.resume(with: .success(coord))
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        Task {
            @MainActor in
            self.didfail = true
            self.resume(with: .failure(error))
        }
    }
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task {
            @MainActor in
            self.authrizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            } else if status == .denied || status == .restricted {
                self.resume(with: .failure(LocationError.notAuthorized))
            }
        }
    }
}
