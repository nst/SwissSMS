//
//  SwissSMS_AppDelegate+TokenField.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 08.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SwissSMS_AppDelegate.h"

@interface SwissSMS_AppDelegate (TokenField)

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex;
- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject;
//- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject;
//- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject;
- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString;
- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index;

@end
