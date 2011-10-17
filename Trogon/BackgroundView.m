//
//  BackgroundView.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "BackgroundView.h"

@implementation BackgroundView

- (void)awakeFromNib {    
	// draw a basic gradient for the view background
	NSColor* gradientBottom = [NSColor colorWithCalibratedRed:0.50 green:0.00 blue:0.00 alpha:1.00];
	NSColor* gradientTop    = [NSColor colorWithCalibratedRed:0.85 green:0.00 blue:0.00 alpha:1.00];
	
	bgGradient = [[NSGradient alloc] initWithStartingColor:gradientBottom
											   endingColor:gradientTop];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	// background gradient
	[bgGradient drawInRect:self.bounds angle:90.0];
	
	NSBezierPath* thePath = [NSBezierPath bezierPath];
	
	[[NSColor grayColor] setStroke];
	
	// bottom line
	[thePath moveToPoint:NSMakePoint(0.0, 0.0)];	
	[thePath lineToPoint:NSMakePoint(self.bounds.size.width, 0.0)];
	
	// top line
	[thePath moveToPoint:NSMakePoint(0.0, self.bounds.size.height)];	
	[thePath lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
	
	[thePath setLineWidth:1.0];
	[thePath stroke];
}

@end
