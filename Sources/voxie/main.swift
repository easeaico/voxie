import Foundation
import Logging

let log = Logger(label: "co.easeai.voxie")

let gpio = GPIO()
let btn = gpio.setupPullUpButton(for: 17)

let capturer = AudioCaptureActor()

let conf = loadConfig()
let conversation = Conversation(config: conf)

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
        
        let player = AudioPlayActor()
        try await conversation.chat(for: await capturer.getData(), player)
        while await player.isPlaying() {
            if btn.isClick() {
                try await player.cancel()
            }
        }
    } catch {
        log.error("chat conversation error: \(error)")
    }
}

