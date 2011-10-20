//
//  AppDelegate.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "NSString+trimLeadingWhitespace.h"
#import "NSString+trimTrailingWhitespace.h"
#import "Task.h"

@implementation AppDelegate
@synthesize sheetControllerProgress = _sheetControllerProgress;
@synthesize window = _window;
@synthesize rvms = _rvms;
@synthesize gemsets = _gemsets;
@synthesize gems = _gems;
@synthesize outputInterpreter = _outputInterpreter;
@synthesize outputGemsetList = _outputGemsetList;
@synthesize outputGemsetUse = _outputGemsetUse;

@synthesize tblRvm = _tblRvm;
@synthesize tblGemSet = _tblGemSet;

@synthesize aryRvmsController = _aryRvmsController;
@synthesize aryGemSetsController = _aryGemSetsController;

- (id)init {
    self = [super init];
    if (self) {
        _rvms = [[NSMutableArray alloc] init];
        _gemsets = [[NSMutableArray alloc] init];
        _gems = [[NSMutableArray alloc] init];
        _outputInterpreter = [[NSMutableString alloc] init];
        _outputGemsetList = [[NSMutableString alloc] init];
        _outputGemsetUse = [[NSMutableString alloc] init];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addInterpretersNotification:)
                                                 name:@"TrogonAddRubyInterpreter" 
                                               object:nil];

    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self reloadInterpreters];
}

- (void)addInterpretersNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshInterpretersNotification:)
                                                 name:@"TrogonRefreshRubyInterpreter" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install"];

    Rvm *rvm = [[notification userInfo] objectForKey:@"rvm"];

    NSString *interpreter = [rvm.interpreter stringByTrimmingTrailingWhitespace];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"[" withString:@""];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm install %@", rvmPath, interpreter];
    [[Task sharedTask] performTask:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
}

- (void)refreshInterpretersNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"TrogonRefreshRubyInterpreter" 
                                                  object:nil];

    [self reloadInterpreters];
}

- (void)reloadInterpreters {
    [_rvms removeAllObjects];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readInterpreterData:)
                                                 name:NSFileHandleDataAvailableNotification 
                                               object:nil];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list", rvmPath];
    [[Task sharedTask] performTask:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
}

-(void)readInterpreterData: (NSNotification *)notification {
    NSData *data;
    NSString *text;
    
    data = [[notification object] availableData];
    text = [[NSString alloc] initWithData:data 
                                 encoding:NSASCIIStringEncoding];
    
    [self.outputInterpreter appendString:text];
    
    if([data length]) {
        [[notification object] waitForDataInBackgroundAndNotify];
    }
    else {
        // pull just the ruby interpreters out of the mess we get back
        for (NSString *line in [self.outputInterpreter componentsSeparatedByString:@"\n"]) {
            // first line is always "rvm rubies" and we don't want it
            if ([line length] > 0 && [line localizedCompare:@"rvm rubies"] != NSOrderedSame) {
                Rvm *aRvm = [[Rvm alloc] init];
                NSArray *interpreters = [[line stringByTrimmingLeadingWhitespace] componentsSeparatedByString:@" "];
                
                if ([interpreters count] > 1) {
                    aRvm.interpreter = [interpreters objectAtIndex:0];
                    [_rvms addObject:aRvm];
                    self.rvms = _rvms;
                }
            }
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSFileHandleDataAvailableNotification 
                                                      object:nil];
        
        [self.outputInterpreter setString:@""];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([aNotification object] == _tblRvm) {
        if ([[self.aryRvmsController selectedObjects] count] == 0) {
            return;
        }
        
        _rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];

        [_gemsets removeAllObjects];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(readGemsetList:)
                                                     name:NSFileHandleDataAvailableNotification 
                                                   object:nil];
        
        NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset list", rvmPath, _rvm.interpreter];
        [[Task sharedTask] performTask:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    }

	if ([aNotification object] == _tblGemSet) {
        if ([[self.aryGemSetsController selectedObjects] count] == 0) {
            return;
        }

        GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
        
        [_gems removeAllObjects];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(readGemsetUse:)
                                                     name:NSFileHandleDataAvailableNotification 
                                                   object:nil];

        NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem list", rvmPath, _rvm.interpreter, gemset.name];
        [[Task sharedTask] performTask:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    }
}

