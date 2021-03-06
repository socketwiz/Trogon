//
//  RubySheetController.h
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Ruby.h"
#import "TaskStep.h"

@interface RubySheetController : NSObject {
    NSView *documentWindow;
    NSPanel *objectSheet;
    NSMutableString *_outputRuby;
    
    NSMutableArray *_rubys;
    __weak NSArrayController *aryRvmsController;
}
@property (nonatomic, retain) IBOutlet NSView *documentWindow;
@property (nonatomic, retain) IBOutlet NSPanel *objectSheet;
@property (retain,readwrite) NSMutableArray *rubys;
@property (weak) IBOutlet NSArrayController *aryRvmsController;
@property (retain, readwrite) NSMutableString *taskOutput;


- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)complete:(id)sender;
@end
