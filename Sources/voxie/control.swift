#if os(Linux)
import wiringPi
#endif

let TimerInterval = 300
var btnPin = 0

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
    if HIGH == digitalRead(btnPin) {
        delay(TimerInterval)
        waitButtonPress()
    }
#else
    _ = readLine()
#endif
}


func waitButtonRelease() {
#if os(Linux)
    if LOW == digitalRead(btnPin) {
        delay(TimerInterval)
        waitButtonRelease()
    }
#else
    _ = readLine()
#endif
}


func waitButtonClick(timeout ms: UInt64) {
#if os(Linux)
    if HIGH == digitalRead(btnPin) {
        delay(TimerInterval)
        ms -= TimerInterval
        if ms <= 0 {
            return
        }

        waitButtonClick(timeout: ms)
    } else {
        delay(TimerInterval)
        ms -= TimerInterval
        if ms <= 0 || HIGH == digitalRead(btnPin) {
            return
        }

        waitButtonClick(timeout: ms)
    }

#else
    _ = readLine()
#endif
}