-(void)readGemsetList: (NSNotification *)notification {
    NSData *data;
    NSString *text;
    
    data = [[notification object] availableData];
    text = [[NSString alloc] initWithData:data 
                                 encoding:NSASCIIStringEncoding];
    
    [self.outputGemsetList appendString:text];
    
    if([data length]) {
        [[notification object] waitForDataInBackgroundAndNotify];
    }
    else {
        // pull just the ruby gemsets out of the mess we get back
        NSInteger cnt = 0;
        for (NSString *line in [self.outputGemsetList componentsSeparatedByString:@"\n"]) {
            if (cnt < 2 || [line length] == 0) { // skip first two lines or empty lines
                cnt++;
                continue;
            }
            
            GemSet *aGemSet = [[GemSet alloc] init];
            aGemSet.name = [line stringByTrimmingLeadingWhitespace];
            [_gemsets addObject:aGemSet];
            self.gemsets = _gemsets;
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSFileHandleDataAvailableNotification 
                                                      object:nil];
        
        [self.outputGemsetList setString:@""];
        
        // set the gemset index so the gems list will refresh
        [self.aryGemSetsController setSelectionIndexes:[NSIndexSet indexSet]];
//        [self.aryGemSetsController setSelectionIndex:0];
    }
}

-(void)readGemsetUse: (NSNotification *)notification {
    NSData *data;
    NSString *text;
    
    data = [[notification object] availableData];
    text = [[NSString alloc] initWithData:data 
                                 encoding:NSASCIIStringEncoding];
    
    [self.outputGemsetUse appendString:text];
    NSInteger gemCount = 0;
    // pull just the ruby gems out of the mess we get back
    for (NSString *line in [text componentsSeparatedByString:@"\n"]) {
        if ([line length] == 0) { // skip empty lines
            continue;
        }
        
        Gem *aGem = [[Gem alloc] init];
        aGem.name = [line stringByTrimmingLeadingWhitespace];
        [_gems addObject:aGem];
        self.gems = _gems;
        gemCount++;
    }
    
    
    if([data length]) {
        [[notification object] waitForDataInBackgroundAndNotify];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSFileHandleDataAvailableNotification 
                                                      object:nil];
        
        if ([self.outputGemsetUse length] == 1) {
            Gem *aGem = [[Gem alloc] init];
            aGem.name = @"No gems for this gemset";
            [_gems addObject:aGem];
            self.gems = _gems;
        }
        
        [self.outputGemsetUse setString:@""];
    }
}

- (IBAction)btnAddInterpreter:(id)sender {
    NSLog(@"btnAddInterpreter");
}

- (IBAction)btnRemoveInterpreter:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshInterpretersNotification:)
                                                 name:@"TrogonRefreshRubyInterpreter" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"uninstall"];
    
    Rvm *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
    
    NSString *interpreter = [rvm.interpreter stringByTrimmingTrailingWhitespace];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm remove %@ --archive", rvmPath, interpreter];
    (void)[[Task sharedTask] performTask:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
}

- (IBAction)btnAddGemset:(id)sender {
    NSLog(@"btnAddGemset");
}

- (IBAction)btnRemoveGemset:(id)sender {
    NSLog(@"btnRemoveGemset");
}

- (IBAction)btnAddGem:(id)sender {
    NSLog(@"btnAddGem");
}

- (IBAction)btnRemoveGem:(id)sender {
    NSLog(@"btnRemoveGem");
}
@end
