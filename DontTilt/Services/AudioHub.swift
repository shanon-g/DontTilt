//
//  AudioHub.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 27/03/26.
//
// MARK: - AUDIO MANAGER: HANDLES ALL BGM & OVERLAPPING SOUND EFFECTS

import Foundation
import AVFoundation

final class AudioHub {
    // Singleton instance so the whole app shares 1 audio manager
    static let shared = AudioHub()
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    
    // MARK: - Audio File Names
    enum MusicTrack: String {
        case menu = "menu_music"
        case restaurant = "restaurant_music_ambience"
        case baby = "baby_music_ambience"
    }
    
    enum SoundEffect: String {
        // Menu Sounds
        case buttonClick = "menu_button_click"
        case countdown10s = "menu_10_second_countdown"
        case babyLevelChosen = "baby_level_chosen"
        case restaurantLevelChosen = "restaurant_level_chosen"
        case enterLevel = "menu_entering_level"
        case countdown321 = "menu_321_countdown"
        
        // Restaurant Level
        case dishesSliding = "restaurant_dishes_sliding"
        case restaurantFailed = "restaurant_failed"
        case restaurantSuccess = "restaurant_finish_success"
        
        // Baby Level
        case babyWakingUp = "baby_waking_up"
        case babyCrying = "baby_crying"
        case babySuccess = "baby_finish_success"
    }
    
    // Configure audio session to play sound even if on silent mode
    private init() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Background Music (BGM)
    
    func playMusic(_ track: MusicTrack) {
        guard let url = findAudioURL(for: track.rawValue) else { return }
        
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // loop infinitely
            bgmPlayer?.volume = 0.6
            bgmPlayer?.play()
        } catch {
            print("Could not play music \(track.rawValue): \(error.localizedDescription)")
        }
    }
    
    func stopMusic() {
        bgmPlayer?.stop()
    }
    
    // MARK: - Sound Effects (SFX)
    
    func playSFX(_ effect: SoundEffect) {
        guard let url = findAudioURL(for: effect.rawValue) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.play()
            
            // Add to array so it doesn't get deallocated mid sound
            sfxPlayers.append(player)
            
            // Clean up players that finished playing
            sfxPlayers.removeAll { !$0.isPlaying }
            
        } catch {
            print("Could not play SFX \(effect.rawValue): \(error.localizedDescription)")
        }
    }
    
    func stopAllSFX() {
        sfxPlayers.forEach { $0.stop() }
        sfxPlayers.removeAll()
    }
    
    // MARK: - Helper Method
    
    /// Searches the main bundle for the audio file, trying common extensions.
    private func findAudioURL(for filename: String) -> URL? {
        let extensions = ["mp3", "wav", "m4a"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                return url
            }
        }
        
        print("Audio file not found: \(filename)")
        return nil
    }
}
