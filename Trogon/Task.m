//
//  Task.m
//  Trogon
//
//  Created by Ricky Nelson on 10/18/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "Task.h"

@implementation Task
static Task* _sharedTask = nil;

+ (Task *)sharedTask {
	@synchronized([Task class])
	{
		if (!_sharedTask) {
			(void)[[self alloc] init];
        }

		return _sharedTask;
	}
    
	return nil;
}

+ (id)alloc
{
	@synchronized([Task class])
	{
		NSAssert(_sharedTask == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedTask = [super alloc];
		return _sharedTask;
	}
    
	return nil;
}

- (void)performTask:(NSString *)aTask arguments:(NSArray *)taskArguments {
    NSTask *_task   = [[NSTask alloc] init];
    NSPipe *input   = [NSPipe pipe];
    NSPipe *output  = [NSPipe pipe];
    NSFileHandle *_fileHandle;
    
    _fileHandle = [output fileHandleForReading];
    [_fileHandle waitForDataInBackgroundAndNotify];
    
    [_task setLaunchPath:aTask];
    [_task setStandardInput:input]; // Cocoa bug, won't exit without this
    [_task setStandardOutput:output];
    [_task setStandardError:output];

    [_task setArguments:taskArguments];
    [_task launch];
}

@end
