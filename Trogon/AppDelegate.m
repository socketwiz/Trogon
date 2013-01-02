//
//  AppDelegate.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

@implementation AppDelegate
@synthesize sheetControllerProgress = _sheetControllerProgress;
@synthesize sheetControllerRvm = _sheetControllerRvm;
@synthesize sheetControllerRubyDoc = _sheetControllerRubyDoc;
@synthesize sheetControllerGemServer = _sheetControllerGemServer;
@synthesize window = _window;
@synthesize rubys = _rvms;
@synthesize gemsets = _gemsets;
@synthesize gems = _gems;
@synthesize ruby = _ruby;
@synthesize taskOutput = _taskOutput;
@synthesize shellWrapper = _shellWrapper;

@synthesize tblRvm = _tblRvm;
@synthesize tblGemset = _tblGemset;
@synthesize tblGem = _tblGem;

@synthesize aryRubyController = _aryRubyController;
@synthesize aryGemSetsController = _aryGemSetsController;
@synthesize aryGemsController = _aryGemsController;

- (id)init {
    self = [super init];
    if (self) {
        _rvms = [[NSMutableArray alloc] init];
        _gemsets = [[NSMutableArray alloc] init];
        _gems = [[NSMutableArray alloc] init];
        _taskOutput = [[NSMutableString alloc] init];
        
        _ruby = [[Ruby alloc] init];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addRubysNotification:)
                                                 name:@"TrogonAddRuby" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addGemsetNotification:)
                                                 name:@"TrogonAddGemset" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addGemNotification:)
                                                 name:@"TrogonAddGem" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addRvmNotification:)
                                                 name:@"TrogonAddRvm" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(launchRdocBrowser:)
                                                 name:@"TrogonLaunchRdocBrowser" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startGemServer:)
                                                 name:@"TrogonStartGemServer" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopGemServer:)
                                                 name:@"TrogonStopGemServer" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(launchTerminalNotification:)
                                                 name:@"TrogonLaunchTerminal" 
                                               object:nil];

    return self;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSError *error = nil;
	if (![self blessHelperWithLabel:@"com.lark.software.TrogonHelper" error:&error]) {
        NSLog(@"Failed to bless TrogonHelper. Error: %@", error);
        return;
    }
    
    NSLog(@"Helper available.");
    
    xpc_connection_t connection = xpc_connection_create_mach_service("com.lark.software.TrogonHelper", NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    
    if (!connection) {
        NSLog(@"Failed to create XPC connection.");
        return;
    }
    
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        
        if (type == XPC_TYPE_ERROR) {
            
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                NSLog(@"XPC connection interupted.");
                
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
                NSLog(@"XPC connection invalid, releasing.");
                xpc_release(connection);
                
            } else {
                NSLog(@"Unexpected XPC connection error.");
            }
            
        } else {
            NSLog(@"Unexpected XPC connection event.");
        }
    });
    
    xpc_connection_resume(connection);
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    const char* request = "Hi there, helper service.";
    xpc_dictionary_set_string(message, "request", request);
    
    NSLog(@"Sending request: %s", request);
    
    xpc_connection_send_message_with_reply(connection, message, dispatch_get_main_queue(), ^(xpc_object_t event) {
        const char* response = xpc_dictionary_get_string(event, "reply");
        NSLog(@"Received response: %s.", response);
    });

    [self reloadRubys];
}

- (BOOL)blessHelperWithLabel:(NSString *)label
                       error:(NSError **)error {
	BOOL result = NO;
    
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				|
                                        kAuthorizationFlagInteractionAllowed	|
                                        kAuthorizationFlagPreAuthorize			|
                                        kAuthorizationFlagExtendRights;
    
	AuthorizationRef authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
	if (status != errAuthorizationSuccess) {
        NSLog(@"Failed to create AuthorizationRef. Error code: %i", status);
	}
    else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
        CFErrorRef cfError = NULL;
		result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, (CFErrorRef *)&cfError);

        if (!result && error)
        {
            *error = CFBridgingRelease(cfError);
        }
	}
	
	return result;
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
    // we need to remove the observer otherwise if we attempt to run simultaneous tasks,
    // a notification will try to run against an observer that no longer exists
    // and create an exception
    [[NSNotificationCenter defaultCenter] removeObserver:self.shellWrapper];

