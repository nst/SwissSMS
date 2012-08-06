// 
//  Message.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 07.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "Message.h"
#import "ABPerson_SwissSMS.h"

@implementation Message 

+(NSArray *)allObjectsInContext:(NSManagedObjectContext *)moc {
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity:[NSEntityDescription entityForName:@"Message" inManagedObjectContext:moc]];
	NSArray *a = [moc executeFetchRequest:fr error:nil];
	[fr release];
	return a;
}

+(unsigned)messagesCountInContext:(NSManagedObjectContext *)moc {
	return [[self allObjectsInContext:moc] count];
}

+(Message *)messageWithText:(NSString *)text name:(NSString *)name phone:(NSString *)phone context:(NSManagedObjectContext *)context {
	Message *message = [NSEntityDescription insertNewObjectForEntityForName: @"Message" inManagedObjectContext:context];
	[message setValue:[NSDate date] forKey:@"date"];
	[message setValue:[[name copy] autorelease] forKey:@"name"];
	[message setValue:[[phone copy] autorelease] forKey:@"phone"];
	[message setValue:[[text copy] autorelease] forKey:@"text"];
	return message;
}

-(NSDictionary *)bluePhoneEliteFormatAndRemove:(BOOL)remove {
	NSMutableString *phone = [NSMutableString stringWithString:[self valueForKey:@"phone"]];
	[phone replaceOccurrencesOfString:@"07" withString:@"+417" options:(unsigned)NULL range:NSMakeRange(0, 4)];
    NSDictionary *d = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:phone, [self valueForKey:@"text"], [NSNumber numberWithInt:3], [[self valueForKey:@"date"] description], nil]
	                                   forKeys:[NSArray arrayWithObjects:@"Address", @"Message", @"State", @"TimeStamp", nil]];
    if(remove) {
        [[self managedObjectContext] deleteObject:self];
        [[self managedObjectContext] save:nil];
    }
    return d;
}

-(NSString *)csvLine {
    NSMutableString *noTabText = [[[self valueForKey:@"text"] mutableCopy] autorelease];
    [noTabText replaceOccurrencesOfString:@"\t" withString:@"    " options:(unsigned)NULL range:NSMakeRange(0,[noTabText length])];

    return [NSString stringWithFormat:@"%@\t%@\t%@\t%@",
        [self valueForKey:@"date"],
        [self valueForKey:@"phone"],
        [self valueForKey:@"name"],
        noTabText];
}

- (ABPerson *)guessedPerson {
    NSString *fullname = [self valueForKey:@"name"];
    NSString *phone = [self valueForKey:@"phone"];
    if(!fullname || !phone) {
        return nil;
    }
    return [ABPerson personFromFullname:fullname mobilePhone:phone];
}

- (void)toggleFlag {
    BOOL state = [[self valueForKey:@"flagged"] boolValue];
    [self setValue:[NSNumber numberWithBool:!state] forKey:@"flagged"];
}

- (NSString *)metadataFilePath {
	NSString *messageNumber = [[[[[self objectID] URIRepresentation] path] pathComponents] lastObject];
	NSString *dir = [[NSApp delegate] valueForKey:@"metadataDirectoryPath"];
	NSString *ext = [[NSApp delegate] valueForKey:@"metadataFileExtension"];
	return [[dir stringByAppendingPathComponent:messageNumber] stringByAppendingPathExtension:ext];
}

- (void)writeMetadataFile {	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
					   [[[self objectID] URIRepresentation] absoluteString], @"objectID",
					   [self valueForKey:@"text"], @"text",
					   [self valueForKey:@"date"], @"date",
					   [self valueForKey:@"name"], @"name",
					   [self valueForKey:@"phone"], @"phone", nil];
	
	NSString *path = [self metadataFilePath];
	
	[d writeToFile:path atomically:YES];
}


- (BOOL)removeMetadataFile {
	NSString *path = [self metadataFilePath];
//	[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
    NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if(success == NO) {
        NSLog(@"-- %@", [error localizedDescription]);
    }
    return success;
}



@end
