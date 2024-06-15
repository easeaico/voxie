import Raylib
import OpenAI

import TOMLKit
import Foundation

struct Config: Codable {
    let asr: ASR
    let tts: TTS
    let llm: LLM

    struct LLM: Codable {
        let scheme: String
        let host: String
        let port: Int
        let apiKey: String
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

let configFile = Bundle.module.url(forResource: "Config", withExtension: "toml")!
let configData = try String(contentsOf: configFile, encoding: .utf8)
let config = try TOMLDecoder().decode(Config.self, from: configData)


let asrConfig = OpenAI.Configuration(token: config.asr.apiKey, host: config.asr.host, port: config.asr.port, scheme: config.asr.scheme)
let asrClient = OpenAI(configuration: asrConfig)

let ttsConfig = OpenAI.Configuration(token: config.tts.apiKey, host: config.tts.host, port: config.tts.port, scheme: config.tts.scheme)
let ttsClient = OpenAI(configuration: ttsConfig)

let llmConfig = OpenAI.Configuration(token: config.llm.apiKey, host: config.llm.host, port: config.llm.port, scheme: config.llm.scheme)
let llmClient = OpenAI(configuration: llmConfig)

func conversation() async throws {
    let inputFile = Bundle.module.url(forResource: "dune", withExtension: "wav")!
    let data = try Data(contentsOf:inputFile)
    let aQuery = AudioTranscriptionQuery(
        file: data,
        fileType: .wav,
        model: .whisper_1
    )
    let asrResult = try await asrClient.audioTranscriptions(query: aQuery)
    print(asrResult.text)

    let cQuery = ChatQuery(
        messages: [.init(role: .user, content: asrResult.text)!],
        model: .gpt3_5Turbo
    )
    let chatResult = try await llmClient.chats(query: cQuery)
    let content = chatResult.choices[0].message.content!.string!
    print(content)
    
    let sQuery = AudioSpeechQuery(
        model: .tts_1,
        input: content,
        voice: .alloy,
        responseFormat: .mp3, 
        speed: 1.0
    )
    let ttsResult = try await ttsClient.audioCreateSpeech(query: sQuery)
    var audioBuffer: [UInt8] = []
    ttsResult.audio.withUnsafeBytes{ audioBuffer.append(contentsOf: $0) }


    let sound = Raylib.loadSoundFromWave(Raylib.LoadWaveFromMemory(".wav", audioBuffer, Int32(audioBuffer.count)))
    Raylib.playSound(sound)
    while Raylib.isSoundPlaying(sound) {
        // nothing to do
    }
    Raylib.unloadSound(sound)
}


Raylib.initAudioDevice()
try await conversation()
print("Press enter to exit...")
while true {
    if let input = readLine() {
        if input.isEmpty {
            break
        }
    }
}
Raylib.closeAudioDevice()
