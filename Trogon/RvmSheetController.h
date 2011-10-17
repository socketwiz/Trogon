//
//  RvmSheetController.h
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RvmSheetController : NSObject {
    NSView *documentWindow;
    NSPanel *objectSheet;  
}
@property (nonatomic, retain) IBOutlet NSView *documentWindow;
@property (nonatomic, retain) IBOutlet NSPanel *objectSheet;

- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)complete:(id)sender;

@end
