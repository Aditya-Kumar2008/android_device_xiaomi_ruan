#ifndef _MSM_DRM_H_
#define _MSM_DRM_H_
#include <linux/types.h>
#include <linux/ioctl.h>

struct drm_msm_event_req { __u32 object_id; __u32 object_type; __u32 event_id; };

#define DRM_IOCTL_MSM_REGISTER_EVENT   _IOWR('d', 0x41, struct drm_msm_event_req)
#define DRM_IOCTL_MSM_DEREGISTER_EVENT _IOWR('d', 0x42, struct drm_msm_event_req)

#endif
