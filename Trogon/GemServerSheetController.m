//
//  GemServerSheetController.m
//  Trogon
//
//  Created by Ricky Nelson on 2/5/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import "GemServerSheetController.h"

@implementation GemServerSheetController
@synthesize lblGem;
@synthesize txtPort;
@synthesize txtViewGemServerOutput;
@synthesize btnStart;
@synthesize btnStop;
@synthesize btnClose;
@synthesize btnViewDocs;
@synthesize documentWindow;
@synthesize objectSheet;

- (id)init {
    self = [super init];
    if (self) {
        _action = [[NSMutableString alloc] init];
    }
    return self;
}

- (IBAction)add:(id)sender ruby:(NSString *)aRuby gem:(NSString *)aGem {
    if (objectSheet == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"GemServerSheet" bundle:myBundle];
        
        BOOL success = [nib instantiateNibWithOwner:self topLevelObjects:nil];
        if (success != YES) {
            NSError *error;
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Unable to load GemServerSheet.xib" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"TrogonGemServerSheetDomainError" code:100 userInfo:errorDetail];
            [NSApp presentError:error];
            NSLog(@"%@", [errorDetail valueForKey:NSLocalizedDescriptionKey]);
            
            return;
        }
    }
    
    [self.txtViewGemServerOutput setEditable:YES];
    [self.txtViewGemServerOutput setString:@""];
    [self.txtViewGemServerOutput setEditable:NO];
    
    NSString *gemLabel = [NSString stringWithFormat:@"%@@%@", aRuby, aGem];
    [self.lblGem setStringValue:gemLabel];
    
    [btnStop setEnabled:NO];
    [btnViewDocs setEnabled:NO];
    
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

- (IBAction)startGemServer:(id)sender {
    [btnStart setEnabled:NO];
    [btnStop setEnabled:YES];
    [btnViewDocs setEnabled:YES];
    [btnClose setEnabled:NO];
    [txtPort setEditable:NO];
    
    _port = [NSString stringWithFormat:@"%i", 8808];
    if ([[txtPort stringValue] localizedCompare:@""] != NSOrderedSame) {
        _port = [txtPort stringValue];
    }

    NSString *serverText = [NSString stringWithFormat:@"Starting Gem Server on port: %@\n", _port];
    [self.txtViewGemServerOutput setEditable:YES];
    [self.txtViewGemServerOutput insertText:serverText];
    [self.txtViewGemServerOutput setEditable:NO];

    NSDictionary *data = @{@"port": _port};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonStartGemServer" 
                                                        object:self
                                                      userInfo:data];
}

-(void)readGemServerOutput: (NSString *)output {
    [self.txtViewGemServerOutput setEditable:YES];
    [self.txtViewGemServerOutput insertText:output];
    [self.txtViewGemServerOutput setEditable:NO];
}

- (IBAction)stopGemServer:(id)sender {
    [btnStart setEnabled:YES];
    [btnStop setEnabled:NO];
    [btnViewDocs setEnabled:NO];
    [btnClose setEnabled:YES];
    [txtPort setEditable:YES];
    
    NSString *serverText = [NSString stringWithFormat:@"Stopping Gem Server\n"];
    [self.txtViewGemServerOutput setEditable:YES];
    [self.txtViewGemServerOutput insertText:serverText];
    [self.txtViewGemServerOutput setEditable:NO];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TrogonStopGemServer" 
                                                        object:self
                                                      userInfo:nil];
}

- (IBAction)viewDocs:(id)sender {
    NSString *docUrl = [NSString stringWithFormat:@"http://localhost:%@", _port];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:docUrl]];
}

- (void)objectSheetDidEnd:(NSWindow *)sheet
               returnCode:(int)returnCode
              contextInfo:(void  *)contextInfo {
    
    if (returnCode == NSOKButton) {
    }
    
    [objectSheet orderOut:self];
}

@end