//	[progressIndicator stopAnimation:self];

    switch (currentState) {
        case READ_RUBYS:
            [self readRubyData:self.taskOutput];
            break;
        case READ_GEMSETS:
            [self readGemsetList:self.taskOutput];
            break;
        case READ_GEMS:
            [self readGemList:self.taskOutput];
            break;
        case READ_RUBYDOCS:
            [self readRubyDocs:self.taskOutput];
            break;
            
        default:
            break;
    }
   
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

    // we need to remove the observer otherwise if we attempt to run simultaneous tasks,
    // a notification will try to run against an observer that no longer exists
    // and create an exception
    [[NSNotificationCenter defaultCenter] removeObserver:self.shellWrapper];
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

    if (self.shellWrapper) {
        // we need to remove the observer otherwise if we attempt to run simultaneous tasks,
        // a notification will try to run against an observer that no longer exists
        // and create an exception
		[[NSNotificationCenter defaultCenter] removeObserver:self.shellWrapper];
    }
    
    self.shellWrapper = wrapper;
    
    @try {
        if (self.shellWrapper) {
            [self.shellWrapper setOutputStringEncoding:NSUTF8StringEncoding];
            [self.shellWrapper startProcess];
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

- (void)addRubysNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshRubysNotification:)
                                                 name:@"TrogonRefreshRuby"
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_ruby"];
    currentState = READ_RUBYS;    
    
    Ruby *ruby = [[notification userInfo] objectForKey:@"ruby"];
    
    NSString *rubyName = [ruby.name stringByTrimmingTrailingWhitespace];
    rubyName = [rubyName stringByReplacingOccurrencesOfString:@"[" withString:@""];
    rubyName = [rubyName stringByReplacingOccurrencesOfString:@"]" withString:@""];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm install %@", rvmPath, rubyName];
    [self runTask:rvmCmd];
}

- (void)addGemsetNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsetsNotification:)
                                                 name:@"TrogonRefreshGemset" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_gemset"];
    
    NSString *gemset = [[notification userInfo] objectForKey:@"gemset"];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset create %@", rvmPath, self.ruby.name, gemset];
    
    [self runTask:rvmCmd];
}

- (void)addGemNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonRefreshGem" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_gem"];
    
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
    NSString *gem = [[notification userInfo] objectForKey:@"gem"];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem install %@", rvmPath, self.ruby.name, gemset.name, gem];
    [self runTask:rvmCmd];
}

- (void)addRvmNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonRefreshRuby"
                                               object:nil];
    
    NSString *rvmCmd = [NSString stringWithFormat:@"tell application \"Terminal\" to (do script \"bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)\" in window 1) activate"];
    
    NSDictionary *errorInfo;
    NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:rvmCmd];
    [scriptObject executeAndReturnError:&errorInfo];
    
    if (errorInfo) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        NSString *errorFromAppleScript = [NSString stringWithFormat:@"AppleScript Error: %@", [errorInfo valueForKey:@"NSAppleScriptErrorMessage"]];
        [errorDetail setValue:errorFromAppleScript forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"trogon" code:100 userInfo:errorDetail];
        
        NSLog(@"AppleScript Command: %@", rvmCmd);
        NSLog(@"%@", errorFromAppleScript);
        
        [NSApp presentError:error];
    }
}

- (void)addRubyDocNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonAddRubyDoc" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_ruby_doc"];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs generate", rvmPath, self.ruby.name];
    [self runTask:rvmCmd];
}

- (void)refreshRubysNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"TrogonRefreshRuby" 
                                                  object:nil];
    
    [self reloadRubys];
}

- (void)refreshGemsetsNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"TrogonRefreshGemset" 
                                                  object:nil];
    
    [self reloadGemsetList];
}

- (void)refreshGemsNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"TrogonRefreshGem" 
                                                  object:nil];
    
    [self reloadGemList];
}

- (void)launchRdocBrowser:(NSNotification *)notification {
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        return;
    }
    
    self.ruby = [[self.aryRubyController selectedObjects] objectAtIndex:0];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs open", rvmPath, self.ruby.name];
    [self runTask:rvmCmd];
}

- (void)startGemServer:(NSNotification *)notification {
    NSString *port = (NSString *)[[notification userInfo] objectForKey:@"port"];
    
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
        
    self.ruby = [[self.aryRubyController selectedObjects] objectAtIndex:0];
    GemSet *aGemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem server --port=%@", rvmPath, self.ruby.name, aGemset.name, port];
    [self runTask:rvmCmd];
}

- (void)stopGemServer:(NSNotification *)notification {
    [self.shellWrapper stopProcess];
}

- (void)reloadRubys {
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rvmPath]) {
        currentState = READ_RUBYS;
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list", rvmPath];
        
        [self runTask:rvmCmd];
    }
    else {
        NSLog(@"RVM not installed");
        [_sheetControllerRvm add:self];
    }
}

