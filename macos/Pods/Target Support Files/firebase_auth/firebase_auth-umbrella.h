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

#import "CustomPigeonHeader.h"
#import "firebase_auth_messages.g.h"
#import "FLTFirebaseAuthPlugin.h"

FOUNDATION_EXPORT double firebase_authVersionNumber;
FOUNDATION_EXPORT const unsigned char firebase_authVersionString[];

