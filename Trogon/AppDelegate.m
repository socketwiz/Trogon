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
@synthesize outputGemList = _outputGemList;
@synthesize rvm = _rvm;

@synthesize tblRvm = _tblRvm;
@synthesize tblGemset = _tblGemset;
@synthesize tblGem = _tblGem;

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
        _outputGemList = [[NSMutableString alloc] init];
        
        _rvm = [[Rvm alloc] init];
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
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil] 
                            object:nil
                          selector:nil
                       synchronous:YES];
}

- (void)refreshInterpretersNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"TrogonRefreshRubyInterpreter" 
                                                  object:nil];
    
    [self reloadInterpreters];
}

- (void)reloadInterpreters {
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list", rvmPath];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                            object:self
                          selector:@selector(readInterpreterData:)
                       synchronous:NO];
}

-(void)readInterpreterData: (NSString *)output {
    [self.rvms removeAllObjects];
    [self.outputInterpreter appendString:output];
    
    // pull just the ruby interpreters out of the mess we get back
    for (NSString *line in [self.outputInterpreter componentsSeparatedByString:@"\n"]) {
        // first line is always "rvm rubies" and we don't want it
        if ([line length] > 0 && [line localizedCompare:@"rvm rubies"] != NSOrderedSame) {
            Rvm *aRvm = [[Rvm alloc] init];
            NSArray *interpreters = [[line stringByTrimmingLeadingWhitespace] componentsSeparatedByString:@" "];
            
            if ([interpreters count] > 1) {
                aRvm.interpreter = [interpreters objectAtIndex:0];
                [self.rvms addObject:aRvm];
                self.rvms = self.rvms;
            }
        }
    }

    // load the gemset list
    [self reloadGemsetList];
    [self.outputInterpreter setString:@""];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([aNotification object] == _tblRvm) {
        if ([[self.aryRvmsController selectedObjects] count] == 0) {
            return;
        }
        
        [self reloadGemsetList];
    }

	if ([aNotification object] == _tblGemset) {
        if ([[self.aryGemSetsController selectedObjects] count] == 0) {
            return;
        }
        
        [self reloadGemList];
    }
}

- (void)reloadGemsetList {
    self.rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset list", rvmPath, self.rvm.interpreter];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                            object:self
                          selector:@selector(readGemsetList:)
                       synchronous:NO];
}

- (void)readGemsetList: (NSString *)output {
    [self.gemsets removeAllObjects];
    [self.outputGemsetList appendString:output];
    
    // pull just the ruby gemsets out of the mess we get back
    NSInteger cnt = 0;
    for (NSString *line in [self.outputGemsetList componentsSeparatedByString:@"\n"]) {
        if (cnt < 2 || [line length] == 0) { // skip first two lines or empty lines
            cnt++;
            continue;
        }
        
        GemSet *aGemSet = [[GemSet alloc] init];
        aGemSet.name = [line stringByTrimmingLeadingWhitespace];
        [self.gemsets addObject:aGemSet];
        self.gemsets = self.gemsets;
    }
    
    [self.outputGemsetList setString:@""];
    [self reloadGemList];
}

- (void)reloadGemList {
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
    
    [self.tblGem reloadData];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem list", rvmPath, self.rvm.interpreter, gemset.name];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                            object:self
                          selector:@selector(readGemList:)
                       synchronous:NO];
}

-(void)readGemList: (NSString *)output {
    [self.gems removeAllObjects];
    [self.outputGemList appendString:output];
    
    NSInteger gemCount = 0;
    // pull just the ruby gems out of the mess we get back
    for (NSString *line in [self.outputGemList componentsSeparatedByString:@"\n"]) {
        if ([line length] == 0) { // skip empty lines
            continue;
        }
        
        Gem *aGem = [[Gem alloc] init];
        aGem.name = [line stringByTrimmingLeadingWhitespace];
        [self.gems addObject:aGem];
        self.gems = self.gems;
        gemCount++;
    }

    if ([self.outputGemList length] == 1) {
        Gem *aGem = [[Gem alloc] init];
        aGem.name = @"No gems for this gemset";
        [self.gems addObject:aGem];
        self.gems = self.gems;
    }

    [self.outputGemList setString:@""];
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
    (void)[[Task sharedTask] performTask:@"/bin/sh" 
                           withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                                  object:nil
                                selector:nil
                             synchronous:YES];
}

- (IBAction)btnRemoveGemset:(id)sender {
    NSLog(@"btnRemoveGemset");
}

- (IBAction)btnRemoveGem:(id)sender {
    NSLog(@"btnRemoveGem");
}
@end
