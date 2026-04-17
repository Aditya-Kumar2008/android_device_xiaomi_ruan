#pragma once
#include <string>
#include <vector>
#include <functional>
#include <memory>
#include "android/hardware/sensors/1.0/types.h"

namespace android {
    template<typename T>
    class sp {
    public:
        sp() : ptr(nullptr) {}
        sp(T* p) : ptr(p) {}
        sp(std::shared_ptr<T> p) : ptr(p) {}

        T* operator->() const { return ptr.get(); }
        T& operator*() const { return *ptr; }
        T* get() const { return ptr.get(); }

        operator bool() const { return ptr != nullptr; }
        bool operator==(std::nullptr_t) const { return ptr == nullptr; }
        bool operator!=(std::nullptr_t) const { return ptr != nullptr; }

        sp(const sp<T>& other) : ptr(other.ptr) {}
        sp<T>& operator=(const sp<T>& other) { ptr = other.ptr; return *this; }

        template<typename U>
        sp(const sp<U>& other) : ptr(std::dynamic_pointer_cast<T>(other.ptr)) {}

    private:
        template<typename U> friend class sp;
        std::shared_ptr<T> ptr;
    };

    namespace frameworks {
        namespace sensorservice {
            namespace V1_0 {
                enum class Result { OK, NOT_EXIST, BAD_VALUE };

                class IEventQueue {
                public:
                    virtual ~IEventQueue() = default;
                    virtual void disableSensor(int32_t sensorHandle) = 0;
                };

                class IEventQueueCallback {
                public:
                    virtual ~IEventQueueCallback() = default;
                };

                class ISensorManager {
                public:
                    virtual ~ISensorManager() = default;

                    virtual void getSensorList(std::function<void(const std::vector<android::hardware::sensors::V1_0::SensorInfo>&, Result)> cb) = 0;
                    virtual void createEventQueue(sp<IEventQueueCallback> callback,
                                                  std::function<void(const sp<IEventQueue>&, Result)> cb) = 0;
                };
            }
        }
    }
}
