#include <iostream>
#include <vector>
#include <memory>
#include <cassert>

#include "SensorNotifier.h"

// Mock IEventQueue
class MockEventQueue : public android::frameworks::sensorservice::V1_0::IEventQueue {
public:
    int32_t disabledSensorHandle = -1;
    void disableSensor(int32_t sensorHandle) override {
        disabledSensorHandle = sensorHandle;
    }
};

class MockEventQueueCallback : public android::frameworks::sensorservice::V1_0::IEventQueueCallback {
};

// Mock ISensorManager
class MockSensorManager : public android::frameworks::sensorservice::V1_0::ISensorManager {
public:
    std::vector<android::hardware::sensors::V1_0::SensorInfo> mockedSensors;
    android::frameworks::sensorservice::V1_0::Result mockedGetSensorListResult = android::frameworks::sensorservice::V1_0::Result::OK;
    android::frameworks::sensorservice::V1_0::Result mockedCreateQueueResult = android::frameworks::sensorservice::V1_0::Result::OK;
    android::sp<MockEventQueue> mockedQueue;

    void getSensorList(std::function<void(const std::vector<android::hardware::sensors::V1_0::SensorInfo>&, android::frameworks::sensorservice::V1_0::Result)> cb) override {
        cb(mockedSensors, mockedGetSensorListResult);
    }

    void createEventQueue(android::sp<android::frameworks::sensorservice::V1_0::IEventQueueCallback> callback,
                          std::function<void(const android::sp<android::frameworks::sensorservice::V1_0::IEventQueue>&, android::frameworks::sensorservice::V1_0::Result)> cb) override {
        mockedQueue = android::sp<MockEventQueue>(std::make_shared<MockEventQueue>());
        android::sp<android::frameworks::sensorservice::V1_0::IEventQueue> q = mockedQueue;
        cb(q, mockedCreateQueueResult);
    }
};

// Test subclass to expose protected methods
class TestSensorNotifier : public SensorNotifier {
public:
    TestSensorNotifier(android::sp<android::frameworks::sensorservice::V1_0::ISensorManager> manager)
        : SensorNotifier(manager) {}

    void notify() override {}

    android::frameworks::sensorservice::V1_0::Result testInitialize(std::string type, bool wakeup, android::sp<android::frameworks::sensorservice::V1_0::IEventQueueCallback> callback) {
        return initializeSensorQueue(type, wakeup, callback);
    }

    int32_t getSensorHandle() const { return mSensorHandle; }
    android::sp<android::frameworks::sensorservice::V1_0::IEventQueue> getQueue() const { return mQueue; }
};

void testSuccess() {
    auto mockManager = std::make_shared<MockSensorManager>();
    android::sp<android::frameworks::sensorservice::V1_0::ISensorManager> manager(mockManager);
    android::hardware::sensors::V1_0::SensorInfo info;
    info.typeAsString = "test.sensor";
    info.flags = android::hardware::sensors::V1_0::SensorFlagBits::WAKE_UP;
    info.sensorHandle = 42;
    mockManager->mockedSensors.push_back(info);

    TestSensorNotifier notifier(manager);
    android::sp<android::frameworks::sensorservice::V1_0::IEventQueueCallback> callback(std::make_shared<MockEventQueueCallback>());
    auto res = notifier.testInitialize("test.sensor", true, callback);

    assert(res == android::frameworks::sensorservice::V1_0::Result::OK);
    assert(notifier.getSensorHandle() == 42);
    assert(notifier.getQueue() != nullptr);
    std::cout << "testSuccess passed\n";
}

void testSensorNotFound() {
    auto mockManager = std::make_shared<MockSensorManager>();
    android::sp<android::frameworks::sensorservice::V1_0::ISensorManager> manager(mockManager);
    android::hardware::sensors::V1_0::SensorInfo info;
    info.typeAsString = "other.sensor";
    info.flags = 0;
    info.sensorHandle = 42;
    mockManager->mockedSensors.push_back(info);

    TestSensorNotifier notifier(manager);
    android::sp<android::frameworks::sensorservice::V1_0::IEventQueueCallback> callback(std::make_shared<MockEventQueueCallback>());
    auto res = notifier.testInitialize("test.sensor", true, callback);

    assert(res == android::frameworks::sensorservice::V1_0::Result::NOT_EXIST);
    std::cout << "testSensorNotFound passed\n";
}

void testGetListFails() {
    auto mockManager = std::make_shared<MockSensorManager>();
    android::sp<android::frameworks::sensorservice::V1_0::ISensorManager> manager(mockManager);
    mockManager->mockedGetSensorListResult = android::frameworks::sensorservice::V1_0::Result::BAD_VALUE;

    TestSensorNotifier notifier(manager);
    android::sp<android::frameworks::sensorservice::V1_0::IEventQueueCallback> callback(std::make_shared<MockEventQueueCallback>());
    auto res = notifier.testInitialize("test.sensor", true, callback);

    assert(res == android::frameworks::sensorservice::V1_0::Result::BAD_VALUE);
    std::cout << "testGetListFails passed\n";
}

void testCreateQueueFails() {
    auto mockManager = std::make_shared<MockSensorManager>();
    android::sp<android::frameworks::sensorservice::V1_0::ISensorManager> manager(mockManager);
    android::hardware::sensors::V1_0::SensorInfo info;
    info.typeAsString = "test.sensor";
    info.flags = android::hardware::sensors::V1_0::SensorFlagBits::WAKE_UP;
    info.sensorHandle = 42;
    mockManager->mockedSensors.push_back(info);
    mockManager->mockedCreateQueueResult = android::frameworks::sensorservice::V1_0::Result::BAD_VALUE;

    TestSensorNotifier notifier(manager);
    android::sp<android::frameworks::sensorservice::V1_0::IEventQueueCallback> callback(std::make_shared<MockEventQueueCallback>());
    auto res = notifier.testInitialize("test.sensor", true, callback);

    assert(res == android::frameworks::sensorservice::V1_0::Result::BAD_VALUE);
    std::cout << "testCreateQueueFails passed\n";
}

int main() {
    testSuccess();
    testSensorNotFound();
    testGetListFails();
    testCreateQueueFails();
    std::cout << "All tests passed!\n";
    return 0;
}
