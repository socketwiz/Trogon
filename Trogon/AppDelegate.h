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
#import "RubyDocSheetController.h"
#import "GemServerSheetController.h"
#import "NSString+trimLeadingWhitespace.h"
#import "NSString+trimTrailingWhitespace.h"
#import "AMShellWrapper.h"

enum STATES {
    NO_HANDLER,
    READ_RUBYS,
    READ_GEMSETS,
    READ_GEMS,
    READ_RUBYDOCS
};

@interface AppDelegate : NSObject <AMShellWrapperDelegate, NSApplicationDelegate> {
    AMShellWrapper *shellWrapper;
    Ruby *_ruby;
    BOOL _isReloadingGemSets;
    BOOL _isReloadingGems;
    
    int currentState;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, readwrite) NSMutableArray *rubys;
@property (retain, readwrite) NSMutableArray *gemsets;
@property (retain, readwrite) NSMutableArray *gems;
@property (retain, readwrite) Ruby *ruby;
@property (retain, readwrite) NSMutableString *taskOutput;

@property (weak) IBOutlet NSTableView *tblRvm;
@property (weak) IBOutlet NSTableView *tblGemset;
@property (weak) IBOutlet NSTableView *tblGem;
@property (weak) IBOutlet NSArrayController *aryRubyController;
@property (weak) IBOutlet NSArrayController *aryGemSetsController;
@property (weak) IBOutlet NSArrayController *aryGemsController;

@property (weak) IBOutlet ProgressSheetController *sheetControllerProgress;
@property (weak) IBOutlet RvmSheetController *sheetControllerRvm;
@property (weak) IBOutlet RubyDocSheetController *sheetControllerRubyDoc;
@property (weak) IBOutlet GemServerSheetController *sheetControllerGemServer;

- (IBAction)btnRemoveRuby:(id)sender;
- (IBAction)btnRemoveGemset:(id)sender;
- (IBAction)btnRemoveGem:(id)sender;

- (IBAction)btnLaunchTerminal:(id)sender;
- (IBAction)btnCreateRvmrc:(id)sender;
- (IBAction)btnLaunchRubyDocs:(id)sender;
- (IBAction)btnLaunchGemServer:(id)sender;

- (void)reloadRubys;
- (void)reloadGemsetList;
- (void)reloadGemList;

- (void)rvmrcInstalled:(NSURL *)pathToFile;
@end
