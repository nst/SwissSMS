//
//  SwissSMS_AppDelegate+Toolbar.h
//  SwissSMS
//
//  Created by Nicolas Seriot on 26.05.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SwissSMS_AppDelegate.h"

@interface SwissSMS_AppDelegate (Toolbar)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;

@end
