//
//  AppDelegate.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "AppDelegate.h"
#import "ScriptQueue.h"
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
@synthesize scriptQueue = _scriptQueue;
@synthesize currentTask = _currentTask;

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
        _scriptQueue = [[ScriptQueue alloc] init];
        
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
    [self.scriptQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];

    [self reloadRubys];
}

- (void)setupHelper
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

-(void)runTask {
    if ([[self.scriptQueue operations] count] > 0) {
        // cancel any currently running task before starting a new one
        for (NSOperation *operation in [self.scriptQueue operations]) {
            [operation cancel];
        }
    }

    [self.scriptQueue addOperation:self.currentTask];
	state = TrogonTaskRunning;
}

//
// observeValueForKeyPath:ofObject:change:context:
//
// Reponds to changes in the ScriptQueue steps or the selected step
//
// Parameters:
//    keyPath - the property
//    object - the object
//    change - the change
//    context - the context
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"operations"])
	{
        if ([self.scriptQueue.operations count] == 0) {
            [self performSelectorOnMainThread:@selector(taskComplete)
                                   withObject:nil waitUntilDone:NO];
        }
        
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change
                          context:context];
}

- (void)taskComplete
{
    // ScriptValue should always be the last element
    NSString *value = [[self.currentTask argumentsArray] objectAtIndex:[[self.currentTask argumentsArray] count] - 1];
    NSString *resolvedString = [[self currentTask] resolvedScriptValueForValue:value];
    
    if ([resolvedString localizedCompare:@"<ScriptValue: rvmList>"] == NSOrderedSame) {
        [self readRubyData:[self.currentTask outputString]];
    }
    if ([resolvedString localizedCompare:@"<ScriptValue: rvmGemList>"] == NSOrderedSame) {
        [self readGemList:[self.currentTask outputString]];
    }
    if ([resolvedString localizedCompare:@"<ScriptValue: rvmGemsetList>"] == NSOrderedSame) {
        [self readGemsetList:[self.currentTask outputString]];
    }
    if ([resolvedString localizedCompare:@"<ScriptValue: rvmDocsOpen>"] == NSOrderedSame) {
        [self readRubyDocs:[self.currentTask outputString]];
    }
}

- (void)addRubysNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshRubysNotification:)
                                                 name:@"TrogonRefreshRuby"
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_ruby"];
    
    Ruby *ruby = [notification userInfo][@"ruby"];
    
    NSString *rubyName = [ruby.name stringByTrimmingTrailingWhitespace];
    rubyName = [rubyName stringByReplacingOccurrencesOfString:@"[" withString:@""];
    rubyName = [rubyName stringByReplacingOccurrencesOfString:@"]" withString:@""];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm install %@", rvmPath, rubyName];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmInstall"],
                        nil];

    [self runTask];
}

- (void)addGemsetNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsetsNotification:)
                                                 name:@"TrogonRefreshGemset" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_gemset"];
    
    NSString *gemset = [notification userInfo][@"gemset"];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset create %@", rvmPath, self.ruby.name, gemset];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmGemsetCreate"],
                        nil];
    
    [self runTask];
}

- (void)addGemNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonRefreshGem" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_gem"];
    
    GemSet *gemset = [self.aryGemSetsController selectedObjects][0];
    NSString *gem = [notification userInfo][@"gem"];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem install %@", rvmPath, self.ruby.name, gemset.name, gem];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmGemInstall"],
                        nil];
    
    [self runTask];
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
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmDocsGenerate"],
                        nil];
    
    [self runTask];
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
    
    self.ruby = [self.aryRubyController selectedObjects][0];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs open", rvmPath, self.ruby.name];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmDocsOpen"],
                        nil];
    
    [self runTask];
}

- (void)startGemServer:(NSNotification *)notification {
    NSString *port = (NSString *)[notification userInfo][@"port"];
    
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
        
    self.ruby = [self.aryRubyController selectedObjects][0];
    GemSet *aGemset = [self.aryGemSetsController selectedObjects][0];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem server --port=%@", rvmPath, self.ruby.name, aGemset.name, port];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmGemServer"],
                        nil];
    
    [self runTask];
}

- (void)stopGemServer:(NSNotification *)notification {
    if ([[scriptQueue operations] count] > 0) {
        for (NSOperation *operation in [scriptQueue operations]) {
            [operation cancel];
        }
    }
}

