//
//  RvmSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "RvmSheetController.h"

@implementation RvmSheetController
@synthesize documentWindow;
@synthesize objectSheet;

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
