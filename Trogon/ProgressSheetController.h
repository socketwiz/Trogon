//
//  ProgressSheetController.h
//  Trogon
//
//  Created by Ricky Nelson on 10/18/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProgressSheetController : NSObject {
    NSView *documentWindow;
    NSPanel *objectSheet;
    NSMutableString *_action;

    __weak NSImageView *imgProgress;
    __weak NSTextField *lblProgress;
    __unsafe_unretained NSTextView *textViewProgress;
    __weak NSButton *btnContinue;
}
@property (nonatomic, retain) IBOutlet NSView *documentWindow;
@property (nonatomic, retain) IBOutlet NSPanel *objectSheet;
@property (retain, readwrite) NSMutableString *action;

- (IBAction)add:(id)sender action:(NSString *)aAction;
- (IBAction)cancel:(id)sender;
- (IBAction)complete:(id)sender;

@property (weak) IBOutlet NSImageView *imgProgress;
@property (weak) IBOutlet NSTextField *lblProgress;
@property (unsafe_unretained) IBOutlet NSTextView *textViewProgress;
@property (weak) IBOutlet NSButton *btnContinue;
@end
