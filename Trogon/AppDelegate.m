//
//  AppDelegate.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "AppDelegate.h"
#import "NSString+trimLeadingWhitespace.h"
#import "NSString+trimTrailingWhitespace.h"
#import "Task.h"

@implementation AppDelegate
@synthesize sheetControllerProgress = _sheetControllerProgress;
@synthesize sheetControllerRvm = _sheetControllerRvm;
@synthesize sheetControllerRubyDoc = _sheetControllerRubyDoc;
@synthesize sheetControllerGemServer = _sheetControllerGemServer;
@synthesize window = _window;
@synthesize rvms = _rvms;
@synthesize gemsets = _gemsets;
@synthesize gems = _gems;
@synthesize ruby = _ruby;

@synthesize tblRvm = _tblRvm;
@synthesize tblGemset = _tblGemset;
@synthesize tblGem = _tblGem;

@synthesize aryRvmsController = _aryRvmsController;
@synthesize aryGemSetsController = _aryGemSetsController;
@synthesize aryGemsController = _aryGemsController;

- (id)init {
    self = [super init];
    if (self) {
        _rvms = [[NSMutableArray alloc] init];
        _gemsets = [[NSMutableArray alloc] init];
        _gems = [[NSMutableArray alloc] init];
        
        _ruby = [[Ruby alloc] init];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addInterpretersNotification:)
                                                 name:@"TrogonAddRubyInterpreter" 
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

    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self reloadInterpreters];
}

- (void)addInterpretersNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshInterpretersNotification:)
                                                 name:@"TrogonRefreshRubyInterpreter" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_ruby"];

    Ruby *ruby = [[notification userInfo] objectForKey:@"ruby"];

    NSString *interpreter = [ruby.interpreter stringByTrimmingTrailingWhitespace];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"[" withString:@""];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm install %@", rvmPath, interpreter];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil] 
                            object:nil
                          selector:nil
                       synchronous:YES];
}

- (void)addGemsetNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsetsNotification:)
                                                 name:@"TrogonRefreshGemset" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_gemset"];
    
    NSString *gemset = [[notification userInfo] objectForKey:@"gemset"];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset create %@", rvmPath, self.ruby.interpreter, gemset];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil] 
                            object:nil
                          selector:nil
                       synchronous:YES];
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
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem install %@", rvmPath, self.ruby.interpreter, gemset.name, gem];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil] 
                            object:nil
                          selector:nil
                       synchronous:YES];
}

- (void)addRvmNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonRefreshRubyInterpreter" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_rvm"];

    NSError *error;
    NSURL *rvmScriptAddress = [NSURL URLWithString:@"https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer"];
    NSString *rvmScript = [NSString stringWithContentsOfURL:rvmScriptAddress encoding:NSUTF8StringEncoding error:&error];
//    NSString *rvmCmd = [NSString stringWithFormat:@"/bin/bash -s stable < <(%@)", rvmScript];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmScript, nil] 
                            object:nil
                          selector:nil
                       synchronous:YES];
}

- (void)addRubyDocNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonAddRubyDoc" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"install_ruby_doc"];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs generate", rvmPath, self.ruby.interpreter];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil] 
                            object:nil
                          selector:nil
                       synchronous:YES];
}

- (void)refreshInterpretersNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"TrogonRefreshRubyInterpreter" 
                                                  object:nil];
    
    [self reloadInterpreters];
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
    if ([[self.aryRvmsController selectedObjects] count] == 0) {
        return;
    }
    
    self.ruby = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs open", rvmPath, self.ruby.interpreter];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                            object:self
                          selector:@selector(readGemList:)
                       synchronous:NO];
}

- (void)startGemServer:(NSNotification *)notification {
    NSString *port = (NSString *)[[notification userInfo] objectForKey:@"port"];
    
    if ([[self.aryRvmsController selectedObjects] count] == 0) {
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
        
    self.ruby = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    _gemServer = [[GemServer alloc] init];
    [_gemServer launchGemServer:self.ruby.interpreter 
                         gemset:gemset.name 
                           port:port];
}

- (void)stopGemServer:(NSNotification *)notification {
    [_gemServer killGemServer];
    _gemServer = nil;
}

- (void)reloadInterpreters {
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rvmPath]) {
        NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list", rvmPath];
        [[Task sharedTask] performTask:@"/bin/sh" 
                         withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                                object:self
                              selector:@selector(readInterpreterData:)
                           synchronous:NO];
    }
    else {
        NSLog(@"RVM not installed");
        [_sheetControllerRvm add:self];
    }
}

-(void)readInterpreterData: (NSString *)output {
    [self.rvms removeAllObjects];
    
    // pull just the ruby interpreters out of the mess we get back
    for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
        // first line is always "rvm rubies" and we don't want it
        if ([line length] > 0 && [line localizedCompare:@"rvm rubies"] != NSOrderedSame) {
            Ruby *aRvm = [[Ruby alloc] init];
            NSArray *interpreters = [[line stringByTrimmingLeadingWhitespace] componentsSeparatedByString:@" "];
            
            if ([interpreters count] > 1) {
                if ([[interpreters objectAtIndex:0] localizedCompare:@"=>"] == NSOrderedSame) {
                    aRvm.interpreter = [interpreters objectAtIndex:1];
                }
                else {
                    aRvm.interpreter = [interpreters objectAtIndex:0];
                }
                [self.rvms addObject:aRvm];
                self.rvms = self.rvms;
            }
        }
    }

    // load the gemset list
    [self reloadGemsetList];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([aNotification object] == _tblRvm) {
        if ([[self.aryRvmsController selectedObjects] count] == 0) {
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
    self.ruby = [[self.aryRvmsController selectedObjects] objectAtIndex:0];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset list", rvmPath, self.ruby.interpreter];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                            object:self
                          selector:@selector(readGemsetList:)
                       synchronous:NO];
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
        
        GemSet *aGemSet = [[GemSet alloc] init];
        aGemSet.name = [line stringByTrimmingLeadingWhitespace];
        [self.gemsets addObject:aGemSet];
        self.gemsets = self.gemsets;
    }
    
    [self reloadGemList];
}

