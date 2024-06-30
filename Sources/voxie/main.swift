import OpenAI
import MiniAudio
import TOMLKit
import Foundation
import Logging

#if os(Linux)
import wiringPi
#endif

let logger = Logger(label: "co.easeai.voxie")

#if os(Linux)
logger.info("linux detected")
let btnPin: Int32 = 17
// uses BCM numbering of the GPIOs and directly accesses the GPIO registers.
wiringPiSetupGpio();

// pin mode ..(INPUT, OUTPUT, PWM_OUTPUT, GPIO_CLOCK)
// set pin 0 to input
pinMode(btnPin, INPUT);

// pull up/down mode (PUD_OFF, PUD_UP, PUD_DOWN) => down
pullUpDnControl(btnPin, PUD_UP);
#endif

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
    let path = Bundle.module.url(forResource: "Config", withExtension: "toml")
    let configData = try String(contentsOf: path!, encoding: .utf8)
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

func waitButtonPress() {
#if os(Linux)
    while HIGH == digitalRead(btnPin) {
        delay(300)
    }
#else
    _ = readLine()
#endif
}


func waitButtonRelease() {
#if os(Linux)
    while LOW == digitalRead(btnPin) {
        delay(300)
    }
#else
    _ = readLine()
#endif
}

func conversation(for data: Data) async throws -> Data {
    let aQuery = AudioTranscriptionQuery(
        file: data,
        fileType: .wav,
        model: config.asr.model,
        responseFormat: .json
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

// Main Loop
while(true) {
    logger.info("waiting for serve")
    do {
        waitButtonPress()
        logger.info("button pressed")

        let capturer = AudioCapturer()
        try capturer.initAudioCaptureDevice(EncodingFormat.wav, AudioFormat.s16, 1, 16000)
        try capturer.startAudioCapturing()
        
        waitButtonRelease()
        logger.info("button released")

        capturer.closeAudioCaptureDevice()
        
        let input = capturer.getData()
        let output = try await conversation(for: input)
        
        let player = AudioPlayer()
        try player.initAudioPlaybackDevice(forPlay: output)
        try player.startAudioPlaying()
        sleep(player.getDuration())
        player.closeAudioPlaybackDevice()
    } catch {
        logger.error("chat conversation error: \(error)")
    }
}

