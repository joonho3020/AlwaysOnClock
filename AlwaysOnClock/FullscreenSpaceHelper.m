//
//  FullscreenSpaceHelper.m
//  AlwaysOnClock
//
//  Created by Joonho Hwangbo on 7/30/25.
//

#import "FullscreenSpaceHelper.h"
#import <Foundation/Foundation.h>
#import <dlfcn.h>

typedef CFArrayRef (*CGSCopyManagedDisplaySpacesFn)(int);
typedef uint64_t (*CGSGetActiveSpaceFn)(int);
extern int CGSMainConnectionID(void);

BOOL isCurrentSpaceFullscreen(void) {
    void *handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY);
    if (!handle) {
        NSLog(@"Failed to load SkyLight");
        return NO;
    }

    CGSCopyManagedDisplaySpacesFn copySpaces =
        (CGSCopyManagedDisplaySpacesFn)dlsym(handle, "CGSCopyManagedDisplaySpaces");
    CGSGetActiveSpaceFn getActiveSpace =
        (CGSGetActiveSpaceFn)dlsym(handle, "CGSGetActiveSpace");

    if (!copySpaces || !getActiveSpace) {
        NSLog(@"Missing CGS symbols");
        dlclose(handle);
        return NO;
    }

    uint64_t activeSpaceID = getActiveSpace(CGSMainConnectionID());
    CFArrayRef displaySpacesRef = copySpaces(CGSMainConnectionID());
    NSArray *displays = CFBridgingRelease(displaySpacesRef);
    dlclose(handle);

    for (NSDictionary *display in displays) {
        NSArray *spaces = display[@"Spaces"];
        for (NSDictionary *space in spaces) {
            NSNumber *spaceID = space[@"id64"];
            NSNumber *type = space[@"type"];
            if ([spaceID unsignedLongLongValue] == activeSpaceID) {
                return [type intValue] == 4; // 4 = fullscreen
            }
        }
    }

    return NO;
}