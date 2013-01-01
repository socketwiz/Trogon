//
//  RubySheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "RubySheetController.h"
#import "NSString+trimTrailingWhitespace.h"

@implementation RubySheetController
@synthesize aryRvmsController;
@synthesize documentWindow;
@synthesize objectSheet;
@synthesize rubys = _rubys;
@synthesize outputRuby = _outputRuby;
@synthesize taskOutput = _taskOutput;


- (void)setShellWrapper:(AMShellWrapper *)newShellWrapper
{
	if (newShellWrapper != shellWrapper) {
		shellWrapper = newShellWrapper;
	}
}

// ============================================================
// conforming to the AMShellWrapperDelegate protocol:
// ============================================================

// output from stdout
- (void)process:(AMShellWrapper *)wrapper appendOutput:(id)output
{
    [self.taskOutput appendString:output];
}

// output from stderr
- (void)process:(AMShellWrapper *)wrapper appendError:(NSString *)error
{
    NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:error forKey:@"NSTaskErrorMessage"];
    
    if (errorInfo) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        NSString *errorFromNSTask = [NSString stringWithFormat:@"NSTask Error: %@", [errorInfo valueForKey:@"NSTaskErrorMessage"]];
        [errorDetail setValue:errorFromNSTask forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"trogon" code:100 userInfo:errorDetail];
        
        NSLog(@"%@", errorFromNSTask);
        
        [NSApp presentError:error];
    }
}

// This method is a callback which your controller can use to do other initialization
// when a process is launched.
- (void)processStarted:(AMShellWrapper *)wrapper
{
    //	[progressIndicator startAnimation:self];
}

// This method is a callback which your controller can use to do other cleanup
// when a process is halted.
- (void)processFinished:(AMShellWrapper *)wrapper withTerminationStatus:(int)resultCode
{
	[self setShellWrapper:nil];
    //	[progressIndicator stopAnimation:self];
    
    [self readAvailableRubys:self.taskOutput];
    
    [self.taskOutput setString:@""];
}

- (void)processLaunchException:(NSException *)exception
{
    //	[progressIndicator stopAnimation:self];
    if (exception) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        NSString *errorFromNSTask = [exception name];
        [errorDetail setValue:errorFromNSTask forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"trogon" code:100 userInfo:errorDetail];
        
        NSLog(@"%@", errorFromNSTask);
        
        [NSApp presentError:error];
    }
	[self setShellWrapper:nil];
}

// ============================================================
// END conforming to the AMShellWrapperDelegate protocol:
// ============================================================

-(void)runTask:(NSString *)rvmCmd {
    AMShellWrapper *wrapper = [[AMShellWrapper alloc] initWithInputPipe:nil
                                                             outputPipe:nil
                                                              errorPipe:nil
                                                       workingDirectory:@"."
                                                            environment:nil
                                                              arguments:[NSArray arrayWithObjects:@"/bin/bash", @"-c", rvmCmd, nil]
                                                                context:NULL];
    [wrapper setDelegate:self];
    [self setShellWrapper:wrapper];
    
    @try {
        if (shellWrapper) {
            [shellWrapper setOutputStringEncoding:NSUTF8StringEncoding];
            [shellWrapper startProcess];
        } else {
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:@"Error creating shell wrapper" forKey:@"NSTaskErrorMessage"];
            
            if (errorInfo) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                NSString *errorFromNSTask = [NSString stringWithFormat:@"NSTask Error: %@", [errorInfo valueForKey:@"NSTaskErrorMessage"]];
                [errorDetail setValue:errorFromNSTask forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"trogon" code:100 userInfo:errorDetail];
                
                NSLog(@"NSTask Command: %@", rvmCmd);
                NSLog(@"%@", errorFromNSTask);
                
                [NSApp presentError:error];
            }
        }
    }
    @catch (NSException *localException) {
        NSLog(@"Caught %@: %@", [localException name], [localException reason]);
        [self processLaunchException:localException];
    }
}

-(void)readAvailableRubys: (NSString *)output {
    [self.outputRuby appendString:output];
    
    // pull just the rubys out of the mess we get back
    for (NSString *line in [self.outputRuby componentsSeparatedByString:@"\n"]) {
        if ([line length] > 0 && ![line hasPrefix:@"#"]) {
            Ruby *aRuby = [[Ruby alloc] init];
            aRuby.name = line;
            [_rubys addObject:aRuby];
            self.rubys = _rubys;
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        _rubys = [[NSMutableArray alloc] init];
        _outputRuby = [[NSMutableString alloc] init];
        _taskOutput = [[NSMutableString alloc] init];
    }
    return self;
}

- (IBAction)add:(id)sender {
    if (objectSheet == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"RubySheet" bundle:myBundle];
        
        BOOL success = [nib instantiateNibWithOwner:self topLevelObjects:nil];
        if (success != YES) {
            NSError *error;
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Unable to load RubySheet.xib" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"TrogonRubySheetDomainError" code:100 userInfo:errorDetail];
            [NSApp presentError:error];
            NSLog(@"%@", [errorDetail valueForKey:NSLocalizedDescriptionKey]);

            return;
        }
    }
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list known", rvmPath];
    [self runTask:rvmCmd];
    
    [NSApp beginSheet:objectSheet
       modalForWindow:[documentWindow window]
        modalDelegate:self
       didEndSelector:@selector(objectSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (IBAction)cancel:(id)sender {
    [NSApp endSheet:objectSheet returnCode:NSCancelButton];
}

- (IBAction)complete:(id)sender {
    [NSApp endSheet:objectSheet returnCode:NSOKButton];
}

- (void)objectSheetDidEnd:(NSWindow *)sheet
               returnCode:(int)returnCode
              contextInfo:(void  *)contextInfo {
    
    if (returnCode == NSOKButton) {
        Ruby *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
        NSDictionary *info = [NSDictionary dictionaryWithObject:rvm forKey:@"ruby"];
        
        // we need to cleanup _before_ we send the notification below to create a new sheet
        // otherwise things get wonky because the new sheet will get created before this one
        // is cleaned up, then when you dimsiss the new sheet, this one persists and you can't 
        // get rid of it :(
        [objectSheet orderOut:self];

        // send it to the AppDelegate so we can display a progress sheet
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonAddRuby"
                                                            object:self
                                                          userInfo:info];        
    }
    else {
        [objectSheet orderOut:self];
    }
}

@end