- (void)reloadGemList {
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
    
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    [self.tblGem reloadData];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem list", rvmPath, self.ruby.interpreter, gemset.name];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                            object:self
                          selector:@selector(readGemList:)
                       synchronous:NO];
}

- (void)readGemList:(NSString *)output {
    [self.gems removeAllObjects];
    
    NSInteger gemCount = 0;
    // pull just the ruby gems out of the mess we get back
    for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
        if ([line length] == 0) { // skip empty lines
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

- (IBAction)btnRemoveInterpreter:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshInterpretersNotification:)
                                                 name:@"TrogonRefreshRubyInterpreter" 
                                               object:nil];

    [_sheetControllerProgress add:self action:@"uninstall_ruby"];
    
    Ruby *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
    
    NSString *interpreter = [rvm.interpreter stringByTrimmingTrailingWhitespace];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm remove %@ --archive", rvmPath, interpreter];
    (void)[[Task sharedTask] performTask:@"/bin/sh" 
                           withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                                  object:nil
                                selector:nil
                             synchronous:YES];
}

- (IBAction)btnRemoveGemset:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsetsNotification:)
                                                 name:@"TrogonRefreshGemset" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"uninstall_gemset"];

    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm --force gemset delete %@", rvmPath, self.ruby.interpreter, gemset.name];
    (void)[[Task sharedTask] performTask:@"/bin/sh" 
                           withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                                  object:nil
                                selector:nil
                             synchronous:YES];
}

- (IBAction)btnRemoveGem:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshGemsNotification:)
                                                 name:@"TrogonRefreshGem" 
                                               object:nil];
    
    [_sheetControllerProgress add:self action:@"uninstall_gem"];
    
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
    Gem *gem = [[self.aryGemsController selectedObjects] objectAtIndex:0];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm gemset use %@ && gem uninstall %@", rvmPath, self.ruby.interpreter, gemset.name, gem.nameWithoutVersion];
    (void)[[Task sharedTask] performTask:@"/bin/sh" 
                           withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                                  object:nil
                                selector:nil
                             synchronous:YES];
}

- (IBAction)toolbarBtnLaunchTerminal:(id)sender {
    if ([[self.aryRvmsController selectedObjects] count] == 0) {
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

    Ruby *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];
    
    NSString *interpreter = [rvm.interpreter stringByTrimmingTrailingWhitespace];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"tell application \"Terminal\" to (do script \"source %@ && rvm %@ && rvm gemset use %@\" in window 1) activate", rvmPath, interpreter, gemset.name];
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

- (IBAction)toolbarBtnCreateRvmrc:(id)sender {
    if ([[self.aryRvmsController selectedObjects] count] == 0) {
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

            self.ruby = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
            GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

            NSString *interpreter = [self.ruby.interpreter stringByTrimmingTrailingWhitespace];
            
            NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
            NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && cd %@ && rvm --rvmrc --create %@@%@", rvmPath, [pathToFile path], interpreter, gemset.name];
            (void)[[Task sharedTask] performTask:@"/bin/sh" 
                                   withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                                          object:nil
                                        selector:nil
                                     synchronous:YES];

            [self performSelectorOnMainThread:@selector(rvmrcInstalled:)
                                   withObject:pathToFile 
                                waitUntilDone:NO];


        }        
    }];
}

- (IBAction)toolbarBtnLaunchRubyDocs:(id)sender {
    if ([[self.aryRvmsController selectedObjects] count] == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"ERROR" 
                                         defaultButton:@"OK" 
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Please select a ruby from the list"];

        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    
    self.ruby = [[self.aryRvmsController selectedObjects] objectAtIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addRubyDocNotification:)
                                                 name:@"TrogonAddRubyDoc" 
                                               object:nil];
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm %@ && rvm docs open", rvmPath, self.ruby.interpreter];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]
                            object:self
                          selector:@selector(readRubyDocs:)
                       synchronous:NO];
}

- (IBAction)toolbarBtnLaunchGemServer:(id)sender {
    if ([[self.aryRvmsController selectedObjects] count] == 0) {
        return;
    }
    if ([[self.aryGemSetsController selectedObjects] count] == 0) {
        return;
    }
    
    self.ruby = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
    GemSet *gemset = [[self.aryGemSetsController selectedObjects] objectAtIndex:0];

    [_sheetControllerGemServer add:self ruby:self.ruby.interpreter gem:gemset.name];
}

- (void)rvmrcInstalled:(NSURL *)pathToFile {
    NSAlert *alert = [NSAlert alertWithMessageText:@"SUCCESS" 
                                     defaultButton:@"OK" 
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@".rvmrc was created at: %@", [pathToFile path]];

    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}
@end