- (void)reloadRubys {
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rvmPath]) {
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list", rvmPath];
        self.currentTask = [TaskStep taskStepWithCommandLine:
                            @"/bin/bash",
                            @"-c",
                            rvmCmd,
                            [ScriptValue scriptValueWithKey:@"rvmList"],
                            nil];
        
        [self runTask];
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
                
                if ([rubys[0] localizedCompare:@"=>"] == NSOrderedSame) {
                    // this is the current ruby
                    aRvm.name = rubys[1];
                }
                else if ([rubys[0] localizedCompare:@"=*"] == NSOrderedSame) {
                    // this is the current and default ruby set
                    aRvm.name = rubys[1];
                }
                else if ([rubys[0] localizedCompare:@"#"] == NSOrderedSame) {
                    continue; // brand new install, no rubies installed
                }
                else {
                    // 1 or more rubies installed, none set as default
                    aRvm.name = rubys[0];
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
    self.ruby = [self.aryRubyController selectedObjects][0];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset list", rvmPath, self.ruby.name];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmGemsetList"],
                        nil];
    
    [self runTask];
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
            if ([gemsets[0] localizedCompare:@"=>"] == NSOrderedSame) {
                // this is the default gemset
                aGemSet.name = gemsets[1];
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
    
    GemSet *gemset = [self.aryGemSetsController selectedObjects][0];

    [self.tblGem reloadData];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem list", rvmPath, self.ruby.name, gemset.name];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmGemList"],
                        nil];
    
    [self runTask];
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
    
    Ruby *rvm = [self.aryRubyController selectedObjects][0];
    
    NSString *ruby = [rvm.name stringByTrimmingTrailingWhitespace];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm remove %@ --archive", rvmPath, ruby];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmRemove"],
                        nil];
    
    [self runTask];
}

- (IBAction)btnRemoveGemset:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsetsNotification:)
                                                 name:@"TrogonRefreshGemset" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"uninstall_gemset"];

    GemSet *gemset = [self.aryGemSetsController selectedObjects][0];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm --force gemset delete %@", rvmPath, self.ruby.name, gemset.name];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmGemsetDelete"],
                        nil];
    
    [self runTask];
}

- (IBAction)btnRemoveGem:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonRefreshGem" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"uninstall_gem"];
    
    GemSet *gemset = [self.aryGemSetsController selectedObjects][0];
    Gem *gem = [self.aryGemsController selectedObjects][0];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem uninstall %@", rvmPath, self.ruby.name, gemset.name, gem.nameWithoutVersion];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmGemUninstall"],
                        nil];
    
    [self runTask];
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
            pathToFile = [oPanel URLs][0];

            self.ruby = [self.aryRubyController selectedObjects][0];
            GemSet *gemset = [self.aryGemSetsController selectedObjects][0];

            NSString *ruby = [self.ruby.name stringByTrimmingTrailingWhitespace];
            
            NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
            NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && cd %@ && rvm --rvmrc --create %@@%@", rvmPath, [pathToFile path], ruby, gemset.name];
            self.currentTask = [TaskStep taskStepWithCommandLine:
                                @"/bin/bash",
                                @"-c",
                                rvmCmd,
                                [ScriptValue scriptValueWithKey:@"rvmRvmrc"],
                                nil];
            
            [self runTask];

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
    
    self.ruby = [self.aryRubyController selectedObjects][0];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addRubyDocNotification:)
                                                 name:@"TrogonAddRubyDoc" 
                                               object:nil];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs open", rvmPath, self.ruby.name];
    self.currentTask = [TaskStep taskStepWithCommandLine:
                        @"/bin/bash",
                        @"-c",
                        rvmCmd,
                        [ScriptValue scriptValueWithKey:@"rvmDocsOpen"],
                        nil];
    
    [self runTask];
}

- (IBAction)btnLaunchGemServer:(id)sender {
    if ([[self.aryRubyController selectedObjects] count] == 0) {
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
    
    self.ruby = [self.aryRubyController selectedObjects][0];
    GemSet *gemset = [self.aryGemSetsController selectedObjects][0];

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
    
    Ruby *rvm = [self.aryRubyController selectedObjects][0];
    GemSet *gemset = [self.aryGemSetsController selectedObjects][0];
    
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
