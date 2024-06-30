#if os(Linux)
import wiringPi
#endif

let TimerInterval: UInt32 = 300
var btnPin: Int32 = 0

func setupDevice(for pin: Int32) {
#if os(Linux)
    wiringPiSetupGpio();
    pinMode(pin, INPUT);
    pullUpDnControl(pin, PUD_UP);
    btnPin = pin
#endif
}


func waitButtonPress() {
#if os(Linux)
    while HIGH == digitalRead(btnPin) {
        delay(TimerInterval)
    }
#else
    _ = readLine()
#endif
}


func waitButtonRelease() {
#if os(Linux)
    while LOW == digitalRead(btnPin) {
        delay(TimerInterval)
    }
#else
    _ = readLine()
#endif
}


func waitButtonClick(timeout ms: UInt64) {
#if os(Linux)
    var time = ms

    while HIGH == digitalRead(btnPin) {
        delay(TimerInterval)
        time -= UInt64(TimerInterval)
        if time <= 0 {
            return
        }
    }

    delay(TimerInterval)
    time -= UInt64(TimerInterval)
    if time <= 0 {
        return
    }

    while LOW == digitalRead(btnPin) {
        delay(TimerInterval)
        time -= UInt64(TimerInterval)
        if time <= 0 {
            return
        }
    }
#else
    _ = readLine()
#endif
}
