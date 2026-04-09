#pragma once

struct touch_mode_request {
    int mode;
    int value;
};

#define TOUCH_MODE_NONUI_MODE 20
#define TOUCH_IOC_SET_CUR_VALUE 0
