//
//  AMShellWrapper.m
//  CommX
//
//  Created by Andreas on 2002-04-24.
//  Based on TaskWrapper from Apple
//
//  2002-06-17 Andreas Mayer
//  - used defines for keys in AMShellWrapperProcessFinishedNotification userInfo dictionary
//  2002-08-30 Andreas Mayer
//  - removed bug in getData that sent all output to appendError:
//  - added setInputStringEncoding: and setOutputStringEncoding:
//  - reactivated code to clear output pipes when the task is finished
//  2004-06-15 Andreas Mayer
//  - renamed stopProcess to cleanup since that is what it does; stopProcess
//    is meant to just terminate the task so it's issuing a [task terminate] only now
//  - appendOutput: and appendError: do some error handling now
//  2004-08-11 Andreas Mayer
//  - removed AMShellWrapperProcessFinishedNotification notification since
//	it prevented the task from getting deallocated
//  - don't retain stdin/out/errHandle
//
//  I had some trouble to decide when the task had really stopped. The Apple example
//  did only examine the output pipe and exited when it was empty - which I found unreliable.
//
//  This, finally, seems to work: Wait until the output pipe is empty *and* we received
//  the NSTaskDidTerminateNotification. Seems obvious now ...  :)


#import "AMShellWrapper.h"


@interface AMShellWrapper (private)
- (void)taskStopped:(NSNotification *)aNotification;
- (NSFileHandle *)stdoutHandle;
- (NSFileHandle *)stderrHandle;
- (void)appendOutput:(NSData *)data;
- (void)appendError:(NSData *)data;
- (void)cleanup;
@end


@implementation AMShellWrapper
@synthesize task = _task;
@synthesize delegate = _delegate;
@synthesize workingDirectory = _workingDirectory;
@synthesize environment = _environment;
@synthesize arguments = _arguments;
@synthesize stdinPipe = _stdinPipe;
@synthesize stdoutPipe = _stdoutPipe;
@synthesize stderrPipe = _stderrPipe;
@synthesize stdinHandle = _stdinHandle;
@synthesize stdoutHandle = _stdoutHandle;
@synthesize stderrHandle = _stderrHandle;
@synthesize inputStringEncoding = _inputStringEncoding;
@synthesize outputStringEncoding = _outputStringEncoding;
@synthesize binaryOutput = _binaryOutput;
@synthesize stdoutEmpty = _stdoutEmpty;
@synthesize stderrEmpty = _stderrEmpty;
@synthesize taskDidTerminate = _taskDidTerminate;

// Do basic initialization

- (id)initWithInputPipe:(id)input
             outputPipe:(id)output
              errorPipe:(id)error
       workingDirectory:(NSString *)directoryPath
            environment:(NSDictionary *)env
              arguments:(NSArray *)args
{
	if ((self = [super init])) {
        if (args) {
            _arguments = args;
        }
        if (env) {
            _environment = env;
        }
        if (directoryPath) {
            _workingDirectory = directoryPath;
        }
        if (input) {
            _stdinPipe = input;
        }
        if (output) {
            _stdoutPipe = output;
        }
        if (error) {
            _stderrPipe = error;
        }

		_inputStringEncoding = NSUTF8StringEncoding;
		_outputStringEncoding = NSUTF8StringEncoding;
	}
	return self;
}

