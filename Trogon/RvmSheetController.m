//
//  RvmSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "RvmSheetController.h"
#import "NSString+trimTrailingWhitespace.h"
#import "Task.h"

@implementation RvmSheetController
@synthesize aryRvmsController;
@synthesize documentWindow;
@synthesize objectSheet;
@synthesize interpreters = _interpreters;
@synthesize outputInterpreter = _outputInterpreter;


-(void)readAvailableInterpreters: (NSString *)output {
    [self.outputInterpreter appendString:output];
    
    // pull just the ruby interpreters out of the mess we get back
    for (NSString *line in [self.outputInterpreter componentsSeparatedByString:@"\n"]) {
        if ([line length] > 0 && ![line hasPrefix:@"#"]) {
            Rvm *aRvm = [[Rvm alloc] init];
            aRvm.interpreter = line;
            [_interpreters addObject:aRvm];
            self.interpreters = _interpreters;
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        _interpreters = [[NSMutableArray alloc] init];
        _outputInterpreter = [[NSMutableString alloc] init];
    }
    return self;
}

- (IBAction)add:(id)sender {
    if (objectSheet == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"RvmSheet" bundle:myBundle];
        
        BOOL success = [nib instantiateNibWithOwner:self topLevelObjects:nil];
        if (success != YES) {
            NSError *error;
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Unable to load RvmSheet.xib" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"TrogonRvmSheetDomainError" code:100 userInfo:errorDetail];
            [NSApp presentError:error];
            NSLog(@"%@", [errorDetail valueForKey:NSLocalizedDescriptionKey]);

            return;
        }
    }
    
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list known", rvmPath];
    [[Task sharedTask] performTask:@"/bin/sh" 
                     withArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil] 
                            object:self
                          selector:@selector(readAvailableInterpreters:)
                       synchronous:NO];
    
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
        Rvm *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];
        NSDictionary *info = [NSDictionary dictionaryWithObject:rvm forKey:@"rvm"];
        
        // we need to cleanup _before_ we send the notification below to create a new sheet
        // otherwise things get wonky because the new sheet will get created before this one
        // is cleaned up, then when you dimsiss the new sheet, this one persists and you can't 
        // get rid of it :(
        [objectSheet orderOut:self];

        // send it to the AppDelegate so we can display a progress sheet
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonAddRubyInterpreter" 
                                                            object:self
                                                          userInfo:info];        
    }
    else {
        [objectSheet orderOut:self];
    }
}

@end
