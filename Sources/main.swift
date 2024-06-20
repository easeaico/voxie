import OpenAI
import MiniAudio
import TOMLKit
import Foundation
import SwiftyGPIO
import Logging

struct Config: Codable {
    let asr: ASR
    let tts: TTS
    let llm: LLM

    struct LLM: Codable {
        let scheme: String
        let host: String
        let port: Int
        let apiKey: String
        let model: String
    }
    
    struct ASR: Codable {
        let scheme: String
        let host: String
        let port: Int
        let apiKey: String
    }
    
    struct TTS: Codable {
        let scheme: String
        let host: String
        let port: Int
        let apiKey: String
    }
}

let logger = Logger(label: "co.easeai.voxie")

let config: Config
do {
    let configData = try String(contentsOf: URL(fileURLWithPath: "Config.toml"), encoding: .utf8)
    config = try TOMLDecoder().decode(Config.self, from: configData)
}
catch {
    logger.error("read Config.toml error: \(error)")
    exit(-1)
}

let asrConfig = OpenAI.Configuration(token: config.asr.apiKey, host: config.asr.host, port: config.asr.port, scheme: config.asr.scheme)
let asrClient = OpenAI(configuration: asrConfig)

let ttsConfig = OpenAI.Configuration(token: config.tts.apiKey, host: config.tts.host, port: config.tts.port, scheme: config.tts.scheme)
let ttsClient = OpenAI(configuration: ttsConfig)

let llmConfig = OpenAI.Configuration(token: config.llm.apiKey, host: config.llm.host, port: config.llm.port, scheme: config.llm.scheme)
let llmClient = OpenAI(configuration: llmConfig)

let capturer = AudioCapturer()
let player = AudioPlayer()

let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPiZero2)
let ledPin = gpios[.P16]!
ledPin.direction = .OUT

let btnPin = gpios[.P17]!
btnPin.pull = .up
btnPin.direction = .IN
btnPin.bounceTime = 1

btnPin.onFalling { gpio in 
    // light on
    ledPin.value = 1

    // close play device
    player.closeAudioPlaybackDevice()

    // start to capture
    do {
        try capturer.initAudioCaptureDevice(EncodingFormat.wav, AudioFormat.s16, 1, 16000)
        try capturer.startAudioCapturing()
    } catch {
        logger.error("start audio capturing error: \(error)")
    }
}

btnPin.onRaising { gpio in 
    // light off
    ledPin.value = 0
    // close capture
    capturer.closeAudioCaptureDevice()
    // send conversation
    let input = capturer.getData()

    // start to capture
    Task {
        do {
            ledPin.value = 1
            let output = try await conversation(for: input)
            ledPin.value = 0

            try player.initAudioPlaybackDevice(forPlay: output)
            try player.startAudioPlaying()
        } catch {
            logger.error("send conversation error: \(error)")
        }
    }
}

func conversation(for data: Data) async throws -> Data {
    let aQuery = AudioTranscriptionQuery(
        file: data,
        fileType: .wav,
        model: .whisper_1
    )
    let asrResult = try await asrClient.audioTranscriptions(query: aQuery)
    logger.info("audio transcription result: \(asrResult.text)")

    let cQuery = ChatQuery(
        messages: [.init(role: .user, content: asrResult.text)!],
        model: config.llm.model
    )
    let chatResult = try await llmClient.chats(query: cQuery)
    let content = chatResult.choices[0].message.content!.string!
    logger.info("ai chat result: \(content)")
    
    let sQuery = AudioSpeechQuery(
        model: .tts_1,
        input: content,
        voice: .alloy,
        responseFormat: .mp3, 
        speed: 1.0
    )
    let ttsResult = try await ttsClient.audioCreateSpeech(query: sQuery)
    logger.info("tts result, data size: \(ttsResult.audio.count)")
    return ttsResult.audio
}

// run event loop
//RunLoop.current.run()
logger.info("wait for servicing")
_ = readLine()
