//
//  MyPerson.m
//  BindingCategory
//
//  Created by Nicolas Seriot on 07.05.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "MyPerson.h"


@implementation ABPerson (SwissSMS)

// http://www.cocoabuilder.com/archive/message/cocoa/2007/5/6/182892
- (id) valueForKeyPath: (NSString*) keyPath {
   NSArray *path = [keyPath componentsSeparatedByString: @"."];
   unsigned i, max;
   max = [path count];
   id value = self;
   for ( i = 0; i < max; i++ ) {
       value = [value valueForKey: [path objectAtIndex: i]];        
   }
   return value;
}

//- (void) setImageData:(NSData *)data {
//    [super setImageData:data];
//}

// #warning might break
// http://www.cocoabuilder.com/archive/message/cocoa/2004/5/8/106572
- (void) encodeWithCoder:(NSCoder *) coder {
   [coder encodeDataObject:[self vCardRepresentation]];
}

- (id) initWithCoder:(NSCoder *)decoder; {
   self=[self init];    // this call assigns a uniqueId
   self=[self initWithVCardRepresentation:[decoder decodeDataObject]];
   return self;
}


@end
