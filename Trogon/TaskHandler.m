//
//  TaskHandler.m
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/01.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "TaskHandler.h"


@implementation TaskHandler

@synthesize taskState;
@synthesize task;

- (id)initWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments
	terminationReceiver:(id)receiver selector:(SEL)selector
{
	self = [super init];
	if (self)
	{
		task = [[NSTask alloc] init];
		[task setLaunchPath:launchPath];
		[task setArguments:arguments];
		
		outputData = [[NSMutableData alloc] init];
		errorData = [[NSMutableData alloc] init];

		[task setStandardInput:[NSPipe pipe]];
		[task setStandardOutput:[NSPipe pipe]];
		[task setStandardError:[NSPipe pipe]];
		NSFileHandle *standardOutputFile = [[task standardOutput] fileHandleForReading];
		NSFileHandle *standardErrorFile = [[task standardError] fileHandleForReading];
		
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(standardOutNotification:)
			name:NSFileHandleDataAvailableNotification
			object:standardOutputFile];
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(standardErrorNotification:)
			name:NSFileHandleDataAvailableNotification
			object:standardErrorFile];
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(terminatedNotification:)
			name:NSTaskDidTerminateNotification
			object:task];
		
		[standardOutputFile waitForDataInBackgroundAndNotify];
		[standardErrorFile waitForDataInBackgroundAndNotify];
		
		terminationReceiver = receiver;
		terminationSelector = selector;
		taskState = TaskHandlerNotLaunched;
	}
	
	return self;
}

- (void)launch
{
	@try
	{
		[task launch];
		taskState = TaskHandlerStillRunning;
	}
	@catch (NSException * e)
	{
		self.taskState = TaskHandlerCouldNotBeLaunched;
		[terminationReceiver
			performSelector:terminationSelector
			withObject:self
			afterDelay:0.0];
	}
}

- (void)appendInputData:(NSData *)newData
{
	@try
	{
		if ([newData length] == 0)
		{
			[[[task standardInput] fileHandleForWriting] closeFile];
		}
		else
		{
			[[[task standardInput] fileHandleForWriting] writeData:newData];
		}
	}
	@catch (NSException *e)
	{
		// input pipe/filehandle has probably closed, ignore
	}
}

- (void)setOutputReceiver:(id)receiver selector:(SEL)selector
{
	outputReceiver = receiver;
	outputSelector = selector;

	outputData = nil;
}

- (void)setErrorReceiver:(id)receiver selector:(SEL)selector
{
	errorReceiver = receiver;
	errorSelector = selector;

	errorData = nil;
}

- (void)sendTerminatedMessageIfReady
{
	if (taskState == TaskHandlerStillRunning ||
		!outputClosed ||
		!errorClosed)
	{
		return;
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[terminationReceiver performSelector:terminationSelector withObject:self];
#pragma clang diagnostic pop
	terminationReceiver = nil;
}

- (void)terminatedNotification: (NSNotification *)notification
{
	switch([task terminationReason])
	{
		case NSTaskTerminationReasonUncaughtSignal:
			self.taskState = TaskHandlerTerminationReasonUncaughtSignal;
			break;
		default:
			self.taskState = TaskHandlerTerminationReasonExit;
			break;
	}
	[self sendTerminatedMessageIfReady];
}

- (void)standardOutNotification: (NSNotification *) notification
{
    NSFileHandle *standardOutputFile = (NSFileHandle *)[notification object];
	
	NSData *availableData = [standardOutputFile availableData];
	if ([availableData length] == 0)
	{
		outputClosed = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[outputReceiver performSelector:outputSelector withObject:nil withObject:self];
#pragma clang diagnostic pop
		outputReceiver = nil;
		
		[self sendTerminatedMessageIfReady];
		return;
	}
	
	[outputData appendData:availableData];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[outputReceiver performSelector:outputSelector withObject:availableData withObject:self];
#pragma clang diagnostic pop
	
    [standardOutputFile waitForDataInBackgroundAndNotify];
}
 
- (void)standardErrorNotification: (NSNotification *) notification
{
    NSFileHandle *standardErrorFile = (NSFileHandle *)[notification object];
	
	NSData *availableData = [standardErrorFile availableData];
	if ([availableData length] == 0)
	{
		errorClosed = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[errorReceiver performSelector:errorSelector withObject:nil withObject:self];
#pragma clang diagnostic pop
		errorReceiver = nil;
		
		[self sendTerminatedMessageIfReady];
		return;
	}
	
	[errorData appendData:availableData];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[errorReceiver performSelector:errorSelector withObject:availableData withObject:self];
#pragma clang diagnostic pop
	
    [standardErrorFile waitForDataInBackgroundAndNotify];
}

- (NSData *)outputData
{
	return outputData;
}

- (NSData *)errorData
{
	return errorData;
}

- (void)terminate
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	terminationReceiver = nil;
	outputReceiver = nil;
	errorReceiver = nil;
	
	[task terminate];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	task = nil;
	outputData = nil;
	errorData = nil;
	terminationReceiver = nil;
	outputReceiver = nil;
	errorReceiver = nil;
}

@end
