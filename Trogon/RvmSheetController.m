//
//  RvmSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 2/2/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import "RvmSheetController.h"

@implementation RvmSheetController
@synthesize lblPathToRvm;
@synthesize rdoRvmChoice;
@synthesize txtRvmPath;
@synthesize btnLocate;
@synthesize btnInstall;
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
    
    [lblPathToRvm setHidden:YES];
    [txtRvmPath setHidden:YES];
    [btnLocate setHidden:YES];
    
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
    else {
        [objectSheet orderOut:self];
    }
}

@end
