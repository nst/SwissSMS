//
//  Message.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 07.04.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <AddressBook/AddressBook.h>

@interface Message :  NSManagedObject  
{
}

+(Message *)messageWithText:(NSString *)text name:(NSString *)name phone:(NSString *)phone context:(NSManagedObjectContext *)context;

+(NSArray *)allObjectsInContext:(NSManagedObjectContext *)moc;
+(unsigned)messagesCountInContext:(NSManagedObjectContext *)moc;

-(NSDictionary *)bluePhoneEliteFormatAndRemove:(BOOL)remove;
-(NSString *)csvLine;
-(ABPerson *)guessedPerson;

-(void)toggleFlag;

@end
