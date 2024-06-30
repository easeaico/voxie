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

    func bootstrap() async throws -> Data {
        let systemMsg = ChatQuery.ChatCompletionMessageParam(role: .system, content: self.config.prompts.system)
        let userMsg = ChatQuery.ChatCompletionMessageParam(role: .system, content: self.config.prompts.first)
        self.messages.append(systemMsg!)
        self.messages.append(userMsg!)

        let cQuery = ChatQuery(
            messages: self.messages,
            model: self.config.llm.model
        )
        let chatResult = try await self.llmClient.chats(query: cQuery)
        let assistantMsg = chatResult.choices[0].message
        self.messages.append(assistantMsg)

        let content = assistantMsg.content!.string!
        log.info("ai chat result: \(content)")
        
        let sQuery = AudioSpeechQuery(
            model: self.config.tts.model,
            input: content,
            voice: .alloy,
            responseFormat: .mp3,
            speed: 1.0
        )
        let ttsResult = try await self.ttsClient.audioCreateSpeech(query: sQuery)
        log.info("tts result, data size: \(ttsResult.audio.count)")
        return ttsResult.audio
    }

    func chat(for data: Data) async throws -> Data {
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

        let cQuery = ChatQuery(
            messages: self.messages,
            model: self.config.llm.model
        )
        let chatResult = try await self.llmClient.chats(query: cQuery)
        let assistantMsg = chatResult.choices[0].message
        self.messages.append(assistantMsg)

        let content = assistantMsg.content!.string!
        log.info("ai chat result: \(content)")
        
        let sQuery = AudioSpeechQuery(
            model: self.config.tts.model,
            input: content,
            voice: .alloy,
            responseFormat: .mp3,
            speed: 1.0
        )
        let ttsResult = try await self.ttsClient.audioCreateSpeech(query: sQuery)
        log.info("tts result, data size: \(ttsResult.audio.count)")
        return ttsResult.audio
    }
}
