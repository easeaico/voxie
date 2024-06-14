import Raylib
import OpenAI
import Foundation

struct Config: Codable {
    let host: String
    let apiKey: String
}

let configUrl = Bundle.module.url(forResource: "Config", withExtension: "plist")!
let configData = try! Data(contentsOf: configUrl)
let decoder = PropertyListDecoder()
let config = try! decoder.decode(Config.self, from: configData)

let configuration = OpenAI.Configuration(token: config.apiKey, host: config.host)
let openAI = OpenAI(configuration: configuration)
let query = ChatQuery(
    messages: [.init(role: .user, content: "who are you")!], 
    model: .gpt3_5Turbo
)
openAI.chats(query: query) { result in
    switch result {
    case .success(let chatResult):
        print("Publisher Success \(chatResult.choices[0].message.content!)")
    case .failure(let error):
        print("Publisher error: \(error)")
    }
}

Thread.sleep(forTimeInterval: 10)

Raylib.initAudioDevice()
let s = Raylib.loadSound("dune.wav")
Raylib.playSound(s)
while Raylib.isSoundPlaying(s) {
    // nothing to do
}
Raylib.unloadSound(s)
Raylib.closeAudioDevice()
