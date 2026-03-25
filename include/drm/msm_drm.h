#ifndef _MSM_DRM_H_
#define _MSM_DRM_H_
#include <linux/types.h>
#include <linux/ioctl.h>

struct drm_msm_event_req { __u32 object_id; __u32 object_type; __u32 event; };
struct drm_msm_event_resp { struct { __u32 type; __u32 length; } base; __u8 data[]; };

#define DRM_EVENT_PANEL_DEAD 0x1
#define DRM_EVENT_CRTC_POWER 0x2
#define DRM_EVENT_HISTOGRAM  0x3
#define DRM_EVENT_SDE_POWER  0x4

#define DRM_MODE_FLAG_CMD_MODE_PANEL 0x100
#define DRM_MODE_FLAG_VID_MODE_PANEL 0x200

#define DRM_IOCTL_MSM_REGISTER_EVENT   _IOWR('d', 0x41, struct drm_msm_event_req)
#define DRM_IOCTL_MSM_DEREGISTER_EVENT _IOWR('d', 0x42, struct drm_msm_event_req)
#endif
