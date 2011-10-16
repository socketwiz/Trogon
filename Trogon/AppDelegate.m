//
//  AppDelegate.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize rvms = _rvms;

- (id)init {
    self = [super init];
    if (self) {
        _rvms = [[NSMutableArray alloc] init];
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
    NSString *rvm = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list", rvm];
    [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    [_task launch];

    [_task waitUntilExit];
    
    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    for (NSString *line in [outputString componentsSeparatedByString:@"\n"]) {
        if ([line length] > 0 && [line localizedCompare:@"rvm rubies"] != NSOrderedSame) {
            Rvm *aRvm = [[Rvm alloc] init];
            aRvm.interpreter = [line stringByReplacingOccurrencesOfString:@" " withString:@""];
            [_rvms addObject:aRvm];
            self.rvms = _rvms;
        }
    }
}

@end
