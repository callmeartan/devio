#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "dummy.h"
#import "FLTFirebaseCorePlugin.h"
#import "FLTFirebasePlugin.h"
#import "FLTFirebasePluginRegistry.h"
#import "messages.g.h"

FOUNDATION_EXPORT double firebase_coreVersionNumber;
FOUNDATION_EXPORT const unsigned char firebase_coreVersionString[];

