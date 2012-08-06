//
//  NSWorkspace_SwissSMS.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 03.05.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWorkspace (SwissSMS)

- (OSStatus) quitApplicationWithBundleID:(NSString*)bundleID;
- (BOOL)appIsRunning:(NSString *)appName;

- (void)openIMClientForScreenName:(NSString *)screenName message:(NSString *)message;

@end
