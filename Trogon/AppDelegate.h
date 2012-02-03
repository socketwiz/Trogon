//
//  AppDelegate.h
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Ruby.h"
#import "GemSet.h"
#import "Gem.h"
#import "ProgressSheetController.h"
#import "RvmSheetController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *_rvms;
    NSMutableArray *_gemsets;
    NSMutableArray *_gems;
    
    Ruby *_ruby;
    
    __weak NSTableView *_tblRvm;
    __weak NSTableView *_tblGemset;
    __weak NSTableView *_tblGem;
    __weak NSArrayController *_aryRvmsController;
    __weak NSArrayController *_aryGemSetsController;
    __weak NSArrayController *_aryGemsController;
    __weak ProgressSheetController *_sheetControllerProgress;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, readwrite) NSMutableArray *rvms;
@property (retain, readwrite) NSMutableArray *gemsets;
@property (retain, readwrite) NSMutableArray *gems;
@property (retain, readwrite) Ruby *ruby;

@property (weak) IBOutlet NSTableView *tblRvm;
@property (weak) IBOutlet NSTableView *tblGemset;
@property (weak) IBOutlet NSTableView *tblGem;
@property (weak) IBOutlet NSArrayController *aryRvmsController;
@property (weak) IBOutlet NSArrayController *aryGemSetsController;
@property (weak) IBOutlet NSArrayController *aryGemsController;

@property (weak) IBOutlet ProgressSheetController *sheetControllerProgress;
@property (weak) IBOutlet RvmSheetController *sheetControllerRvm;

- (IBAction)btnRemoveInterpreter:(id)sender;
- (IBAction)btnRemoveGemset:(id)sender;
- (IBAction)btnRemoveGem:(id)sender;

- (IBAction)toolbarBtnLaunchTerminal:(id)sender;
- (IBAction)toolbarBtnCreateRvmrc:(id)sender;

- (void)reloadInterpreters;
- (void)reloadGemsetList;
- (void)reloadGemList;

- (void)rvmrcInstalled:(NSURL *)pathToFile;
@end
