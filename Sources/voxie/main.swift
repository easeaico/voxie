import OpenAI
import MiniAudio
import TOMLKit
import Foundation
import Logging
import wiringPi

let logger = Logger(label: "co.easeai.voxie")

let btnPin: Int32 = 17
// uses BCM numbering of the GPIOs and directly accesses the GPIO registers.
wiringPiSetupGpio();

// pin mode ..(INPUT, OUTPUT, PWM_OUTPUT, GPIO_CLOCK)
// set pin 0 to input
pinMode(btnPin, INPUT);

// pull up/down mode (PUD_OFF, PUD_UP, PUD_DOWN) => down
pullUpDnControl(btnPin, PUD_UP);

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
        let model: String
    }
    
    struct TTS: Codable {
        let scheme: String
        let host: String
        let port: Int
        let apiKey: String
        let model: String
    }
}


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


Task {
    do {
        while HIGH == digitalRead(btnPin) {
            delay(200)
        }
        logger.info("button pushed")

        // start to capture
        let capturer = AudioCapturer()
        do {
            try capturer.initAudioCaptureDevice(EncodingFormat.wav, AudioFormat.s16, 1, 16000)
            try capturer.startAudioCapturing()
        } catch {
            logger.error("start audio capturing error: \(error)")
        }
        
        while LOW == digitalRead(btnPin) {
            delay(200)
        }
        logger.info("button released")

        // close capture
        capturer.closeAudioCaptureDevice()
        // send conversation
        let input = capturer.getData()
        let output = try await conversation(for: input)

        let player = AudioPlayer()
        try player.initAudioPlaybackDevice(forPlay: output)
        try player.startAudioPlaying()
        Thread.sleep(forTimeInterval: Double(player.getDuration()))
        // close play device
        player.closeAudioPlaybackDevice()
    } catch {
        logger.error("send conversation error: \(error)")
    }
}

func conversation(for data: Data) async throws -> Data {
    let aQuery = AudioTranscriptionQuery(
        file: data,
        fileType: .wav,
        model: config.asr.model,
        responseFormat: .text
    )
    logger.info("audio transcription query: \(aQuery)")
    let asrResult = try await asrClient.audioTranscriptions(query: aQuery)
    logger.info("audio transcription result: \(asrResult)")

    let cQuery = ChatQuery(
        messages: [.init(role: .user, content: asrResult.text)!],
        model: config.llm.model
    )
    let chatResult = try await llmClient.chats(query: cQuery)
    let content = chatResult.choices[0].message.content!.string!
    logger.info("ai chat result: \(content)")
    
    let sQuery = AudioSpeechQuery(
        model: config.tts.model,
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
logger.info("wait for servicing")
_ = readLine()
