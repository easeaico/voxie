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
    }
    
    private var datas: [Data]
    private let player: AudioPlayer
    private var state: PlayState
    private var over: Bool

    init() {
        self.player = AudioPlayer()
        self.datas = [Data]()
        self.state = .inited
        self.over = false
        
        Task {
            while true {
                let state = await self.state
                switch state {
                    case .inited:
                        if await hasNext() {
                            try await playNext()
                        }
                        await self.setState(.playing)
                    case .playing:
                        if await hasNext() {
                            try await playNext()
                        } else if await isOver() {
                            await self.setState(.played)
                        }
                    case .cancelled, .played:
                        self.player.closePlaybackDevice()
                        // break task loop
                        break
                }
            
                try await Task.sleep(nanoseconds: 200 * 1_000)
            }
        }
    }
    
    private func setState(_ state: PlayState) {
        self.state = state
    }
    
    private func isOver() -> Bool {
        return self.over
    }

    private func hasNext() -> Bool {
        return !self.datas.isEmpty
    }

    private func playNext() throws {
        let data = self.datas.removeFirst()
        try player.initDeviceOrUpdate(for: data)
        try player.startAudioPlaying()
        sleep(player.getDuration())
        try player.stopAudioPlaying()
    }
    
    func addAudio(data d: Data){
        self.datas.append(d)
    }
    
    func cancel() throws {
        if state == .inited || state == .playing {
            self.state = .cancelled
            // stop current playing
            try player.stopAudioPlaying()
        }
    }
    
    func overData() {
        self.over = true
    }
    
    func isPlaying() -> Bool {
        let state = self.state
        return state != .played && state != .cancelled
    }
}
