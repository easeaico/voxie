import Foundation
import OpenAI

class Conversation {
    let config: Config

    let asrClient: OpenAI
    let ttsClient: OpenAI
    let llmClient: OpenAI

    var messages: [ChatQuery.ChatCompletionMessageParam]

    init(config: Config) {
        self.config = config

        self.asrClient = OpenAI(configuration: 
            OpenAI.Configuration(token: config.asr.apiKey, host: config.asr.host, port: config.asr.port, scheme: config.asr.scheme))
        self.ttsClient = OpenAI(configuration: 
            OpenAI.Configuration(token: config.tts.apiKey, host: config.tts.host, port: config.tts.port, scheme: config.tts.scheme))
        self.llmClient = OpenAI(configuration: 
            OpenAI.Configuration(token: config.llm.apiKey, host: config.llm.host, port: config.llm.port, scheme: config.llm.scheme))

        self.messages = []
    }
    
    func doChatResp() async throws {
        let query = ChatQuery(
            messages: self.messages,
            model: self.config.llm.model
        )
        
        var content = ""
        var paragraph = ""
        for try await result in self.llmClient.chatsStream(query: query) {
            guard let current = result.choices[0].delta.content else {
                continue
            }
            
            paragraph.append(current)
            content.append(current)
            
            let lines = paragraph.split(separator: "\n")
            let count = lines.count
            if count <= 1 {
                continue
            }
            
            for i in 0...(count-2){
                let sQuery = AudioSpeechQuery(
                    model: self.config.tts.model,
                    input: String(lines[i]),
                    voice: .alloy,
                    responseFormat: .mp3,
                    speed: 1.0
                )
                let ttsResult = try await self.ttsClient.audioCreateSpeech(query: sQuery)
                log.info("tts result, data size: \(ttsResult.audio.count)")
                
                let player = try startPlayback(for: ttsResult.audio)
                sleep(player.getDuration())
                endPlayback(for: player)
            }
            paragraph = String(lines[count - 1])
        }
        
        if !paragraph.isEmpty {
            let sQuery = AudioSpeechQuery(
                model: self.config.tts.model,
                input: paragraph,
                voice: .alloy,
                responseFormat: .mp3,
                speed: 1.0
            )
            let ttsResult = try await self.ttsClient.audioCreateSpeech(query: sQuery)
            log.info("tts result, data size: \(ttsResult.audio.count)")
            
            let player = try startPlayback(for: ttsResult.audio)
            sleep(player.getDuration())
            endPlayback(for: player)
        }
        
        let assistantMsg = ChatQuery.ChatCompletionMessageParam(role: .assistant, content: content)
        self.messages.append(assistantMsg!)
    }

    func bootstrap() async throws {
        let systemMsg = ChatQuery.ChatCompletionMessageParam(role: .system, content: self.config.prompts.system)
        let userMsg = ChatQuery.ChatCompletionMessageParam(role: .system, content: self.config.prompts.first)
        self.messages.append(systemMsg!)
        self.messages.append(userMsg!)
        
        try await self.doChatResp()
    }

    func chat(for data: Data) async throws {
        let aQuery = AudioTranscriptionQuery(
            file: data,
            fileType: .wav,
            model: self.config.asr.model,
            responseFormat: .json
        )
        log.info("audio transcription query: \(aQuery)")
        let asrResult = try await self.asrClient.audioTranscriptions(query: aQuery)
        log.info("audio transcription result: \(asrResult)")
    
        let userMsg = ChatQuery.ChatCompletionMessageParam(role: .user, content: asrResult.text)
        self.messages.append(userMsg!)

        try await self.doChatResp()
    }
}
