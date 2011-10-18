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

@implementation AppDelegate
@synthesize window = _window;
@synthesize rvms = _rvms;
@synthesize gemsets = _gemsets;
@synthesize gems = _gems;

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
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadInterpretersNotification:)
                                                 name:@"TrogonReloadInterpreters" 
                                               object:nil];
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self reloadInterpreters];
}

- (void)reloadInterpretersNotification:(NSNotification *)notification {
    [self reloadInterpreters];
}

- (void)reloadInterpreters {
    [_rvms removeAllObjects];

    NSTask *_task;
    NSPipe *pipe = [NSPipe pipe];
    
    _task = [[NSTask alloc] init];
    [_task setLaunchPath:@"/bin/sh"];
    [_task setStandardInput:[NSPipe pipe]]; // xcode bug, won't exit without this
    [_task setStandardOutput: pipe];
    [_task setStandardError: pipe];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list", rvmPath];
    [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    [_task launch];
    
    [_task waitUntilExit];
    
    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    // pull just the ruby interpreters out of the mess we get back
    for (NSString *line in [outputString componentsSeparatedByString:@"\n"]) {
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
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([aNotification object] == _tblRvm) {
        [_gemsets removeAllObjects];
        _rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
        
        // set the gemset index so the gems list will refresh
        [self.aryGemSetsController setSelectionIndex:0];

        NSTask *_task;
        NSPipe *pipe = [NSPipe pipe];
        
        _task = [[NSTask alloc] init];
        [_task setLaunchPath:@"/bin/sh"];
        [_task setStandardInput:[NSPipe pipe]]; // xcode bug, won't exit without this
        [_task setStandardOutput: pipe];
        [_task setStandardError: pipe];
        NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset list", rvmPath, _rvm.interpreter];
        [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
        [_task launch];
        
        [_task waitUntilExit];
        
        NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        // pull just the ruby gemsets out of the mess we get back
        NSInteger cnt = 0;
        for (NSString *line in [outputString componentsSeparatedByString:@"\n"]) {
            if (cnt < 2 || [line length] == 0) { // skip first two lines or empty lines
                cnt++;
                continue;
            }

            GemSet *aGemSet = [[GemSet alloc] init];
            aGemSet.name = [line stringByTrimmingLeadingWhitespace];
            [_gemsets addObject:aGemSet];
            self.gemsets = _gemsets;
        }
    }

	if ([aNotification object] == _tblGemSet) {
        if ([[self.aryGemSetsController selectedObjects] count] == 0) {
            return;
        }

        [_gems removeAllObjects];
        GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
        
        NSTask *_task;
        NSPipe *pipe = [NSPipe pipe];
        
        _task = [[NSTask alloc] init];
        [_task setLaunchPath:@"/bin/sh"];
        [_task setStandardInput:[NSPipe pipe]]; // xcode bug, won't exit without this
        [_task setStandardOutput: pipe];
        [_task setStandardError: pipe];
        NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem list", rvmPath, _rvm.interpreter, gemset.name];
        [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
        [_task launch];
        
        [_task waitUntilExit];
        
        NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        NSInteger gemCount = 0;
        // pull just the ruby gems out of the mess we get back
        for (NSString *line in [outputString componentsSeparatedByString:@"\n"]) {
            if ([line length] == 0) { // skip empty lines
                continue;
            }
            
            Gem *aGem = [[Gem alloc] init];
            aGem.name = [line stringByTrimmingLeadingWhitespace];
            [_gems addObject:aGem];
            self.gems = _gems;
            gemCount++;
        }
        
        if (gemCount == 0) {
            Gem *aGem = [[Gem alloc] init];
            aGem.name = @"No gems for this gemset";
            [_gems addObject:aGem];
            self.gems = _gems;
        }
    }
}

- (IBAction)btnAddInterpreter:(id)sender {
    NSLog(@"btnAddInterpreter");
}

- (IBAction)btnRemoveInterpreter:(id)sender {
    NSLog(@"btnRemoveInterpreter");
    Rvm *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
    
    NSTask *_task;
    NSPipe *pipe = [NSPipe pipe];
    
    _task = [[NSTask alloc] init];
    [_task setLaunchPath:@"/bin/sh"];
    [_task setStandardInput:[NSPipe pipe]]; // xcode bug, won't exit without this
    [_task setStandardOutput: pipe];
    [_task setStandardError: pipe];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    
    // strip trailing spaces, [ and ] characters
    NSString *interpreter = [rvm.interpreter stringByTrimmingTrailingWhitespace];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"[" withString:@""];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm remove %@ --archive", rvmPath, interpreter];
    [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    [_task launch];
    
    [_task waitUntilExit];

    [self reloadInterpreters];
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
