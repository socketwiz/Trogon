//
//  RvmSheetController.h
//  Trogon
//
//  Created by Ricky Nelson on 2/2/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RvmSheetController : NSObject {
    NSView *documentWindow;
    NSPanel *objectSheet;
    
    __weak NSButton *btnInstall;
    __weak NSButton *btnLocate;
    __weak NSTextField *txtRvmPath;
    __weak NSMatrix *rdoRvmChoice;
    __weak NSTextField *lblPathToRvm;
}

@property (nonatomic, retain) IBOutlet NSView *documentWindow;
@property (strong) IBOutlet NSPanel *objectSheet;
@property (weak) IBOutlet NSButton *btnInstall;
@property (weak) IBOutlet NSButton *btnLocate;
@property (weak) IBOutlet NSTextField *txtRvmPath;
@property (weak) IBOutlet NSMatrix *rdoRvmChoice;

- (IBAction)add:(id)sender;
- (IBAction)complete:(id)sender;
- (IBAction)cancel:(id)sender;
@property (weak) IBOutlet NSTextField *lblPathToRvm;
@end
