//
//  FlagImageTransformer.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 25.05.07.
//  Copyright 2007 Sen:te SA. All rights reserved.
//

#import "FlagImageTransformer.h"


@implementation FlagImageTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

-(id)init {
    [super init];
    
    flaggedImage = [NSImage imageNamed:@"Flagged.png"];
    
    return self;
}

-(void)dealloc {
    [flaggedImage release];
    [super dealloc];
}

- (id)transformedValue:(NSNumber *)value {
    return [value boolValue] ? flaggedImage : nil;
}

@end
