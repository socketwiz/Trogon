//
//  RvmSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 2/2/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import "RvmSheetController.h"

@implementation RvmSheetController
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
