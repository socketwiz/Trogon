//
//  Gem.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "Gem.h"

@implementation Gem
@synthesize name = _name;
@synthesize nameWithoutVersion = _nameWithoutVersion;

- (NSString *)nameWithoutVersion {
    NSArray *parts = [self.name componentsSeparatedByString:@" "];
    
    return parts[0];
}

@end
