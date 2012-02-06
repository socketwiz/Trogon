//
//  RvmSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 2/2/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import "RvmSheetController.h"

@implementation RvmSheetController
@synthesize txtViewInstaller;
@synthesize objectSheet;
@synthesize documentWindow;


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

    NSString *text = [NSString stringWithFormat:@"If you click install, a script will be downloaded from:\n\nhttps://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer\n\nand will be executed on your system in order to install the latest RVM. You are encouraged to view this script and understand it so that you feel more comfortable running it."];

    [self.txtViewInstaller setEditable:YES];
    [self.txtViewInstaller insertText:text];
    [self.txtViewInstaller setEditable:NO];

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
        // we need to cleanup _before_ we send the notification below to create a new sheet
        // otherwise things get wonky because the new sheet will get created before this one
        // is cleaned up, then when you dimsiss the new sheet, this one persists and you can't 
        // get rid of it :(
        [objectSheet orderOut:self];
        
        // send it to the AppDelegate so we can display a progress sheet
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonAddRvm" 
                                                            object:self
                                                          userInfo:nil];
    }
    else {
        [objectSheet orderOut:self];
    }
}

@end
