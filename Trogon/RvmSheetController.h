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
}

@property (nonatomic, retain) IBOutlet NSView *documentWindow;
@property (strong) IBOutlet NSPanel *objectSheet;
@property (unsafe_unretained) IBOutlet NSTextView *txtViewInstaller;

- (IBAction)add:(id)sender;
- (IBAction)complete:(id)sender;
- (IBAction)cancel:(id)sender;
@end
