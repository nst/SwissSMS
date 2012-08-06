/*
 *  IMService_TigerCompat.h
 *  SwissSMS
 *
 *  Created by Cédric Luthi on 22.11.07.
 *  Copyright 2007 Cédric Luthi. All rights reserved.
 *
 */

#import <InstantMessage/IMService.h>

// Silence warning: ‘IMService’ may not respond to ‘+imageNameForStatus:’ when compiling on Tiger with MacOSX10.4u SDK
@interface IMService (TigerCompat)

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
+ (NSString *)imageNameForStatus:(IMPersonStatus)status;
#endif

@end
