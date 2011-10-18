//
//  NSString+trimTrailingWhitespace.m
//  Trogon
//
//  Created by Ricky Nelson on 10/17/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import "NSString+trimTrailingWhitespace.h"

@implementation NSString (trimTrailingWhitespace)
- (NSString *)stringByTrimmingTrailingWhitespace {
    NSInteger i = [self length];
    
    while ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i-1]]) {
        i--;
    }
    
    NSRange nonWhitespaceRange = {0, i};
    return [self substringWithRange:nonWhitespaceRange];
}
@end
