//
//  NSString+trimLeadingWhitespace.m
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "NSString+trimLeadingWhitespace.h"

@implementation NSString (trimLeadingWhitespace)
- (NSString *)stringByTrimmingLeadingWhitespace {
    NSInteger i = 0;
    
    while ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    
    return [self substringFromIndex:i];
}
@end
