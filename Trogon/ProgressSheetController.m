//
//  ProgressSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 10/18/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "ProgressSheetController.h"

@implementation ProgressSheetController
@synthesize btnContinue;
@synthesize textViewProgress;
@synthesize lblProgress;
@synthesize imgProgress;
@synthesize documentWindow;
@synthesize objectSheet;
@synthesize action = _action;

- (id)init {
    self = [super init];
    if (self) {
        _action = [[NSMutableString alloc] init];
    }
    return self;
}

- (IBAction)add:(id)sender action:(NSString *)aAction {
    [self.action setString:aAction];
    
    if (objectSheet == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"ProgressSheet" bundle:myBundle];
        
        BOOL success = [nib instantiateNibWithOwner:self topLevelObjects:nil];
        if (success != YES) {
            NSError *error;
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Unable to load ProgressSheet.xib" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"TrogonProgressSheetDomainError" code:100 userInfo:errorDetail];
            [NSApp presentError:error];
            NSLog(@"%@", [errorDetail valueForKey:NSLocalizedDescriptionKey]);
            
            return;
        }
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readInstallProgress:)
                                                 name:NSFileHandleDataAvailableNotification 
                                               object:nil];

    if ([self.action localizedCompare:@"install_ruby"] == NSOrderedSame) {
        [self.lblProgress setStringValue:@"Installing new Ruby"];
    }
    if ([self.action localizedCompare:@"uninstall_ruby"] == NSOrderedSame) {
        [self.lblProgress setStringValue:@"Uninstalling Ruby"];
    }
    
    if ([self.action localizedCompare:@"install_gemset"] == NSOrderedSame) {
        [self.lblProgress setStringValue:@"Installing new Gemset"];
    }
    if ([self.action localizedCompare:@"uninstall_gemset"] == NSOrderedSame) {
        [self.lblProgress setStringValue:@"Uninstalling Gemset"];
    }
    
    if ([self.action localizedCompare:@"install_gem"] == NSOrderedSame) {
        [self.lblProgress setStringValue:@"Installing new Gem"];
    }
    if ([self.action localizedCompare:@"uninstall_gem"] == NSOrderedSame) {
        [self.lblProgress setStringValue:@"Uninstalling Gem"];
    }

    [self.textViewProgress setString:@""];
    [self.btnContinue setEnabled:NO];

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
    }
    
    [objectSheet orderOut:self];
}

-(void)readInstallProgress: (NSNotification *)notification {
    NSData *data;
    NSString *text;
    
    data = [[notification object] availableData];
    text = [[NSString alloc] initWithData:data 
                                 encoding:NSASCIIStringEncoding];
    
    [self.textViewProgress insertText:text];
    
    if([data length]) {
        [[notification object] waitForDataInBackgroundAndNotify];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSFileHandleDataAvailableNotification 
                                                      object:nil];

        if ([self.action localizedCompare:@"install_ruby"] == NSOrderedSame) {            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonRefreshRubyInterpreter" 
                                                                object:self
                                                              userInfo:nil];
            [self.lblProgress setStringValue:@"Ruby Installation Complete"];
        }
        if ([self.action localizedCompare:@"uninstall_ruby"] == NSOrderedSame) {            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonRefreshRubyInterpreter" 
                                                                object:self
                                                              userInfo:nil];
            [self.lblProgress setStringValue:@"Ruby Uninstall Complete"];
        }
        
        if ([self.action localizedCompare:@"install_gemset"] == NSOrderedSame) {            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonRefreshGemset" 
                                                                object:self
                                                              userInfo:nil];
            [self.lblProgress setStringValue:@"Gemset Installation Complete"];
        }
        if ([self.action localizedCompare:@"uninstall_gemset"] == NSOrderedSame) {            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonRefreshGemset" 
                                                                object:self
                                                              userInfo:nil];
            [self.lblProgress setStringValue:@"Gemset Uninstall Complete"];
        }
        
        if ([self.action localizedCompare:@"install_gem"] == NSOrderedSame) {            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonRefreshGem" 
                                                                object:self
                                                              userInfo:nil];
            [self.lblProgress setStringValue:@"Gem Installation Complete"];
        }
        if ([self.action localizedCompare:@"uninstall_gem"] == NSOrderedSame) {            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonRefreshGem" 
                                                                object:self
                                                              userInfo:nil];
            [self.lblProgress setStringValue:@"Gem Uninstall Complete"];
        }
        [self.btnContinue setEnabled:YES];
    }
}

@end
