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
@synthesize taskOutput = _taskOutput;


-(void)readAvailableRubys:(NSNotification *)notification {
    NSString *output = [notification userInfo][@"ouput"];

    // pull just the rubys out of the mess we get back
    for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
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
        _taskOutput = [[NSMutableString alloc] init];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readAvailableRubys:)
                                                 name:@"TrogonReadAvailableRubys"
                                               object:nil];

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
    TaskStep *task = [TaskStep taskStepWithCommandLine:
                      @"/bin/bash",
                      @"-c",
                      rvmCmd,
                      [ScriptValue scriptValueWithKey:@"rvmListKnown"],
                      nil];

    // send it to the AppDelegate so we can run the task from a common NSOperationQueue
    NSDictionary *info = @{@"task": task};

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonRvmListKnown"
                                                        object:self
                                                      userInfo:info];
    
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
        Ruby *rvm = [self.aryRvmsController selectedObjects][0];
        NSDictionary *info = @{@"ruby": rvm};
        
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
