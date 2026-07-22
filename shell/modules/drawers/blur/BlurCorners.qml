import QtQuick
import Quickshell

Region {
    required property real inLeft
    required property real inRight
    required property real inTop
    required property real inBottom
    required property real rTop
    required property real rBottom

    // Top-Left Corner (each strip extends to inTop — zero junction gap)
    Region { x: inLeft - rTop*0.9987; y: inTop - rTop*0.0500; width: rTop*0.9987; height: rTop*0.0500 }
    Region { x: inLeft - rTop*0.9950; y: inTop - rTop*0.1000; width: rTop*0.9950; height: rTop*0.1000 }
    Region { x: inLeft - rTop*0.9887; y: inTop - rTop*0.1500; width: rTop*0.9887; height: rTop*0.1500 }
    Region { x: inLeft - rTop*0.9798; y: inTop - rTop*0.2000; width: rTop*0.9798; height: rTop*0.2000 }
    Region { x: inLeft - rTop*0.9682; y: inTop - rTop*0.2500; width: rTop*0.9682; height: rTop*0.2500 }
    Region { x: inLeft - rTop*0.9539; y: inTop - rTop*0.3000; width: rTop*0.9539; height: rTop*0.3000 }
    Region { x: inLeft - rTop*0.9367; y: inTop - rTop*0.3500; width: rTop*0.9367; height: rTop*0.3500 }
    Region { x: inLeft - rTop*0.9165; y: inTop - rTop*0.4000; width: rTop*0.9165; height: rTop*0.4000 }
    Region { x: inLeft - rTop*0.8930; y: inTop - rTop*0.4500; width: rTop*0.8930; height: rTop*0.4500 }
    Region { x: inLeft - rTop*0.8660; y: inTop - rTop*0.5000; width: rTop*0.8660; height: rTop*0.5000 }
    Region { x: inLeft - rTop*0.8352; y: inTop - rTop*0.5500; width: rTop*0.8352; height: rTop*0.5500 }
    Region { x: inLeft - rTop*0.8000; y: inTop - rTop*0.6000; width: rTop*0.8000; height: rTop*0.6000 }
    Region { x: inLeft - rTop*0.7599; y: inTop - rTop*0.6500; width: rTop*0.7599; height: rTop*0.6500 }
    Region { x: inLeft - rTop*0.7141; y: inTop - rTop*0.7000; width: rTop*0.7141; height: rTop*0.7000 }
    Region { x: inLeft - rTop*0.6614; y: inTop - rTop*0.7500; width: rTop*0.6614; height: rTop*0.7500 }
    Region { x: inLeft - rTop*0.6000; y: inTop - rTop*0.8000; width: rTop*0.6000; height: rTop*0.8000 }
    Region { x: inLeft - rTop*0.5268; y: inTop - rTop*0.8500; width: rTop*0.5268; height: rTop*0.8500 }
    Region { x: inLeft - rTop*0.4359; y: inTop - rTop*0.9000; width: rTop*0.4359; height: rTop*0.9000 }
    Region { x: inLeft - rTop*0.3122; y: inTop - rTop*0.9500; width: rTop*0.3122; height: rTop*0.9500 }
    // Top-Right Corner (each strip extends to inTop — zero junction gap)
    Region { x: inRight; y: inTop - rTop*0.0500; width: rTop*0.9987; height: rTop*0.0500 }
    Region { x: inRight; y: inTop - rTop*0.1000; width: rTop*0.9950; height: rTop*0.1000 }
    Region { x: inRight; y: inTop - rTop*0.1500; width: rTop*0.9887; height: rTop*0.1500 }
    Region { x: inRight; y: inTop - rTop*0.2000; width: rTop*0.9798; height: rTop*0.2000 }
    Region { x: inRight; y: inTop - rTop*0.2500; width: rTop*0.9682; height: rTop*0.2500 }
    Region { x: inRight; y: inTop - rTop*0.3000; width: rTop*0.9539; height: rTop*0.3000 }
    Region { x: inRight; y: inTop - rTop*0.3500; width: rTop*0.9367; height: rTop*0.3500 }
    Region { x: inRight; y: inTop - rTop*0.4000; width: rTop*0.9165; height: rTop*0.4000 }
    Region { x: inRight; y: inTop - rTop*0.4500; width: rTop*0.8930; height: rTop*0.4500 }
    Region { x: inRight; y: inTop - rTop*0.5000; width: rTop*0.8660; height: rTop*0.5000 }
    Region { x: inRight; y: inTop - rTop*0.5500; width: rTop*0.8352; height: rTop*0.5500 }
    Region { x: inRight; y: inTop - rTop*0.6000; width: rTop*0.8000; height: rTop*0.6000 }
    Region { x: inRight; y: inTop - rTop*0.6500; width: rTop*0.7599; height: rTop*0.6500 }
    Region { x: inRight; y: inTop - rTop*0.7000; width: rTop*0.7141; height: rTop*0.7000 }
    Region { x: inRight; y: inTop - rTop*0.7500; width: rTop*0.6614; height: rTop*0.7500 }
    Region { x: inRight; y: inTop - rTop*0.8000; width: rTop*0.6000; height: rTop*0.8000 }
    Region { x: inRight; y: inTop - rTop*0.8500; width: rTop*0.5268; height: rTop*0.8500 }
    Region { x: inRight; y: inTop - rTop*0.9000; width: rTop*0.4359; height: rTop*0.9000 }
    Region { x: inRight; y: inTop - rTop*0.9500; width: rTop*0.3122; height: rTop*0.9500 }
    // Bottom-Left Corner (each strip extends from inBottom — zero junction gap)
    Region { x: inLeft - rBottom*0.9987; y: inBottom; width: rBottom*0.9987; height: rBottom*0.0500 }
    Region { x: inLeft - rBottom*0.9950; y: inBottom; width: rBottom*0.9950; height: rBottom*0.1000 }
    Region { x: inLeft - rBottom*0.9887; y: inBottom; width: rBottom*0.9887; height: rBottom*0.1500 }
    Region { x: inLeft - rBottom*0.9798; y: inBottom; width: rBottom*0.9798; height: rBottom*0.2000 }
    Region { x: inLeft - rBottom*0.9682; y: inBottom; width: rBottom*0.9682; height: rBottom*0.2500 }
    Region { x: inLeft - rBottom*0.9539; y: inBottom; width: rBottom*0.9539; height: rBottom*0.3000 }
    Region { x: inLeft - rBottom*0.9367; y: inBottom; width: rBottom*0.9367; height: rBottom*0.3500 }
    Region { x: inLeft - rBottom*0.9165; y: inBottom; width: rBottom*0.9165; height: rBottom*0.4000 }
    Region { x: inLeft - rBottom*0.8930; y: inBottom; width: rBottom*0.8930; height: rBottom*0.4500 }
    Region { x: inLeft - rBottom*0.8660; y: inBottom; width: rBottom*0.8660; height: rBottom*0.5000 }
    Region { x: inLeft - rBottom*0.8352; y: inBottom; width: rBottom*0.8352; height: rBottom*0.5500 }
    Region { x: inLeft - rBottom*0.8000; y: inBottom; width: rBottom*0.8000; height: rBottom*0.6000 }
    Region { x: inLeft - rBottom*0.7599; y: inBottom; width: rBottom*0.7599; height: rBottom*0.6500 }
    Region { x: inLeft - rBottom*0.7141; y: inBottom; width: rBottom*0.7141; height: rBottom*0.7000 }
    Region { x: inLeft - rBottom*0.6614; y: inBottom; width: rBottom*0.6614; height: rBottom*0.7500 }
    Region { x: inLeft - rBottom*0.6000; y: inBottom; width: rBottom*0.6000; height: rBottom*0.8000 }
    Region { x: inLeft - rBottom*0.5268; y: inBottom; width: rBottom*0.5268; height: rBottom*0.8500 }
    Region { x: inLeft - rBottom*0.4359; y: inBottom; width: rBottom*0.4359; height: rBottom*0.9000 }
    Region { x: inLeft - rBottom*0.3122; y: inBottom; width: rBottom*0.3122; height: rBottom*0.9500 }
    // Bottom-Right Corner (each strip extends from inBottom — zero junction gap)
    Region { x: inRight; y: inBottom; width: rBottom*0.9987; height: rBottom*0.0500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.9950; height: rBottom*0.1000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.9887; height: rBottom*0.1500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.9798; height: rBottom*0.2000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.9682; height: rBottom*0.2500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.9539; height: rBottom*0.3000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.9367; height: rBottom*0.3500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.9165; height: rBottom*0.4000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.8930; height: rBottom*0.4500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.8660; height: rBottom*0.5000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.8352; height: rBottom*0.5500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.8000; height: rBottom*0.6000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.7599; height: rBottom*0.6500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.7141; height: rBottom*0.7000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.6614; height: rBottom*0.7500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.6000; height: rBottom*0.8000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.5268; height: rBottom*0.8500 }
    Region { x: inRight; y: inBottom; width: rBottom*0.4359; height: rBottom*0.9000 }
    Region { x: inRight; y: inBottom; width: rBottom*0.3122; height: rBottom*0.9500 }
}
