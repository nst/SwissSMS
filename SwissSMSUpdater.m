//
//  SwissSMSUpdater.m
//  SwissSMS
//
//  Created by Cédric Luthi on 4/6/08.
//  Copyright 2008 Cédric Luthi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SwissSMSUpdater.h"
#import <Sparkle/SUAppcastItem.h>
//#import <Sparkle/SUUtilities.h>


@implementation SwissSMSUpdater

// The Sparkle 1.1 implementation compares the version in the appcast ([updateItem fileVersion])
// to host app "version" (CFBundleVersion). But for SwissSMS CFBundleVersion is the svn revision number.
// We want to compare the appcast version to the dotted version of SwissSMS which lies in CFBundleShortVersionString.
// Original implementation:
// return SUStandardVersionComparison([updateItem fileVersion], SUHostAppVersion()) == NSOrderedAscending;
- (BOOL)newVersionAvailable
{
	return NO;//SUStandardVersionComparison([updateItem fileVersion], SUInfoValueForKey(@"CFBundleShortVersionString")) == NSOrderedAscending;
}

@end
