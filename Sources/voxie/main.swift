import Foundation
import Logging

let log = Logger(label: "co.easeai.voxie")

let gpio = GPIO()
let btn = gpio.setupPullUpButton(for: 17)

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

        let capturer = try startCapture()
        btn.untilRelease()
        log.info("button released")

        let input = endCapture(for: capturer)
        try await conversation.chat(for: input)
    } catch {
        log.error("chat conversation error: \(error)")
    }
}

