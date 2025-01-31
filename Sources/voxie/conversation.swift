import Foundation
import OpenAI
import MiniAudio

class Conversation {
    let config: Config

    let asrClient: OpenAI
    let ttsClient: OpenAI
    let llmClient: OpenAI

    var messages: [ChatQuery.ChatCompletionMessageParam]
    
    init(config: Config) {
        self.config = config

        self.asrClient = OpenAI(configuration: 
            OpenAI.Configuration(token: config.asr.apiKey, host: config.asr.host, port: config.asr.port, scheme: config.asr.scheme, timeoutInterval: 120))
        self.ttsClient = OpenAI(configuration:
            OpenAI.Configuration(token: config.tts.apiKey, host: config.tts.host, port: config.tts.port, scheme: config.tts.scheme, timeoutInterval: 120))
        self.llmClient = OpenAI(configuration: 
            OpenAI.Configuration(token: config.llm.apiKey, host: config.llm.host, port: config.llm.port, scheme: config.llm.scheme, timeoutInterval: 120))

        self.messages = []
    }
    
    func speechRequest(for input: String) async throws -> Data {
        let sQuery = AudioSpeechQuery(
            model: self.config.tts.model,
            input: input,
            voice: .alloy,
            responseFormat: .mp3,
            speed: 1.0
        )
        let ttsResult = try await self.ttsClient.audioCreateSpeech(query: sQuery)
        return ttsResult.audio
    }
    
    func doChatResp(_ player: AudioPlayActor) async throws {
        let query = ChatQuery(
            messages: self.messages,
            model: self.config.llm.model
        )
        
        var content = ""
        var paragraph = ""
        
        self.logMessages(messages: query.messages)
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
                let audio = try await speechRequest(for: String(lines[i]))
                await player.addAudio(data: audio)
            }
            paragraph = String(lines[count - 1])
        }
        
        if !paragraph.isEmpty {
            let audio = try await speechRequest(for: paragraph)
            await player.addAudio(data: audio)
        }
        await player.overData()
        
        log.info("chat stream resp content: \(content)")
        let assistantMsg = ChatQuery.ChatCompletionMessageParam(role: .assistant, content: content)
        self.messages.append(assistantMsg!)
    }

    func bootstrap() async throws {
        let systemMsg = ChatQuery.ChatCompletionMessageParam(role: .system, content: self.config.prompts.system)
        let userMsg = ChatQuery.ChatCompletionMessageParam(role: .system, content: self.config.prompts.first)
        self.messages.append(systemMsg!)
        self.messages.append(userMsg!)
        
        try await self.doChatResp(AudioPlayActor())
    }

    func chat(for data: Data, _ player: AudioPlayActor) async throws {
        let aQuery = AudioTranscriptionQuery(
            file: data,
            fileType: .wav,
            model: self.config.asr.model,
            responseFormat: .json
        )
        let asrResult = try await self.asrClient.audioTranscriptions(query: aQuery)
        log.info("audio transcription result: \(asrResult)")
        if asrResult.text.isEmpty {
            return
        }
    
        let userMsg = ChatQuery.ChatCompletionMessageParam(role: .user, content: asrResult.text)
        self.messages.append(userMsg!)

        try await self.doChatResp(player)
    }
    
    private func logMessages(messages: [ChatQuery.ChatCompletionMessageParam]){
        log.info("chat context: \n")
        for msg in messages {
            log.info("\(msg.role): \(msg.content!.string!)\n\n")
        }
    }
}
