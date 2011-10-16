//
//  AppDelegate.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "NSString+trimLeadingWhitespace.h"

@implementation AppDelegate
@synthesize aryRvmsController = _aryRvmsController;
@synthesize window = _window;
@synthesize rvms = _rvms;
@synthesize gemsets = _gemsets;
@synthesize gems = _gems;

@synthesize tblRvm = _tblRvm;


- (id)init {
    self = [super init];
    if (self) {
        _rvms = [[NSMutableArray alloc] init];
        _gemsets = [[NSMutableArray alloc] init];
        _gems = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == _tblRvm)
	{
        [_gemsets removeAllObjects];
        Rvm *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];

        NSTask *_task;
        NSPipe *pipe = [NSPipe pipe];
        
        _task = [[NSTask alloc] init];
        [_task setLaunchPath:@"/bin/sh"];
        [_task setStandardInput:[NSPipe pipe]]; // xcode bug, won't exit without this
        [_task setStandardOutput: pipe];
        [_task setStandardError: pipe];
        NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset list", rvmPath, rvm.interpreter];
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
}

@end
