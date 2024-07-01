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

func blockPlayback(for data: Data, _ player: AudioPlayer) throws {
    try player.initDeviceOrUpdate(for: data)
    try player.startAudioPlaying()
    sleep(player.getDuration())
    try player.stopAudioPlaying()
}
