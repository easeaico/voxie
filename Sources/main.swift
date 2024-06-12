import CoreAudio
import Raylib

Raylib.initAudioDevice()
let s = Raylib.loadSound("dune.wav")
Raylib.playSound(s)
while Raylib.isSoundPlaying(s) {
    // nothing to do
}
Raylib.unloadSound(s)
Raylib.closeAudioDevice()
