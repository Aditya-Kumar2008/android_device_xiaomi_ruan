#pragma once
#include <string>
#include <cstdint>

namespace android {
    namespace hardware {
        namespace sensors {
            namespace V1_0 {
                struct SensorFlagBits {
                    static constexpr uint32_t WAKE_UP = 1;
                };

                struct SensorInfo {
                    std::string typeAsString;
                    uint32_t vendor;
                    uint32_t version;
                    int32_t sensorHandle;
                    uint32_t type;
                    float maxRange;
                    float resolution;
                    float power;
                    int32_t minDelay;
                    uint32_t fifoReservedEventCount;
                    uint32_t fifoMaxEventCount;
                    std::string requiredPermission;
                    int32_t maxDelay;
                    uint32_t flags;
                };
            }
        }
    }
}
