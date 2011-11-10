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
#import "Gem.h"
#import "ProgressSheetController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *_rvms;
    NSMutableArray *_gemsets;
    NSMutableArray *_gems;
    NSMutableString *_outputInterpreter;
    NSMutableString *_outputGemsetList;
    NSMutableString *_outputGemList;
    
    Rvm *_rvm;
    
    __weak NSTableView *_tblRvm;
    __weak NSTableView *_tblGemset;
    __weak NSTableView *_tblGem;
    __weak NSArrayController *_aryRvmsController;
    __weak NSArrayController *_aryGemSetsController;
    __weak ProgressSheetController *_sheetControllerProgress;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, readwrite) NSMutableArray *rvms;
@property (retain, readwrite) NSMutableArray *gemsets;
@property (retain, readwrite) NSMutableArray *gems;
@property (retain, readwrite) NSMutableString *outputInterpreter;
@property (retain, readwrite) NSMutableString *outputGemsetList;
@property (retain, readwrite) NSMutableString *outputGemList;
@property (retain, readwrite) Rvm *rvm;

@property (weak) IBOutlet NSTableView *tblRvm;
@property (weak) IBOutlet NSTableView *tblGemset;
@property (weak) IBOutlet NSTableView *tblGem;
@property (weak) IBOutlet NSArrayController *aryRvmsController;
@property (weak) IBOutlet NSArrayController *aryGemSetsController;

@property (weak) IBOutlet ProgressSheetController *sheetControllerProgress;

- (IBAction)btnRemoveInterpreter:(id)sender;
- (IBAction)btnRemoveGemset:(id)sender;
- (IBAction)btnRemoveGem:(id)sender;

- (void)reloadInterpreters;
- (void)reloadGemsetList;
- (void)reloadGemList;
@end
