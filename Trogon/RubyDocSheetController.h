//
//  RubyDocSheetController.h
//  Trogon
//
//  Created by Ricky Nelson on 2/4/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RubyDocSheetController : NSObject {
    NSView *documentWindow;
    NSPanel *objectSheet;
}
@property (nonatomic, retain) IBOutlet NSView *documentWindow;
@property (nonatomic, retain) IBOutlet NSPanel *objectSheet;

- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)complete:(id)sender;

@end
