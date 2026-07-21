// Minimal declarations for Apple's private MultitouchSupport.framework.
// These symbols are not publicly documented by Apple; the shapes below
// reflect the framework's well-known ABI (as reverse-engineered and used
// by numerous open-source trackpad utilities over the years) and are
// written fresh here rather than copied from any single project.
#ifndef MULTITOUCH_SUPPORT_SHIM_H
#define MULTITOUCH_SUPPORT_SHIM_H

#include <CoreFoundation/CoreFoundation.h>

typedef struct { float x, y; } MTPoint;
typedef struct { MTPoint position, velocity; } MTVector;

typedef struct {
    int32_t frame;
    double timestamp;
    int32_t identifier;
    int32_t state;      // 4 = touching, 1 = starting, 7 = ending, etc.
    int32_t fingerId;
    int32_t handId;
    MTVector normalizedVector;
    float zTotal;
    int32_t unused2;
    float zDensity;
} MTTouch;

typedef void *MTDeviceRef;

typedef void (*MTContactCallbackFunction)(MTDeviceRef device,
                                           MTTouch *data,
                                           int32_t numFingers,
                                           double timestamp,
                                           int32_t frame);

extern MTDeviceRef MTDeviceCreateDefault(void);
extern void MTRegisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
extern void MTDeviceStart(MTDeviceRef device, int32_t unused);
extern void MTDeviceStop(MTDeviceRef device);
extern void MTDeviceRelease(MTDeviceRef device);

#endif
