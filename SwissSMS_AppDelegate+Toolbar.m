//
//  SwissSMS_AppDelegate+Toolbar.m
//  SwissSMS
//
//  Created by Nicolas Seriot on 26.05.07.
//  Copyright 2007 Nicolas Seriot. All rights reserved.
//

#import "SwissSMS_AppDelegate+Toolbar.h"

@implementation SwissSMS_AppDelegate (Toolbar)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    //NSLog(@"itemIdentifier %@", itemIdentifier);
    //return [toolbarItems objectForKey:itemIdentifier];
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualToString:@"newMessage"]) {
        [item setLabel:NSLocalizedString(@"New message", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Create new message", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Creates a new message", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"NewMessage.png"]];
        [item setTarget:self];
        [item setAction:@selector(toolbaritemclicked:)];
    } else if ([itemIdentifier isEqualToString:@"messageInspector"]) {
        [item setLabel:NSLocalizedString(@"Inspector", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Message Inspector", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Shows/hides the message inspector", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"Inspect.png"]];
        [item setTarget:self];
        [item setAction:@selector(toolbaritemclicked:)];
    } else if ([itemIdentifier isEqualToString:@"inspector"]) {
        [item setLabel:NSLocalizedString(@"Inspector", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Message Inspector", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Shows/hides the message inspector", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"Inspect.png"]];
        [item setTarget:self];
        [item setAction:@selector(toolbaritemclicked:)];
    } else if ([itemIdentifier isEqualToString:@"flag"]) {
        [item setLabel:NSLocalizedString(@"Flag", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Flag", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Flag selected messages", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"Flag.png"]];
        [item setTarget:self];
        [item setAction:@selector(toolbaritemclicked:)];
    } else if ([itemIdentifier isEqualToString:@"deleteMessage"]) {
        [item setLabel:NSLocalizedString(@"Delete", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Delete selected messages", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Deletes the selected messages", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"Delete.png"]];
        [item setTarget:self];
        [item setAction:@selector(toolbaritemclicked:)];
    } else if ([itemIdentifier isEqualToString:@"searchField"]) {
        [item setLabel:NSLocalizedString(@"Search", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Search", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Search your messages", @"Toolbar tooltip")];
        NSRect fRect = [searchItemView frame];
        [item setView:searchItemView];
        [item setMinSize:fRect.size];
        [item setMaxSize:fRect.size];
    } else if ([itemIdentifier isEqualToString:@"senderPopup"]) {
		[item setLabel:NSLocalizedString(@"Sender", @"Toolbar item")];
		[item setPaletteLabel:NSLocalizedString(@"Choose the SMS service", @"Toolbar customize")];
		[item setToolTip:NSLocalizedString(@"SMS service", @"Toolbar tooltip")];
		NSRect fRect = [senderItemView frame];
		[item setView:senderItemView];
		[item setMinSize:fRect.size];
		[item setMaxSize:fRect.size];

        //[item setTarget:self];
        //[item setAction:@selector(toolbaritemclicked:)];
    }
    
    return [item autorelease];
    
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:@"newMessage", @"messageInspector", @"flag", @"deleteMessage", NSToolbarFlexibleSpaceItemIdentifier, @"searchField", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    NSArray *standardItems = [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
                                                       NSToolbarSpaceItemIdentifier,
                                                       NSToolbarFlexibleSpaceItemIdentifier,
                                                       NSToolbarCustomizeToolbarItemIdentifier, nil];
	NSArray *moreItems = [NSArray arrayWithObjects:@"senderPopup", nil];
    return [[[self toolbarDefaultItemIdentifiers:nil] arrayByAddingObjectsFromArray:standardItems] arrayByAddingObjectsFromArray:moreItems];
}

- (void)toolbaritemclicked:(NSToolbarItem*)item {
    //NSLog(@"-- toolbaritemclicked %@", [item label]);
    
    NSString *identifier = [item itemIdentifier];
    if([identifier isEqualToString:@"newMessage"]) {
        [self newMessage:self];
    } else if ([identifier isEqualToString:@"messageInspector"]) {
        [messageInspector isVisible] ? [messageInspector orderOut:self] : [messageInspector orderFront:self];
    } else if ([identifier isEqualToString:@"deleteMessage"]) {
        [messagesController remove:self];
    } else if ([identifier isEqualToString:@"flag"]) {
        [self toggleFlagOnSelectedMessages:self];
    }    
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    
    NSString *identifier = [theItem itemIdentifier];
    if([identifier isEqualToString:@"newMessage"]) {
        return !isSending;
    } else if ([identifier isEqualToString:@"messageInspector"]) {
        return [[messagesController selectedObjects] count] == 1;
    } else if ([[NSArray arrayWithObjects:@"flag", @"deleteMessage", nil] containsObject:identifier]) {
        return [[messagesController selectedObjects] count] > 0;
    }
    
    return YES;
}

@end
