//
//  SensorHub.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 16/03/26.
//
// MARK: - HARDWARE MANAGER: READS GYRO, ACCELEROMETER, COMPASS, & CUSTOM STEPS

import Foundation
import CoreMotion
import CoreLocation
import Combine
import UIKit

final class SensorHub: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()

    @Published var rollDegrees: Double = 0
    @Published var pitchDegrees: Double = 0
    @Published var yawRadians: Double = 0

    @Published var horizontalTiltDegrees: Double = 0
    @Published var verticalTiltDegrees: Double = 0

    @Published var userAccelerationZ: Double = 0
    @Published var movementMagnitude: Double = 0
    @Published var rotationMagnitude: Double = 0
    
    @Published var customStepCount: Int = 0
    
    @Published var headingDegrees: Double = 0
    @Published var courseDegrees: Double = -1
    @Published var locationAuthorized: Bool = false
    @Published var stepSurge: Double = 0

    var motionAvailable: Bool { motionManager.isDeviceMotionAvailable }
    var headingAvailable: Bool { CLLocationManager.headingAvailable() }

    // State variable to track the "bounce" of a footstep
//    private var isStepping = false
    
    private var isStepReady = true
    private var lastStepTime = Date()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone

        let status = locationManager.authorizationStatus
        locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
    }

    func requestPermissions() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startAll() {
        startMotion()
        restartPedometerSession()
        startLocationIfPossible()
    }

    func stopAll() {
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    // reset custom counter
    func restartPedometerSession() {
        DispatchQueue.main.async {
            self.customStepCount = 0
        }
    }

    private func startMotion() {
        guard motionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            self.rollDegrees = motion.attitude.roll * 180 / .pi
            self.pitchDegrees = motion.attitude.pitch * 180 / .pi
            self.yawRadians = motion.attitude.yaw
            self.userAccelerationZ = motion.userAcceleration.z

            self.updateScreenSpaceTilt(from: motion)

            let ax = motion.userAcceleration.x
            let ay = motion.userAcceleration.y
            let az = motion.userAcceleration.z
            let currentMovement = sqrt(ax * ax + ay * ay + az * az)
            
            self.movementMagnitude = currentMovement

            let gx = motion.rotationRate.x
            let gy = motion.rotationRate.y
            let gz = motion.rotationRate.z
            self.rotationMagnitude = sqrt(gx * gx + gy * gy + gz * gz)
            
            // This is custom step counternya (apple punya gabisa lol)
            // harus stabilize first
            let now = Date()

            if self.isStepReady {
                // 1. Check if the vertical bounce is hard enough
                let isHardEnough = az > GameConfig.Physics.stepImpactThreshold
                
                // 2. calculate horizontal movement (dpn, blkng, right, left)
                let xyForce = sqrt(ax * ax + ay * ay)
                let isActuallyWalking = xyForce > 0.04 // requires a bit of body travel
                
                // 3. check if enough time has passed
                let isNotTooFast = now.timeIntervalSince(self.lastStepTime) > GameConfig.Physics.stepCooldown
                
                // 4. check if just violently twisting
                let isNotViolentShake = self.rotationMagnitude < GameConfig.Physics.maxShakeRotation

                // Combine all 1-4
                if isHardEnough && isActuallyWalking && isNotTooFast && isNotViolentShake {
                    self.isStepReady = false
                    self.lastStepTime = now
                    
                    let xForce = motion.userAcceleration.x
                    
                    DispatchQueue.main.async {
                        self.stepSurge = xForce
                        self.customStepCount += 1
                    }
                }
            } else {
                // wait for phone to stabilize
                if az < GameConfig.Physics.stepSettleThreshold {
                    self.isStepReady = true
                }
            }
        }
    }

    private func updateScreenSpaceTilt(from motion: CMDeviceMotion) {
        let gravity = motion.gravity
        let orientation = currentInterfaceOrientation()

        let horizontalComponent: Double
        let verticalComponent: Double

        if orientation == .landscapeLeft {
            horizontalComponent = -gravity.y
            verticalComponent = gravity.x
        } else {
            // Default assumes Landscape Right
            horizontalComponent = gravity.y
            verticalComponent = -gravity.x
        }

        let screenNormal = -gravity.z

        horizontalTiltDegrees = atan2(horizontalComponent, screenNormal) * 180 / .pi
        verticalTiltDegrees = atan2(verticalComponent, screenNormal) * 180 / .pi
    }

    private func currentInterfaceOrientation() -> UIInterfaceOrientation {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .interfaceOrientation ?? .landscapeRight
    }

    private func startLocationIfPossible() {
        guard headingAvailable else { return }
        guard locationAuthorized else { return }

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            let orientation = windowScene.interfaceOrientation
            locationManager.headingOrientation = (orientation == .landscapeLeft) ? .landscapeLeft : .landscapeRight
        }

        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways

        if locationAuthorized {
            startLocationIfPossible()
        } else {
            locationManager.stopUpdatingHeading()
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let trueHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingDegrees = trueHeading
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        if last.course >= 0 {
            courseDegrees = last.course
        }
        
    }
}
