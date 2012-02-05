//
//  GemServer.m
//  Trogon
//
//  Created by Ricky Nelson on 2/5/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import "GemServer.h"

@implementation GemServer

- (id)init {
    self = [super init];
    if (self) {
        _task   = [[NSTask alloc] init];
    }
    return self;
}

- (void)launchGemServer:(NSString *)ruby 
                 gemset:(NSString *)aGemset 
                   port:(NSString *)port
{
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem server --port=%@", rvmPath, ruby, aGemset, port];
    NSPipe *input   = [NSPipe pipe];
    NSPipe *output  = [NSPipe pipe];
    NSFileHandle *_fileHandle;
    
    _fileHandle = [output fileHandleForReading];

    [_fileHandle waitForDataInBackgroundAndNotify];
    
    [_task setLaunchPath:@"/bin/sh"];
    [_task setStandardInput:input]; // Cocoa bug, won't exit without this
    [_task setStandardOutput:output];
    [_task setStandardError:output];
    
    [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    
    @try {
        [_task launch];
    }
    @catch (NSException *exception) {
        //TODO: handle error better, maybe an nsnotification back to appdelegate and post a pretty error
        NSLog(@"ERROR: %@", [exception reason]);
    }
}

- (void)killGemServer {
    [_task terminate];
}
@end
