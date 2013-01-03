//
//  AMShellWrapper.h
//  CommX
//
//  Created by Andreas on 2002-04-24.
//  Based on TaskWrapper from Apple
//
//  2002-06-17 Andreas Mayer
//  - used defines for keys in AMShellWrapperProcessFinishedNotification userInfo dictionary
//  2002-08-30 Andreas Mayer
//  - added setInputStringEncoding: and setOutputStringEncoding:
//  2009-09-07 Andreas Mayer
//  - renamed protocol to AMShellWrapperDelegate
//  - added process parameter to append... methods
//  - changed parameter type of processStarted: and processFinished: methods
//  - removed controller argument from initializer
//  - added binaryOutput option; changed -process:appendOutput: accordingly
//  - appendInput now accepts input as NSData or NSString


#import <Foundation/Foundation.h>

#define AMShellWrapperProcessFinishedNotification @"AMShellWrapperProcessFinishedNotification"
#define AMShellWrapperProcessFinishedNotificationTaskKey @"AMShellWrapperProcessFinishedNotificationTaskKey"
#define AMShellWrapperProcessFinishedNotificationTerminationStatusKey @"AMShellWrapperProcessFinishedNotificationTerminationStatusKey"


@class AMShellWrapper;


@protocol AMShellWrapperDelegate
// implement this protocol to control your AMShellWrapper object:

- (void)process:(AMShellWrapper *)wrapper appendOutput:(id)output;
// output from stdout

- (void)process:(AMShellWrapper *)wrapper appendError:(NSString *)error;
// output from stderr

- (void)processStarted:(AMShellWrapper *)wrapper;
// This method is a callback which your controller can use to do other initialization
// when a process is launched.

- (void)processFinished:(AMShellWrapper *)wrapper withTerminationStatus:(int)resultCode;
// This method is a callback which your controller can use to do other cleanup
// when a process is halted.

// AMShellWrapper posts a AMShellWrapperProcessFinishedNotification when a process finished.
// The userInfo of the notification contains the corresponding NSTask ((NSTask *), key @"task")
// and the result code ((NSNumber *), key @"resultCode")
// ! notification removed since it prevented the task from getting deallocated

@end


@interface AMShellWrapper : NSObject {
}

@property (nonatomic, strong) NSTask *task;
@property (nonatomic, weak) id <AMShellWrapperDelegate> delegate;
@property (nonatomic, copy) NSString *workingDirectory;
@property (nonatomic, strong) NSDictionary *environment;
@property (nonatomic, strong) NSArray *arguments;
@property (nonatomic, strong) id stdinPipe;
@property (nonatomic, strong) id stdoutPipe;
@property (nonatomic, strong) id stderrPipe;
@property (nonatomic, strong) NSFileHandle *stdinHandle;
@property (nonatomic, strong) NSFileHandle *stdoutHandle;
@property (nonatomic, strong) NSFileHandle *stderrHandle;
@property (nonatomic) NSStringEncoding inputStringEncoding;
@property (nonatomic) NSStringEncoding outputStringEncoding;
@property (nonatomic, getter=isBinaryOutput) BOOL binaryOutput;
@property (nonatomic, getter=isStdoutEmpty) BOOL stdoutEmpty;
@property (nonatomic, getter=isStderrEmpty) BOOL stderrEmpty;
@property (nonatomic, getter=isTaskTerminated) BOOL taskDidTerminate;

- (id)initWithInputPipe:(id)input
             outputPipe:(id)output
              errorPipe:(id)error
       workingDirectory:(NSString *)directoryPath
            environment:(NSDictionary *)env
              arguments:(NSArray *)args;
// This is the designated initializer
// The first argument should be the path to the executable to launch with the NSTask.
// Allowed for stdin/stdout and stderr are
// - values of type NSFileHandle or
// - NSPipe or
// - nil, in which case this wrapper class automatically connects to the callbacks
//   and appendInput: method and provides asynchronous feedback notifications.
// The environment argument may be nil in which case the environment is inherited from
// the calling process.

- (void)startProcess;
// This method launches the process, setting up asynchronous feedback notifications.

- (void)stopProcess;
// This method stops the process, stoping asynchronous feedback notifications.

- (void)appendInput:(id)input;
// input to stdin
- (void)closeInput;


@end
