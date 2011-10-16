//
//  AppDelegate.h
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Rvm.h"
#import "GemSet.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *_rvms;
    NSMutableArray *_gemsets;
    NSMutableArray *_gems;
    
    __weak NSTableView *_tblRvm;
    __weak NSArrayController *_aryRvmsController;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain,readwrite) NSMutableArray *rvms;
@property (retain,readwrite) NSMutableArray *gemsets;
@property (retain,readwrite) NSMutableArray *gems;

@property (weak) IBOutlet NSTableView *tblRvm;
@property (weak) IBOutlet NSArrayController *aryRvmsController;
@end
