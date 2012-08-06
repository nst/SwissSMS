//
//  NSManagedObjectContext+Metadata.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 20.06.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSManagedObjectContext (Metadata)

- (BOOL)saveWithMetadata:(NSError **)error;
- (BOOL)saveWithMetadata:(NSError **)error allItems:(BOOL)allItems;

@end
