import MiniAudio
import Foundation

func startCapture() throws -> AudioCapturer {
    let capturer = AudioCapturer()
    try capturer.initAudioCaptureDevice(EncodingFormat.wav, AudioFormat.s16, 1, 16000)
    try capturer.startAudioCapturing()

    return capturer
}

func endCapture(for capturer: AudioCapturer) -> Data {
    capturer.closeAudioCaptureDevice()
    return capturer.getData()
}

func startPlayback(for data: Data) throws -> AudioPlayer {
    let player = AudioPlayer()
    try player.initAudioPlaybackDevice(forPlay: data)
    try player.startAudioPlaying()
    return player
}

func endPlayback(for player: AudioPlayer) {
    player.closeAudioPlaybackDevice()
}
