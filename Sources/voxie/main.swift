import Foundation
import Logging

let log = Logger(label: "co.easeai.voxie")

let gpio = GPIO()
let btn = gpio.setupPullUpButton(for: 17)
let player = AudioPlayActor()
let capturer = AudioCaptureActor()

let conf = loadConfig()
let conversation = Conversation(config: conf, player: player)

do {
    try await conversation.bootstrap()
} catch {
    log.error("boot conversation error: \(error)")
}

// Main Loop
while(true) {
    log.info("waiting for serve")
    do {
        btn.untilPress()
        log.info("button pressed")
        try await capturer.startCapture()
        btn.untilRelease()
        log.info("button released")
        await capturer.stopCapture()
        
        try await conversation.chat(for: await capturer.getData())
        btn.untilClick{ () -> Bool in
            return await player.isPlayed()
        }
    } catch {
        log.error("chat conversation error: \(error)")
    }
}

