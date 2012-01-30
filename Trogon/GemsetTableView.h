//
//  GemsetTableView.h
//  Trogon
//
//  Created by Ricky Nelson on 11/14/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GemsetTableView : NSTableView {
    NSMenu *gemsetMenu;

    NSTrackingRectTag trackingTag;
	BOOL mouseOverView;
	NSInteger mouseOverRow;
	NSInteger lastOverRow;
}

- (IBAction)launchWithTerminal:(id)sender;
@end
