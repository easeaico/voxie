import Foundation
import Logging

let log = Logger(label: "co.easeai.voxie")

let gpio = GPIO()
let btn = gpio.setupPullUpButton(for: 17)

let conf = loadConfig()
let conversation = Conversation(config: conf) 

let dispatchGroup = DispatchGroup()
let dispatchQueue = DispatchQueue(label: "co.easeai.voxie")

 let output = try await conversation.bootstrap()
 let player = try startPlayback(for: output)
 sleep(player.getDuration())
 endPlayback(for: player)

// Main Loop
while(true) {
    log.info("waiting for serve")
    do {
        btn.untilPress()
        log.info("button pressed")

        let capturer = try startCapture()
        btn.untilRelease()
        log.info("button released")

        let input = endCapture(for: capturer)
        let output = try await conversation.chat(for: input)

        let player = try startPlayback(for: output)
        log.info("waiting for player, seconds: \(player.getDuration())")
        btn.untilClick(timeout: UInt64(player.getDuration() * 1000))
        endPlayback(for: player)
    } catch {
        log.error("chat conversation error: \(error)")
    }
}

