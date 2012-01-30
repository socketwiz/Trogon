//
//  GemsetTableView.m
//  Trogon
//
//  Created by Ricky Nelson on 11/14/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "GemsetTableView.h"

@implementation GemsetTableView
- (void)awakeFromNib {
    gemsetMenu = [[NSMenu alloc] initWithTitle:@"Gemset Menu"];
    NSMenuItem *item;
    NSString *title = @"Launch Terminal with Gemset";
    
    item = [[NSMenuItem alloc] initWithTitle:title action:@selector(launchWithTerminal:) keyEquivalent:@""];
    [gemsetMenu addItem:item];

    [[self window] setAcceptsMouseMovedEvents:YES];
	trackingTag = [self addTrackingRect:[self frame] owner:self userData:nil assumeInside:NO];
	mouseOverView = NO;
	mouseOverRow = -1;
	lastOverRow = -1;
}

-(void)setSelectionFromClick{
    NSLog(@"Clicked row[%ld]", mouseOverRow);
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:mouseOverRow];
    [self selectRowIndexes:thisIndexSet byExtendingSelection:NO];
}

- (IBAction)launchWithTerminal:(id)sender {
    NSLog(@"Launch Terminal");
}

- (NSMenu *)menuForEvent:(NSEvent *)evt 
{
    NSLog(@"menuForEvent");
    [self setSelectionFromClick];
    return gemsetMenu;
}
- (void)mouseEntered:(NSEvent*)theEvent
{
	mouseOverView = YES;
    [self becomeFirstResponder];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
	if (mouseOverView) {
		mouseOverRow = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
		
		if (lastOverRow == mouseOverRow) {
			return;
        }
		else {
			[self setNeedsDisplayInRect:[self rectOfRow:lastOverRow]];
			lastOverRow = mouseOverRow;
		}
        
        [self setNeedsDisplayInRect:[self rectOfRow:mouseOverRow]];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	mouseOverView = NO;
	[self setNeedsDisplayInRect:[self rectOfRow:mouseOverRow]];
	mouseOverRow = -1;
	lastOverRow = -1;
}

- (NSInteger)mouseOverRow
{
	return mouseOverRow;
}
@end
