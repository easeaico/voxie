import TOMLKit
import Foundation

struct Config: Codable {
    let asr: ASR
    let tts: TTS
    let llm: LLM
    let prompts: Prompts

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

    struct Prompts: Codable {
        let system: String
        let first: String
    }
}

func loadConfig() -> Config {
    let config: Config
    do {
        let path = Bundle.module.url(forResource: "Config", withExtension: "toml")
        let configData = try String(contentsOf: path!, encoding: .utf8)
        config = try TOMLDecoder().decode(Config.self, from: configData)
    }
    catch {
        log.error("read Config.toml error: \(error)")
        exit(-1)
    }

    return config
}
