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
    let fileManager = FileManager.default
    let currentDirectoryURL = fileManager.currentDirectoryPath
    let configFileURL = currentDirectoryURL.appendingPathComponent("Config.toml")
    log.info("config file url: \(configFileURL)")

    do {
        let fileContent = try String(contentsOfFile: configFileURL, encoding: .utf8)
        let config = try TOMLDecoder().decode(Config.self, from: fileContent)
        return config
    } catch {
        log.error("error while reading config file: \(error.localizedDescription)")
        exit(-1)
    }
}