// Here's where we actually kick off the process via an NSTask.
- (void)startProcess
{
	BOOL error = NO;
	// We first let the controller know that we are starting
	[self.delegate processStarted:self];
	self.task = [[NSTask alloc] init];
	// The output of stdout and stderr is sent to a pipe so that we can catch it later
	// and send it along to the controller; we redirect stdin too, so that it accepts
	// input from us instead of the console
	if (self.stdinPipe == nil) {
		NSPipe *newPipe = [[NSPipe alloc] init];
		if (newPipe) {
			[self.task setStandardInput:newPipe];
			self.stdinHandle = [[self.task standardInput] fileHandleForWriting];
			// we do NOT retain stdinHandle here since it is retained (and released)
			// by the task standardInput pipe (or so I hope ...)
		} else {
			perror("AMShellWrapper - failed to create pipe for stdIn");
			error = YES;
		}
	} else {
		[self.task setStandardInput:self.stdinPipe];
		if ([self.stdinPipe isKindOfClass:[NSPipe class]])
			self.stdinHandle = [self.stdinPipe fileHandleForWriting];
		else
			self.stdinHandle = self.stdinPipe;
	}
	
	if (self.stdoutPipe == nil) {
		NSPipe *newPipe = [[NSPipe alloc] init];
		if (newPipe) {
			[self.task setStandardOutput:newPipe];
			self.stdoutHandle = [[self.task standardOutput] fileHandleForReading];
		} else {
			perror("AMShellWrapper - failed to create pipe for stdOut");
			error = YES;
		}
	} else {
		[self.task setStandardOutput:self.stdoutPipe];
		self.stdoutHandle = self.stdoutPipe;
	}
	
	if (self.stderrPipe == nil) {
		NSPipe *newPipe = [[NSPipe alloc] init];
		if (newPipe) {
			[self.task setStandardError:newPipe];
			self.stderrHandle = [[self.task standardError] fileHandleForReading];
		} else {
			perror("AMShellWrapper - failed to create pipe for stdErr");
			error = YES;
		}
	} else {
		[self.task setStandardError:self.stderrPipe];
		self.stderrHandle = self.stderrPipe;
	}
	
	if (!error) {
		// setting the current working directory
		if (self.workingDirectory != nil)
			[self.task setCurrentDirectoryPath:self.workingDirectory];
		
		// Setting the environment if available
		if (self.environment != nil)
			[self.task setEnvironment:self.environment];
		
		// The path to the binary is the first argument that was passed in
		[self.task setLaunchPath:self.arguments[0]];
		
		// The rest of the task arguments are just grabbed from the array
		[self.task setArguments:[self.arguments subarrayWithRange:NSMakeRange(1, ([self.arguments count] - 1))]];
		
		// Here we register as an observer of the NSFileHandleReadCompletionNotification,
		// which lets us know when there is data waiting for us to grab it in the task's file
		// handle (the pipe to which we connected stdout and stderr above).
		// -getData: will be called when there is data waiting. The reason we need to do this
		// is because if the file handle gets filled up, the task will block waiting to send
		// data and we'll never get anywhere. So we have to keep reading data from the file
		// handle as we go.
		if (self.stdoutPipe == nil) // we have to handle this ourselves:
			[[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(getData:)
                                                         name:NSFileHandleReadCompletionNotification
                                                       object:self.stdoutHandle];
		
		if (self.stderrPipe == nil) // we have to handle this ourselves:
			[[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(getData:)
                                                         name:NSFileHandleReadCompletionNotification
                                                       object:self.stderrHandle];
		
		// We tell the file handle to go ahead and read in the background asynchronously,
		// and notify us via the callback registered above when we signed up as an observer.
		// The file handle will send a NSFileHandleReadCompletionNotification when it has
		// data that is available.
		[self.stdoutHandle readInBackgroundAndNotify];
		[self.stderrHandle readInBackgroundAndNotify];
		
		// since waiting for the output pipes to run dry seems unreliable in terms of
		// deciding wether the task has died, we go the 'clean' route and wait for a notification
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(taskStopped:)
                                                     name:NSTaskDidTerminateNotification object:self.task];
		
		// we will wait for data in stdout; there may be nothing to receive from stderr
		self.stdoutEmpty = NO;
		self.stderrEmpty = YES;
		
		// launch the task asynchronously
		[self.task launch];
		
		// since the notification center does not retain the observer, make sure
		// we don't get deallocated early
	} else {
		[self performSelector:@selector(cleanup) withObject:nil afterDelay:0];
	}
}

// terminate the task
- (void)stopProcess
{
	[self.task terminate];
}

// If the task ends, there is no more data coming through the file handle even when
// the notification is sent, or the process object is released, then this method is called.
- (void)cleanup
{
	NSData *data;
	int terminationStatus = -1;
	
	if (self.isTaskTerminated) {
		// It is important to clean up after ourselves so that we don't leave potentially
		// deallocated objects as observers in the notification center; this can lead to
		// crashes.
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		
		// Make sure the task has actually stopped!
		//[task terminate];
		
		// NSFileHandle availableData is a blocking read - what were they thinking? :-/
		// Umm - OK. It comes back when the file is closed. So here we go ...
		
		// clear stdout
		while ((data = [self.stdoutHandle availableData]) && [data length]) {
			[self appendOutput:data];
		}
		
		// clear stderr
		while ((data = [self.stderrHandle availableData]) && [data length]) {
			[self appendError:data];
		}
		terminationStatus = [self.task terminationStatus];
	}
	
	// we tell the controller that we finished, via the callback, and then blow away
	// our connection to the controller.  NSTasks are one-shot (not for reuse), so we
	// might as well be too.
	[self.delegate processFinished:self withTerminationStatus:terminationStatus];

	self.delegate = nil;

	// we are done; go ahead and kill us if you like ...
}

// input to stdin
- (void)appendInput:(id)input
{
	if ([input isKindOfClass:[NSString class]]) {
		[self.stdinHandle writeData:[input dataUsingEncoding:self.inputStringEncoding]];
	} else if ([input isKindOfClass:[NSData class]]) {
		[self.stdinHandle writeData:input];
	} else {
		NSLog(@"AMShellWrapper -appendInput expects NSString or NSData parameter (found: %@)", NSStringFromClass([input class]));
	}

}

- (void)closeInput
{
	[self.stdinHandle closeFile];
}

- (void)appendOutput:(NSData *)data
{
	if (self.isBinaryOutput) {
		[self.delegate process:self appendOutput:data];
	} else {
		NSString *outputString = [[NSString alloc] initWithData:data encoding:self.outputStringEncoding];
		if (outputString) {
			[self.delegate process:self appendOutput:outputString];
		} else {
			NSLog(@"AMShellWrapper - not able to encode output. Specified encoding: %u", (unsigned int)self.outputStringEncoding);
		}
	}
}

- (void)appendError:(NSData *)data
{
	NSString *errorString = [[NSString alloc] initWithData:data encoding:self.outputStringEncoding];
	if (errorString) {
		[self.delegate process:self appendError:errorString];
	} else {
		NSLog(@"AMShellWrapper - not able to encode output. Specified encoding: %u", (unsigned int)self.outputStringEncoding);
	}
}

// This method is called asynchronously when data is available from the task's file handle.
// We just pass the data along to the controller as an NSString.
- (void)getData:(NSNotification *)aNotification
{
	NSData *data;
	id notificationObject;
	
	notificationObject = [aNotification object];
	data = [aNotification userInfo][NSFileHandleNotificationDataItem];
	
	// If the length of the data is zero, then the task is basically over - there is nothing
	// more to get from the handle so we may as well shut down.
	if ([data length]) {
		// Send the data on to the controller; we can't just use +stringWithUTF8String: here
		// because -[data bytes] is not necessarily a properly terminated string.
		// -initWithData:encoding: on the other hand checks -[data length]
		if ([notificationObject isEqualTo:self.stdoutHandle]) {
			[self appendOutput:data];
			self.stdoutEmpty = NO;
		} else if ([notificationObject isEqualTo:self.stderrHandle]) {
			[self appendError:data];
			self.stderrEmpty = NO;
		} else {
			// this should really not happen ...
		}
		
		// we need to schedule the file handle go read more data in the background again.
		[notificationObject readInBackgroundAndNotify];
	} else {
		if ([notificationObject isEqualTo:self.stdoutHandle]) {
			self.stdoutEmpty = YES;
		} else if ([notificationObject isEqualTo:self.stderrHandle]) {
			self.stderrEmpty = YES;
		} else {
			// this should really not happen ...
		}
		// if there is no more data in the pipe AND the task did terminate, we are done
		if (self.isStdoutEmpty && self.isStderrEmpty && self.isTaskTerminated) {
			[self cleanup];
		}
	}
	
	// we need to schedule the file handle go read more data in the background again.
	//[notificationObject readInBackgroundAndNotify];  
}

- (void)taskStopped:(NSNotification *)aNotification
{
	if (!self.isTaskTerminated) {
		self.taskDidTerminate = YES;
		// did we receive all data?
		if (self.isStdoutEmpty && self.isStderrEmpty) {
			// no data left - do the clean up
			[self cleanup];
		}
	}
}


@end
