//
//  NSManagedObjectContext+Metadata.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 20.06.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import "NSManagedObjectContext+Metadata.h"
#import "Message.h"

@implementation NSManagedObjectContext (Metadata)

- (BOOL)saveWithMetadata:(NSError **)error allItems:(BOOL)allItems {
	
	// ensure metadata directory is present, create it if it is not
	// TODO: manage errors
	NSString *dir = [[NSApp delegate] valueForKey:@"metadataDirectoryPath"];
	BOOL isDir;
	//NSLog(@"-- %d", [[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]);
	if(![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]) {
		NSString *topDir = [dir stringByDeletingLastPathComponent];
		//NSLog(@"-- %d", [[NSFileManager defaultManager] fileExistsAtPath:topDir isDirectory:&isDir]);
		if(![[NSFileManager defaultManager] fileExistsAtPath:topDir isDirectory:&isDir]) {
			BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:topDir attributes:nil];
			NSLog(@"created %d %@", dirCreated, topDir);
		}
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]) {
			BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:dir attributes:nil];
			NSLog(@"created %d %@", dirCreated, dir);
		}
	}
	/*
	if(allItems) {
	
	}
	*/
	NSSet *insert = allItems ? [Message allObjectsInContext:self] : [[[self insertedObjects] copy] autorelease];
	NSSet *remove = [[[self deletedObjects] copy] autorelease];
	
	if(![self save:error]) {
		NSLog(@"could not save database");
		[remove release];
		return NO;
	}

	[remove makeObjectsPerformSelector:@selector(removeMetadataFile)];
	[insert makeObjectsPerformSelector:@selector(writeMetadataFile)];
	/*
	if(!allItems) {
		[insert release];
	}
	[remove release];
	*/
	return YES;
}

- (BOOL)saveWithMetadata:(NSError **)error {
	return [self saveWithMetadata:error allItems:NO];
}

@end
