//
//  PreferencesController.m
//  Simple Preferences
//
//  Created by John Devor on 12/24/06.
//
// http://www.indiehig.com/wiki/Preference_Windows
/*
Copyright (c) <year> <copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#import "PreferencesController.h"
#import "NSFileManager_SwissSMS.h"

#define WINDOW_TITLE_HEIGHT 78

static PreferencesController *sharedPreferencesController = nil;

@implementation PreferencesController

+ (PreferencesController *)sharedPreferencesController
{
	if (!sharedPreferencesController) {
		sharedPreferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
	}
	return sharedPreferencesController;
}

- (void)awakeFromNib
{
    GeneralToolbarItemIdentifier = NSLocalizedString(@"General", @"prefs > toolbar");
    NetworkToolbarItemIdentifier = NSLocalizedString(@"Network", @"prefs > toolbar");
    UpdateToolbarItemIdentifier = NSLocalizedString(@"Update", @"prefs > toolbar");

	id toolbar = [[[NSToolbar alloc] initWithIdentifier:@"preferences toolbar"] autorelease];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	[toolbar setSizeMode:NSToolbarSizeModeDefault];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate:self];
	[toolbar setSelectedItemIdentifier:GeneralToolbarItemIdentifier];
	[[self window] setToolbar:toolbar];
	
	[self setActiveView:generalPreferenceView animate:NO];
	[[self window] setTitle:GeneralToolbarItemIdentifier];
}

- (IBAction)showWindow:(id)sender 
{
	if (![[self window] isVisible])
		[[self window] center];
	[super showWindow:sender];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		GeneralToolbarItemIdentifier,
		NetworkToolbarItemIdentifier,
		UpdateToolbarItemIdentifier,
		nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar 
{
	return [NSArray arrayWithObjects:
		GeneralToolbarItemIdentifier,
		UpdateToolbarItemIdentifier,
		NetworkToolbarItemIdentifier,
		nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
		GeneralToolbarItemIdentifier,
		NetworkToolbarItemIdentifier,
		UpdateToolbarItemIdentifier,
		nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
	if ([identifier isEqualToString:GeneralToolbarItemIdentifier]) {
		[item setLabel:GeneralToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"general"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} else if ([identifier isEqualToString:UpdateToolbarItemIdentifier]) {
		[item setLabel:UpdateToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"update"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} else if ([identifier isEqualToString:NetworkToolbarItemIdentifier]) {
		[item setLabel:NetworkToolbarItemIdentifier];
		[item setImage:[NSImage imageNamed:@"network"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} else
		item = nil;
	return item; 
}

- (void)toggleActivePreferenceView:(id)sender
{
	NSView *view = nil;
	
	if ([[sender itemIdentifier] isEqualToString:GeneralToolbarItemIdentifier])
		view = generalPreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:UpdateToolbarItemIdentifier])
		view = updatePreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:NetworkToolbarItemIdentifier])
		view = networkPreferenceView;
	
	[self setActiveView:view animate:YES];
	[[self window] setTitle:[sender itemIdentifier]];
}

- (void)setActiveView:(NSView *)view animate:(BOOL)flag
{
	// set the new frame and animate the change
	NSRect windowFrame = [[self window] frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TITLE_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([[self window] frame]) - ([view frame].size.height + WINDOW_TITLE_HEIGHT);
	
	if ([[activeContentView subviews] count] != 0)
		[[[activeContentView subviews] objectAtIndex:0] removeFromSuperview];
	[[self window] setFrame:windowFrame display:YES animate:flag];
	
	[activeContentView setFrame:[view frame]];
	[activeContentView addSubview:view];
}

#pragma mark tools management

- (IBAction)openKeychainAccessApp:(id)sender {
	NSString *script= [NSString stringWithFormat:@"tell application \"Keychain Access\"\nactivate\nend tell\n"];
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource:script];
    [as executeAndReturnError:NULL];
    [as release];
}

@end