-(void)readRubyData: (NSString *)output {
    [self.rubys removeAllObjects];
    
    // pull just the rubys out of the mess we get back
    for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
        // first line is always "rvm rubies" and we don't want it
        if ([line length] > 0 && [line localizedCompare:@"rvm rubies"] != NSOrderedSame) {
            Ruby *aRvm = [[Ruby alloc] init];
            NSArray *rubys = [[line stringByTrimmingLeadingWhitespace] componentsSeparatedByString:@" "];
            
            if ([rubys count] > 1) {
                /* # => - current */
                /* # =* - current && default */
                /* #  * - default */
                
                if ([[rubys objectAtIndex:0] localizedCompare:@"=>"] == NSOrderedSame) {
                    // this is the current ruby
                    aRvm.name = [rubys objectAtIndex:1];
                }
                else if ([[rubys objectAtIndex:0] localizedCompare:@"=*"] == NSOrderedSame) {
                    // this is the current and default ruby set
                    aRvm.name = [rubys objectAtIndex:1];
                }
                else if ([[rubys objectAtIndex:0] localizedCompare:@"#"] == NSOrderedSame) {
                    continue; // brand new install, no rubies installed
                }
                else {
                    // 1 or more rubies installed, none set as default
                    aRvm.name = [rubys objectAtIndex:0];
                }
                [self.rubys addObject:aRvm];
                self.rubys = self.rubys;
            }
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([aNotification object] == _tblRvm) {
        if ([[self.aryRubyController selectedObjects] count] == 0) {
            return;
        }

        [self reloadGemsetList];
    }

	if ([aNotification object] == _tblGemset) {
        if ([[self.aryGemSetsController selectedObjects] count] == 0) {
            return;
        }
        
        [self reloadGemList];
    }
}

- (void)reloadGemsetList {
    self.ruby = [[self.aryRubyController selectedObjects] objectAtIndex:0];

    currentState = READ_GEMSETS;
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset list", rvmPath, self.ruby.name];
    [self runTask:rvmCmd];
}

- (void)readGemsetList: (NSString *)output {
    [self.gemsets removeAllObjects];
    
    // pull just the ruby gemsets out of the mess we get back
    NSInteger cnt = 0;
    for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
        if (cnt < 2 || [line length] == 0) { // skip first two lines or empty lines
            cnt++;
            continue;
        }

        NSArray *gemsets = [[line stringByTrimmingLeadingWhitespace] componentsSeparatedByString:@" "];

        GemSet *aGemSet = [[GemSet alloc] init];
        if ([gemsets count] > 1) {
            if ([[gemsets objectAtIndex:0] localizedCompare:@"=>"] == NSOrderedSame) {
                // this is the default gemset
                aGemSet.name = [gemsets objectAtIndex:1];
                if ([aGemSet.name localizedCompare:@"(default)"] == NSOrderedSame) {
                    aGemSet.name = @"default";
                }
            }
        }
        else {
            aGemSet.name = [line stringByTrimmingLeadingWhitespace];
        }

        [self.gemsets addObject:aGemSet];
        self.gemsets = self.gemsets;
    }
}

- (void)reloadGemList {
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
    
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    [self.tblGem reloadData];

    currentState = READ_GEMS;
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem list", rvmPath, self.ruby.name, gemset.name];
    [self runTask:rvmCmd];
}

- (void)readGemList:(NSString *)output {
    [self.gems removeAllObjects];
    
    NSInteger gemCount = 0;
    // pull just the ruby gems out of the mess we get back
    for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
        if ([line length] == 0) { // skip empty lines
            continue;
        }
        if ([line hasPrefix:@"Using"]) {
            continue;
        }
        
        Gem *aGem = [[Gem alloc] init];
        aGem.name = [line stringByTrimmingLeadingWhitespace];
        [self.gems addObject:aGem];
        self.gems = self.gems;
        gemCount++;
    }

    if ([output length] == 1) {
        Gem *aGem = [[Gem alloc] init];
        aGem.name = @"No gems for this gemset";
        [self.gems addObject:aGem];
        self.gems = self.gems;
    }
}

- (void)readRubyDocs:(NSString *)output {
    if ([output hasPrefix:@"ERROR: rdoc docs are missing"]) {
        [_sheetControllerRubyDoc add:self];
    }
}

