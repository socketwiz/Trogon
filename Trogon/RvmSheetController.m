//
//  RvmSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "RvmSheetController.h"
#import "NSString+trimTrailingWhitespace.h"

@implementation RvmSheetController
@synthesize aryRvmsController;
@synthesize documentWindow;
@synthesize objectSheet;
@synthesize interpreters = _interpreters;

- (void)awakeFromNib {
    if ([_interpreters count] > 0) {
        return;
    }
    
    NSTask *_task;
    NSPipe *pipe = [NSPipe pipe];
    
    _task = [[NSTask alloc] init];
    [_task setLaunchPath:@"/bin/sh"];
    [_task setStandardInput:[NSPipe pipe]]; // xcode bug, won't exit without this
    [_task setStandardOutput: pipe];
    [_task setStandardError: pipe];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm list known", rvmPath];
    [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    [_task launch];
    
    [_task waitUntilExit];
    
    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    // pull just the ruby interpreters out of the mess we get back
    for (NSString *line in [outputString componentsSeparatedByString:@"\n"]) {
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
    
    [NSApp beginSheet:objectSheet
       modalForWindow:[documentWindow window]
        modalDelegate:self
       didEndSelector:@selector(objectSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)cancel:(id)sender {
    [NSApp endSheet:objectSheet returnCode:NSCancelButton];
}

- (IBAction)complete:(id)sender {
    Rvm *rvm = [[self.aryRvmsController selectedObjects] objectAtIndex:0];

    NSTask *_task;
    NSPipe *pipe = [NSPipe pipe];
    
    _task = [[NSTask alloc] init];
    [_task setLaunchPath:@"/bin/sh"];
    [_task setStandardInput:[NSPipe pipe]]; // xcode bug, won't exit without this
    [_task setStandardOutput: pipe];
    [_task setStandardError: pipe];
    NSString *rvmPath = [NSString stringWithString:[@"~/.rvm/scripts/rvm" stringByExpandingTildeInPath]];
    
    // strip trailing spaces, [ and ] characters
    NSString *interpreter = [rvm.interpreter stringByTrimmingTrailingWhitespace];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"[" withString:@""];
    interpreter = [interpreter stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSString *rvmCmd = [NSString stringWithFormat:@"source %@ && rvm install %@", rvmPath, interpreter];
    [_task setArguments:[NSArray arrayWithObjects:@"-c", rvmCmd, nil]];
    [_task launch];
    
    [_task waitUntilExit];
    
//    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
//    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonReloadInterpreters" 
                                                        object:nil];

    [NSApp endSheet:objectSheet returnCode:NSOKButton];
}

- (void)objectSheetDidEnd:(NSWindow *)sheet
               returnCode:(int)returnCode
              contextInfo:(void  *)contextInfo {
    
    if (returnCode == NSOKButton) {
    }
    
    [objectSheet orderOut:self];
}

@end
