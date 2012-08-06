//
//  NSFileManager_SwissSMS.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 25.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (SwissSMS)

- (BOOL)copyResource:(NSString *)sourcePath toChosenDestination:(NSString *)defaultDir;

@end
