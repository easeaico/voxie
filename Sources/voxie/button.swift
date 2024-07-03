#if os(Linux)
import wiringPi
#endif

class PullUpButton {
    let TimerInterval: UInt32 = 300
    let btnPin: Int32

    init(for btnPin: Int32) {
        self.btnPin = btnPin
#if os(Linux)
        pinMode(self.btnPin, INPUT);
        pullUpDnControl(self.btnPin, PUD_UP);
#endif
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

    func isClick() -> Bool {
    #if os(Linux)
        if LOW == digitalRead(self.btnPin) {
            delay(TimerInterval)
            if HIGH == digitalRead(self.btnPin) {
                return true
            }
        }
        
        delay(TimerInterval)
        return false
    #else
        return false
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
        return PullUpButton(for: pin)
    }
}



