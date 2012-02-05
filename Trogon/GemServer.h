//
//  GemServer.h
//  Trogon
//
//  Created by Ricky Nelson on 2/5/12.
//  Copyright (c) 2012 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GemServer : NSObject {
    NSTask *_task;
}

- (void)launchGemServer:(NSString *)ruby 
                 gemset:(NSString *)aGemset 
                   port:(NSString *)port;
- (void)killGemServer;
@end
