#!/vendor/bin/sh
# The dwc3 controller can miss the cable attach at boot and stay
# "not attached" until a replug. Cycling its mode re-runs the attach.
udc=/sys/class/udc/a600000.dwc3/state
mode=/sys/devices/platform/soc/a600000.ssusb/mode

for i in 1 2 3 4 5 6; do
    sleep 10
    [ "$(cat $udc)" = configured ] && exit 0
    echo none > $mode
    sleep 2
    echo peripheral > $mode
done