- (IBAction)btnRemoveRuby:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshRubysNotification:)
                                                 name:@"TrogonRefreshRuby"
                                               object:nil];

    [_sheetControllerProgress add:self action:@"uninstall_ruby"];
    
    Ruby *rvm = [[self.aryRubyController selectedObjects] objectAtIndex:0];
    
    currentState = NO_HANDLER;
    NSString *ruby = [rvm.name stringByTrimmingTrailingWhitespace];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm remove %@ --archive", rvmPath, ruby];
    [self runTask:rvmCmd];
}

- (IBAction)btnRemoveGemset:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsetsNotification:)
                                                 name:@"TrogonRefreshGemset" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"uninstall_gemset"];

    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    currentState = NO_HANDLER;
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm --force gemset delete %@", rvmPath, self.ruby.name, gemset.name];
    [self runTask:rvmCmd];
}

- (IBAction)btnRemoveGem:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonRefreshGem" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"uninstall_gem"];
    
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
    Gem *gem = [[self.aryGemsController selectedObjects] objectAtIndex:0];
    
    currentState = NO_HANDLER;
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem uninstall %@", rvmPath, self.ruby.name, gemset.name, gem.nameWithoutVersion];
    [self runTask:rvmCmd];
}

- (IBAction)btnLaunchTerminal:(id)sender {
    [self launchTerminal];
}

- (IBAction)btnCreateRvmrc:(id)sender {
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"ERROR" 
                                         defaultButton:@"OK" 
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please select a ruby from the list"];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"ERROR" 
                                         defaultButton:@"OK" 
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please select a gemset from the list"];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }

    NSOpenPanel * oPanel = [NSOpenPanel openPanel];
    
    [oPanel setCanChooseFiles:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];

    [oPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode)
    {
        NSURL *pathToFile = nil;

        if (returnCode == NSOKButton) {
            pathToFile = [[oPanel URLs] objectAtIndex:0];

            self.ruby = [[self.aryRubyController selectedObjects] objectAtIndex:0];
            GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

            NSString *ruby = [self.ruby.name stringByTrimmingTrailingWhitespace];
            
            currentState = NO_HANDLER;
            NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
            NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && cd %@ && rvm --rvmrc --create %@@%@", rvmPath, [pathToFile path], ruby, gemset.name];
            [self runTask:rvmCmd];

            [self performSelectorOnMainThread:@selector(rvmrcInstalled:)
                                   withObject:pathToFile 
                                waitUntilDone:NO];


        }        
    }];
}

- (IBAction)btnLaunchRubyDocs:(id)sender {
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"ERROR" 
                                         defaultButton:@"OK" 
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please select a ruby from the list"];

        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    
    self.ruby = [[self.aryRubyController selectedObjects] objectAtIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addRubyDocNotification:)
                                                 name:@"TrogonAddRubyDoc" 
                                               object:nil];
    
    currentState = READ_RUBYDOCS;
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs open", rvmPath, self.ruby.name];
    [self runTask:rvmCmd];
}

- (IBAction)btnLaunchGemServer:(id)sender {
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
    
    self.ruby = [[self.aryRubyController selectedObjects] objectAtIndex:0];
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    [_sheetControllerGemServer add:self ruby:self.ruby.name gem:gemset.name];
}

- (void)rvmrcInstalled:(NSURL *)pathToFile {
    NSAlert *alert = [NSAlert alertWithMessageText:@"SUCCESS" 
                                     defaultButton:@"OK" 
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@".rvmrc was created at: %@", [pathToFile path]];

    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)launchTerminalNotification:(NSNotification *)aNotification
{
    [self launchTerminal];
}

- (void)launchTerminal {
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"ERROR" 
                                         defaultButton:@"OK" 
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please select a ruby from the list"];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"ERROR" 
                                         defaultButton:@"OK" 
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please select a gemset from the list"];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    
    Ruby *rvm = [[self.aryRubyController selectedObjects] objectAtIndex:0];
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
    
    NSString *ruby = [rvm.name stringByTrimmingTrailingWhitespace];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"tell application \"Terminal\" to (do script \"source %@ && rvm %@ && rvm gemset use %@\" in window 1) activate", rvmPath, ruby, gemset.name];
    
    NSDictionary *errorInfo;
    NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:rvmCmd];
    [scriptObject executeAndReturnError:&errorInfo];
    
    if (errorInfo) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        NSString *errorFromAppleScript = [NSString stringWithFormat:@"AppleScript Error: %@", [errorInfo valueForKey:@"NSAppleScriptErrorMessage"]];
        [errorDetail setValue:errorFromAppleScript forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"trogon" code:100 userInfo:errorDetail];
        
        NSLog(@"AppleScript Command: %@", rvmCmd);
        NSLog(@"%@", errorFromAppleScript);
        
        [NSApp presentError:error];
    }
}
@end
