import MiniAudio
import Foundation

actor AudioCaptureActor {
    enum CaptureState {
        case inited
        case started
        case stopped
    }
    
    enum CaptureError : Error {
        case notFinish
    }
    
    private let capturer: AudioCapturer
    private var state: CaptureState
    
    init() {
        self.capturer = AudioCapturer()
        self.state = .inited
    }
    
    func startCapture() throws {
        try self.capturer.initCaptureDevice(EncodingFormat.wav, AudioFormat.s16, 1, 16000)
        try self.capturer.startAudioCapturing()
        self.state = .started
    }
    
    func stopCapture() {
        self.capturer.closeCaptureDevice()
        self.state = .stopped
    }
    
    func getData() throws -> Data {
        if self.state == .stopped {
            return self.capturer.getData()
        }
        
        throw CaptureError.notFinish
    }
}

actor AudioPlayActor {
    enum PlayState {
        case inited
        case playing
        case played
        case cancelled
        case done
    }
    
    private var datas: [Data]
    private let player: AudioPlayer
    private var state: PlayState

    init() {
        self.player = AudioPlayer()
        self.datas = [Data]()
        self.state = .inited
        
        Task {
            while true {
                let state = await self.state
                if state == .cancelled || state == .done {
                    break
                }
                
                if await hasNext() {
                    try await playNext()
                } else {
                    try await Task.sleep(nanoseconds: 200 * 1_000)
                }
            }
            
            let state = await self.state
            if state == .done {
                while await hasNext() {
                    try await playNext()
                }
            }
            
            await closePlayback()
        }
    }
    
    private func closePlayback() {
        self.state = .played
        self.player.closePlaybackDevice()
    }
    
    private func playNext() throws {
        if self.state == .inited {
            self.state = .playing
        }
        
        let data = self.datas.removeFirst()
        try player.initDeviceOrUpdate(for: data)
        try player.startAudioPlaying()
        sleep(player.getDuration())
        try player.stopAudioPlaying()
    }
    
    func addAudio(data d: Data){
        self.datas.append(d)
    }
    
    func hasNext() -> Bool {
        return !self.datas.isEmpty
    }
    
    func cancel() throws {
        try player.stopAudioPlaying()
        self.state = .cancelled
    }
    
    func done() {
        self.state = .done
    }
    
    func isPlayed() -> Bool {
        return self.state == .played
    }
}
