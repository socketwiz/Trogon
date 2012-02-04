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

- (void)performTask:(NSString *)aTask 
      withArguments:(NSArray *)taskArguments 
             object:(NSObject *)anObject 
           selector:(SEL)aSelector 
        synchronous:(BOOL)isSynchronous {
    NSTask *_task   = [[NSTask alloc] init];
    NSPipe *input   = [NSPipe pipe];
    NSPipe *output  = [NSPipe pipe];
    NSFileHandle *_fileHandle;
    
    _fileHandle = [output fileHandleForReading];
    
    if (isSynchronous == YES) {
        [_fileHandle waitForDataInBackgroundAndNotify];
    }
    
    [_task setLaunchPath:aTask];
    [_task setStandardInput:input]; // Cocoa bug, won't exit without this
    [_task setStandardOutput:output];
    [_task setStandardError:output];

    [_task setArguments:taskArguments];
    
    @try {
        [_task launch];
    }
    @catch (NSException *exception) {
        //TODO: handle error better, maybe an nsnotification back to appdelegate and post a pretty error
        NSLog(@"ERROR: %@", [exception reason]);
    }
    @finally {
        if (isSynchronous == NO) {
            NSMutableDictionary *arguments = [[NSMutableDictionary alloc] init];
            
            [arguments setValue:_fileHandle forKey:@"file_handle"];
            [arguments setValue:anObject forKey:@"object"];
            [arguments setValue:NSStringFromSelector(aSelector) forKey:@"selector"];
            
            //read the data off in a background thread, then pass the text onto to the appropriate selector
            [self performSelectorInBackground:@selector(readDataUsingArguments:) withObject:arguments];
        }
    }
}

- (void)readDataUsingArguments:(NSDictionary *)theArguments {
    NSFileHandle *theFileHandle = [theArguments valueForKey:@"file_handle"];
    NSData *data = [theFileHandle readDataToEndOfFile];
    
    NSObject *theClass = [theArguments objectForKey:@"object"];
    SEL theSelector = NSSelectorFromString([theArguments objectForKey:@"selector"]);

    NSString *taskOutput;
    taskOutput = [[NSString alloc] initWithData: data
                                       encoding: NSUTF8StringEncoding];
    
    if (theClass && theSelector) {
        // run on main thread because the interface is going to be updated in these selectors
        [theClass performSelectorOnMainThread:theSelector withObject:taskOutput waitUntilDone:YES];
    }
}
@end
