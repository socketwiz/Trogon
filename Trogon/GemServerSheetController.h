//
//  GemServerSheetController.h
//  Trogon
//
//  Created by Ricky Nelson on 2/5/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GemServerSheetController : NSObject {
    NSView *documentWindow;
    NSPanel *objectSheet;
    NSMutableString *_action;
    NSString *_port;
}
@property (nonatomic, retain) IBOutlet NSView *documentWindow;
@property (nonatomic, retain) IBOutlet NSPanel *objectSheet;

- (IBAction)add:(id)sender ruby:(NSString *)aRuby gem:(NSString *)aGem;
- (IBAction)cancel:(id)sender;
- (IBAction)complete:(id)sender;
- (IBAction)startGemServer:(id)sender;
- (IBAction)stopGemServer:(id)sender;
- (IBAction)viewDocs:(id)sender;

@property (weak) IBOutlet NSTextField *lblGem;
@property (weak) IBOutlet NSTextField *txtPort;
@property (unsafe_unretained) IBOutlet NSTextView *txtViewGemServerOutput;

@property (weak) IBOutlet NSButton *btnStart;
@property (weak) IBOutlet NSButton *btnStop;
@property (weak) IBOutlet NSButton *btnClose;
@property (weak) IBOutlet NSButton *btnViewDocs;
@end
