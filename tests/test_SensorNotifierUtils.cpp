#include <gtest/gtest.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

#include "../sensors/include/SensorNotifierUtils.h"

class SensorNotifierUtilsTest : public ::testing::Test {
protected:
    int createTempFile(const char* content, size_t len) {
        char temp_file[] = "/tmp/sensor_test_XXXXXX";
        int fd = mkstemp(temp_file);
        if (fd >= 0) {
            write(fd, content, len);
            unlink(temp_file); // Ensure file is deleted when closed
        }
        return fd;
    }
};

TEST_F(SensorNotifierUtilsTest, ReadBoolTrue) {
    int fd = createTempFile("1", 1);
    ASSERT_GE(fd, 0);
    EXPECT_TRUE(readBool(fd));
    close(fd);
}

TEST_F(SensorNotifierUtilsTest, ReadBoolFalse) {
    int fd = createTempFile("0", 1);
    ASSERT_GE(fd, 0);
    EXPECT_FALSE(readBool(fd));
    close(fd);
}

TEST_F(SensorNotifierUtilsTest, ReadBoolInvalidFd) {
    EXPECT_FALSE(readBool(-1));
}

TEST_F(SensorNotifierUtilsTest, ReadBoolEmptyFile) {
    int fd = createTempFile("", 0);
    ASSERT_GE(fd, 0);
    EXPECT_FALSE(readBool(fd));
    close(fd);
}

TEST_F(SensorNotifierUtilsTest, ReadBoolOtherChar) {
    int fd = createTempFile("2", 1);
    ASSERT_GE(fd, 0);
    EXPECT_TRUE(readBool(fd));
    close(fd);
}

TEST_F(SensorNotifierUtilsTest, ReadBoolMultipleChars) {
    int fd = createTempFile("10", 2);
    ASSERT_GE(fd, 0);
    EXPECT_TRUE(readBool(fd));
    close(fd);
}
