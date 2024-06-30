#if os(Linux)
import wiringPi
#endif

class PullUpButton {
    let TimerInterval: UInt32 = 300
    let btnPin: Int32

    init(for btnPin: Int32) {
        self.btnPin = btnPin
    }

    func untilPress() {
    #if os(Linux)
        while HIGH == digitalRead(self.btnPin) {
            delay(TimerInterval)
        }
    #else
        _ = readLine()
    #endif
    }


    func untilRelease() {
    #if os(Linux)
        while LOW == digitalRead(self.btnPin) {
            delay(TimerInterval)
        }
    #else
        _ = readLine()
    #endif
    }


    func untilClick(timeout ms: UInt64) {
    #if os(Linux)
        var time = ms

        while HIGH == digitalRead(self.btnPin) {
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

        while LOW == digitalRead(self.btnPin) {
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
}

class GPIO {

    init() {
    #if os(Linux)
        wiringPiSetupGpio();
    #endif
    }

    func setupPullUpButton(for pin: Int32) -> PullUpButton {
    #if os(Linux)
        pinMode(pin, INPUT);
        pullUpDnControl(pin, PUD_UP);
    #endif
        return PullUpButton(for: pin)
    }
}



