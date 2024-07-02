import MiniAudio
import Foundation

func startCapture() throws -> AudioCapturer {
    let capturer = AudioCapturer()
    try capturer.initCaptureDevice(EncodingFormat.wav, AudioFormat.s16, 1, 16000)
    try capturer.startAudioCapturing()

    return capturer
}

func endCapture(for capturer: AudioCapturer) -> Data {
    capturer.closeCaptureDevice()
    return capturer.getData()
}

func playData(for player: AudioPlayer, _ data: Data) throws {
    try player.initDeviceOrUpdate(for: data)
    try player.startAudioPlaying()
    sleep(player.getDuration())
    try player.stopAudioPlaying()
}

actor AudioPlayActor {
    private var datas: [Data]
    private var isDone: Bool
    private let player: AudioPlayer

    init() {
        self.player = AudioPlayer()
        self.datas = [Data]()
        self.isDone = false
        
        Task {
            while true {
                if await self.isDone {
                    break
                }
                
                if await hasNext() {
                    try playData(for: player, await nextAudio())
                } else {
                    try await Task.sleep(nanoseconds: 200 * 1_000)
                }
            }
            
            while await hasNext() {
                try playData(for: player, await nextAudio())
            }
            
            player.closePlaybackDevice()
        }
    }
    
    func addAudio(data d: Data){
        self.datas.append(d)
    }
    
    func hasNext() -> Bool {
        return !self.datas.isEmpty
    }
    
    func nextAudio() -> Data {
        return self.datas.removeFirst()
    }
    
    func done() {
        self.isDone = true
    }
}
